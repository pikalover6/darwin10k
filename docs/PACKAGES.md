# Package Reference — PureDarwin Xmas

This document describes every source package used to build PureDarwin Xmas,
including its role in the system, where its source comes from, and any special
build notes.

All packages are from Apple's Darwin 9 open-source release (Mac OS X 10.5 Leopard),
available at: https://opensource.apple.com/

---

## Bootstrap / Toolchain

### bootstrap_cmds-75
**Role:** Provides `mig` (Mach Interface Generator), the tool that generates C
stubs from Mach RPC interface definitions (`.defs` files). Required by xnu and
IOKit.  
**Source:** https://opensource.apple.com/tarballs/bootstrap_cmds/

### cctools-667.8.0
**Role:** Apple's port of the traditional UNIX binary tools: `as` (assembler),
`ld` (static linker), `ar`, `ranlib`, `nm`, `otool`, `lipo`, `strip`,
`size`, etc. These are the low-level tools that GCC and Clang invoke.  
**Source:** https://opensource.apple.com/tarballs/cctools/

### gcc-5664.3 (GCC 4.2)
**Role:** Apple's customised GCC 4.2 compiler. Required to build XNU and
several base libraries that use GCC-specific extensions (`__attribute__`,
`__builtin_*`) that Clang does not support identically.  
**Source:** https://opensource.apple.com/tarballs/gcc/

---

## Kernel

### xnu-1228.15.4
**Role:** The XNU kernel. XNU ("X is Not Unix") is a hybrid kernel combining
the Mach microkernel, a BSD Unix subsystem, and the I/O Kit driver framework.
Version 1228 ships with Mac OS X 10.5.8 (Leopard).  
**Build notes:** Requires GCC 4.2 and `bootstrap_cmds` (for `mig`). Uses the
`EXPORT_SYMBOLS_LIST` mechanism to restrict which kernel symbols are visible.  
**Source:** https://opensource.apple.com/tarballs/xnu/

---

## Dynamic Linker

### dyld-96.2
**Role:** The dynamic link editor — the very first code that runs in a
user-space process. Responsible for loading shared libraries, performing symbol
binding, and executing initializers before `main()` is called.  
**Source:** https://opensource.apple.com/tarballs/dyld/

---

## Core Libraries

### Libsystem-111.1.4
**Role:** The umbrella library (`/usr/lib/libSystem.B.dylib`) that re-exports
most of the Darwin base: libm, libpthread, libc, libinfo, libresolv, etc.
Every user-space process links against this.  
**Source:** https://opensource.apple.com/tarballs/Libsystem/

### libpthread-65.1.1
**Role:** POSIX threads implementation for Darwin. Provides `pthread_create`,
`pthread_mutex_*`, `pthread_cond_*`, etc.  
**Source:** https://opensource.apple.com/tarballs/libpthread/

### Libc-498.1.7
**Role:** The Darwin C library — `malloc`, `stdio`, `string.h` functions, etc.
Darwin's libc is derived from FreeBSD's.  
**Source:** https://opensource.apple.com/tarballs/Libc/

### libclosure-38
**Role:** Implements Apple's "Blocks" extension to C (`^{ ... }`), used
extensively in Grand Central Dispatch and modern Objective-C.  
**Source:** https://opensource.apple.com/tarballs/libclosure/

### libresolv-41
**Role:** DNS resolver library. Provides `res_query`, `res_search`, etc.  
**Source:** https://opensource.apple.com/tarballs/libresolv/

### Libnotify-5
**Role:** Implements the `notify(3)` API for inter-process notifications via
the `notifyd` daemon.  
**Source:** https://opensource.apple.com/tarballs/Libnotify/

### Libinfo-406.1
**Role:** Provides `getpwuid`, `getgrgid`, `gethostbyname`, and other lookup
functions, routing queries through `DirectoryService` or flat files.  
**Source:** https://opensource.apple.com/tarballs/Libinfo/

### CommonCrypto-32212
**Role:** Apple's in-kernel and user-space cryptography library. Provides AES,
SHA, HMAC, and digest functions used by Security.framework and the kernel.  
**Source:** https://opensource.apple.com/tarballs/CommonCrypto/

### copyfile-103.10.8
**Role:** `copyfile(3)` — extended-attribute–aware file copy including HFS+
resource forks and metadata.  
**Source:** https://opensource.apple.com/tarballs/copyfile/

---

## CoreFoundation

### CF-476.17
**Role:** CoreFoundation (CFString, CFArray, CFDictionary, CFRunLoop, etc.).
This is the pure-C foundation of the Cocoa / Cocoa Touch object model and many
system services. Darwin ships the "lite" version without Objective-C.  
**Source:** https://opensource.apple.com/tarballs/CF/

---

## Unicode / Locale

### ICU-334.4
**Role:** International Components for Unicode — the full Unicode library.
Used by CoreFoundation, CFString, and many other frameworks for text
processing, collation, and locale support.  
**Source:** https://opensource.apple.com/tarballs/ICU/

---

## Init System

### launchd-258.1
**Role:** Apple's replacement for `init`, `inetd`, `cron`, and `xinetd`.
`launchd` is PID 1 on Darwin — the first user-space process. It reads
`.plist` launch agents / daemons and manages service lifecycle.  
**Source:** https://opensource.apple.com/tarballs/launchd/

