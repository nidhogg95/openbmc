# PROJECT KNOWLEDGE BASE

**Generated:** 2026-04-07
**Commit:** b1c61cac52
**Branch:** master

## OVERVIEW

OpenBMC workspace — BMC firmware build environment based on Yocto/OpenEmbedded + BitBake. Main repo in `openbmc/` subdirectory. 27 own layers + 4 upstream symlinked layers, 76 hardware platforms across 20+ vendors.

## STRUCTURE

```
openbmc-workspace/
├── CLAUDE.md              # AI interaction guide (requires Chinese responses)
├── AGENTS.md              # This file (workspace-level)
├── start-qemu-webui.sh    # QEMU launcher (evb-ast2600, ports 2222/2443/2623)
├── evb-2u-egs_Hardware_Definition.md  # ★ Hardware definition doc (98%, 1359 lines, 19 sections)
├── evb-2u-egs_OEM_IPMI_Commands.md   # ★ OEM IPMI commands doc (78 commands, 2148 lines)
├── AMI_bmc_code/          # AMI MegaRAC SPX 4.0 source (35,015 files, 2.1GB, from v3r4.zip)
│   ├── src/core/          # 469 core modules (PDK, IPMI, HAL, sensors, fan control)
│   └── prj/               # Project configs, DTS, HAL generated code
└── openbmc/               # <- Main repo, ALL development here
    ├── AGENTS.md           # Detailed repo-level guide (layer architecture, machine map, known hacks)
    ├── setup               # Build env entry point (MUST source, never execute)
    ├── openbmc-env          # Simplified env restore (when build/ exists)
    ├── meta-phosphor/       # ★ Core shared layer (AGENTS.md inside)
    ├── meta-aspeed/         # Primary SoC: AST2400/2500/2600/2700 (AGENTS.md inside)
    ├── meta-nuvoton/        # SoC: NPCM750/845
    ├── meta-facebook/       # Largest vendor — 16 machines, 3-level nesting (AGENTS.md inside)
    ├── meta-ibm/            # IBM — 10 machines, mixed placement (AGENTS.md inside)
    ├── meta-google/         # Google gBMC distro overlay, no machines (AGENTS.md inside)
    ├── meta-<vendor>/       # 20+ other vendor layers
    ├── upstream-layers/     # Upstream read-only repos
    │   ├── bitbake/         # BitBake engine (symlinked to repo root)
    │   ├── openembedded-core/ # OE-Core: meta/, scripts/ (symlinked to repo root)
    │   ├── meta-openembedded/ # meta-oe, meta-networking, meta-python (symlinked)
    │   ├── meta-arm/        # ARM platform support (symlinked)
    │   ├── meta-security/   # Security recipes incl. meta-tpm (symlinked)
    │   ├── meta-raspberrypi/# RPi support (symlinked)
    │   └── yocto-docs/      # Reference docs (NOT symlinked)
    ├── build/               # Build output
    │   └── evb-ast2600/     # Active build (conf/local.conf, tmp/deploy/)
    ├── .gitreview           # Gerrit: gerrit.openbmc-project.xyz:29418
    ├── eslint.config.js     # JSON5 linting (comments allowed in JSON files)
    └── OWNERS               # 4 repo-wide maintainers
```

## SUB-AGENTS.MD INDEX

Detailed per-layer documentation exists in these files — consult them for layer-specific work:

