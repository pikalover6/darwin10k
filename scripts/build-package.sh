#!/usr/bin/env bash
# scripts/build-package.sh
# Build a single Darwin 9 / PureDarwin Xmas source package.
#
# Usage:  build-package.sh <package-name> <sources-dir> <output-dir>
#
# The script:
#  1. Locates the matching tarball in <sources-dir>
#  2. Extracts it into <output-dir>/build/<package>
#  3. Applies any patches from patches/<package>/
#  4. Runs the Apple-style "B&I" (Build and Integration) build
#  5. Installs artefacts into <output-dir>/sysroot
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPTS_DIR")"
PATCHES_DIR="$REPO_ROOT/patches"

PKG="${1:?Usage: build-package.sh <package-name> <sources-dir> <output-dir>}"
SOURCES_DIR="${2:-$REPO_ROOT/sources}"
OUTPUT_DIR="${3:-$REPO_ROOT/output}"

BUILD_DIR="$OUTPUT_DIR/build"
SYSROOT="$OUTPUT_DIR/sysroot"
PKG_BUILD="$BUILD_DIR/$PKG"

mkdir -p "$BUILD_DIR" "$SYSROOT"

# ── Utility ───────────────────────────────────────────────────────────────────
log()  { echo "[build-package:$PKG] $*"; }
die()  { echo "[build-package:$PKG][ERROR] $*" >&2; exit 1; }

# ── Locate source tarball ─────────────────────────────────────────────────────
# Look for <PKG>-*.tar.gz or <PKG>-*.tar.bz2 in the sources directory.
TARBALL=$(find "$SOURCES_DIR" -maxdepth 1 \
    \( -name "${PKG}-*.tar.gz" -o -name "${PKG}-*.tar.bz2" -o -name "${PKG}-*.tar.xz" \) \
    | sort -V | tail -1)

[[ -n "$TARBALL" ]] || die "No source tarball found for '$PKG' in $SOURCES_DIR"
log "Tarball: $(basename "$TARBALL")"

# ── Extract ───────────────────────────────────────────────────────────────────
if [[ -d "$PKG_BUILD" ]]; then
    log "Removing stale build directory..."
    rm -rf "$PKG_BUILD"
fi

log "Extracting..."
mkdir -p "$PKG_BUILD"
tar -xf "$TARBALL" -C "$PKG_BUILD" --strip-components=1

# ── Apply patches ─────────────────────────────────────────────────────────────
PKG_PATCHES="$PATCHES_DIR/$PKG"
if [[ -d "$PKG_PATCHES" ]]; then
    log "Applying patches from $PKG_PATCHES ..."
    for patch in "$PKG_PATCHES"/*.patch; do
        [[ -f "$patch" ]] || continue
        log "  patch: $(basename "$patch")"
        patch -p1 -d "$PKG_BUILD" < "$patch" || die "Patch failed: $patch"
    done
fi

# ── Build ─────────────────────────────────────────────────────────────────────
# Apple Darwin packages follow the "B&I" convention. Most packages use xcodebuild
# or a classic Makefile. We detect which system to use.

cd "$PKG_BUILD"

# Common build environment variables for Darwin 9 / Leopard SDK
DARWIN9_SDK="$(xcrun --show-sdk-path 2>/dev/null || true)"
export SDKROOT="${DARWIN9_SDK}"
export MACOSX_DEPLOYMENT_TARGET="10.5"
export DSTROOT="$SYSROOT"
export OBJROOT="$PKG_BUILD/.obj"
export SYMROOT="$PKG_BUILD/.sym"
export RC_ProjectName="$PKG"
export RC_ARCHS="i386 x86_64"

mkdir -p "$OBJROOT" "$SYMROOT"

# ── Per-package build logic ───────────────────────────────────────────────────
# Most Apple open-source packages support `make install DSTROOT=...` or
# `xcodebuild install`.  We try the most common approaches in order.

build_with_xcodebuild() {
    log "Building with xcodebuild..."
    xcodebuild \
        DSTROOT="$DSTROOT" \
        OBJROOT="$OBJROOT" \
        SYMROOT="$SYMROOT" \
        SDKROOT="$SDKROOT" \
        MACOSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
        RC_ARCHS="$RC_ARCHS" \
        install 2>&1
}

build_with_make() {
    log "Building with make install..."
    make -j"$(sysctl -n hw.logicalcpu 2>/dev/null || echo 4)" \
        DSTROOT="$DSTROOT" \
        install 2>&1
}

build_with_configure() {
    log "Building with ./configure && make install..."
    ./configure \
        --prefix=/usr \
        --host=i386-apple-darwin9 2>&1
    make -j"$(sysctl -n hw.logicalcpu 2>/dev/null || echo 4)" 2>&1
    make DESTDIR="$DSTROOT" install 2>&1
}

# Dispatch
if [[ -n "$(find . -maxdepth 2 -name '*.xcodeproj' -o -name '*.xcworkspace' 2>/dev/null | head -1)" ]]; then
    build_with_xcodebuild
elif [[ -f "GNUmakefile" || -f "Makefile" ]]; then
    build_with_make
elif [[ -f "configure" ]]; then
    build_with_configure
else
    die "Don't know how to build '$PKG' — no Makefile, xcodeproj, or configure found."
fi

log "Package '$PKG' installed to $SYSROOT"
