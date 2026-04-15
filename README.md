# darwin10k — PureDarwin Xmas from Source

**darwin10k** is a build system that lets you compile [PureDarwin Xmas](https://www.puredarwin.org) entirely from publicly available Apple open-source releases.

PureDarwin Xmas was the first public demonstration release of PureDarwin, released on 25 December 2008. It is based on **Darwin 9** (the open-source core of Mac OS X 10.5 Leopard) and runs on x86 hardware and virtual machines (VMware/QEMU).

---

## Quick Start

```bash
# 1. Verify your build environment
make check-env

# 2. Download all source tarballs (~600 MB)
make fetch

# 3. Build all packages in order (~2–4 hours on modern hardware)
make build

# 4. Assemble the bootable disk image
make image
```

The final disk image will be written to `output/puredarwin-xmas.img`.

---

## Requirements

| Tool | Version | Notes |
|------|---------|-------|
| macOS | 10.14+ (Mojave or later) | Build host must be macOS |
| Xcode | 14+ | Full Xcode, **not** just the CLT |
| Xcode CLT | Matching Xcode | `xcode-select --install` |
| curl / wget | Any | Needed for `make fetch` |
| Python 3 | 3.8+ | Used by build helper scripts |
| GNU make | 3.81+ | Bundled with Xcode CLT |

> **Note:** PureDarwin Xmas and its source packages were produced for 32/64-bit x86. Cross-compilation from Apple Silicon Macs using Rosetta 2 is possible but may require additional patches.

---

## Repository Layout

```
darwin10k/
├── Makefile                  — Top-level build automation
├── scripts/
│   ├── setup-env.sh          — Environment prerequisite checks
│   ├── fetch-sources.sh      — Download source tarballs from Apple
│   ├── build-all.sh          — Build every package in dependency order
│   ├── build-package.sh      — Build a single named package
│   └── create-image.sh       — Assemble the bootable disk image
├── packages/
│   ├── package-list.txt      — Full package manifest (name, version, URL, sha256)
│   └── build-order.txt       — Annotated dependency/build order
├── patches/
│   └── README.md             — Patch documentation
└── docs/
    ├── BUILDING.md           — Step-by-step build guide
    ├── PACKAGES.md           — Package descriptions and rationale
    └── TROUBLESHOOTING.md    — Common issues and fixes
```

---

## Background

Darwin is the open-source UNIX-based operating system that underpins macOS, iOS, tvOS and watchOS. Apple publishes the source code for many Darwin components at <https://opensource.apple.com>.

**PureDarwin** is a community project (<https://github.com/PureDarwin/PureDarwin>) that assembles those components into a usable bootable system. The *Xmas* edition was a snapshot of Darwin 9 (XNU 1228), the version shipped with Mac OS X 10.5 Leopard.

### Key components

| Component | Package | Version |
|-----------|---------|---------|
| Kernel | xnu | 1228.15.4 |
| Dynamic linker | dyld | 96.2 |
| C compiler | gcc | 5664.3 (GCC 4.2) |
| Assembler / linker tools | cctools | 667.8.0 |
| Init / launch daemon | launchd | 258.1 |
| Base system library | Libsystem | 111.1.4 |
| POSIX threads | libpthread | 65.1.1 |
| CoreFoundation | CF | 476.17 |
| Bootstrap build tools | bootstrap_cmds | 75 |
| Shell | bash | 88 |

See [docs/PACKAGES.md](docs/PACKAGES.md) for the complete list.

---

## License

The source packages downloaded by this project are Apple open-source releases governed by the **Apple Public Source License (APSL) 2.0** and other open-source licenses. See each package's source tarball for its individual license.

The build scripts in this repository are released under the **MIT License** — see [LICENSE](LICENSE) for details.
