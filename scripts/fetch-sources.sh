#!/usr/bin/env bash
# scripts/fetch-sources.sh
# Download all PureDarwin Xmas source tarballs from Apple's open-source site.
#
# Usage:  fetch-sources.sh <sources-dir>
#
# Each entry in packages/package-list.txt has the format:
#   <name> <version> <sha256> <url>
# Lines beginning with # are comments.
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPTS_DIR")"
PACKAGE_LIST="$REPO_ROOT/packages/package-list.txt"

SOURCES_DIR="${1:-$REPO_ROOT/sources}"
mkdir -p "$SOURCES_DIR"

# ── Utility helpers ───────────────────────────────────────────────────────────
log()  { echo "[fetch] $*"; }
warn() { echo "[fetch][WARN] $*" >&2; }
die()  { echo "[fetch][ERROR] $*" >&2; exit 1; }

# Download a single URL to a destination file.
fetch_url() {
    local url="$1"
    local dest="$2"

    if command -v curl &>/dev/null; then
        curl -fSL --retry 3 --retry-delay 2 -o "$dest" "$url"
    elif command -v wget &>/dev/null; then
        wget -q --tries=3 --wait=2 -O "$dest" "$url"
    else
        die "Neither curl nor wget is available."
    fi
}

# Verify a SHA-256 checksum.
verify_sha256() {
    local file="$1"
    local expected="$2"

    local actual
    if command -v shasum &>/dev/null; then
        actual=$(shasum -a 256 "$file" | awk '{print $1}')
    elif command -v sha256sum &>/dev/null; then
        actual=$(sha256sum "$file" | awk '{print $1}')
    else
        warn "No SHA-256 tool — skipping verification of $(basename "$file")"
        return 0
    fi

    if [[ "$actual" != "$expected" ]]; then
        warn "SHA-256 mismatch for $(basename "$file")"
        warn "  expected: $expected"
        warn "  actual:   $actual"
        return 1
    fi
    return 0
}

# ── Main ──────────────────────────────────────────────────────────────────────
[[ -f "$PACKAGE_LIST" ]] || die "Package list not found: $PACKAGE_LIST"

TOTAL=0
SKIPPED=0
FETCHED=0
FAILED=0

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Downloading PureDarwin Xmas source tarballs"
echo " Destination: $SOURCES_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

while IFS= read -r line; do
    # Skip comments and blank lines
    [[ -z "$line" || "$line" == \#* ]] && continue

    read -r NAME VERSION SHA256 URL <<< "$line"
    ((TOTAL++)) || true

    FILENAME=$(basename "$URL")
    DEST="$SOURCES_DIR/$FILENAME"

    if [[ -f "$DEST" ]]; then
        # Already downloaded — verify and skip
        if verify_sha256 "$DEST" "$SHA256"; then
            log "SKIP  $NAME-$VERSION  (already downloaded, checksum OK)"
            ((SKIPPED++)) || true
            continue
        else
            warn "Re-downloading $NAME-$VERSION (checksum mismatch)..."
            rm -f "$DEST"
        fi
    fi

    log "FETCH $NAME-$VERSION"
    log "      $URL"

    if fetch_url "$URL" "$DEST"; then
        if verify_sha256 "$DEST" "$SHA256"; then
            log "  → OK  $(du -sh "$DEST" | awk '{print $1}')"
            ((FETCHED++)) || true
        else
            warn "Checksum failed for $NAME-$VERSION — removing file."
            rm -f "$DEST"
            ((FAILED++)) || true
        fi
    else
        warn "Download failed for $NAME-$VERSION ($URL)"
        rm -f "$DEST"
        ((FAILED++)) || true
    fi
    echo ""

done < "$PACKAGE_LIST"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Fetch complete: $FETCHED downloaded, $SKIPPED skipped, $FAILED failed"
echo " Total packages: $TOTAL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ "$FAILED" -gt 0 ]]; then
    echo "ERROR: $FAILED package(s) could not be downloaded."
    echo "       Check your network connection and see docs/TROUBLESHOOTING.md."
    exit 1
fi

echo "All sources ready in: $SOURCES_DIR"
echo "Next step:  make build"
echo ""
