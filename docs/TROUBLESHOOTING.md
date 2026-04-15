# Troubleshooting

Common build problems and their solutions when building PureDarwin Xmas from source.

---

## Table of Contents

1. [Environment / Prerequisites](#1-environment--prerequisites)
2. [Fetch Failures](#2-fetch-failures)
3. [Compiler and Toolchain Issues](#3-compiler-and-toolchain-issues)
4. [xnu (Kernel) Build Failures](#4-xnu-kernel-build-failures)
5. [dyld Build Failures](#5-dyld-build-failures)
6. [GCC Build Failures](#6-gcc-build-failures)
7. [Library Build Failures](#7-library-build-failures)
8. [Image Creation Issues](#8-image-creation-issues)
9. [Boot / Runtime Issues](#9-boot--runtime-issues)

---

## 1. Environment / Prerequisites

### `make check-env` fails with "Xcode not found"

Install Xcode from the App Store or from
https://developer.apple.com/download/applications/.

After installation, accept the license:
```bash
sudo xcodebuild -license accept
```

Then switch to the full Xcode toolchain (not just CLT):
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### `make check-env` warns about `gcc-4.2`

GCC 4.2 is required for `xnu` and some base libraries. Install via MacPorts:

```bash
sudo port install apple-gcc42
```

Or create a symlink if you have a compatible GCC already:
```bash
sudo ln -s /usr/bin/gcc /usr/local/bin/gcc-4.2   # only if versions match!
```

### "only N GB available" disk space warning

The build requires approximately 20 GB of free disk space:
- ~600 MB downloaded sources
- ~5 GB for build intermediates
- ~2 GB for the final disk image
- ~10 GB for the sysroot and object files

Free up disk space or point the build at a larger volume:
```bash
# Symlink output and sources to another volume
ln -s /Volumes/BigDisk/darwin10k-build output
ln -s /Volumes/BigDisk/darwin10k-sources sources
```

---

## 2. Fetch Failures

### "Download failed" for one or more packages

Apple's open-source server may temporarily rate-limit or be unavailable. Try:
```bash
# Re-run fetch — already-downloaded packages are skipped
make fetch
```

If the URL is permanently broken, check whether Apple has updated the package
version number or path. Update `packages/package-list.txt` accordingly.

### SHA-256 mismatch after download

The canonical checksum in `packages/package-list.txt` may be wrong (listed as
`PLACEHOLDER`). To update it:
```bash
shasum -a 256 sources/<package>-<version>.tar.gz
# Copy the hash into package-list.txt for the matching line
```

---

## 3. Compiler and Toolchain Issues

### `ld: warning: ignoring file ...` / link failures with modern ld

The modern `ld` shipped with Xcode (ld64) may reject two-level namespace flags
or bitcode from Darwin 9 object files. Add to the package's Makefile or
xcodebuild invocation:

```bash
OTHER_LDFLAGS="-Wl,-no_deduplicate -Wl,-no_compact_unwind"
```

### Clang rejects GCC extension syntax

Some packages use `__attribute__((visibility(...)))` or GCC inline assembly
syntax not supported by Clang. Switch to GCC 4.2 for that package:

```bash
make package PKG=<failing-package> CC=gcc-4.2 CXX=g++-4.2
```

### Header `<stdint.h>` or `<sys/types.h>` conflicts

Darwin 9 headers sometimes conflict with the modern macOS SDK. Set `SDKROOT`
to a Leopard SDK if you have one, or add the missing typedef:

```bash
export SDKROOT=/path/to/MacOSX10.5.sdk
make build
```

Leopard SDKs are included in Xcode 4.3 and earlier. Later Xcode versions
dropped them; they can be extracted from an old Xcode DMG.

---

## 4. xnu (Kernel) Build Failures

### `mig: command not found`

`mig` (Mach Interface Generator) is built by `bootstrap_cmds`. Ensure it was
built first:
```bash
make package PKG=bootstrap_cmds
```

Then verify:
```bash
which mig     # should be in /usr/local/bin or similar
```

### `xnu: error: too many errors emitted`

XNU uses GCC-specific pragmas to suppress warnings. With Clang these become
errors. Set the compiler explicitly:
```bash
make package PKG=xnu CC=gcc-4.2
```

### `kextsymbols` or `ctfconvert` not found

The kernel build uses DTrace's CTF (Compact Type Format) tools. Install them
from the DTrace source package or via MacPorts:
```bash
sudo port install dtrace
```

---

## 5. dyld Build Failures

### `dyld: error: no such file or directory: /usr/include/mach-o/dyld.h`

The dyld public headers must come from the xnu source tree, not the SDK. Copy
them manually:
```bash
cp -R sources/xnu-1228.15.4/EXTERNAL_HEADERS/mach-o \
      "$(xcrun --show-sdk-path)/usr/include/"
```

---

## 6. GCC Build Failures

### `gcc` stage-2 build fails with linker errors

GCC's stage-2 bootstrap (where GCC compiles itself) requires the stage-1
compiler to have been installed first. Run the build with `STAGE1_CFLAGS=-O0`
to reduce optimisation during bootstrap:
```bash
make package PKG=gcc STAGE1_CFLAGS=-O0
```

---

## 7. Library Build Failures

### `Libsystem` fails with "can't open output file"

The `DSTROOT` path may have permission issues. Ensure the output directory is
writable:
```bash
chmod -R u+w output/sysroot
```

### `CF` (CoreFoundation) fails with missing `uuid_t`

The `uuid` type was moved to a new header in later SDKs. Add:
```bash
# In CF-476.17/CFBase.h or patch the source:
#include <uuid/uuid.h>
```

A ready-made patch is provided in `patches/CF/`.

---

## 8. Image Creation Issues

### `hdiutil: create failed` — "Resource temporarily unavailable"

Another process holds a lock on the disk subsystem. Try:
```bash
sudo killall -9 hdiutil   # force-kill any stuck hdiutil
make image
```

### `bless` fails with "Can't bless a non-HFS volume"

The image must be formatted as HFS+. If you see this, `hdiutil create` may
have used a different filesystem. Check with:
```bash
hdiutil imageinfo output/puredarwin-xmas.sparseimage
```

Recreate with an explicit `-fs HFS+` flag (already set in `create-image.sh`).

### Image is too small

Increase `IMAGE_SIZE_MB` in `scripts/create-image.sh` (default: 2048 MB):
```bash
# Edit the variable at the top of the file:
IMAGE_SIZE_MB=4096
```

---

## 9. Boot / Runtime Issues

### VM hangs at "still waiting for root device"

The kernel cannot find its root filesystem. Ensure:
1. The HFS+ volume is the first partition on the image.
2. `boot.efi` is present in `System/Library/CoreServices/`.
3. The volume is blessed (`bless --folder ...` ran successfully).

### `launchd` panics immediately

A missing or malformed `/etc/rc` or `/sbin/launchd` causes an immediate panic.
Verify these files exist in the sysroot:
```bash
ls -la output/sysroot/sbin/launchd
ls -la output/sysroot/etc/rc
```

### "dyld: Library not loaded" on first boot

A required dylib is missing from the image. Use `otool -L` to find
dependencies:
```bash
otool -L output/sysroot/sbin/launchd
```

Then check whether each listed dylib exists in the sysroot.

### Shell shows garbage / no `$PATH`

The `/etc/profile` or `/etc/bashrc` from the sysroot may be missing or
malformed. Check:
```bash
cat output/sysroot/etc/profile
```

---

## Getting Further Help

- **PureDarwin community:** https://github.com/PureDarwin/PureDarwin
- **PureDarwin Discord:** https://discord.gg/9kz8XXRRcT
- **Apple open-source:** https://opensource.apple.com
- **OpenDarwin archive:** https://web.archive.org/web/*/http://www.opendarwin.org/
