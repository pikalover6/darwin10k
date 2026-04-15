#!/usr/bin/env bash
# scripts/build-all.sh
# Build every PureDarwin Xmas package in the correct dependency order.
#
# Usage:  build-all.sh <sources-dir> <output-dir>
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPTS_DIR")"
BUILD_ORDER="$REPO_ROOT/packages/build-order.txt"

SOURCES_DIR="${1:-$REPO_ROOT/sources}"
OUTPUT_DIR="${2:-$REPO_ROOT/output}"
BUILD_DIR="$OUTPUT_DIR/build"
SYSROOT="$OUTPUT_DIR/sysroot"

mkdir -p "$BUILD_DIR" "$SYSROOT"

# ── Utility ───────────────────────────────────────────────────────────────────
log()  { echo "[build] $*"; }
die()  { echo "[build][ERROR] $*" >&2; exit 1; }

# ── Timestamps for progress tracking ─────────────────────────────────────────
STAMP_DIR="$OUTPUT_DIR/.stamps"
mkdir -p "$STAMP_DIR"

is_built() {
    [[ -f "$STAMP_DIR/$1.done" ]]
}

mark_built() {
    touch "$STAMP_DIR/$1.done"
}

# ── Build loop ────────────────────────────────────────────────────────────────
[[ -f "$BUILD_ORDER" ]] || die "Build order file not found: $BUILD_ORDER"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Building PureDarwin Xmas"
echo " Sources:  $SOURCES_DIR"
echo " Sysroot:  $SYSROOT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

STEP=0
TOTAL=$(grep -c '^[^#[:space:]]' "$BUILD_ORDER" || true)

while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue

    PKG="$line"
    ((STEP++)) || true

    if is_built "$PKG"; then
        log "[$STEP/$TOTAL] SKIP $PKG (already built)"
        continue
    fi

    log "[$STEP/$TOTAL] BUILD $PKG"
    PKG_LOG="$OUTPUT_DIR/logs/$PKG.log"
    mkdir -p "$(dirname "$PKG_LOG")"

    if "$SCRIPTS_DIR/build-package.sh" "$PKG" "$SOURCES_DIR" "$OUTPUT_DIR" \
           > "$PKG_LOG" 2>&1; then
        mark_built "$PKG"
        log "         → OK"
    else
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo " BUILD FAILED for: $PKG"
        echo " Log: $PKG_LOG"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        tail -40 "$PKG_LOG"
        echo ""
        echo "See docs/TROUBLESHOOTING.md for common fixes."
        exit 1
    fi

done < "$BUILD_ORDER"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " All $STEP packages built successfully."
echo " Sysroot: $SYSROOT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next step:  make image"
echo ""