| File | Scope |
|------|-------|
| `openbmc/AGENTS.md` | Full repo architecture, layer dependencies, machine map, known hacks |
| `openbmc/meta-phosphor/AGENTS.md` | Core layer: recipes, bbclasses, distro config, image structure |
| `openbmc/meta-aspeed/AGENTS.md` | ASPEED SoC support (AST2400–AST2700), u-boot, TF-A |
| `openbmc/meta-facebook/AGENTS.md` | Facebook 16-machine vendor layer, 3-level nesting patterns |
| `openbmc/meta-ibm/AGENTS.md` | IBM 10 machines, hybrid placement, VIRTUAL-RUNTIME overrides |
| `openbmc/meta-google/AGENTS.md` | gBMC distro overlay, distro config details, image modifications |
| `openbmc/meta-openpower/AGENTS.md` | OpenPOWER host support: 7 bbclasses, own distro, flash strategies |
| `openbmc/meta-hpe/AGENTS.md` | HPE 4 machines + own GXP SoC layer, 5 bbclasses |
| `openbmc/meta-quanta/AGENTS.md` | Quanta 5 machines, Google gBMC crossover (meta-gbs) |
| `openbmc/meta-ampere/AGENTS.md` | Ampere 3 machines (mt* naming), meta-common pattern |
| `openbmc/meta-nuvoton/AGENTS.md` | Nuvoton SoC (NPCM750/845) + EVB dual role, dynamic-layers |
| `openbmc/meta-fii/AGENTS.md` | FII/Foxconn 2 machines, per-machine distro extending gBMC |

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Configure machine build | `openbmc/setup` | Must source: `. setup <machine>` |
| Find supported machines | `openbmc/meta-*/conf/machine/*.conf` | 76 machine configs (nested up to 3 levels) |
| Core recipes/bbclasses | `openbmc/meta-phosphor/` | All shared OpenBMC logic |
| Vendor customizations | `openbmc/meta-<vendor>/` | Override via `.bbappend` |
| Upstream layers (RO) | `openbmc/upstream-layers/` | bitbake/OE-Core/meta-arm/meta-security |
| Build artifacts | `openbmc/build/<machine>/tmp/deploy/images/<machine>/` | `.static.mtd`, `.ubi.mtd`, fitImage |
| Build logs | `openbmc/build/<machine>/tmp/work/<arch>/<pkg>/<ver>/temp/` | `log.do_compile`, `log.do_install` |
| QEMU testing | `start-qemu-webui.sh` | WebUI :2443, SSH :2222, IPMI :2623, pw `0penBmc` |
| Distro config chain | `meta-phosphor/conf/distro/` | `openbmc-phosphor.conf` → `phosphor-base.inc` → `phosphor-defaults.inc` |
| Image features | `meta-phosphor/classes/obmc-phosphor-image.bbclass` | FEATURE_PACKAGES mapping |
| VIRTUAL-RUNTIME defaults | `meta-phosphor/conf/distro/include/phosphor-defaults.inc` | Key extension points for vendors |
| Per-machine distro tune | `meta-phosphor/conf/distro/include/openbmc-phosphor/${MACHINE}.inc` | Auto-included if exists |
| AMI source code | `AMI_bmc_code/src/core/` | 469 modules, PDK/IPMI/HAL/sensors |
| Hardware definition doc | `evb-2u-egs_Hardware_Definition.md` | 98% coverage, 19 sections, 1359 lines |
| OEM IPMI commands doc | `evb-2u-egs_OEM_IPMI_Commands.md` | 78 commands, 2148 lines |

## CONVENTIONS

- **Language**: All AI responses must be in Chinese (per CLAUDE.md and global AGENTS.md)
- **Build entry**: Every new shell needs `. setup <machine>` or `. openbmc-env`
- **Recipe changes**: Use `.bbappend` in vendor layer; NEVER edit `meta-phosphor` or upstream directly
- **Code review**: Gerrit only (`gerrit.openbmc-project.xyz:29418`), NOT GitHub PRs
- **OWNERS file**: Repo-wide maintainer list (4 people), not per-directory
- **Init system**: systemd exclusively (`INIT_MANAGER = "systemd"`); D-Bus via dbus-broker
- **Packages**: IPK format (`package_ipk`)
- **Yocto series**: Current core is `whinlatter`; layers also declare compat with `walnascar`
- **Distro**: `openbmc-phosphor`, codename `styhead`
- **Image model**: Feature-driven — content controlled via `IMAGE_FEATURES` mapped to packagegroups, not direct `IMAGE_INSTALL`
- **VIRTUAL-RUNTIME**: Core services swappable via `VIRTUAL-RUNTIME_obmc-*`; use `?=` or `??=` to allow overrides
- **QA strictness**: 9 warnings promoted to errors in `phosphor-base.inc` (`already-stripped`, `compile-host-path`, `install-host-path`, `installed-vs-shipped`, `ldflags`, `pn-overrides`, `rpaths`, `staticdev`, `useless-rpaths`)
- **SPDX/SBOM**: Enabled globally (`INHERIT += "create-spdx"`)
- **JSON files**: Treated as JSON5 (comments allowed); linted via root `eslint.config.js`
- **Editor**: VSCode with `yocto-project.yocto-bitbake` extension recommended; shared settings in `.vscode/`

## ANTI-PATTERNS

