# Patches

This directory contains source patches that must be applied before building
certain Darwin 9 packages on modern macOS hosts.

## Structure

```
patches/
└── <package-name>/
    └── 0001-description-of-change.patch
    └── 0002-another-change.patch
```

Patches are applied in filename sort order using `patch -p1`.

## When Patches Are Needed

Darwin 9 source code was written to build on Mac OS X 10.5 with Xcode 3.1.
Building on modern macOS (10.14+) with Xcode 14+ requires patches for:

- **Removed headers** — `<sys/kern_control.h>`, `<stdint.h>` guards, etc.
- **Deprecated APIs** — some POSIX symbols changed prototype between SDKs.
- **GCC-ism vs. Clang** — GCC 4.2 accepted constructs that Clang rejects (and
  vice versa). The `cctools` and `xnu` packages need the most patching.
- **64-bit pointer alignment** — some 32-bit-only structs need modern casts.

## Applying Patches Manually

```bash
cd sources/<package>-<version>
for p in ../../patches/<package>/*.patch; do
    patch -p1 < "$p"
done
```

## Submitting Patches

If you discover a new fix, please:
1. Generate the patch with `git diff` or `diff -u`.
2. Name it descriptively: `0001-fix-header-include-on-modern-sdk.patch`.
3. Place it in `patches/<package>/`.
4. Open a pull request with a brief description of what it fixes and which
   macOS / Xcode version it was tested on.
