# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Communication Preferences

**IMPORTANT: Always respond in Chinese (中文).** All responses, explanations, and communications should be in Chinese unless the user explicitly requests otherwise.

## Project Overview

This is an OpenBMC workspace. OpenBMC is a Linux distribution for Baseboard Management Controllers (BMCs) used in servers, switches, and RAID appliances. It's built using the Yocto/OpenEmbedded build system with BitBake as the build tool.

## Build System Architecture

OpenBMC uses a layered architecture with Yocto/OpenEmbedded:

- **Base layers**: `meta` (OpenEmbedded-Core), `meta-openembedded` (additional OE layers)
- **Core OpenBMC layer**: `meta-phosphor` - shared content for all OpenBMC systems
- **Hardware vendor layers**: `meta-<vendor>` directories (e.g., `meta-facebook`, `meta-google`, `meta-ibm`) contain machine-specific configurations
- **SoC layers**: `meta-aspeed`, `meta-nuvoton` for BMC chip support
- **Build output**: `build/<machine-name>/` directories contain build artifacts

The build system generates complete firmware images including kernel, rootfs, and bootloader.

## Common Development Commands

### Initial Setup

```bash
# Navigate to the openbmc directory
cd openbmc

# List available machines
. setup

# Configure build environment for a specific machine
. setup <machine-name> [build-dir]
# Example: . setup evb-ast2600
# This sources the environment and creates build/<machine-name>/ if not specified
```

### Building

```bash
# After sourcing setup, build the complete firmware image
bitbake obmc-phosphor-image

# Build a specific package
bitbake <package-name>

# Clean a package and rebuild
bitbake -c clean <package-name>
bitbake <package-name>

# Force rebuild without cleaning
bitbake -f <package-name>
```

### Development Workflow

```bash
# Source the build environment (must be done in each new shell)
. openbmc-env

# Run repository-level tests (when available)
make check

# View build logs
less build/<machine>/tmp/work/<package-path>/temp/log.do_<task>
```

### QEMU Testing

OpenBMC images can be tested with QEMU. The CI system uses `arm-softmmu` QEMU models for automated testing.

## Key Directories

- `upstream-layers/`: Upstream Yocto/OE layers (bitbake, openembedded-core, etc.)
- `meta-phosphor/`: Core OpenBMC layer with shared recipes and configurations
- `meta-<vendor>/`: Vendor-specific machine configurations and customizations
- `build/<machine>/conf/`: Build configuration files
  - `local.conf`: Local build settings (MACHINE, parallelism, image features)
  - `bblayers.conf`: Layer configuration
- `build/<machine>/tmp/`: Build artifacts, work directories, and output images

## Important Concepts

### Machine Configuration
Each supported hardware platform has a machine configuration file in `meta-*/conf/machine/*.conf`. The MACHINE variable in `local.conf` determines which hardware is being built for.

### Recipes
BitBake recipes (`.bb` files) define how to build packages. Recipe modifications typically go in vendor-specific layers using `.bbappend` files to override or extend base recipes.

### D-Bus Architecture
OpenBMC uses D-Bus extensively for inter-process communication. Many services expose D-Bus interfaces for management operations.

## Testing

- Repository-level: `make check` (when available in individual repos)
- System-level: CI builds images and runs automated tests using Robot Framework
- Test repository: https://github.com/openbmc/openbmc-test-automation

## Build Environment Notes

- The `setup` script must be **sourced** (not executed) to configure the environment
- Each new shell session requires re-sourcing the setup or openbmc-env
- Build directories are created under `build/<machine-name>/` by default
- BitBake maintains state in `build/<machine>/tmp/` and shared state cache in `sstate-cache/`
- Downloads are cached in `build/<machine>/downloads/`

## Development Guidelines

- Follow the contributing guidelines at https://github.com/openbmc/docs/blob/master/CONTRIBUTING.md
- Contributions should include test cases
- Code changes are tested via Jenkins CI before merging
- Use vendor-specific layers for machine-specific customizations
- Prefer `.bbappend` files over modifying base recipes directly