- **Never execute setup script**: Must `source` (`. setup`), executing does nothing
- **Never modify upstream-layers/**: Symlinked to upstream read-only repos
- **Never edit meta-phosphor .bb files directly**: Use `.bbappend` in vendor layer
- **Never submit GitHub PRs**: Project uses Gerrit code review
- **Never use `=` for VIRTUAL-RUNTIME vars**: Use `?=` or `??=` to allow overrides
- **Never create bblayers.conf manually**: Generated by `setup` + TEMPLATECONF
- **Never use GPL/LGPL without version number**: Enforced by licensing policy
- **Never use default root password in production**: `0penBmc` is public knowledge
- **Never use `obmc-fan-mgmt` feature**: Deprecated; use `obmc-fan-control`
- **Never add to `packagegroup-obmc-apps-extras`**: Deprecated; use specific packagegroups
- **Never add packages directly to image**: Use `IMAGE_FEATURES` → packagegroup pattern

## COMMANDS

```bash
# Enter main repo
cd openbmc

# List all supported machines
. setup

# Configure specific machine
. setup evb-ast2600

# Restore existing build env (when build/ exists)
. openbmc-env

# Build full firmware image
bitbake obmc-phosphor-image

# Build single package
bitbake <package-name>

# Clean rebuild
bitbake -c clean <package-name> && bitbake <package-name>

# Force rebuild without cleaning
bitbake -f <package-name>

# Launch QEMU test
cd /home/dev/openbmc-workspace && bash start-qemu-webui.sh
```

## AMI → OpenBMC MIGRATION PROJECT

Target platform: **evb-2u-egs** (Intel EGS, AST2600 A1, 2U rack)

### Source Material

- `AMI_bmc_code/` — AMI MegaRAC SPX 4.0 full source (35,015 files, 2.1GB from `v3r4.zip`)
- Critical implementation files in `src/core/libipmipdk-ARM-AST2600-AST2600EVB-AMI-src/data/`:
  - `PDKHW.c` (4,129 lines) — Power sequence, platform init
  - `PDKHook_Private.c` (7,681 lines) — Sensor dispatch, VR temp, disk status
  - `fsit_fsc.c` (4,933 lines) — PID fan control
  - `PDKHooks.c` — Fan model RPM tables, PSU/ADC
- HAL generated code: `prj/*/thdpmc/*/data/ast2600evb.c` (62,693 lines)

### Output Documents (white-labeled, no vendor info)

| Document | Lines | Coverage | Content |
|----------|-------|----------|---------|
| `evb-2u-egs_Hardware_Definition.md` | 1,359 | 98% | 19 sections: GPIO(47 pins), I2C(26+ devices), power sequence, fan PID, sensors, CPLD, LED |
| `evb-2u-egs_OEM_IPMI_Commands.md` | 2,148 | 100% | 78 OEM IPMI commands with full request/response format |

### Platform Quick Reference

```
SoC: AST2600 A1 | Flash: 2× SPI w25q512 (each 64MB), dual-bank A/B, 128MB total | Console: ttyS4@115200 | SOL: ttyS3
NICs: mac1(RGMII-RXID) + mac2(RGMII) | MAC EEPROM: bus3/0x50/offset 0xff0
CPUs: 2 (EGS) | DIMMs: 32 | System Fans: 4 | PSUs: 2 (redundant)
Fan CPLD: bus9/0x22 (Lattice or Altera, IDCODE runtime detect)
CPLD regs: 0x03=tach, 0x04=PWM, 0x05=presence, 0x0A=status/control
PSU PMBus: bus7, 0x58/0x59 | PECI: CPU0=0x30, CPU1=0x31
Power button out: GPIO69(GPIOI5) | Reset out: GPIO121(GPIOP1)
Power OK: GPIO47(GPIOF7) | SLP_S3: GPIO168(GPIOV0) | SLP_S4: GPIO169(GPIOV1)
```

### Remaining Items (P3, non-blocking)

1. MB CPLD exact chip model — need BOM/PCB visual inspection
2. GPIO174 hardware-level confirmation — need schematic for MEMHOT vs SSIF_ALERT

### Next Step

Create `meta-evb-2u-egs/` machine layer skeleton under `openbmc/` with DTS, machine.conf, layer.conf.

## NOTES

- Current build dir `evb-ast2600` exists; use `. openbmc-env` to restore
- `openbmc-env` only restores env — does NOT select machine or modify `MACHINE`
- `setup` selects machine, generates build dir, rewrites `MACHINE` in `local.conf`
- Template default machine is `qemuarm`; the `setup` script overrides it
- 76 machines across 27 vendor layers; largest is meta-facebook (16 machines with 3-level nesting)
- `upstream-layers/` contains 7 items: bitbake, openembedded-core, 4 meta-* layers, yocto-docs
- `bitbake` and `scripts` at repo root are symlinks to `upstream-layers/openembedded-core/`
- `meta-arm`, `meta-openembedded`, `meta-raspberrypi`, `meta-security` at repo root are symlinks to `upstream-layers/`
- `ROOT_HOME = "/home/root"` — non-standard, historical legacy
- CI via Jenkins (`jenkins.openbmc.org`), no in-repo CI workflows; tests via Robot Framework in separate repo
- GitHub Issues for bugs only; questions go to mailing list (`openbmc@lists.ozlabs.org`) or Discord
- User-created layers (`meta-mycompany`, `meta-myproduct`) exist locally but are untracked
