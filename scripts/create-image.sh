#!/usr/bin/env bash
# scripts/create-image.sh
# Assemble all built packages into a bootable PureDarwin Xmas disk image.
#
# Usage:  create-image.sh <output-dir>
#
# The script creates a raw HFS+ disk image that can be booted under VMware,
# QEMU, or written to physical media.
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPTS_DIR")"

OUTPUT_DIR="${1:-$REPO_ROOT/output}"
SYSROOT="$OUTPUT_DIR/sysroot"
IMAGE="$OUTPUT_DIR/puredarwin-xmas.img"

# Image size in MB (must be large enough for the full sysroot)
IMAGE_SIZE_MB=2048

die() { echo "[image][ERROR] $*" >&2; exit 1; }
log() { echo "[image] $*"; }

[[ -d "$SYSROOT" ]] || die "Sysroot not found at $SYSROOT. Run 'make build' first."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Creating PureDarwin Xmas disk image"
echo " Sysroot:  $SYSROOT"
echo " Image:    $IMAGE"
echo " Size:     ${IMAGE_SIZE_MB} MB"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── macOS hdiutil-based image creation ───────────────────────────────────────
if [[ "$(uname -s)" == "Darwin" ]]; then
    log "Creating sparse image..."
    SPARSE_IMAGE="${IMAGE%.img}.sparseimage"
    rm -f "$SPARSE_IMAGE" "$IMAGE"

    hdiutil create \
        -size "${IMAGE_SIZE_MB}m" \
        -fs "HFS+" \
        -volname "PureDarwin Xmas" \
        -type SPARSE \
        -o "${IMAGE%.img}"

    log "Mounting image..."
    MOUNT_POINT=$(mktemp -d "/tmp/puredarwin-mount.XXXXXX")
    hdiutil attach "$SPARSE_IMAGE" -mountpoint "$MOUNT_POINT" -nobrowse

    trap 'log "Unmounting..."; hdiutil detach "$MOUNT_POINT" -force 2>/dev/null || true; rm -rf "$MOUNT_POINT"' EXIT

    # ── Populate the image ────────────────────────────────────────────────────
    log "Copying sysroot into image..."
    rsync -aH --exclude='.DS_Store' "$SYSROOT/" "$MOUNT_POINT/"

    # Ensure key directories exist
    for dir in bin sbin usr/bin usr/sbin usr/lib usr/libexec etc var tmp private; do
        mkdir -p "$MOUNT_POINT/$dir"
    done

    # Create standard symlinks (PureDarwin Xmas layout)
    log "Creating filesystem symlinks..."
    for link in etc var tmp; do
        if [[ ! -L "$MOUNT_POINT/$link" ]]; then
            ln -sf "private/$link" "$MOUNT_POINT/$link"
        fi
    done

    # ── Install bootloader (boot.efi / BootX) ────────────────────────────────
    # The bootloader from the sysroot is already copied; bless the volume.
    log "Blessing the volume..."
    bless --folder "$MOUNT_POINT/System/Library/CoreServices" \
          --bootefi  "$MOUNT_POINT/System/Library/CoreServices/boot.efi" \
          --setBoot  2>/dev/null || \
    bless --folder "$MOUNT_POINT/System/Library/CoreServices" 2>/dev/null || \
    log "  (bless unavailable — image may need manual boot configuration)"

    log "Unmounting image..."
    hdiutil detach "$MOUNT_POINT" -force
    rm -rf "$MOUNT_POINT"
    trap - EXIT

    log "Converting to read-only flat image..."
    hdiutil convert "$SPARSE_IMAGE" -format UDIF -o "${IMAGE%.img}" -ov
    # hdiutil names the output with .dmg — rename to .img for clarity
    if [[ -f "${IMAGE%.img}.dmg" && ! -f "$IMAGE" ]]; then
        mv "${IMAGE%.img}.dmg" "$IMAGE"
    fi
    rm -f "$SPARSE_IMAGE"

else
    # ── Non-macOS fallback (e.g., CI environment — produce a tar archive) ──
    log "Non-macOS host detected — creating tar archive instead of HFS+ image."
    TAR_OUT="${IMAGE%.img}.tar.gz"
    tar -czf "$TAR_OUT" -C "$SYSROOT" .
    log "Sysroot archive: $TAR_OUT"
    IMAGE="$TAR_OUT"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Disk image ready: $IMAGE"
SIZE=$(du -sh "$IMAGE" 2>/dev/null | awk '{print $1}')
echo " Size: $SIZE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To run the image in VMware or QEMU, see docs/BUILDING.md."
echo ""
