# darwin10k — PureDarwin Xmas from Source
# Top-level Makefile

SHELL       := /bin/bash
SCRIPTS_DIR := $(CURDIR)/scripts
SOURCES_DIR := $(CURDIR)/sources
OUTPUT_DIR  := $(CURDIR)/output
LOG_DIR     := $(CURDIR)/logs

.PHONY: all check-env fetch build image clean distclean help

all: check-env fetch build image

## ── Environment check ────────────────────────────────────────────────────────
check-env:
	@echo "==> Checking build environment..."
	@$(SCRIPTS_DIR)/setup-env.sh

## ── Source fetch ─────────────────────────────────────────────────────────────
fetch: check-env
	@echo "==> Fetching source tarballs..."
	@mkdir -p "$(SOURCES_DIR)" "$(LOG_DIR)"
	@$(SCRIPTS_DIR)/fetch-sources.sh "$(SOURCES_DIR)" 2>&1 | tee "$(LOG_DIR)/fetch.log"

## ── Build all packages ───────────────────────────────────────────────────────
build: fetch
	@echo "==> Building all packages..."
	@mkdir -p "$(LOG_DIR)"
	@$(SCRIPTS_DIR)/build-all.sh "$(SOURCES_DIR)" "$(OUTPUT_DIR)" 2>&1 | tee "$(LOG_DIR)/build.log"

## ── Create disk image ────────────────────────────────────────────────────────
image: build
	@echo "==> Creating bootable disk image..."
	@mkdir -p "$(OUTPUT_DIR)"
	@$(SCRIPTS_DIR)/create-image.sh "$(OUTPUT_DIR)" 2>&1 | tee "$(LOG_DIR)/image.log"
	@echo ""
	@echo "==> Done!  Disk image: $(OUTPUT_DIR)/puredarwin-xmas.img"

## ── Build a single package ───────────────────────────────────────────────────
# Usage: make package PKG=xnu
package:
ifndef PKG
	$(error PKG is not set. Usage: make package PKG=<package-name>)
endif
	@$(SCRIPTS_DIR)/build-package.sh "$(PKG)" "$(SOURCES_DIR)" "$(OUTPUT_DIR)"

## ── Cleanup ──────────────────────────────────────────────────────────────────
clean:
	@echo "==> Cleaning build artifacts..."
	@rm -rf "$(OUTPUT_DIR)/build"
	@echo "    Build directory removed."

distclean: clean
	@echo "==> Removing downloaded sources and output..."
	@rm -rf "$(SOURCES_DIR)" "$(OUTPUT_DIR)" "$(LOG_DIR)"
	@echo "    All generated files removed."

## ── Help ─────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "darwin10k — PureDarwin Xmas from Source"
	@echo ""
	@echo "Usage:"
	@echo "  make check-env        Verify build prerequisites"
	@echo "  make fetch            Download all source tarballs"
	@echo "  make build            Build all packages in dependency order"
	@echo "  make image            Create the bootable disk image"
	@echo "  make all              Run all of the above (default)"
	@echo "  make package PKG=<n>  Build a single package by name"
	@echo "  make clean            Remove build artifacts"
	@echo "  make distclean        Remove all generated files and downloaded sources"
	@echo "  make help             Show this help message"
	@echo ""
	@echo "Output:"
	@echo "  sources/              Downloaded source tarballs"
	@echo "  output/               Build output and final disk image"
	@echo "  logs/                 Build logs"
	@echo ""
