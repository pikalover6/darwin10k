# Building PureDarwin Xmas from Source

This guide walks through every step needed to compile PureDarwin Xmas from
Apple's publicly available open-source releases and produce a bootable disk image.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Fetching the Sources](#2-fetching-the-sources)
3. [Build Stages](#3-build-stages)
4. [Creating the Disk Image](#4-creating-the-disk-image)
5. [Running the Image](#5-running-the-image)
6. [Building a Single Package](#6-building-a-single-package)
7. [Incremental Rebuilds](#7-incremental-rebuilds)

---

## 1. Prerequisites

### macOS host

The build **must** run on macOS. Darwin 9 was produced by Apple's own build
infrastructure and many packages use Apple-specific build rules, `xcodebuild`,
and SDK headers that do not exist on Linux or Windows.

Tested host configurations:

| macOS | Xcode | Notes |
|-------|-------|-------|
| 14 Sonoma | 15 | Primary target |
| 13 Ventura | 14 | Tested |
| 12 Monterey | 14 | Should work |
| 11 Big Sur | 13 | Limited testing |

### Install Xcode

```bash
# Install from App Store or:
xcodebuild -version   # verify Xcode is installed
xcode-select --install  # install Command Line Tools if prompted
```

### Legacy GCC 4.2 (for xnu)

The XNU kernel and some base libraries require GCC 4.2 because they use GCC
extensions not available in Clang. Install via MacPorts or Homebrew:

```bash
# MacPorts (recommended)
sudo port install apple-gcc42

# Homebrew (unofficial tap)
brew install https://raw.githubusercontent.com/mistydemeo/tigerbrew/master/Library/Formula/apple-gcc42.rb
```

After installation, verify:

```bash
gcc-4.2 --version
```

### Verify all prerequisites

```bash
make check-env
```

---

## 2. Fetching the Sources

All source packages are downloaded from Apple's open-source server
(`opensource.apple.com`). The total download is approximately 600 MB.

```bash
make fetch
```

Tarballs are saved to `sources/` and verified against SHA-256 checksums in
`packages/package-list.txt`.

> **Tip:** If a package fails to download (network error), simply re-run
> `make fetch` — already-downloaded packages are skipped automatically.

### What gets downloaded

See [`packages/package-list.txt`](../packages/package-list.txt) for the full
manifest. Key packages include:

| Package | Version | Description |
|---------|---------|-------------|
| xnu | 1228.15.4 | XNU Mach/BSD kernel |
| dyld | 96.2 | Dynamic linker |
| gcc | 5664.3 | Apple GCC 4.2 compiler |
| cctools | 667.8.0 | Assembler, linker, object tools |
| Libsystem | 111.1.4 | Base system library (libSystem.B.dylib) |
| launchd | 258.1 | Init and launch daemon |
| CF | 476.17 | CoreFoundation |
| bash | 88 | Bash shell |

---

## 3. Build Stages

```bash
make build
```

Packages are built in the order defined in
[`packages/build-order.txt`](../packages/build-order.txt). The stages are:

| Stage | Packages | Purpose |
|-------|----------|---------|
| 1 | bootstrap_cmds | Mach Interface Generator (mig) |
| 2 | cctools | Assembler, linker, object tools |
| 3 | gcc | Compiler |
| 4 | dyld | Dynamic linker ABI |
| 5 | Core libraries | Libsystem, libpthread, Libc, … |
| 6 | xnu | Kernel |
| 7 | ICU | Unicode / locale support |
| 8 | CF | CoreFoundation |
| 9 | IOKitUser | User-space IOKit |
| 10 | launchd | Init system |
| 11 | Security | Crypto / Keychain |
| 12 | Compression | zlib, bzip2 |
| 13–15 | Filesystems, boot | HFS+, BootX |
| 16–18 | Commands, scripting | bash, shell/file/text commands, perl, python, ruby |

Build artefacts accumulate in `output/sysroot/`, which mirrors the final
filesystem layout (`/bin`, `/usr`, `/System/Library`, etc.).

### Build logs

Each package's build log is written to `output/logs/<package>.log`.  
The combined log for the full build is `logs/build.log`.

---

## 4. Creating the Disk Image

```bash
make image
```

This script (`scripts/create-image.sh`):
1. Creates a 2 GB sparse HFS+ image using `hdiutil`.
2. Mounts it and `rsync`s the sysroot into it.
3. Creates the required symlinks (`/etc → private/etc`, etc.).
4. Blesses the CoreServices folder so the bootloader is found.
5. Converts the sparse image to a flat read-only UDIF image.

Output: `output/puredarwin-xmas.img`

---

## 5. Running the Image

### VMware Fusion / Workstation

1. Create a new VM → "Use an existing virtual disk".
2. Select `output/puredarwin-xmas.img`.
3. Set the guest OS to **"Other > Darwin"** (32-bit or 64-bit).
4. Allocate at least 512 MB RAM.
5. Boot and watch the console.

### QEMU

```bash
qemu-system-x86_64 \
  -m 512 \
  -drive file=output/puredarwin-xmas.img,format=raw \
  -nographic \
  -serial mon:stdio
```

### Physical hardware

Write the image to a USB drive (use with care):

```bash
# Replace /dev/diskN with your USB device — DOUBLE CHECK before running!
sudo dd if=output/puredarwin-xmas.img of=/dev/diskN bs=4m status=progress
```

---

## 6. Building a Single Package

To rebuild one package without running the full build:

```bash
make package PKG=xnu
make package PKG=launchd
```

The build stamp at `output/.stamps/<package>.done` is deleted automatically
before rebuilding.

---

## 7. Incremental Rebuilds

The build system records a stamp file (`output/.stamps/<pkg>.done`) after
each successfully built package. Re-running `make build` skips packages whose
stamp already exists, allowing you to resume after a failure or add new
packages.

To force a full rebuild:

```bash
make clean   # remove build artefacts (keeps downloaded sources)
make build
```

To start completely from scratch:

```bash
make distclean
make all
```
