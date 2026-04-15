#!/usr/bin/env bash
# scripts/setup-env.sh
# Verify that all build prerequisites are present before starting the build.
set -euo pipefail

PASS=0
FAIL=0
WARN=0

ok()   { echo "  [OK]   $*"; ((PASS++)) || true; }
fail() { echo "  [FAIL] $*"; ((FAIL++)) || true; }
warn() { echo "  [WARN] $*"; ((WARN++)) || true; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " PureDarwin Xmas — from Source"
echo " Environment check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Operating system ──────────────────────────────────────────────────────────
echo ""
echo "▸ Operating System"
if [[ "$(uname -s)" == "Darwin" ]]; then
    MACOS_VER=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
    MACOS_MAJOR=$(echo "$MACOS_VER" | cut -d. -f1)
    MACOS_MINOR=$(echo "$MACOS_VER" | cut -d. -f2)
    # macOS 11+ uses a single-digit major (11, 12, 13, …); 10.x uses two-part.
    # Minimum supported: macOS 10.14 (Mojave).
    SUPPORTED=0
    if [[ "$MACOS_MAJOR" -ge 11 ]]; then
        SUPPORTED=1   # macOS 11 Big Sur or later — always OK
    elif [[ "$MACOS_MAJOR" -eq 10 && "${MACOS_MINOR:-0}" -ge 14 ]]; then
        SUPPORTED=1   # macOS 10.14 Mojave through 10.15 Catalina — OK
    fi
    if [[ "$SUPPORTED" -eq 1 ]]; then
        ok "macOS $MACOS_VER"
    else
        fail "macOS $MACOS_VER is too old (need 10.14 Mojave or later)"
    fi
else
    fail "This build must run on macOS (found: $(uname -s))"
fi

# ── Xcode ─────────────────────────────────────────────────────────────────────
echo ""
echo "▸ Xcode"
if xcodebuild -version &>/dev/null; then
    XCODE_VER=$(xcodebuild -version 2>/dev/null | head -1 | awk '{print $2}')
    ok "Xcode $XCODE_VER found"
else
    fail "Xcode not found — install from the App Store or developer.apple.com"
fi

if xcode-select -p &>/dev/null; then
    XCODE_PATH=$(xcode-select -p)
    ok "Xcode Command Line Tools at $XCODE_PATH"
else
    fail "Xcode Command Line Tools not found — run: xcode-select --install"
fi

# ── Compiler toolchain ────────────────────────────────────────────────────────
echo ""
echo "▸ Compiler Toolchain"
for tool in cc c++ clang clang++; do
    if command -v "$tool" &>/dev/null; then
        VER=$("$tool" --version 2>&1 | head -1)
        ok "$tool — $VER"
    else
        fail "$tool not found"
    fi
done

# ── GNU make ──────────────────────────────────────────────────────────────────
echo ""
echo "▸ Build Tools"
if command -v make &>/dev/null; then
    MAKE_VER=$(make --version 2>&1 | head -1)
    ok "make — $MAKE_VER"
else
    fail "make not found"
fi

# Legacy GCC 4.2 for some Darwin 9 packages
if command -v gcc-4.2 &>/dev/null || [[ -x /usr/bin/gcc-4.2 ]]; then
    ok "gcc-4.2 found (required for xnu and some base libraries)"
else
    warn "gcc-4.2 not found — some packages (xnu) may fail to compile."
    warn "  Install MacPorts or Homebrew's legacy gcc42 cask."
fi

# ── Fetch tools ───────────────────────────────────────────────────────────────
echo ""
echo "▸ Fetch Tools"
if command -v curl &>/dev/null; then
    ok "curl $(curl --version | head -1 | awk '{print $2}')"
elif command -v wget &>/dev/null; then
    ok "wget $(wget --version 2>&1 | head -1)"
else
    fail "Neither curl nor wget found — needed to download source tarballs"
fi

# shasum / sha256sum for verification
if command -v shasum &>/dev/null; then
    ok "shasum (SHA-256 verification available)"
elif command -v sha256sum &>/dev/null; then
    ok "sha256sum (SHA-256 verification available)"
else
    warn "No SHA-256 tool found — source tarballs will not be verified"
fi

# ── Python ────────────────────────────────────────────────────────────────────
echo ""
echo "▸ Python"
if command -v python3 &>/dev/null; then
    PY_VER=$(python3 --version 2>&1 | awk '{print $2}')
    ok "python3 $PY_VER"
else
    warn "python3 not found — some build helper scripts may not work"
fi

# ── Disk space ────────────────────────────────────────────────────────────────
echo ""
echo "▸ Disk Space"
AVAIL_KB=$(df -k . | awk 'NR==2{print $4}')
AVAIL_GB=$(( AVAIL_KB / 1024 / 1024 ))
NEEDED_GB=20
if [[ "$AVAIL_GB" -ge "$NEEDED_GB" ]]; then
    ok "${AVAIL_GB} GB available (need at least ${NEEDED_GB} GB)"
else
    warn "Only ${AVAIL_GB} GB available — at least ${NEEDED_GB} GB recommended"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Results: ${PASS} passed, ${WARN} warnings, ${FAIL} failures"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
    echo "ERROR: $FAIL prerequisite(s) missing. Please fix the issues above and re-run."
    exit 1
fi

if [[ "$WARN" -gt 0 ]]; then
    echo "WARNING: $WARN warning(s) above. The build may succeed but some packages"
    echo "         could fail. See docs/TROUBLESHOOTING.md for guidance."
fi

echo "Environment looks good — proceed with:  make fetch"
echo ""