---

## IOKit

### IOKitUser-388.2.1
**Role:** User-space half of the IOKit driver framework. Provides the
`IOServiceGetMatchingService`, `IORegistryExplorer`, etc. APIs that user-space
processes use to communicate with kernel drivers.  
**Source:** https://opensource.apple.com/tarballs/IOKitUser/

---

## Security

### corecrypto-106.1
**Role:** Low-level crypto primitives used by the kernel and Security.framework.  
**Source:** https://opensource.apple.com/tarballs/corecrypto/

### OpenSSL-0.9.8j
**Role:** Apple's port of OpenSSL 0.9.8, used for TLS/SSL by many tools and
for `xar` (the package archive tool).  
**Source:** https://opensource.apple.com/tarballs/OpenSSL/

### Security-36163
**Role:** Security.framework — Keychain, certificates, code signing, and the
`securityd` daemon.  
**Source:** https://opensource.apple.com/tarballs/Security/

---

## Filesystems

### hfs-226.1.1
**Role:** HFS+ kernel extension and user-space utilities (`fsck_hfs`,
`newfs_hfs`, `hfs.util`). PureDarwin Xmas boots from an HFS+ volume.  
**Source:** https://opensource.apple.com/tarballs/hfs/

---

## Boot

### BootX-75.2
**Role:** Apple's Open Firmware bootloader for PowerPC, and the EFI boot file
(`boot.efi`) for Intel Macs. Loads the kernel and RAMdisk.  
**Source:** https://opensource.apple.com/tarballs/BootX/

---

## Configuration

### configd-395.6
**Role:** System Configuration framework daemon. Manages dynamic store for
network configuration, interface state, and reachability.  
**Source:** https://opensource.apple.com/tarballs/configd/

---

## Compression

### zlib-36
**Role:** Apple's port of zlib (gzip-compatible compression). Used by the
kernel, xar, and many user-space tools.  
**Source:** https://opensource.apple.com/tarballs/zlib/

### bzip2-29
**Role:** bzip2 compression library and tools.  
**Source:** https://opensource.apple.com/tarballs/bzip2/

---

## Shell and Commands

### bash-88
**Role:** Apple's port of GNU Bash. The default interactive shell on Darwin.  
**Source:** https://opensource.apple.com/tarballs/bash/

### shell_cmds-162
**Role:** POSIX shell-related commands: `sh`, `echo`, `date`, `sleep`, `kill`,
`test`, `printf`, `true`, `false`, etc.  
**Source:** https://opensource.apple.com/tarballs/shell_cmds/

### file_cmds-207
**Role:** File manipulation commands: `ls`, `cp`, `mv`, `rm`, `mkdir`,
`chmod`, `chown`, `stat`, `ln`, `install`, etc.  
**Source:** https://opensource.apple.com/tarballs/file_cmds/

### text_cmds-71.1.1
**Role:** Text processing commands: `sed`, `awk`, `sort`, `uniq`, `wc`,
`head`, `tail`, `cut`, `tr`, etc.  
**Source:** https://opensource.apple.com/tarballs/text_cmds/

### adv_cmds-158.1
**Role:** Advanced commands: `finger`, `last`, `w`, `ps`, `top`, `lsvfs`,
`chpass`, `vipw`, etc.  
**Source:** https://opensource.apple.com/tarballs/adv_cmds/

### basic_cmds-58.1.1
**Role:** Classic UNIX utilities: `su`, `login`, `getty`, `uname`, `hostname`.  
**Source:** https://opensource.apple.com/tarballs/basic_cmds/

### network_cmds-329.2.2
**Role:** Networking commands: `ifconfig`, `netstat`, `ping`, `traceroute`,
`arp`, `route`, `nslookup`, `telnet`, `ftp`, `rsh`, etc.  
**Source:** https://opensource.apple.com/tarballs/network_cmds/

### diskdev_cmds-557.1
**Role:** Disk device utilities: `mount`, `umount`, `df`, `du`, `fsck`,
`newfs`, `pdisk`, `fdisk`, etc.  
**Source:** https://opensource.apple.com/tarballs/diskdev_cmds/

### system_cmds-548.1.1
**Role:** Miscellaneous system commands: `reboot`, `shutdown`, `sysctl`,
`kextload`, `kextstat`, `dynamic_pager`, `accton`, etc.  
**Source:** https://opensource.apple.com/tarballs/system_cmds/

---

## Scripting Runtimes

### perl-87
**Role:** Apple's port of Perl 5.  
**Source:** https://opensource.apple.com/tarballs/perl/

### python-24
**Role:** Apple's port of Python 2.5.  
**Source:** https://opensource.apple.com/tarballs/python/

### ruby-89
**Role:** Apple's port of Ruby 1.8.  
**Source:** https://opensource.apple.com/tarballs/ruby/

---

## Archive Tools

### xar-253
**Role:** `xar` (eXtensible ARchive) — Apple's signed archive format, used to
distribute OS X packages (`.pkg` files).  
**Source:** https://opensource.apple.com/tarballs/xar/
