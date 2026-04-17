# OpenBMC 从零到精通：嵌入式全栈工程师实战教程

> **项目背景**：基于 evb-2u-egs 平台（Intel EGS + AST2600），从 AMI MegaRAC SPX 4.0 迁移至 OpenBMC
> **目标读者**：有 C/嵌入式基础但零 OpenBMC 经验的工程师
> **终极目标**：达到 Meta/Google/Microsoft 等大厂嵌入式全栈开发岗面试秒杀水平

---

## 目录

- [第零章：架构全景 — 8层认知模型](#第零章架构全景--8层认知模型)
  - [0.1 BMC 是什么](#01-bmc-是什么)
  - [0.2 Yocto / OpenEmbedded / BitBake 三者关系](#02-yocto--openembedded--bitbake-三者关系)
  - [0.3 Layer 架构 — OpenBMC 的灵魂](#03-layer-架构--openbmc-的灵魂)
  - [0.4 BitBake 变量系统](#04-bitbake-变量系统)
  - [0.5 Recipe (.bb) 和 Append (.bbappend)](#05-配方-bb-和-append-bbappend)
  - [0.6 OpenBMC 特有架构](#06-openbmc-特有架构)
  - [0.7 构建流程全景](#07-构建流程全景)
  - [0.8 evb-2u-egs 在体系中的位置](#08-evb-2u-egs-在体系中的位置)
- [第一章：Yocto/BitBake 深度精通](#第一章yoctobitbake-深度精通)
  - [1.1 BitBake 任务执行链](#11-bitbake-任务执行链)
  - [1.2 依赖解析机制](#12-依赖解析机制)
  - [1.3 变量作用域与展开时机](#13-变量作用域与展开时机)
  - [1.4 OVERRIDES 机制深度剖析](#14-overrides-机制深度剖析)
  - [1.5 bbclass 继承体系](#15-bbclass-继承体系)
  - [1.6 sstate-cache 与构建加速](#16-sstate-cache-与构建加速)
  - [1.7 镜像构建流程](#17-镜像构建流程)
  - [1.8 调试 BitBake 构建问题](#18-调试-bitbake-构建问题)
  - [1.9 BitBake 面试题速查](#19-bitbake-面试题速查)
- [第二章：OpenBMC 框架精通](#第二章openbmc-框架精通)
- [第三章：实战篇 — 手把手创建机器层](#第三章实战篇--手把手创建机器层)
- [第四章：Linux 内核与设备树](#第四章linux-内核与设备树)
- [第五章：IPMI 与 Redfish 协议精通](#第五章ipmi-与-redfish-协议精通)
- [第六章：调试与验证](#第六章调试与验证)
  - [§6.10 实战 Troubleshooting 案例集](#610-实战-troubleshooting-案例集--evb-2u-egs-项目真实战报)
- [第七章：面试必杀技](#第七章面试必杀技)
- [第八章：进阶之路](#第八章进阶之路)
- [第九章：实机烧录与硬件调试](#第九章实机烧录与硬件调试)
  - [§9.1 从 QEMU 到真机——心态准备与工具清单](#91-从-qemu-到真机心态准备与工具清单)
  - [§9.2 串口连接与调试控制台](#92-串口连接与调试控制台)
  - [§9.3 Flash 分区布局详解](#93-flash-分区布局详解)
  - [§9.4 初次烧录实战](#94-初次烧录实战)
  - [§9.5 首次启动验证清单](#95-首次启动验证清单)
  - [§9.6 运行时固件更新](#96-运行时固件更新)
  - [§9.7 双 Flash A/B Bank 策略](#97-双-flash-ab-bank-策略)
  - [§9.8 实机常见故障排查](#98-实机常见故障排查)
  - [§9.9 面试加分点：实机经验总结](#99-面试加分点实机经验总结)
  - [§9.10 ARM32 内存管理深度解析（面试杀手锏）](#910-arm32-内存管理深度解析面试杀手锏)

---

## 第零章：架构全景 — 8层认知模型

### 0.1 BMC 是什么

BMC（Baseboard Management Controller）是服务器主板上的一颗**独立的嵌入式处理器**，它的职责是：

```
┌─────────────────────────────────────────────────────────────┐
│                    服务器主机 (Host)                          │
│   Intel Xeon / AMD EPYC / ARM ...                           │
│   运行 Linux / Windows / ESXi 等 OS                         │
│   ↑ 这是客户买服务器要用的东西                                │
└───────────┬─────────────────────────────────────────────────┘
            │  PECI (温度)  │  GPIO (开关机)  │  I2C (传感器)
            │  LPC/eSPI     │  JTAG           │  UART (串口)
┌───────────▼─────────────────────────────────────────────────┐
│                    BMC (我们开发的)                           │
│   AST2600 ARM SoC, 运行 Linux (OpenBMC)                     │
│   职责：                                                     │
│   1. 开关机控制 (即使主机关机，BMC也在运行)                    │
│   2. 硬件监控 (温度/电压/风扇转速)                            │
│   3. 风扇控制 (PID算法自动调速)                               │
│   4. 远程管理 (IPMI/Redfish/WebUI/SSH)                       │
│   5. 固件更新 (BIOS/CPLD/自身)                               │
│   6. 日志记录 (SEL/错误事件)                                  │
└─────────────────────────────────────────────────────────────┘
```

**关键理解**：BMC 是一台**独立的小电脑**，有自己的 CPU（ARM）、内存（512MB-2GB）、Flash（32-128MB）、网卡。它和主机的关系类似于汽车的"行车电脑"和"发动机"的关系 — 行车电脑监控发动机，但它们是独立系统。

**面试要点**：当别人问"BMC 和 BIOS 什么关系"，你要说：BMC 在主机上电之前就已经在运行了，它负责给主机供电序列（power sequencing）；BIOS 是主机启动时运行的固件，它通过 IPMI/KCS 和 BMC 通信获取硬件信息。

#### 🔬 实操：在仓库中感受 BMC

在我们的工作区中，BMC 相关的一切都在 `openbmc/` 目录下。你可以这样验证：

```bash
# 查看构建好的固件镜像（如果已构建过）
ls openbmc/build/evb-ast2600/tmp/deploy/images/evb-ast2600/
# 你会看到 .static.mtd 文件 — 这就是刷入 SPI Flash 的完整固件

# 查看我们要移植的 AMI 代码（对照参考）
ls AMI_bmc_code/src/core/ | head -20
# 469 个核心模块 — PDK、IPMI、HAL、传感器、风扇控制
# 我们的任务就是把这些功能在 OpenBMC 框架下重新实现
```

**关键区分**：我们工作区有两套代码：
- `AMI_bmc_code/` — AMI MegaRAC SPX 4.0 的完整源码（旧方案，作为参考）
- `openbmc/` — OpenBMC 仓库（新方案，我们要在这里创建 `meta-evb-2u-egs`）

---

### 0.2 Yocto / OpenEmbedded / BitBake 三者关系

这三个名字经常让新手困惑。它们的关系是：

```
┌─────────────────────────────────────────────────────────────┐
│  Yocto Project (雨伞项目)                                    │
│  ├── 不是一个软件，是一个协作项目/标准                         │
│  ├── 定义了"怎么做嵌入式 Linux 发行版"的规范                  │
│  └── 提供参考实现和工具链                                     │
│                                                              │
│  ├── BitBake (构建引擎)                                      │
│  │   ├── 类似 make/cmake/ninja 的角色                        │
│  │   ├── 解析 .bb/.bbappend/.bbclass/.conf 文件              │
│  │   ├── 计算依赖图 → 调度编译任务 → 输出 packages            │
│  │   └── 用 Python 写的，配方文件混合 Python + Shell          │
│  │                                                           │
│  ├── OpenEmbedded-Core (基础配方集)                           │
│  │   ├── 提供 gcc, glibc, busybox, systemd 等基础包          │
│  │   ├── 提供 image.bbclass, kernel.bbclass 等核心类          │
│  │   └── 所有嵌入式 Linux 都需要的底层                        │
│  │                                                           │
│  └── Poky (参考发行版)                                       │
│      └── = BitBake + OE-Core + Yocto自己的配置               │
└─────────────────────────────────────────────────────────────┘
```

**类比**：
- **BitBake** = 编译器 (把配方变成二进制)
- **OE-Core** = 标准库 (基础包和工具)
- **Yocto** = 语言规范 (定义了配方怎么写)
- **Layer** = 库/模块 (按功能分组的配方集合)

#### 🔬 实操：验证三者在仓库中的真实存在

```bash
# BitBake — 构建引擎
ls -la openbmc/bitbake
# lrwxrwxrwx bitbake -> upstream-layers/bitbake/
# 它是一个符号链接！指向 openembedded-core 里的子目录

# 实际的 bitbake 可执行文件
ls openbmc/bitbake/bin/
# bitbake  bitbake-diffsigs  bitbake-dumpsig  bitbake-getvar  bitbake-hashclient ...
# 这些全是 Python 脚本

# OpenEmbedded-Core — 基础配方集
ls openbmc/upstream-layers/openembedded-core/meta/recipes-core/
# busybox/  dbus/  glib-2.0/  glibc/  systemd/  ...
# 这些就是所有嵌入式 Linux 系统都需要的基础包

# Yocto 标准 — 参考文档
ls openbmc/upstream-layers/yocto-docs/
# documentation/  ...
# Yocto 官方文档源文件（reStructuredText 格式）
```

**💡 理解符号链接的设计**：OpenBMC 把 `bitbake/`、`scripts/`、`meta-arm/`、`meta-openembedded/` 等都做成符号链接指向 `upstream-layers/` 内部，这是为了让仓库根目录看起来"平坦"，同时保证上游代码统一放在 `upstream-layers/` 目录下管理，与本项目的自有代码隔离。

---

### 0.3 Layer 架构 — OpenBMC 的灵魂

这是**面试最爱问的部分**。Layer 是 Yocto 的核心设计哲学。

#### 为什么需要 Layer？

想象你要做 10 台不同服务器的 BMC 固件。它们 95% 的代码相同（都需要 IPMI、都需要 Web 界面），但 5% 不同（GPIO 引脚、传感器地址、风扇数量）。

```
                    ┌──────────────────────────────────────┐
                    │   openbmc-phosphor (共享发行版)        │
优先级 1 (最低)      │   IPMI / Redfish / WebUI / 更新机制   │
                    │   所有机器都用                         │
                    └──────────────┬───────────────────────┘
                                   │ 继承
                    ┌──────────────▼───────────────────────┐
优先级 5             │   meta-aspeed (SoC 层)                │
                    │   AST2600 的 U-Boot / 内核 / DTS      │
                    │   所有用 AST2600 的机器共用             │
                    └──────────────┬───────────────────────┘
                                   │ 继承 + 覆盖
          ┌────────────────────────▼─────────────────────────────┐
优先级 10  │   meta-evb-2u-egs (你的机器层) ← 我们要创建的        │
          │   这台特定机器的 GPIO / 传感器 / 风扇 / 电源配置      │
          │   通过 .bbappend 覆盖上层的默认值                     │
          └──────────────────────────────────────────────────────┘
```

#### Layer 优先级（BBFILE_PRIORITY）

```python
# 当两个 layer 都提供同一个 配方 的 .bbappend 时，
# 优先级高的后执行（后执行 = 最终生效）
BBFILE_PRIORITY_phosphor-layer = 1      # 最先执行，提供默认值
BBFILE_PRIORITY_aspeed-layer = 5        # SoC 层覆盖
BBFILE_PRIORITY_evb-2u-egs-layer = 10   # 机器层最终决定
```

**面试题**："如果 distro 默认的 `SERIAL_CONSOLES` 设置的是 ttyS0，但你的板子用 ttyS4，怎么办？"
**答**：在 `meta-evb-2u-egs/conf/machine/evb-2u-egs.conf` 里写 `SERIAL_CONSOLES = "115200;ttyS4"`，因为 machine.conf 的变量会覆盖 distro 默认值。覆盖机制基于 BitBake 的变量赋值优先级：`=` > `?=` > `??=`。

#### 🔬 实操：用真实代码理解 Layer 架构

##### OpenBMC 仓库顶层目录结构

在实际的 `openbmc/` 仓库中执行 `ls`，你会看到这样的目录：

```
openbmc/
├── setup                    ← 构建入口（必须 source，不能 execute）
├── openbmc-env              ← 恢复已有构建环境的快捷脚本
│
│  ===== 基础工具 =====
├── bitbake -> upstream-layers/bitbake/   ← 符号链接！
├── scripts -> upstream-layers/openembedded-core/scripts/   ← 符号链接！
│
│  ===== 上游只读层（全部是符号链接）=====
├── meta-arm -> upstream-layers/meta-arm/
├── meta-openembedded -> upstream-layers/meta-openembedded/
├── meta-raspberrypi -> upstream-layers/meta-raspberrypi/
├── meta-security -> upstream-layers/meta-security/
│
│  ===== SoC 芯片支持层 =====
├── meta-aspeed/             ← AST2400/2500/2600/2700（我们用的）
├── meta-nuvoton/            ← NPCM750/845
│
│  ===== 核心框架层 =====
├── meta-phosphor/           ← ★ OpenBMC 核心！所有共享逻辑在这里
│
│  ===== 厂商定制层（每个厂商一个）=====
├── meta-facebook/           ← 16 台机器，3 层嵌套（最大的厂商层）
├── meta-ibm/                ← 10 台机器
├── meta-google/             ← gBMC 发行版覆盖层
├── meta-quanta/             ← 5 台机器 ← 我们的模板 s6q 在这里
├── meta-ampere/             ← 3 台机器
├── ... (20+ 其他厂商)
│
│  ===== 构建输出 =====
├── build/                   ← bitbake 的工作目录
│   └── evb-ast2600/         ← 当前活跃的构建配置
│
│  ===== 上游仓库原始位置 =====
└── upstream-layers/         ← 不要修改这里面的任何东西！
    ├── bitbake/
    ├── openembedded-core/
    ├── meta-arm/
    ├── meta-openembedded/
    ├── meta-security/
    ├── meta-raspberrypi/
    └── yocto-docs/
```

**关键理解**：

1. **符号链接的设计意图**：`bitbake`、`scripts`、`meta-arm` 等在仓库根目录出现，但它们实际上是指向 `upstream-layers/` 内部的符号链接。这样做的好处是 `setup` 脚本可以直接引用 `${OEROOT}/bitbake/` 而不需要写长路径。
2. **upstream-layers/ 是只读的**：这些是上游社区的仓库，我们**绝对不能修改**。如果需要修改上游包的行为，在自己的厂商层用 `.bbappend` 覆盖。
3. **每个 meta-xxx/ 就是一个 layer**：Layer 不是什么抽象概念，就是一个包含 `conf/layer.conf` 的目录。

##### 真实 Layer 文件树 — meta-s6q 完整结构

`meta-quanta/meta-s6q` 是我们创建 `meta-evb-2u-egs` 的**主要模板**（同样是 x86 + AST2600 平台，51个文件）。它的完整目录结构：

```
meta-quanta/meta-s6q/                     ← 一个完整的机器层
├── conf/
│   ├── layer.conf                         ← Layer 注册文件（告诉 BitBake "我是谁"）
│   ├── machine/
│   │   └── s6q.conf                       ← 机器定义（硬件参数）
│   └── templates/
│       └── default/
│           ├── bblayers.conf.sample       ← setup 脚本用的模板
│           ├── conf-notes.txt             ← 构建完成后显示的提示
│           └── local.conf.sample          ← 本地构建配置模板
├── recipes-phosphor/                      ← 覆盖 meta-phosphor 的配方
│   ├── configuration/                     ← Entity Manager 硬件描述
│   │   ├── entity-manager_%.bbappend
│   │   └── entity-manager/
│   │       └── *.json                     ← 传感器/设备拓扑定义
│   ├── fans/                              ← 风扇控制配置
│   │   ├── phosphor-pid-control_%.bbappend
│   │   └── phosphor-pid-control/
│   │       └── config.json                ← PID 参数
│   ├── ipmi/                              ← IPMI 配置
│   │   ├── phosphor-ipmi-config.bbappend
│   │   └── phosphor-ipmi-config/
│   │       ├── dev_id.json                ← 设备标识
│   │       ├── channel_config.json        ← IPMI 通道
│   │       └── ...
│   └── leds/                              ← LED 定义
│       ├── phosphor-led-manager_%.bbappend
│       └── phosphor-led-manager/
│           └── led-group-config.json      ← LED 组/GPIO
├── recipes-s6q/                           ← 机器特有的包
│   └── packagegroups/
│       └── packagegroup-s6q-apps.bb       ← 这台机器需要的软件列表
└── recipes-kernel/                        ← 内核定制
    └── linux/
        └── linux-aspeed_%.bbappend        ← 内核补丁/配置
```

**⚠️ 注意**：上面的目录树是一个典型机器层的**示意图**，展示了常见的 bbappend 文件组织模式。实际的 s6q 层并不包含 `entity-manager_%.bbappend`、`phosphor-pid-control_%.bbappend` 和 `linux-aspeed_%.bbappend` — 这些是我们在 evb-2u-egs 层中需要创建的新文件。s6q 的实际 bbappend 文件列表请参考 §0.4 的完整清单。

**模式总结**：每个 `.bbappend` 文件旁边通常有一个同名目录，里面放着该 `.bbappend` 需要的配置文件（JSON/cfg/patch）。这是 Yocto 的 `FILESEXTRAPATHS` 约定。

##### layer.conf 逐行解读

**文件**：`meta-quanta/meta-s6q/conf/layer.conf`（11行，完整）

以下是 s6q 的 `layer.conf` **完整原文**（11行），逐行加注释：

```python
# We have a conf and classes directory, add to BBPATH
BBPATH .= ":${LAYERDIR}"
# BBPATH 是 BitBake 的搜索路径，类似 shell 的 PATH
# .= 是"追加赋值"，把当前 layer 的路径加入搜索列表
# ${LAYERDIR} 自动展开为这个 layer.conf 所在目录的绝对路径

# We have recipes-* directories, add to BBFILES
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
            ${LAYERDIR}/recipes-*/*/*.bbappend"
# 用反斜杠续行把 .bb 和 .bbappend 写在同一条语句里
# 通配符匹配：recipes-phosphor/ipmi/xxx.bbappend 等
# 注意是两级通配：recipes-xxx/yyy/*.bb

BBFILE_COLLECTIONS += "s6q-layer"
# 层的集合名 — 用于 BBFILE_PATTERN 和 BBFILE_PRIORITY 的后缀
# 注意名字是 "s6q-layer" 而不是 "meta-s6q"
# 命名没有硬性规定，但必须在整个构建中唯一

BBFILE_PATTERN_s6q-layer := "^${LAYERDIR}/"
# 告诉 BitBake 本层配方的正则匹配模式
# 以本层目录开头的文件都属于 s6q-layer 这个 collection
# 注意用 := （立即展开），因为 ${LAYERDIR} 必须在解析时就锁定

LAYERSERIES_COMPAT_s6q-layer := "wrynose whinlatter"
# 兼容的 Yocto 发行版系列
# wrynose 和 whinlatter 是 Yocto 的版本代号
# 当前 OpenBMC 使用 whinlatter 系列
```

**注意：s6q 的 layer.conf 非常精简** — 只有 5 条有效语句。它**没有** `BBFILE_PRIORITY`（使用默认值）和 `LAYERDEPENDS`（不声明显式依赖）。这是合法的：
- 没有 `BBFILE_PRIORITY` → BitBake 使用默认优先级 1
- 没有 `LAYERDEPENDS` → BitBake 不做层依赖检查（依赖的层必须通过 `bblayers.conf.sample` 正确列出）

有些层（如 meta-facebook 的子层）会写 `LAYERDEPENDS` 和 `BBFILE_PRIORITY`，但对于简单的机器层不是必须的。

**💡 你创建 `meta-evb-2u-egs` 时的 layer.conf 改动**：

| s6q 原值 | evb-2u-egs 改为 | 原因 |
|---------|-----------------|------|
| `s6q-layer` | `evb-2u-egs-layer` | Collection 名必须全局唯一 |
| `wrynose whinlatter` | `wrynose whinlatter` | 不变，保持相同兼容系列 |
| 其他 | 不变 | 结构完全一致 |

##### machine.conf 逐行解读

**文件**：`meta-quanta/meta-s6q/conf/machine/s6q.conf`（31行）

> 💡 **大白话**：`machine.conf` 就像是一台机器的"出生证明"。你买了一台服务器，它有什么芯片、多大的 Flash、用什么方式和主机通信——所有这些"这台机器是谁"的信息，全写在这一个文件里。OpenBMC 的构建系统（BitBake）读到这个文件，就知道该怎么编译出匹配这台硬件的固件。
>
> 打个比方：你去配眼镜，验光师拿到你的度数（近视 300、散光 50）——这就是 machine.conf。镜片厂根据这张处方单来磨镜片（编译固件）。没有这张单子，厂家就不知道给你磨什么度数。

以下是 s6q 的 `s6q.conf` **完整原文**（31行），逐行加注释：

```python
# ===== 第一段：告诉构建系统"内核该用什么硬件描述文件" =====

# KMACHINE = "aspeed"
# 注释掉了 — 因为 aspeed.inc 已经设置 KMACHINE = "aspeed"

KERNEL_DEVICETREE = "aspeed/${KMACHINE}-bmc-quanta-${MACHINE}.dtb"
```

> **大白话**：Linux 内核启动时需要一个"硬件说明书"（叫设备树 Device Tree），告诉内核"这块板子上有哪些芯片、接在哪条总线上"。这行就是告诉构建系统：去找名为 `aspeed/aspeed-bmc-quanta-s6q.dtb` 的设备树文件来编译。
>
> `${KMACHINE}` 和 `${MACHINE}` 是变量，会被自动替换。就像 Word 的邮件合并——模板里写"尊敬的{姓名}"，打印时自动替换成具体名字。

```python
# ===== 第二段：告诉构建系统"U-Boot 怎么编译" =====

UBOOT_MACHINE = "ast2600_openbmc_defconfig"
UBOOT_DEVICETREE = "ast2600a1-evb"
```

> **大白话**：U-Boot 是 BMC 上电后第一个运行的程序（引导加载器），类似于 PC 的 BIOS。这两行告诉构建系统：
> - 用哪个"编译配方"来编 U-Boot（`ast2600_openbmc_defconfig`）
> - 给 U-Boot 用哪个设备树（`ast2600a1-evb`，表示 AST2600 A1 版芯片的评估板）
>
> 为什么内核和 U-Boot 各有一个设备树？因为它们运行在不同阶段：U-Boot 在更早期，只需要知道怎么读 Flash、找到内核在哪里；内核启动后需要知道所有外设的详细信息。

```python
# ===== 第三段：引入"公共模板" =====

require conf/machine/include/ast2600.inc
require conf/machine/include/obmc-bsp-common.inc
```

> **大白话**：`require` 就是"把另一个文件的内容复制粘贴到这里"。
> - `ast2600.inc` 是 AST2600 芯片通用的配置（CPU 架构是 ARM、内存地址从哪开始、默认串口是 ttyS4 等）。**所有用 AST2600 的板子都会引入这个文件**，这样就不用在每台机器的 conf 里重复写一遍。
> - `obmc-bsp-common.inc` 是 OpenBMC 所有机器都共享的基础配置。
>
> 就像写简历时用模板——模板提供格式和通用内容，你只需要填自己的个人信息。

```python
# ===== 第四段：Flash 芯片有多大 =====

FLASH_SIZE = "65536"
```

> **大白话**：BMC 的固件（操作系统+应用程序+配置）全部烧写在 SPI Flash 芯片上。这行告诉构建系统"生成的固件镜像最大 65536 KB（= 64 MB）"。
>
> evb-2u-egs 使用双 w25q512 (每片 64MB) 主备冗余，总 128MB。但 FLASH_SIZE 只填单个 bank 的大小，因为编译出的镜像只会烧写到一个 bank 上。

```python
# ===== 第五段：这台机器需要哪些功能 =====

MACHINE_FEATURES += "\
        obmc-bmc-state-mgmt \
        obmc-chassis-state-mgmt \
        obmc-host-ipmi \
        obmc-host-state-mgmt \
        obmc-phosphor-chassis-mgmt \
        obmc-phosphor-fan-mgmt \
        obmc-phosphor-flash-mgmt \
        bonding \
        "
```

> **大白话**：这就是一张"功能清单"，像点菜一样勾选这台机器需要哪些软件功能：
> - `obmc-bmc-state-mgmt` → 我需要 **BMC 自身状态管理**（BMC 自己的开关机管理）
> - `obmc-chassis-state-mgmt` → 我需要 **机箱状态管理**（知道机箱是开着还是关着）
> - `obmc-host-ipmi` → 我需要 **IPMI 协议支持**（和主机之间的标准通信）
> - `obmc-host-state-mgmt` → 我需要 **主机状态管理**（控制主机开关机）
> - `obmc-phosphor-chassis-mgmt` → 我需要 **机箱管理扩展包**
> - `obmc-phosphor-fan-mgmt` → 我需要 **风扇管理**（测速、调速、报警）
> - `obmc-phosphor-flash-mgmt` → 我需要 **固件更新管理**（在线升级 BMC/BIOS 固件）
> - `bonding` → 我需要 **网口绑定**（两个网口合并成一个，提高可靠性）
>
> 构建系统看到这张清单后，会自动安装对应的软件包到固件里。**没勾选的功能就不会被编译进去**，这样固件体积更小。

```python
# ===== 第六段：关键服务用谁的实现 =====

VIRTUAL-RUNTIME_obmc-inventory-manager = "entity-manager"
PREFERRED_PROVIDER_virtual/obmc-inventory-data = "entity-manager"
```

> **大白话**：OpenBMC 框架把很多功能设计成了"接口"——比如"库存管理"这个活儿，可以由不同的软件来干。`VIRTUAL-RUNTIME` 就是告诉系统"库存管理这个活儿交给 entity-manager 来做"。
>
> 这里用 `=`（等号硬赋值），意思是"就它了，不许换"。就像你指定装修公司"刷墙必须用立邦"——写死了，不接受替换。

```python
VIRTUAL-RUNTIME_obmc-host-state-manager ?= "x86-power-control"
VIRTUAL-RUNTIME_obmc-chassis-state-manager ?= "x86-power-control"
```

> **大白话**：主机电源管理交给 `x86-power-control`（Intel x86 平台专用的电源控制服务）。注意这里用的是 `?=`（问号等号），意思是"**如果没人指定过，就用这个**"。
>
> 打个比方：`=` 是"我要大杯拿铁"（定死了），`?=` 是"如果你没想好喝什么，默认给你大杯拿铁"（给个建议，但你可以改）。用 `?=` 是因为可能有更上层的配置想换一个实现，留了灵活性。

```python
PREFERRED_PROVIDER_virtual/obmc-chassis-mgmt = "packagegroup-s6q-apps"
PREFERRED_PROVIDER_virtual/obmc-fan-mgmt = "packagegroup-s6q-apps"
PREFERRED_PROVIDER_virtual/obmc-flash-mgmt = "packagegroup-s6q-apps"
PREFERRED_PROVIDER_virtual/obmc-system-mgmt = "packagegroup-s6q-apps"
```

> **大白话**：`PREFERRED_PROVIDER` 是告诉构建系统"当需要某个虚拟功能时，用哪个具体的软件包来提供"。这 4 行全部指向 `packagegroup-s6q-apps`——这是 s6q 这台机器的**"总打包清单"**。
>
> 想象你开了一家餐厅，"套餐 A"包含：汤 + 主菜 + 甜点 + 饮料。这里的 `packagegroup-s6q-apps` 就是这个"套餐 A"，把 s6q 需要的所有定制化软件一网打尽。对我们 evb-2u-egs 来说，改成 `packagegroup-evb-2u-egs-apps` 就好。

```python
PREFERRED_PROVIDER_virtual/obmc-host-ipmi-hw ?= "phosphor-ipmi-kcs"
```

> **大白话**：BMC 和主机之间通信有很多种方式（KCS、BT、SSIF 等）。这行选择了 KCS（Keyboard Controller Style）。这是 x86 服务器最常见的方式——BMC 和主机之间通过一组 I/O 寄存器加状态位握手来传递 IPMI 命令，就像政务窗口递表格：一方把表格放到窗口台面（数据寄存器），然后按铃（写状态位），另一方听到铃响来取件、处理、再把回执放回台面按铃通知。

**⚠️ 注意：s6q.conf 中没有以下变量**（教程早期版本曾错误地列出）：
- 没有 `MACHINEOVERRIDES` — 不需要手动添加，因为 BitBake 自动将 `${MACHINE}` 加入 OVERRIDES
- 没有 `VIRTUAL-RUNTIME_obmc-discover-system-state` — 使用 phosphor-defaults.inc 的默认值
- 没有 `VIRTUAL-RUNTIME_obmc-fan-control` — 使用 phosphor-defaults.inc 的默认值（phosphor-fan-control）
- 没有 `VIRTUAL-RUNTIME_obmc-flash-bmc-mgmt` — 使用 phosphor-defaults.inc 的默认值

> 💡 **大白话**：这里列出的变量不在 s6q.conf 里，不代表它们不存在。它们是在更上游的"公共模板"（phosphor-defaults.inc）里用 `?=` 或 `??=` 设了默认值。就像你住酒店——你没特别要求的东西（毛巾数量、枕头硬度），酒店都有默认配置。只有你想改的才需要写出来。**machine.conf 里只写"跟默认不同的部分"，其余全靠继承。**

##### ast2600.inc — SoC 公共配置

> 💡 **大白话**：如果说 `s6q.conf`（machine.conf）是"这台具体机器的身份证"，那 `ast2600.inc` 就是"AST2600 芯片的族谱"。所有用 AST2600 芯片的板子（不管是 s6q、evb-2u-egs 还是其他），都共享这些底层参数。就像同一个车型的发动机参数——不管是哪家 4S 店卖的，发动机排量、马力都一样。

**文件**：`meta-aspeed/conf/machine/include/ast2600.inc`（22行）

```python
SOC_FAMILY = "aspeed-g6"
# 设置 SoC 家族标识 — "g6" 是 ASPEED 第 6 代的代号
# AST2600 属于 G6 家族（G5=AST2500, G4=AST2400）
```

> **大白话**：给芯片家族起个名字。就像说"这颗 CPU 是 Intel 第 12 代"。这里说的是"ASPEED 第 6 代"。后面的构建系统可以根据这个名字来决定编译哪些驱动。

```python
# 启用 SPL 签名（安全启动）
SOCSEC_SIGN_ENABLE ?= "1"
SOCSEC_SIGN_SOC ?= "2600"
```

> **大白话**：安全启动，防止有人往 BMC 里刷入恶意固件。就像手机的 bootloader 锁——只允许运行经过签名认证的系统。这里用 `?=` 是因为有些开发阶段可能想关掉它方便调试。

```python
include conf/machine/include/soc-family.inc
# 来自 OE-Core，自动将 SOC_FAMILY 加入 MACHINEOVERRIDES
# 效果：MACHINEOVERRIDES =. "aspeed-g6:"

require conf/machine/include/aspeed.inc
# ASPEED 通用配置（所有 AST 系列共享）
# 设置 kernel/bootloader 的 PREFERRED_PROVIDER、QEMU 参数等
```

> **大白话**：又是"引入公共模板"。`soc-family.inc` 把芯片家族名加入系统的"标签列表"，这样后面写配置时可以针对 `aspeed-g6` 做特殊处理。`aspeed.inc` 则是所有 ASPEED 芯片（不限于 AST2600）共用的配置。
>
> 这就像一个层级关系：**所有 BMC** → **所有 ASPEED 芯片** → **AST2600 专属** → **你的具体板子**。每一层都能添加或覆盖上一层的配置。

```python
DEFAULTTUNE = "armv7ahf-vfpv4d16"
require conf/machine/include/arm/arch-armv7a.inc
# AST2600 使用 ARM Cortex-A7 双核
# armv7ahf = ARMv7-A 硬浮点
# vfpv4d16 = VFPv4 浮点单元，16个双精度寄存器
```

> **大白话**：告诉编译器"这颗 CPU 的具体型号和能力"。就像告诉厨师"你的灶台是电磁炉还是煤气灶"——不同的灶台做菜的方式不一样。`armv7ahf` 表示"ARM v7 架构，带硬件浮点运算"，编译器就知道可以用硬件来做小数计算（比软件模拟快几十倍）。

```python
SERIAL_CONSOLES ?= "115200;ttyS4"
# AST2600 默认串口是 ttyS4（UART5）
# 注意用 ?= 而不是 = ，允许机器层覆盖（某些板子可能用不同 UART）
# 这就是为什么 evb-2u-egs 硬件定义文档中写 Console: ttyS4@115200
```

> **大白话**：BMC 的"命令行窗口"连在哪个串口上。`115200` 是波特率（通信速度），`ttyS4` 是第 5 个串口。开发调试时，你用 USB 转串口线连到板子上，电脑上用 PuTTY/minicom 打开这个端口，就能看到 BMC 的启动日志和命令行。这是嵌入式开发最基本的调试手段——没有屏幕键盘，全靠这根线。

```python
UBOOT_ENTRYPOINT ?= "0x80001000"
UBOOT_LOADADDRESS ?= "0x80001000"
# U-Boot 加载内核的地址

# QEMU 相关配置
QB_SYSTEM_NAME = "qemu-system-arm"
QB_MACHINE = "-machine ast2600-evb"
QB_MEM = "-m 1G"

PREFERRED_VERSION_u-boot-aspeed-sdk = "v2019.04+%"
PREFERRED_VERSION_u-boot-fw-utils-aspeed-sdk = "v2019.04+%"
# U-Boot 版本锁定到 v2019.04+ 系列
```

> **大白话**：
> - `UBOOT_ENTRYPOINT/LOADADDRESS`：告诉 U-Boot "把 Linux 内核搬到内存的哪个位置再执行"。`0x80001000` 是内存地址，不用记，直接用 AST2600 的默认值就行。
> - `QB_*`：QEMU 模拟器的参数。没有实机时，可以用 QEMU 在电脑上模拟一台 AST2600 来测试，非常方便。
> - `PREFERRED_VERSION`：锁定 U-Boot 版本到 `v2019.04+` 系列。这是个保险措施——防止上游更新了一个不兼容的新版本导致你的板子不能启动。

**注意 ast2600.inc 不包含的内容**（易混淆）：
- **没有** `MACHINE_FEATURES` — 这是在 `aspeed.inc` 中添加 `hw-rng`
- **没有** `PREFERRED_PROVIDER_virtual/kernel` — 在 `aspeed.inc` 中用 `?=` 设置
- **没有** `PREFERRED_PROVIDER_virtual/bootloader` — 同样在 `aspeed.inc` 中
- **没有** `QB_KERNEL_CMDLINE_APPEND` — QEMU 参数比较精简

> **大白话**：这里专门列出"你以为会在 ast2600.inc 里的但其实不在的"变量。它们在更上层的 `aspeed.inc`（所有 ASPEED 芯片共用）里。新手经常搞混"在哪一层定义的"——记住继承链：`aspeed.inc` → `ast2600.inc` → 你的 `machine.conf`。

##### s6q 与 evb-2u-egs 对比表

> 💡 **大白话**：下面这张表是"抄作业指南"。左边是 s6q（我们的模板/参考），右边是我们要创建的 evb-2u-egs。大部分内容可以直接抄，只有几个地方需要改成我们自己的名字和参数。

| 配置项 | s6q (模板) | evb-2u-egs (我们的) | 备注 |
|--------|-----------|--------------------|----- |
| `KERNEL_DEVICETREE` | `aspeed/${KMACHINE}-bmc-quanta-${MACHINE}.dtb` | `aspeed/aspeed-bmc-evb-2u-egs.dtb` | 需要写新 DTS |
| `UBOOT_MACHINE` | `ast2600_openbmc_defconfig` | `ast2600_openbmc_defconfig` | 相同，标准 SPI Flash 启动 |
| `UBOOT_DEVICETREE` | `ast2600a1-evb` | `ast2600-evb-2u-egs` | U-Boot DTS |
| `FLASH_SIZE` | `65536` | `65536` | 都是单 bank 64MB（evb-2u-egs 为双 w25q512 主备，总 128MB） |
| `MACHINE_FEATURES` | 8 个 features + bonding | 类似，按需调整 | x86 平台通用 |
| `VIRTUAL-RUNTIME_obmc-inventory-manager` | `= "entity-manager"` | `= "entity-manager"` | 硬赋值，确定选择 |
| `VIRTUAL-RUNTIME_obmc-host-state-manager` | `?= "x86-power-control"` | `?= "x86-power-control"` | 相同 |
| `PREFERRED_PROVIDER_virtual/obmc-*-mgmt` | `packagegroup-s6q-apps` | `packagegroup-evb-2u-egs-apps` | 改成我们的包组名 |
| Collection 名 | `s6q-layer` | `evb-2u-egs-layer` | layer.conf 中唯一标识 |

> **大白话**：
> - **可以直接抄的**：`UBOOT_MACHINE`、`FLASH_SIZE`、`MACHINE_FEATURES`、两个 `VIRTUAL-RUNTIME` —— 因为 s6q 和我们都是 AST2600 + x86 主机 + SPI Flash 启动，底层一样。
> - **必须改的**：`KERNEL_DEVICETREE`（改成我们的板子名）、`UBOOT_DEVICETREE`（改成我们的 U-Boot 设备树名）、所有 `packagegroup-s6q-apps`（改成 `packagegroup-evb-2u-egs-apps`）、Collection 名（改成 `evb-2u-egs-layer`）。
> - **总结**：90% 抄作业，10% 改名字。这就是参考模板的价值。

---

### 0.4 BitBake 变量系统

> 💡 **大白话**：这一节是**整个教程最重要的基础**。BitBake 的变量系统就像一门"微型编程语言"——你在 `.conf` 和 `.bb` 文件里写的每一行，本质上都是在操作变量。不理解变量系统，后面所有内容都是雾里看花。
>
> 打个比方：变量系统就是 Excel 的公式。你在 A1 格写 `=B1+C1`，A1 的值取决于 B1 和 C1。BitBake 的变量也一样——一个变量的最终值，取决于很多文件里对它的设置，最后按规则算出一个"赢家"。

这是写配方的基础。不理解这个，你写的每一行配方都是在猜。

#### 赋值运算符

```python
# 1. 硬赋值 — 无条件覆盖一切
VAR = "value"

# 2. 默认值 — 只在没人设过时生效
VAR ?= "default"          # 软默认（第一个 ?= 赢）
VAR ??= "weak_default"    # 弱默认（所有 ?= 之后才考虑）

# 3. 追加/前置 — 不覆盖，而是添加
VAR += "appended"         # 追加（带空格）
VAR =+ "prepended"        # 前置（带空格）
VAR:append = " appended"  # 追加（无自动空格，注意引号内前导空格！）
VAR:prepend = "prepended " # 前置

# 4. 条件覆盖 — 基于 OVERRIDES
VAR:machine-name = "only_for_this_machine"
VAR:class-target = "only_for_target_build"
```

> **大白话**：
> - `=` 就是"我说了算"，不管别人之前设了什么，我直接覆盖。老板拍板。
> - `?=` 是"如果还没人说话，我先提个建议"。先到先得，后来的 `?=` 没用。
> - `??=` 是"如果到最后都没人做决定，那就用我的"。最弱的兜底方案，但同级别里最后一个 `??=` 赢。
> - `+=` 是"在现有内容后面加点东西"，像往购物车里多加一件商品。
> - `:append` 和 `+=` 类似，但**不自动加空格**，而且**解析时机不同**（更靠后执行，所以能覆盖 `+=`）。

#### OVERRIDES 机制 — Yocto 最强大的特性

```python
# OVERRIDES 是一个冒号分隔的列表，定义了"当前上下文"
OVERRIDES = "linux:arm:armv7a:evb-2u-egs:class-target:..."

# 当你写：
KERNEL_FEATURES:evb-2u-egs = "special-feature"
# BitBake 看到 OVERRIDES 里有 "evb-2u-egs"，所以这个赋值生效

# 当构建另一台机器时，OVERRIDES 里没有 "evb-2u-egs"，这行被忽略
```

> **大白话**：OVERRIDES 是一个"标签系统"。构建系统在运行时会给自己贴一堆标签，比如"我正在构建的是 ARM 架构的、AST2600 芯片的、evb-2u-egs 这台机器的"。
>
> 当你在配置里写 `SRC_URI:evb-2u-egs = "xxx"`，BitBake 就会检查自己的标签列表——如果有 `evb-2u-egs` 这个标签，这行就生效；没有就当它不存在。
>
> 这就像你在淘宝上设置："如果收货地址是北京，运费 10 元；如果是新疆，运费 30 元"。OVERRIDES 就是那个"收货地址"标签。

**面试必杀技**：OVERRIDES 在 Honister (Yocto 3.4, 2021) 中从下划线改成了冒号。旧语法 `VAR_append` 变成 `VAR:append`。能说出这个历史变更和准确的版本号，面试官会知道你不是只看了教程。

#### 🔬 实操：用真实代码理解变量优先级

> 💡 **大白话**：前面讲了 `=`、`?=`、`??=` 这些符号的理论规则，现在来看 OpenBMC 仓库里**真实在用**的例子。看真代码比看理论管用十倍。

我们来看 OpenBMC 仓库中**真正在用**的变量赋值，理解 `?=` 和 `??=` 的实战差异。

**文件**：`meta-phosphor/conf/distro/include/phosphor-defaults.inc`（169行）

这个文件是整个 OpenBMC 的"默认值中心"，**所有机器**构建时都会加载它。摘录关键部分：

> **大白话**：想象一个公司的"员工手册"——里面写了所有岗位的默认规章制度。每个部门（每台机器）可以在自己的部门规定里覆盖某些条款，但如果没特别说明，就按员工手册走。`phosphor-defaults.inc` 就是 OpenBMC 的"员工手册"。

```python
# ======= phosphor-defaults.inc 实际内容节选 =======

# -- 实例数量（用 ??= 弱默认）--
OBMC_BMC_INSTANCES ??= "0"
OBMC_HOST_INSTANCES ??= "0"
# 这些用 ??= 因为不同平台（多主机等）可能需要覆盖

# -- 核心服务的默认实现（全部用 ?= 软默认）--
VIRTUAL-RUNTIME_obmc-bmc-state-manager ?= "phosphor-state-manager-bmc"
VIRTUAL-RUNTIME_obmc-chassis-state-manager ?= "phosphor-state-manager-chassis"
VIRTUAL-RUNTIME_obmc-host-state-manager ?= "phosphor-state-manager-host"
VIRTUAL-RUNTIME_obmc-discover-system-state ?= "phosphor-state-manager-discover"
VIRTUAL-RUNTIME_obmc-fan-control ?= "phosphor-fan-control"
VIRTUAL-RUNTIME_obmc-inventory-manager ?= "phosphor-inventory-manager"
VIRTUAL-RUNTIME_obmc-sensors-hwmon ?= "phosphor-hwmon"

# -- IPMI provider（也是 ?= 软默认）--
VIRTUAL-RUNTIME_phosphor-ipmi-providers ?= "phosphor-ipmi-fru"
```

**⚠️ 重要澄清：phosphor-defaults.inc 中所有 VIRTUAL-RUNTIME 用的都是 `?=`（软默认），不是 `??=`（弱默认）！**

只有 `OBMC_BMC_INSTANCES`、`OBMC_HOST_INSTANCES` 等少数变量用了 `??=`。

**为什么全部 VIRTUAL-RUNTIME 用 `?=`？**

```
变量赋值优先级（从高到低）：

  1. =   硬赋值（无条件覆盖一切）
  2. ?=  软默认（第一个 ?= 赢，后来的 ?= 被忽略）
  3. ??= 弱默认（所有解析完成后，没人设过才用）

设计意图：
```

| phosphor-defaults.inc | 机器层 machine.conf | 谁赢？ | 原因 |
|----------------------|-------------------|----|------|
| `?= "phosphor-state-manager-host"` | `?= "x86-power-control"` | **取决于解析顺序** | 两个 `?=` 竞争，先被解析的赢 |
| `?= "phosphor-state-manager-host"` | `= "x86-power-control"` | **machine.conf** | `=` 无条件覆盖 `?=` |

这就是为什么 s6q.conf 中某些变量用 `?=`（如 `VIRTUAL-RUNTIME_obmc-host-state-manager ?= "x86-power-control"`），而某些用 `=`（如 `VIRTUAL-RUNTIME_obmc-inventory-manager = "entity-manager"`）— 需要确定性覆盖的用 `=`，允许进一步覆盖的用 `?=`。

> **大白话**：回想前面 s6q.conf 里的咖啡比喻。entity-manager 用 `=` 是因为"就它了，铁了心不换"；x86-power-control 用 `?=` 是因为"先选这个，但如果某个更上层的配置说用别的，那也行"。设计上的考量是：entity-manager 是唯一可选的库存管理实现，没有替代品；而电源管理有可能被测试环境替换成模拟版本。

**实际覆盖链演示**：

假设构建 `s6q` 时状态管理器的变量解析过程：

> **大白话**：下面是一个"谁说了算"的推演过程，像法庭辩论一样——两个文件都想设同一个变量，到底听谁的？

```
第1步：BitBake 解析 phosphor-defaults.inc
  VIRTUAL-RUNTIME_obmc-host-state-manager ?= "phosphor-state-manager-host"
  → 这是 ?= ，当前无值，设为 "phosphor-state-manager-host"

第2步：BitBake 解析 s6q.conf
  VIRTUAL-RUNTIME_obmc-host-state-manager ?= "x86-power-control"
  → 也是 ?= ，但已经有值了（第1步设的），被忽略！

等等——这意味着 s6q 的覆盖没生效？
不！因为 BitBake 解析机器层的 conf 文件通常在 distro 层之前。
实际顺序是 machine.conf 先于 distro includes 被解析。
所以 s6q.conf 的 ?= 先执行，phosphor-defaults.inc 的 ?= 被忽略。
→ 最终值 = "x86-power-control" ✓

如果用 = 呢？
  VIRTUAL-RUNTIME_obmc-host-state-manager = "x86-power-control"
  → 无论解析顺序如何，= 都赢 ?= ，结果确定。
  → 但 = 也意味着别人不能再覆盖你了。
```

**关键区别场景**：

```python
# 场景A：两个 ?= 竞争
# 文件1 (先解析): VAR ?= "aaa"
# 文件2 (后解析): VAR ?= "bbb"
# 结果：VAR = "aaa" （第一个 ?= 赢）

# 场景B：两个 ??= 竞争
# 文件1 (先解析): VAR ??= "aaa"
# 文件2 (后解析): VAR ??= "bbb"
# 结果：VAR = "bbb" （最后一个 ??= 赢 — 与 ?= 相反！）

# 场景C：?= 和 ??= 混合
# 文件1: VAR ??= "aaa"
# 文件2: VAR ?= "bbb"
# 结果：VAR = "bbb" （?= 总是赢 ??=，不管解析顺序）
```

**⚠️ 面试陷阱**：面试官可能问"两个 `??=` 谁赢？"。答案是**最后一个**，因为 `??=` 是"所有解析完成后才决定"，最后赋值的覆盖之前的。这和 `?=`（第一个赢）恰好相反。这个细节很多老手都说不清楚。

> **大白话**：
> - `?=` 先到先得——第一个占坑的赢（像排队买票）
> - `??=` 后来居上——最后一个说话的赢（像拍卖举牌，最后一次出价算数）
> - `=` 无敌——不管谁先谁后，用 `=` 的总是赢（像法院判决，终审裁定）

#### 🔬 深入：`:=` 立即展开 — 为什么 FILESEXTRAPATHS 必须用它

在 s6q 的所有 `.bbappend` 文件中，你会看到一个固定模式：

```python
FILESEXTRAPATHS:prepend:s6q := "${THISDIR}/${PN}:"
#                            ^^
#                     注意这里是 := 不是 =
```

> **大白话**：`:=` 是"拍照"——**此刻此地**，`${THISDIR}` 指向哪个目录就记录哪个目录。如果用 `=` 就变成了"回忆"——等到需要用的时候才去想当初是哪个目录，但那时候可能已经"忘了"（上下文变了）。
>
> 打个比方：你在北京发短信给快递员"请送到我的当前位置"。如果是 `:=`（立即展开），快递员收到的是"北京市朝阳区 xx 路 xx 号"——定死了。如果是 `=`（延迟展开），快递员收到的是"我的当前位置"——等他去送的时候，你可能已经飞到上海了，包裹就送错地方了。

**为什么必须用 `:=` 而不是 `=`？**

```python
# := 是"立即展开"（Immediate Expansion）
# 在 BitBake 解析到这一行的瞬间，就把 ${THISDIR} 和 ${PN} 替换成实际值
# 此时 ${THISDIR} = "/path/to/meta-s6q/recipes-phosphor/ipmi"
# 此时 ${PN} = "phosphor-ipmi-config"

# 如果用 = （延迟展开）：
FILESEXTRAPATHS:prepend:s6q = "${THISDIR}/${PN}:"
# ${THISDIR} 在真正使用时才展开
# 但问题是：当 BitBake 实际搜索文件时，可能已经切换了上下文
# ${THISDIR} 可能指向别的 layer 的目录了！
# 结果：找不到文件，构建失败，报错信息还很难看懂
```

**记忆口诀**：

> `FILESEXTRAPATHS` 永远用 `:=`，因为路径必须在**看到这行代码的那一刻**就锁定。

这是 Yocto 新手最容易犯的错误之一。用 `=` 也许 90% 的情况能工作（因为碰巧上下文没变），但一旦 layer 结构复杂了就会出诡异的 bug。

#### 🔬 深入：`:append` 的空格陷阱

> **大白话**：这是新手第一天就会踩的坑。`+=` 会自动帮你加空格（贴心），但 `:append` 不加（冷漠）。用 `:append` 的时候必须自己在引号里手动写空格，否则两个东西会粘在一起，导致构建报错。

`:append` 和 `+=` 都是追加，但行为有微妙差异：

```python
# += 自动在前面加一个空格
SRC_URI += "file://my-patch.patch"
# 结果：SRC_URI = "git://xxx.git;... file://my-patch.patch"
#                                   ^ 自动加的空格

# :append 不加任何东西，完全按字面追加
SRC_URI:append = "file://my-patch.patch"
# 结果：SRC_URI = "git://xxx.git;...file://my-patch.patch"
#                                   ^ 没有空格！两个 URI 粘在一起了！
# 这会导致 BitBake 无法解析 SRC_URI，报错 "malformed url"

# 正确写法 — 引号内手动加前导空格
SRC_URI:append = " file://my-patch.patch"
#                 ^ 手动空格
```

**为什么 `:append` 存在？为什么不直接用 `+=`？**

答案是**执行时机不同**：

```python
# += 是"解析时追加"（parse-time）
# :append 是"所有解析完成后追加"（deferred）

# 实际影响：
SRC_URI = "git://xxx.git"
SRC_URI += "file://a.patch"      # 立即追加 → SRC_URI = "git://xxx.git file://a.patch"
SRC_URI ?= "should-not-work"     # 已经有值了，?= 不生效

# 但：
SRC_URI = "git://xxx.git"
SRC_URI:append = " file://a.patch"   # 延迟追加 — 现在不执行
SRC_URI ?= "totally-different"        # ?= 看到 SRC_URI 已被 = 设过，不生效
# 最终：先应用 = ，再应用 :append
# SRC_URI = "git://xxx.git file://a.patch"
```

**面试级理解**：`:append` 的真正用途是**跨文件追加时保证顺序**。在 `.bbappend` 文件中，你不知道原始 `.bb` 文件的 `SRC_URI` 被谁设过，用 `:append` 可以确保你的追加**一定在最后**，不会被其他赋值覆盖。

> **大白话**：`+=` 像排队——你站在当前队列的最后面，但后面可能还有人插队（别的 `=` 可以覆盖你）。`:append` 像合同附加条款——不管前面正文怎么改，附加条款始终附在最后。所以在 `.bbappend` 文件里（你无法控制正文怎么写），用 `:append` 最保险。

#### 🔬 深入：`:append` vs `:prepend` 的冒号位置差异

对比 s6q 中两个真实的 `FILESEXTRAPATHS` 写法：

```python
# 写法A（大多数文件用这个）— prepend + 末尾冒号
FILESEXTRAPATHS:prepend:s6q := "${THISDIR}/${PN}:"
#              ^^^^^^^^                          ^
#              前置追加                     分隔冒号在值的末尾

# 写法B（phosphor-dbus-monitor 用这个）— append + 前置冒号
FILESEXTRAPATHS:append:s6q := ":${THISDIR}/${PN}"
#              ^^^^^^^         ^
#              后置追加  分隔冒号在值的开头
```

**为什么冒号位置不同？**

```
FILESEXTRAPATHS 是一个冒号分隔的路径列表，类似 shell 的 PATH：
  /path/a:/path/b:/path/c

当你 :prepend（前置追加）时：
  新路径 + ":" + 旧列表
  = "${THISDIR}/${PN}:" + "/path/a:/path/b:/path/c"
  → 冒号要放在新值末尾

当你 :append（后置追加）时：
  旧列表 + ":" + 新路径
  = "/path/a:/path/b:/path/c" + ":${THISDIR}/${PN}"
  → 冒号要放在新值开头
```

**用 `:prepend` 还是 `:append` 有什么区别？**

BitBake 搜索文件时，**从左到右**扫描 `FILESEXTRAPATHS`。`:prepend` 把你的路径放在最前面，所以你的文件优先被找到。大多数情况用 `:prepend`（我们的文件应该优先于上游默认文件）。

---

### 0.5 Recipe (.bb) 和 Append (.bbappend)

#### Recipe = 软件包的构建说明书

> 💡 **大白话**：Recipe（`.bb` 文件）就像是一张**菜谱**。它上面写清楚了：这道菜叫什么名字（SUMMARY），需要去哪里买菜（SRC_URI），要买哪些配料（DEPENDS），最后怎么把菜做出来（do_compile、do_install）。BitBake 就像是一个严格按照菜谱做菜的机器厨师。

```python
# 例：phosphor-pid-control_git.bb (在 meta-phosphor 里)
SUMMARY = "Phosphor PID Fan Control"
LICENSE = "Apache-2.0"

SRC_URI = "git://github.com/openbmc/phosphor-pid-control.git;branch=master"
SRCREV = "abc123..."

inherit meson pkgconfig        # 用 meson 构建系统

DEPENDS = "sdbusplus nlohmann-json"  # 编译依赖
RDEPENDS:${PN} = "bash"              # 运行依赖

# BitBake 自动执行：
# do_fetch → do_unpack → do_patch → do_configure → do_compile → do_install → do_package
```

#### Append = 对已有 配方 的修改

> 💡 **大白话**：`.bbappend`（追加文件）就像是你在别人菜谱上贴的一张**便签纸**。"菜谱本身写得挺好，但是我不喜欢放香菜" —— 于是你在便签上写："不要香菜，多放点辣"。BitBake 厨师看到原版菜谱后，一定会看你的便签，并以你的便签为准。

```python
# 例：phosphor-pid-control_%.bbappend (在 meta-evb-2u-egs 里)
# % 匹配所有版本

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://config.json"  # 追加我们的配置文件

do_install:append() {
    install -d ${D}${datadir}/swampd
    install -m 0644 ${UNPACKDIR}/config.json ${D}${datadir}/swampd/config.json
}
```

**为什么用 .bbappend 而不是直接改 .bb？**

1. **可维护性**：上游更新 .bb 文件时，你的修改不会丢失
2. **解耦**：你的机器特定配置和通用代码分离
3. **多机器支持**：不同机器各自的 .bbappend 互不干扰
4. **代码审查**：改动清晰可追溯

**面试题**："FILESEXTRAPATHS:prepend 末尾的冒号是什么意思？"
**答**：FILESEXTRAPATHS 是路径列表，用冒号分隔。`:prepend` 会把新路径加到列表前面，但不会自动加冒号分隔符，所以必须手动加。如果忘了这个冒号，路径会和原有路径粘在一起，导致找不到文件。

> **大白话**：`FILESEXTRAPATHS:prepend` 就像是你**给搜索引擎塞了点钱**，强行把你的公司广告顶到了搜索结果的最前面。别人一搜，首先看到的就是你的文件（优先级最高）。而那个**冒号（`:`）** 就像是广告和正常结果之间的那条分割线，如果忘了画线，结果就全粘在一起，连你自己的广告都看不清了。

#### 🔬 实操：真实 .bbappend 逐行解剖

下面以 `meta-quanta/meta-s6q` 中的 `phosphor-ipmi-config.bbappend` 为例，这是一个典型的机器层 `.bbappend` 文件。我们将来为 evb-2u-egs 写的文件结构与它几乎一模一样。

**文件路径**：`meta-quanta/meta-s6q/recipes-phosphor/ipmi/phosphor-ipmi-config.bbappend`

```python
# ==================== 完整文件内容（14行）====================

FILESEXTRAPATHS:prepend:s6q := "${THISDIR}/${PN}:"

SRC_URI:append:s6q = " file://bond_channel_config.json"
SRC_URI:append:s6q = " file://bond_channel_access.json"

do_install:append:s6q() {
    if ${@bb.utils.contains('MACHINE_FEATURES', 'bonding', 'true', 'false', d)};
    then
        install -m 0644 -D ${UNPACKDIR}/bond_channel_access.json \
            ${D}${datadir}/ipmi-providers/channel_access.json
        install -m 0644 -D ${UNPACKDIR}/bond_channel_config.json \
            ${D}${datadir}/ipmi-providers/channel_config.json
    fi
}
```

> **💡 你可能注意到了：s6q 的这个 bbappend 没有显式安装 `dev_id.json`！** 那 `dev_id.json` 怎么被安装到镜像里的？秘密在于 `FILESEXTRAPATHS:prepend`：它把 `meta-s6q/.../phosphor-ipmi-config/` 目录加到搜索路径的最前面。当上游 `phosphor-ipmi-config.bb` 执行 `file://dev_id.json` 下载时，BitBake 会先在 s6q 的目录下找——找到了 s6q 版本的 `dev_id.json`，就用它替代了上游默认的那个。这就是 **文件覆盖机制**——不需要写任何额外的安装代码。

**逐行深度解析**：

**第1行** `FILESEXTRAPATHS:prepend:s6q := "${THISDIR}/${PN}:"`

| 部分 | 含义 |
|------|------|
| `FILESEXTRAPATHS` | BitBake 搜索本地文件（`file://` 引用）时的路径列表 |
| `:prepend` | 把新路径加到列表**最前面**（搜索时优先找到我们的文件） |
| `:s6q` | **OVERRIDES 条件** — 只在 `MACHINE=s6q` 时生效 |
| `:=` | **立即展开赋值** — 在解析这行的瞬间就把 `${THISDIR}` 和 `${PN}` 替换成实际值 |
| `${THISDIR}` | 展开为这个 `.bbappend` 文件所在的目录路径 |
| `${PN}` | 包名（Package Name），这里是 `phosphor-ipmi-config` |
| 末尾 `:` | **关键！** 路径列表分隔符，不加这个冒号，新路径会和旧路径粘连 |

所以这一行展开后的效果是：告诉 BitBake "构建 s6q 机器时，先到 `meta-s6q/recipes-phosphor/ipmi/phosphor-ipmi-config/` 目录下找文件"。这也是 `dev_id.json` 被覆盖的关键。

> **大白话**：**文件覆盖机制**（File Shadowing）就像是你找工作时把自己的同名简历偷偷塞到一摞简历的**最上面**。老板只看第一份叫"简历.pdf"的文件，看到了你的名字就直接录取了，底下压着的原来那个人的简历直接作废。只要名字一样（同名），谁在上面谁赢。

**第3-4行** `SRC_URI:append:s6q = " file://bond_channel_config.json"` 等

| 部分 | 含义 |
|------|------|
| `SRC_URI` | 源文件列表（所有需要获取的文件） |
| `:append` | 追加到已有列表的末尾 |
| `:s6q` | 只在构建 s6q 时追加 |
| `" file://..."` | **注意引号内的前导空格！** `:append` 不会自动加空格，必须手动加，否则和前一个 URI 粘连 |
| `file://` | 表示从本地目录取文件（即 FILESEXTRAPATHS 指定的目录） |

> **大白话**：注意那个**前面的空格**！用 `:append` 拼接字符串的时候如果忘了加空格，就像你发微信**不加标点符号**：本来想说"吃了饭 还有苹果"（两件事），结果发成了"吃了饭还有苹果"——人还能猜出意思，但 BitBake 是机器人，它看到 `git://xxx.gitfile://a.patch` 这种粘在一起的东西，直接罢工报错 `malformed url`。

这里只追加了 bonding 相关的 JSON 文件。`dev_id.json` 不需要追加到 SRC_URI，因为上游 recipe 已经引用了它，`FILESEXTRAPATHS:prepend` 会让 BitBake 优先找到 s6q 的版本。

**第6-14行** `do_install:append:s6q()` 函数体

> **大白话**：原版菜谱里的 `do_install` 相当于交房（安装软件）。你用 `do_install:append` 就相当于**开发商交完房之后，你自己再去给窗户加装一副窗帘**（你的额外安装步骤）。先交房，再装窗帘，顺序不能错。

这是一个 Shell 函数，在原始 `do_install` 执行完之后追加执行。注意里面有 `bb.utils.contains` 条件判断：

| 命令 | 含义 |
|------|------|
| `${@bb.utils.contains(...)}` | 内联 Python，检查 `MACHINE_FEATURES` 是否包含 `bonding` |
| `install -m 0644 -D` | 安装文件，权限 `0644`（所有人可读，属主可写），`-D` 自动创建父目录 |
| `${UNPACKDIR}` | BitBake 解包目录，`file://` 下载的文件解压到这里（注意：新版 Yocto 用 `UNPACKDIR`，旧版用 `WORKDIR`） |
| `${D}` | 安装根目录（packaging 阶段的 destdir） |
| `${datadir}` | `/usr/share`（标准数据文件目录） |
| `ipmi-providers/` | phosphor-ipmi-host 运行时读取配置的目录 |

只有当 `s6q.conf` 中设置了 `MACHINE_FEATURES += "bonding"` 时，才会用 bonding 专用的 channel 配置覆盖默认配置。

**dev_id.json 实际内容**：

```json
{
    "id": 32,
    "revision": 1,
    "addn_dev_support": 141,
    "manuf_id": 7244,
    "prod_id": 13905,
    "aux": 0
}
```

这是 IPMI `Get Device ID` 命令的返回数据。每个字段含义：

| 字段 | 含义 | s6q 的值 | evb-2u-egs 需要改成什么 |
|------|------|---------|------------------------|
| `id` | 设备 ID | 32 | 根据我们的平台设定 |
| `revision` | 设备版本 | 1 | 根据固件版本 |
| `addn_dev_support` | 支持的功能位掩码 | 141 (0x8D) | 根据实际支持的功能 |
| `manuf_id` | 制造商 ID（IANA 分配） | 7244 (Quanta) | 需要申请或使用自己的 |
| `prod_id` | 产品 ID | 13905 | 我们自己定义 |
| `aux` | 辅助版本信息 | 0 | 固件辅助版本 |

**💡 模式总结 — 你写 evb-2u-egs 的 bbappend 时的模板**：

```python
# 文件：meta-evb-2u-egs/recipes-phosphor/ipmi/phosphor-ipmi-config.bbappend
# 只需要把所有 :s6q 替换为 :evb-2u-egs
# 注意：dev_id.json 不需要显式安装，FILESEXTRAPATHS 覆盖即可

FILESEXTRAPATHS:prepend:evb-2u-egs := "${THISDIR}/${PN}:"
```

#### 🔬 深入：`%` 通配符 — 版本匹配的秘密

注意 s6q 的 16 个 `.bbappend` 文件有两种命名风格：

```
phosphor-ipmi-config.bbappend         ← 没有 %（s6q 实际使用的命名）
phosphor-ipmi-host_%.bbappend         ← 有 %（s6q 实际使用的命名）
x86-power-control_%.bbappend          ← 有 %（s6q 实际使用的命名）
```

**区别**：

```python
# 有 % 的 .bbappend：
phosphor-pid-control_%.bbappend
# % 是通配符，匹配任何版本
# 匹配：phosphor-pid-control_git.bb
# 匹配：phosphor-pid-control_1.0.bb
# 匹配：phosphor-pid-control_任何版本.bb
```

> 💡 **大白话**：`_%` 就相当于**外卖单子上写了"张三*"**。只要收件人姓张三，不管后面的名字是"狗蛋"还是"二麻子"（版本号怎么变），快递员都能把快递（补充配置文件）交给他。如果没有那个 `%`，那就必须是名字就叫"张三"的一个字不能差，差一个字都送不到。

**实际意义**：OpenBMC 的大部分配方文件名带版本后缀（如 `_git.bb` 表示从 git 拉取源码），所以大部分 `.bbappend` 都用 `_%` 结尾来匹配。如果写错了（该加 `%` 没加），BitBake 会找不到对应的配方文件，在解析阶段触发 fatal error（"No recipes available for..."），构建直接中止。所以文件名写错不是静默失败而是编译报错，但如果你没有仔细看报错信息就可能遗漏。

**💡 安全检查命令**：

```bash
# 构建时加这个参数，BitBake 会警告找不到匹配配方的 .bbappend
bitbake -c build obmc-phosphor-image 2>&1 | grep "No recipes"
# 如果看到 "No recipes available for: xxx.bbappend"，说明文件名写错了
```

#### 🔬 深入：PACKAGECONFIG — 编译期功能开关

在 LED manager 的 `.bbappend` 中有一行：

```python
PACKAGECONFIG:append:s6q = " use-lamp-test"
```

这不是安装文件，而是**编译期功能开关**。它的作用是：

```python
# 在原始 .bb 文件中（meta-phosphor 里），通常会定义：
PACKAGECONFIG[use-lamp-test] = "-Duse-lamp-test=enabled,-Duse-lamp-test=disabled"
# 完整格式：PACKAGECONFIG[功能名] = "启用参数,禁用参数,构建依赖,运行时依赖,与之冲突的功能"
# 这里只用了前 2 个字段（启用/禁用参数），后 3 个字段留空省略

# 当 PACKAGECONFIG 包含 "use-lamp-test" 时：
# meson configure 命令会加上 -Duse-lamp-test=enabled
# 编译出的二进制程序就包含 lamp-test（灯板测试）功能

# 当 PACKAGECONFIG 不包含时：
# meson configure 加 -Duse-lamp-test=disabled
# 这个功能的代码被条件编译排除掉了
```

> 💡 **大白话**：**PACKAGECONFIG 功能开关**，就像是你去点同一杯拿铁，服务员问你：**加糖还是不加糖**？拿铁（源代码）其实都是那一种咖啡豆，只是因为你（bbappend）在点单的时候加了"加糖"（use-lamp-test 开启），咖啡机里就会多混入一勺糖浆。最终做出来的这杯咖啡（编译好的二进制文件），虽然名字还叫拿铁，但味道已经包含了这多出来的一点甜味（灯测试功能）。

**理解 PACKAGECONFIG 的重要性**：它让同一份源代码根据不同机器的需求，编译出不同功能集的二进制文件。这比"所有功能全编进去"更节省 Flash 空间（BMC 的单 bank Flash 只有 64MB，很宝贵）。

#### 🔬 深入：`bb.utils.contains` — 运行时条件判断

`systemd-conf_%.bbappend` 中有一个更高级的模式：

```python
SRC_URI:append:s6q = "${@bb.utils.contains('MACHINE_FEATURES', 'bonding',\
                        ' ${BONDING_CONF}', '', d)}"
```

逐层解析：

| 部分 | 含义 |
|------|------|
| `${@...}` | 内联 Python 表达式（BitBake 调用 Python 求值） |
| `bb.utils.contains(A, B, C, D, d)` | 如果变量 A 包含值 B，返回 C，否则返回 D |
| `'MACHINE_FEATURES'` | 要检查的变量名 |
| `'bonding'` | 要检查是否存在的值 |
| `' ${BONDING_CONF}'` | 存在时追加的内容（注意前导空格） |
| `''` | 不存在时追加空字符串（即什么也不加） |
| `d` | BitBake 数据字典对象（固定参数） |

> **大白话**：`bb.utils.contains` 就是一个超级豪华版的 **`if-else` 判断器**，相当于去收银台结账前问系统："请帮我翻一下这位顾客的购物车（`MACHINE_FEATURES`），看看里面有没有叫做'网卡绑定'（`bonding`）的东西？如果买了这个，那就顺便送一份'网卡配置文件'（`BONDING_CONF`），没买就算了（`''`空字符串）。"

**do_install 中也用了类似技巧**：

```bash
if ${@bb.utils.contains('MACHINE_FEATURES', 'bonding', 'true', 'false', d)};
then
    # 安装 bonding 相关的网络配置文件
    install -m 0644 ${UNPACKDIR}/10-bmc-bond0.netdev ${D}${sysconfdir}/systemd/network/
    ...
else
    # 没有 bonding 功能，只配置基础 IPv6
    echo -e "[Network]\nLinkLocalAddressing=ipv6" > \
        ${D}${sysconfdir}/systemd/network/00-bmc-eth0.network.d/eth0.conf
fi
```

> **大白话**：`${@...}`（内嵌 Python）的作用就是：你在写一篇流利的中文（Shell 脚本）的时候，突然碰到了一个中文无法表达的词汇，于是你在中间**插了一句英文**（Python），这句话用`${@ }`括起来告诉大脑"这里要切换语言"。两套系统混着用不仅毫无破绽，而且非常丝滑。这也是 Yocto 里极其精妙的"无缝切换多语言混合双打"机制。

**这里用 `${@...}` 在 Shell 函数里嵌入 Python 判断，返回 `true` 或 `false` 字符串给 bash 的 `if` 语句。** 这是 Yocto 里非常强大的"跨语言"机制 — Shell 和 Python 无缝混合。

**面试要点**：能讲清楚 `bb.utils.contains` 的用法和 `${@...}` 的求值时机，说明你真正理解了 BitBake 的执行模型，而不只是会复制粘贴配方。

---

### 0.6 OpenBMC 特有架构

#### D-Bus — 进程间通信总线

OpenBMC 的所有服务通过 D-Bus 通信。这是和 AMI MegaRAC 最大的**架构差异**。

```
AMI 方式：                          OpenBMC 方式：
┌─────────────┐                    ┌─────────────┐
│  IPMI 处理   │                    │  IPMI daemon │
│  直接读取    │                    │  通过 D-Bus  │
│  硬件寄存器  │                    │  请求数据    │
└──────┬──────┘                    └──────┬──────┘
       │ 直接操作                          │ D-Bus call
┌──────▼──────┐                    ┌──────▼──────┐
│   传感器HAL  │                    │ 传感器服务   │
│   PDK钩子    │                    │ (独立进程)  │
└─────────────┘                    └──────┬──────┘
                                          │ sysfs/i2c-dev
                                   ┌──────▼──────┐
                                   │  Linux 驱动  │
                                   └─────────────┘
```

**AMI 是单体架构**：一个大进程包含所有功能，通过函数调用。
**OpenBMC 是多进程解耦架构**：每个功能是独立进程，通过 D-Bus 通信。

> 💡 **大白话**：AMI 就像路边的小餐馆，一个大厨包揽了切菜、炒菜、收银（单体架构）。效率高，但大厨一请假，整个餐馆就瘫痪了。而 OpenBMC 像大饭店，有专门的切菜工、炒菜师傅和前台服务员（多进程架构），某个人请假不会影响其他人。
> D-Bus 就是饭店里的"点餐对讲机"（或公司内部的企业微信群）。各个服务通过对讲机广播和接收消息，而不是直接跑去别人工位上拍肩膀。这样虽然多了一道传话的手续（延迟略高），但管理起来井井有条，排查问题也更方便。

好处：
- 一个服务崩溃不会影响其他服务
- 服务可以独立更新
- 用标准工具（busctl）调试

代价：
- 延迟略高（进程间通信 vs 函数调用）
- 需要理解 D-Bus 接口定义（phosphor-dbus-interfaces）

#### entity-manager — 声明式硬件描述

这是 OpenBMC 最精妙的设计之一：

```json
// 传统方式：代码里写死传感器
// "总线3地址0x48是CPU温度传感器，阈值85度"
// → 每换一台机器就要改代码

// OpenBMC 方式：JSON 声明
{
    "Name": "Inlet_Temp",
    "Type": "TMP75",
    "Bus": 21,
    "Address": "0x48",
    "Thresholds": [
        {"Direction": "greater than", "Value": 85, "Severity": 1}
    ]
}
// → 换机器只需要换 JSON，代码不动
```

> 💡 **大白话**：entity-manager 的声明式描述就像宜家的组装说明书——你只需要在 JSON 里写明白"这里需要装一个温度传感器"，系统就会自动去处理底层的驱动，不需要你自己从零开始"造螺丝"。
> 过去 AMI 把配置用 C 代码硬编码，就像把收件地址直接刻在快递箱上，换个地址就得把箱子重新回炉重造（重新编译代码）。而 OpenBMC 用 JSON 配置文件，就像把收件地址写在便签上贴上去（随时可换）。只要撕下旧便签换张新的，同一个箱子（同一套核心代码）就能发往不同的机器。这也是为什么要大费周章提取 AMI 硬件定义的原因。

**这就是为什么我们从 AMI 代码里提取硬件定义这么重要** — 这些数据全部要转化为 entity-manager 的 JSON 配置。AMI 把它写在 C 代码里（ast2600evb.c 的 62693 行），OpenBMC 把它写在 JSON 里（几百行）。

#### VIRTUAL-RUNTIME — 可替换的服务实现

```python
# meta-phosphor 定义默认实现：
VIRTUAL-RUNTIME_obmc-fan-control ?= "phosphor-fan-control"

# 如果某个厂商想用自己的风扇控制：
# 在他们的 machine.conf 里：
VIRTUAL-RUNTIME_obmc-fan-control = "my-custom-fan-daemon"
# ?= 表示"如果之前没有被赋值过就用这个默认值"（比 ??= 优先级略高）
```

**面试题**："VIRTUAL-RUNTIME 和 PREFERRED_PROVIDER 什么区别？"
**答**：PREFERRED_PROVIDER 选择构建时用哪个 配方 提供某个包名（编译时多选一），VIRTUAL-RUNTIME 选择运行时安装哪个实现（安装时多选一）。前者影响编译，后者影响镜像内容。OpenBMC 大量使用 VIRTUAL-RUNTIME 来实现"同一功能可以由不同 配方 提供"的模式。

> 💡 **大白话**：`VIRTUAL-RUNTIME` 就像你手机上的默认浏览器应用。系统规定必须要有一个浏览器（虚拟接口），自带的是 Chrome，但你不喜欢的话，完全可以在设置里换成 Firefox。功能一样但实现不同。
> 它俩的区别在于：`PREFERRED_PROVIDER` 像是饭店老板选择"食材供应商"（编译时决定），买哪家的白菜决定了厨房里用什么原料；`VIRTUAL-RUNTIME` 则是选"哪个服务员端盘子"（运行时决定），菜已经做好了，看派谁去把它端给客人。

#### 🔬 实操：D-Bus 路径在真实配置中的体现

IPMI 传感器配置文件 `ipmi-sensors.yaml`（s6q 有 2393 行）是**构建期输入**——BitBake 在编译 `phosphor-ipmi-host` 时将 YAML 转换为内部传感器映射。运行时 ipmid 使用的是构建产物，不会再读 YAML 文件。每个传感器条目都通过 D-Bus 路径来定位数据：

```yaml
# 取自 meta-s6q/recipes-phosphor/configuration/s6q-yaml-config/ipmi-sensors.yaml
0x01:                    # IPMI 传感器编号 0x01
  entityID: 0x0A         # IPMI 实体类型：Power Supply
  entityInstance: 0x01   # 第1个电源
  sensorType: 0x03       # IPMI 传感器类型：Current（电流）
  path: /xyz/openbmc_project/sensors/current/PSU0_Current
  #     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  #     这就是 D-Bus 对象路径！
  #     IPMI daemon 通过这个路径向 D-Bus 查询传感器的当前读数
  sensorReadingType: 0x01
  multiplierM: 78        # 线性公式系数 M
  offsetB: 0             # 线性公式偏移 B
  bExp: 0                # B 的指数
  rExp: -3               # 结果指数（工程值 = (M × raw + B × 10^bExp) × 10^rExp）
  unit: xyz.openbmc_project.Sensor.Value.Unit.Amperes
  #     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  #     D-Bus 接口中定义的枚举值
  serviceInterface: org.freedesktop.DBus.Properties
  #                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  #     标准 D-Bus 属性接口 — IPMI daemon 用 Get/Set 方法读写
  interfaces:
    xyz.openbmc_project.Sensor.Value:
    #   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    #   phosphor-dbus-interfaces 中定义的传感器值接口
      Value:
        Offsets:
          0xFF:
            type: double  # 读数类型是浮点数
```

**理解这个关系链**：

```
IPMI 命令 "Get Sensor Reading" (传感器编号 0x01)
    ↓ ipmid 查询构建期从 ipmi-sensors.yaml 生成的传感器映射
    ↓ （注意：ipmi-sensors.yaml 是构建期输入，运行时不会再读 YAML 文件）
    ↓ 找到 path = /xyz/openbmc_project/sensors/current/PSU0_Current
    ↓ 先通过 ObjectMapper 解析该 path 的 owning service
    ↓ 再调用 <service, path, org.freedesktop.DBus.Properties>.Get(
    ↓     "xyz.openbmc_project.Sensor.Value", "Value")
    ↓ 传感器服务返回当前电流值（比如 3.14 安培，工程值）
    ↓ ipmid 用 M/B/bExp/rExp 公式做逆缩放，得到 IPMI raw byte
    ↓ 返回给远程管理客户端
```

> 💡 **大白话**：D-Bus 上定位一个东西需要三要素：**bus name**（谁在提供服务，类似公司名）、**path**（具体资源位置，类似门牌号 `/xyz/openbmc_project/sensors/temperature/CPU0`）、**interface**（这个资源支持哪些操作，类似窗口办什么业务）。IPMI daemon 本身手里没有货物（传感器数据），它只知道 path（门牌号），需要去 D-Bus 上查数据。
> 但是 D-Bus 上有很多服务，该去问谁呢？这就轮到 ObjectMapper 出场了。它就像 114 查号台——IPMI daemon 报出一个 path（门牌号），ObjectMapper 就会告诉它："这个 path 归 bus name `xyz.openbmc_project.HwmonTempSensor` 管，它实现了 `xyz.openbmc_project.Sensor.Value` interface，你去找它要数据吧。" 这样 IPMI daemon 就不用死记硬背每个数据存在哪个进程里了。

**💡 这就是 OpenBMC 和 AMI 的本质区别**：AMI 中 IPMI 处理函数直接读 I2C 寄存器（`PDKHook_Private.c` 里的硬编码），而 OpenBMC 中 IPMI daemon **只和 D-Bus 打交道**，完全不知道底层硬件是什么。硬件细节全部封装在传感器服务里。

#### 🔬 实操：Packagegroup — 机器的"软件清单"

每台机器需要安装什么软件包，由 packagegroup 文件定义。看 s6q 的：

**文件**：`meta-s6q/recipes-s6q/packagegroups/packagegroup-s6q-apps.bb`

```python
SUMMARY = "OpenBMC for S6Q - Applications"

inherit packagegroup        # 声明这是一个软件包组，不是实际软件

PACKAGES = " \
    ${PN}-chassis \          # 机箱管理子包组
    ${PN}-fans \             # 风扇控制子包组
    ${PN}-flash \            # 固件更新子包组
    ${PN}-system \           # 系统服务子包组
    "

# ===== 每个子包组的实际依赖 =====

# 机箱管理 = x86 开关机控制
RDEPENDS:${PN}-chassis = " \
    x86-power-control \      # ← 读我们写的 power-config-host0.json
    "

# 风扇控制 = PID 闭环调速
RDEPENDS:${PN}-fans = " \
    phosphor-pid-control \   # ← 读我们写的 config.json
    "

# 固件更新 = OTA 升级管理
RDEPENDS:${PN}-flash = " \
    phosphor-software-manager \
    "

# 系统服务 = IPMI/日志/看门狗等
RDEPENDS:${PN}-system = " \
    phosphor-ipmi-ipmb \     # IPMB（BMC 和 ME 之间的通信）
    phosphor-hostlogger \    # 主机串口日志记录
    phosphor-sel-logger \    # SEL（系统事件日志）
    ipmitool \               # IPMI 命令行工具（调试用）
    phosphor-post-code-manager \  # POST 码记录
    phosphor-host-postd \    # POST 码监控守护进程
    phosphor-watchdog \      # 硬件看门狗
    phosphor-virtual-sensor \ # 虚拟传感器（计算型传感器）
    "
```

> 💡 **大白话**：Packagegroup 就像搬家时的装箱清单。为了不把零散的东西搞混，你会把所有的机箱管理软件装进一箱、风扇控制一箱、系统服务一箱。然后在大箱子上贴个总标签 `packagegroup-s6q-apps`。构建系统搬运时，只要看到这个总标签，就能把这台机器需要的所有软件一次性全带走，绝不会漏掉。

**PROVIDES/RPROVIDES 的作用**：

```python
PROVIDES += " virtual/obmc-chassis-mgmt"
RPROVIDES:${PN}-chassis = " virtual-obmc-chassis-mgmt"
```

> 💡 **大白话**：这两个词就像求职网站上的技能标签。构建系统说："我需要一个会'机箱管理'（`virtual/obmc-chassis-mgmt`）的人"。你的软件包就贴上 `PROVIDES` 和 `RPROVIDES` 标签说："我会做这个！" 这样招聘方（构建系统）一搜技能标签，就能准确无误地把你招进最终的固件镜像里。

这两行让这个 packagegroup **满足** image 构建时的虚拟依赖。完整的选择链是：

1. `s6q.conf` 中 `PREFERRED_PROVIDER_virtual/obmc-chassis-mgmt = "packagegroup-s6q-apps"` 告诉 BitBake 用这个 packagegroup
2. `obmc-phosphor-image.bbclass` 中 `IMAGE_FEATURES` → `FEATURE_PACKAGES_obmc-chassis-mgmt` → `virtual-obmc-chassis-mgmt`
3. packagegroup 的 `RPROVIDES` 声明"我提供了 `virtual-obmc-chassis-mgmt`"
4. BitBake 最终把 packagegroup 的 `RDEPENDS`（如 `x86-power-control`）拉进镜像

> **注意**：s6q 使用了 `obmc-fan-mgmt`，这是历史兼容写法。新 machine layer（包括我们的 evb-2u-egs）应优先使用 `obmc-fan-control`，`obmc-fan-mgmt` 已被标记为 deprecated。

**obmc-phosphor-image.bbappend — 镜像级别的额外包**：

```python
OBMC_IMAGE_EXTRA_INSTALL:append:s6q = " usb-ethernet-gadget"
IMAGE_FEATURES:append:s6q = " obmc-dbus-monitor"
```

仅2行，因为大部分内容已经通过 packagegroup 和 `MACHINE_FEATURES` 机制自动包含了。`usb-ethernet-gadget` 是 s6q 特有需求（通过 USB 模拟网卡），`obmc-dbus-monitor` 启用 D-Bus 事件监控。

> 💡 **大白话**：`.bbappend` 像装修清单的补充页。官方的 `obmc-phosphor-image` 配方已经把主清单写得很完整了，你不需要把基础清单重抄一遍。只要在补充页里写上："除了标准配置，我这里只加几个特殊需求（比如模拟网卡）"，施工队（BitBake）打包时就会顺手把这些加上。

---

### 0.7 构建流程全景

```
源码                    BitBake 处理                        输出
┌──────────┐     ┌─────────────────────────┐     ┌──────────────────┐
│ .bb       │     │ 1. 解析所有 layer 的     │     │ tmp/deploy/      │
│ .bbappend │────▶│    conf + 配方 文件    │     │ ├── images/      │
│ .bbclass  │     │ 2. 构建依赖图           │     │ │   └── *.mtd     │
│ .conf     │     │ 3. 调度任务到线程池      │     │ │       (Flash镜像)│
│ patches/  │     │ 4. fetch→unpack→patch   │────▶│ ├── ipk/         │
│ configs/  │     │    →configure→compile   │     │ │   └── *.ipk     │
└──────────┘     │    →install→package     │     │ │       (软件包)   │
                  │ 5. 组装 rootfs          │     │ └── licenses/     │
                  │ 6. 生成 Flash 镜像      │     └──────────────────┘
                  └─────────────────────────┘

Flash 镜像结构 (evb-2u-egs, 单 bank 64MB, 双 bank 主备共 128MB, 概念示意图，精确偏移待 DTS/U-Boot 实现后确定):
┌────────────────────────────────────────┐
│ U-Boot SPL                             │ ← 第一阶段引导
│ U-Boot                                 │ ← 第二阶段引导 + 环境变量
│ Kernel (fitImage)                      │ ← Linux 内核 + DTB + initramfs
│ RW rootfs (UBI/Static)                 │ ← 可写文件系统
│ [Bank B - 备用 (独立 64MB Flash 芯片)]  │ ← 主备冗余，物理独立
└────────────────────────────────────────┘
```

> 💡 **大白话**：Flash镜像里的每个分区就像一本书——封面是U-Boot（引导），目录是Kernel（系统核心），正文是rootfs（所有应用程序）。至于Bank B备用芯片，就像手机双系统——如果平台实现了 bootcount/回滚逻辑，A系统升级失败时可以自动切回B系统，大幅降低变砖风险。

#### 🔬 实操：构建入口 — setup 脚本和模板文件

##### `. setup <machine>` 到底做了什么？

当你执行 `. setup s6q` 时，setup 脚本做了以下事情：

```bash
# 1. 根据机器名找到模板目录
#    meta-quanta/meta-s6q/conf/templates/default/
#    （通过 TEMPLATECONF 机制）

# 2. 创建 build/s6q/ 目录

# 3. 从模板复制配置文件
#    bblayers.conf.sample → build/s6q/conf/bblayers.conf
#    local.conf.sample → build/s6q/conf/local.conf

# 4. 替换 ##OEROOT## 占位符为实际的仓库路径

# 5. 设置环境变量 (BUILDDIR, PATH 等)

# 6. 显示 conf-notes.txt 内容
#    "Common targets are:
#         obmc-phosphor-image"
```

> 💡 **大白话**：`. setup <machine>` 脚本就像游戏开始前选角色——你选了哪台机器，后面所有装备（配置）都围绕这个角色来。

**重要**：必须用 `source`（或 `.`）执行，不能直接 `./setup`。因为 setup 需要修改当前 shell 的环境变量（`BUILDDIR`、`PATH`），直接执行会在子 shell 中运行，环境变量改不了父 shell。

> 💡 **大白话**：为什么必须 source 而不能直接执行？就像调闹钟——你得在自己手机上调（source修改当前shell），不能在别人手机上调（子进程改不了父进程）。

##### bblayers.conf.sample — 声明需要哪些 Layer

> 💡 **大白话**：`bblayers.conf` 声明 Layer 就像厨师做菜前先确认食材来源——从哪个仓库拿面粉、从哪个仓库拿鸡蛋，列一张清单。

```python
# s6q 的 bblayers.conf.sample（完整 17 行）

LCONF_VERSION = "8"    # 配置文件版本号
BBPATH = "${TOPDIR}"   # BitBake 工作目录
BBFILES ?= ""          # 初始为空，各 layer 的 layer.conf 会追加

BBLAYERS ?= " \
  ##OEROOT##/meta \                              # OE-Core 基础层
  ##OEROOT##/meta-openembedded/meta-oe \         # OE 扩展软件包
  ##OEROOT##/meta-openembedded/meta-networking \  # 网络相关包
  ##OEROOT##/meta-openembedded/meta-python \     # Python 相关包
  ##OEROOT##/meta-phosphor \                     # ★ OpenBMC 核心框架
  ##OEROOT##/meta-aspeed \                       # ★ AST2600 SoC 支持
  ##OEROOT##/meta-quanta \                       # Quanta 公共层
  ##OEROOT##/meta-quanta/meta-s6q\               # ★ s6q 机器层
  "
# ##OEROOT## 在 setup 时被替换为仓库的绝对路径
```

> 💡 **大白话**：`##OEROOT##` 占位符就像合同模板里的“甲方：______”——签合同时再填上具体的名字（实际路径）。

**💡 evb-2u-egs 的 bblayers.conf.sample 对比**：

```python
# 我们的版本不需要 meta-quanta，直接引用自己的层
BBLAYERS ?= " \
  ##OEROOT##/meta \
  ##OEROOT##/meta-openembedded/meta-oe \
  ##OEROOT##/meta-openembedded/meta-networking \
  ##OEROOT##/meta-openembedded/meta-python \
  ##OEROOT##/meta-phosphor \
  ##OEROOT##/meta-aspeed \
  ##OEROOT##/meta-evb-2u-egs \
  "
# 少了 meta-quanta 和 meta-quanta/meta-s6q
# 多了 meta-evb-2u-egs（我们是顶层独立层，不嵌套在其他厂商层下面）
```

##### local.conf.sample — 关键配置项速查

local.conf.sample 有 258 行，大部分是注释。真正重要的只有几行：

```python
MACHINE ??= "s6q"                          # 默认构建的机器（??= 弱默认，setup 会覆盖）
DISTRO ?= "openbmc-phosphor"               # 发行版 = OpenBMC
PACKAGE_CLASSES ?= "package_ipk"           # 包格式 = IPK（小型嵌入式首选）
EXTRA_IMAGE_FEATURES ?= "allow-root-login" # 允许 root 登录（开发用，生产要去掉）
CONF_VERSION = "2"                         # 配置兼容性版本号
```

> 💡 **大白话**：`local.conf.sample` 里的各项配置，就像手机的系统设置——默认语言、默认输入法、是否开启开发者模式。
>
> 关于 `??=` 和 `?=` 的区别：`??=` 是铅笔写的（很容易被覆盖），`?=` 是圆珠笔写的（也能被覆盖但更持久）。

**面试知识**：`local.conf` 是用户本地配置里**优先级很高**、最常用于覆盖 layer 默认值的文件。如果你在 `local.conf` 中用 `=` 设置一个变量，它会覆盖所有 layer 中的 `?=` 和 `??=`。这就是为什么 `local.conf` 里的变量大多用 `?=` 或 `??=` — 避免意外覆盖 layer 的设置。

---

### 0.8 evb-2u-egs 在体系中的位置

```
Layer 堆栈 (自底向上)：

┌─ openembedded-core ──────────────────────────────────────────┐
│  gcc, glibc, systemd, bash, python, openssl ...              │
│  → 所有 Linux 发行版的基础                                    │
├─ meta-openembedded ──────────────────────────────────────────┤
│  更多软件包: boost, curl, i2c-tools, lmsensors ...           │
├─ meta-phosphor ──────────────────────────────────────────────┤
│  OpenBMC 框架: IPMI, Redfish, WebUI, phosphor-* 服务         │
│  VIRTUAL-RUNTIME 默认值, IMAGE_FEATURES, bbclasses           │
├─ meta-aspeed ────────────────────────────────────────────────┤
│  AST2600 支持: U-Boot (aspeed), Linux 内核 (aspeed)          │
│  SoC 级别的 DTS base, 启动配置                               │
├─ meta-evb-2u-egs (我们的) ───────────────────────────────────┤
│  机器配置: evb-2u-egs.conf                                   │
│  GPIO 定义 → x86-power-control JSON                          │
│  传感器拓扑 → entity-manager JSON                            │
│  风扇PID → phosphor-pid-control JSON                         │
│  LED 定义 → phosphor-led-manager JSON                        │
│  OEM IPMI → 自定义 配方 (Phase 5)                          │
│  内核 DTS → linux-aspeed bbappend + patch (Phase 4)          │
└──────────────────────────────────────────────────────────────┘
```

**从 AMI 到 OpenBMC 的数据流映射**：

> 💡 **大白话**：这就好比搬家时的物品对照表——原来在旧家（AMI代码）哪个抽屉里的东西，搬到新家（OpenBMC框架）后应该塞进哪个柜子（配置文件）。

| AMI 代码 | 数据 | OpenBMC 目标 |
|----------|------|-------------|
| `ast2600evb.c` (62K行) | I2C/GPIO/传感器 | `entity-manager JSON` (~500行) |
| `PDKHW.c` (4K行) | 开关机时序 | `power-config-host0.json` (~100行) |
| `fsit_fsc.c` (5K行) | PID风扇控制 | `phosphor-pid-control config.json` (~200行) |
| `fibercmds.c` | OEM IPMI命令 | 自定义 shared library (~2K行) |
| `PDKHook_Private.c` (7.7K行) | 传感器轮询逻辑 | **大部分不需要移植**，但非全部（见下方说明） |
| `ast2600evb_r1b.dts` | 设备树 | `linux-aspeed bbappend` + DTS patch |

注意倒数第二行 — AMI 的 `PDKHook_Private.c` 7681行传感器轮询代码，**常规 hwmon/PMBus/PECI 传感器**在 OpenBMC 里不需要移植，因为 Linux 内核驱动 + entity-manager 自动发现机制可以覆盖。但 **CPLD 风扇/磁盘状态读取、聚合型 MEM_TMP 传感器、部分离散/OEM 逻辑**仍需要编写自定义服务或驱动。这是架构升级的威力，同时也是需要注意的边界。

> 💡 **大白话**：6万多行C代码变成几百行JSON，就像从手写信变成了发微信——内容还是一样，但载体效率完全不同了。至于为啥那7000多行轮询代码不用搬？因为OpenBMC里的Linux内核驱动已经帮你把活儿干了——就像以前你得自己造轮子，现在直接去商场买现成的轮子安上就行。

#### 面试加分知识点

1. **"OpenBMC 和 AMI MegaRAC 的本质区别是什么？"**
   → AMI 是单体 RTOS + 闭源 PDK 钩子；OpenBMC 是全 Linux + D-Bus 多进程解耦 + 声明式配置。AMI 改硬件要改 C 代码重编译；OpenBMC 改 JSON 就行。

   > 💡 **大白话**：AMI像是个焊死的铁盒，想加功能得找原厂师傅（改C代码编译）；OpenBMC像是乐高积木，各个零件互相独立（多进程），想换什么功能自己拔插改配置单（改JSON）就行。

2. **"为什么大厂（Meta/Google/Microsoft）选择 OpenBMC？"**
   → 供应链安全（开源可审计）、可定制性（不依赖 AMI 闭源 PDK）、统一管理（所有厂商硬件用同一框架）、安全更新速度（CVE 修复不依赖第三方）。

   > 💡 **大白话**：想象你开了100家连锁餐厅，每家的收银系统都是不同厂家的闭源软件——出了bug得排队等原厂修，换供应商得全部重新培训。大厂选 OpenBMC 就像统一换成自己能改的开源收银系统：代码自己能审计（安全）、所有门店统一界面（管理）、发现漏洞自己当天就能打补丁（速度），再也不用被任何一家供应商卡脖子。

3. **"BitBake 和 Buildroot 什么区别？"**
   → Buildroot 是"给我一个根文件系统"，BitBake/Yocto 是"给我一个完整的发行版基础设施，包括包管理、SDK、可复现构建"。Buildroot 适合简单嵌入式，Yocto 适合需要长期维护的产品线。

   > 💡 **大白话**：Buildroot 像是路边摊的"现炒快餐"，简单快捷，吃完就走；BitBake 像是"米其林中央厨房"，有标准化菜谱、进销存管理系统，适合天天开门营业的大饭店。

4. **"你的项目里遇到的最大挑战是什么？"**
   → 从 AMI 闭源代码库反向工程出完整的硬件定义。AMI 把配置分散在 DTS、PMC 传感器表（431个条目）、HAL 生成代码（62K行）、PDK 钩子函数里。我通过系统性分析把这些信息提取、交叉验证、统一到两份文档（1967行硬件定义 + 2152行 OEM IPMI 命令），实现了 98% 覆盖率。

   > 💡 **大白话**：具体来说，AMI 把硬件信息分散在至少4个不同位置——DTS（设备树）里埋了 I2C 地址，PMC 表里藏了 431 个传感器阈值，HAL 生成代码（6万多行！）里有 GPIO 映射，PDK 钩子函数里有电源时序逻辑。没有任何一份统一文档把它们串起来。我的工作就像从4本不同语言写的旧账本里，交叉比对出一份完整的资产清单——最终整理出 1967 行硬件定义 + 2152 行 IPMI 命令规格，覆盖率 98%。

#### 🔬 实操：我们的文档如何映射到机器层文件

现在把之前提取的硬件定义文档和我们要创建的 20 个文件对应起来，让你清楚**每个文件的数据从哪来**：

**实施阶段定义**：

> 💡 **大白话**：这其实就像是一场装修工程。Phase 1 是毛坯房交付（搭好骨架），Phase 2 是水电管网安装（填好配置 JSON），Phase 3 是确定软装清单（打包 Packagegroup），Phase 4 是定制打柜子（改内核 DTS 认硬件），Phase 5 是装全屋智能（加 OEM 自定义命令），最后 Phase 6 是验收通电（测试）。

| 阶段 | 名称 | 内容 | 预估工作量 |
|------|------|------|-----------|
| Phase 1 | 骨架搭建 | layer.conf, machine.conf, 模板文件, COPYING.MIT | 半天 |
| Phase 2 | 配置 JSON | entity-manager, PID 风扇, LED, 电源控制, dev_id | 1-2 天 |
| Phase 3 | Packagegroup | packagegroup-evb-2u-egs-apps.bb, image bbappend | 半天 |
| Phase 4 | 内核 DTS | linux-aspeed bbappend + DTS patch（GPIO/I2C/SPI） | 2-3 天 |
| Phase 5 | OEM IPMI | 78 个 OEM 命令的 C++ 实现 shared library | 1-2 周 |
| Phase 6 | 调试验证 | QEMU 测试 → 实机烧录 → 功能验证 | 持续 |

> 💡 **大白话**：这棵树就像是做菜的食材清单。它清楚地告诉你，做每一道菜（也就是 OpenBMC 里的配置文件）需要准备哪些食材（配置数据），以及应该去哪个超市（之前整理好的文档的哪一节）买，按图索骥绝不会乱。

```text
evb-2u-egs_Hardware_Definition.md (1967行)
│
├── §1.0 machine.conf 示例
│   └──→ conf/machine/evb-2u-egs.conf
│        （文档中有完整的 ready-to-use 代码片段）
│
├── §6-§13 I2C/传感器/VR/DIMM/PSU/CPLD 拓扑
│   └──→ recipes-phosphor/configuration/entity-manager/evb-2u-egs-baseboard.json
│        （431个传感器条目需要分流处理：）
│        （  · 标准 hwmon/PMBus/PECI 传感器 → entity-manager JSON exposes）
│        （  · CPLD 风扇/磁盘状态 → 自定义服务或内核驱动）
│        （  · 离散/BIOS 事件 → IPMI 配置或独立处理）
│        （  · FRU 数据 → entity-manager 拓扑定义）
│        （所有 I2C 地址、总线号、阈值都在文档中）
│
├── §8 风扇 PID 参数
│   └──→ recipes-phosphor/fans/phosphor-pid-control/config.json
│        （需要将 §8.4/§8.5 的多热区 PID 参数表转换为 zone 配置）
│        （7个热区各有独立的 Kp/Ki/Kd 和参考温度，不是单一全局 setpoint）
│
├── §12 LED GPIO 定义
│   └──→ recipes-phosphor/leds/phosphor-led-manager/led-group-config.json
│        （ID LED=GPIO15/GPIOB7, Fan Fault LED=GPIO52/GPIOG4, 均 active-low）
│        （LED_ID_BLUE/AMBER 的 list.cfg 123/124 为逻辑枚举，物理 GPIO 待确认）
│
├── §16.11 电源控制 JSON
│   └──→ recipes-x86/chassis/x86-power-control/power-config-host0.json
│        （文档中有完整的 ready-to-use JSON）
│        （GPIO69=PowerOut, GPIO121=ResetOut, GPIO47=PowerOK 等）
│
├── §2 Flash/启动 + §5 GPIO 定义 + §6 I2C 总线拓扑
│   └──→ recipes-kernel/linux/linux-aspeed_%.bbappend
│        （DTS patch：GPIO 方向/名称、I2C 设备声明、SPI 分区表）
│
└── IPMI 配置决策（IANA manufacturer ID + product ID 约定）
    └──→ recipes-phosphor/ipmi/phosphor-ipmi-config/dev_id.json
         （制造商 ID 需 IANA 分配，产品 ID 由平台自定义；若未定应标记 TBD）

evb-2u-egs_OEM_IPMI_Commands.md (约2152行)
│
└── 78 个 OEM 命令
    └──→ Phase 5 自定义配方（后期开发）
         （创建 shared library 注册到 phosphor-ipmi-host）
```

**实际工作量评估**：

| 文件 | 数据来源 | 工作量 | 备注 |
|------|---------|--------|------|
| `evb-2u-egs.conf` | HW 文档 §1.0 | 低 | 文档已有完整代码 |
| `layer.conf` | s6q 模板 | 低 | 改名即可 |
| `bblayers.conf.sample` | s6q 模板 | 低 | 删除 meta-quanta 行 |
| `local.conf.sample` | s6q 模板 | 低 | 改 MACHINE 名 |
| `power-config-host0.json` | HW 文档 §16.11 | 低 | 文档已有完整 JSON |
| `dev_id.json` | IPMI 配置决策 (IANA) | 低 | 8 行 JSON，manuf_id 需 IANA 分配 |
| `config.json` (PID) | HW 文档 §8 | 中 | 7 热区 PID 参数需转换为 zone 配置 |
| `entity-manager JSON` | HW 文档 §6-§13 | **高** | 传感器需分流到 EM/PECI/CPLD 多个目标 |
| `led-group-config.json` | HW 文档 §12 | 低 | 几个 LED 定义 |
| `linux-aspeed bbappend` | HW 文档 §2+§5+§6 | **高** | 需要写 DTS patch |
| OEM IPMI recipes | OEM 文档 | **高** | Phase 5 后期 |

**Phase 1-3（骨架+配置JSON）可以在 1-2 天内完成**，因为大部分数据已经在文档中准备好了。Phase 4（内核DTS）和 Phase 5（OEM IPMI）是真正需要深入工程的部分。

---

## 第一章：Yocto/BitBake 深度精通

第零章给了你全景认知，本章将深入 BitBake 的内部机制。掌握这些内容后，你在面试中能够解释"BitBake 为什么这样设计"，而不仅仅是"BitBake 怎么用"。

### 1.1 BitBake 任务执行链

每个 配方 在 BitBake 中会经历一系列**任务（Task）**。理解这条链是调试构建问题的基础。

```
do_fetch          从 SRC_URI 指定的位置下载源码（git clone / wget）
    ↓
do_unpack         解压源码包到 UNPACKDIR（新版 Yocto 使用 ${UNPACKDIR}，位于 ${WORKDIR} 下）
    ↓
do_patch          按顺序应用 SRC_URI 中的 .patch 文件
    ↓
do_populate_lic   提取并验证 LICENSE 信息
    ↓
do_configure      运行配置（autoconf/cmake/meson 的 configure 阶段）
    ↓
do_compile        编译源码
    ↓
do_install        将编译产物安装到 ${D}（staging 目录，模拟根文件系统）
    ↓
do_package        将 ${D} 中的文件分割成多个包（-dev, -dbg, -doc 等）
    ↓
do_package_write_ipk   生成 .ipk 包文件到 deploy 目录
```

> **大白话**：BitBake 任务链就像一条标准化的工厂流水线——原材料（源码）依次经过"领料→拆包→打磨补丁→质检→校准→加工→装配→分装→入库"九道工序，每道工序结束后打上一个"质检戳"（stamp 文件）。下次生产同款产品时，哪道工序的原料和参数没变，就直接跳过，从已打戳的那一道继续往下做，而不是从头来过。

**关键理解**：
- 每个任务都有**输入签名（Signature）**。如果输入没变，BitBake 首先检查本地 stamp 文件跳过任务；如果工作目录不存在（例如 clean 后），再尝试从 sstate-cache 恢复之前的输出（通过 setscene 任务）。两者是不同的缓存层级。
- 你可以用 `bitbake -c <task> <配方>` 单独执行某个任务
- `do_install` 是最容易出错的地方 — 路径写错、权限不对都会在这里暴露

**实战命令**：
```bash
# 只执行 compile 任务
bitbake -c compile phosphor-pid-control

# 查看某个 配方 的所有可用任务
bitbake -c listtasks phosphor-pid-control

# 进入 devshell（在 配方 的工作目录打开一个 shell）
bitbake -c devshell phosphor-pid-control
# → 这是调试编译问题的神器！你可以在 shell 里手动运行 make/meson
```

> **大白话**：`bitbake -c devshell` 就像直接走进工厂车间操作机器——绕过了所有自动化调度，你站在那道工序的工位上亲手操作，能立刻看到报错原因，也能手动尝试修复命令。相比之下，正常 `bitbake` 是"远程下单让工厂自动跑"，出问题了只能看报告，不能现场调试。

> **面试要点**：面试官问"BitBake 一个包需要多久"时，正确的回答不是给时间，而是解释 sstate-cache 机制。首次构建可能要几小时，但有 sstate 缓存后，增量构建只需要几十秒。

---

### 1.2 依赖解析机制

BitBake 管理两种依赖：

```python
# 编译时依赖 — 这个包在编译时需要的东西
DEPENDS = "sdbusplus nlohmann-json boost"
# 效果：在 do_configure 前，确保这些包已经 do_populate_sysroot 完成

# 运行时依赖 — 安装到镜像时需要一起装的东西
RDEPENDS:${PN} = "bash i2c-tools"
# 效果：安装本包时，自动拉取这些运行依赖包

# 任务级依赖 — 精确控制任务执行顺序
do_configure[depends] += "virtual/kernel:do_shared_workdir"
```

> **大白话**：`DEPENDS` 和 `RDEPENDS` 就像两种不同时间段的"入场条件"——`DEPENDS` 是"施工前必须到场的原材料"（编译时需要头文件和库），`RDEPENDS` 是"建成后必须配套安装的设施"（运行时需要的其他程序）。忘写 `DEPENDS` 会在盖房子时发现没有钢筋；忘写 `RDEPENDS` 会在入住后发现没有天然气管道。

**依赖图可视化**：
```bash
# 生成依赖图（dot 格式）
bitbake -g obmc-phosphor-image

# 转为 PNG（需要 graphviz）
dot -Tpng task-depends.dot -o deps.png
```

**循环依赖**是 BitBake 最常见的致命错误。当 A 的 DEPENDS 包含 B，B 的 DEPENDS 又包含 A 时，BitBake 会直接拒绝构建。解决方案通常是分析依赖方向：如果 A 只在运行时需要 B（而非编译时），就将其从 `DEPENDS` 移到 `RDEPENDS`；或者拆分包来打破环路。

> **大白话**：循环依赖就像两个工人互相卡着对方——甲说"你先把地基打好我才能装门"，乙说"你先把门装好我才能打地基"，结果谁都动不了。解决方法是问自己：乙真的需要门来打地基吗？如果不是，只是安装后需要门，那就把这个依赖移到运行时，打破僵局。

> **面试要点**：`DEPENDS` vs `RDEPENDS` 的区别。DEPENDS 影响编译阶段（交叉编译 sysroot），RDEPENDS 影响打包阶段（IPK 依赖关系链）。一个典型例子：如果你的代码 `#include <nlohmann/json.hpp>` 但 DEPENDS 里没写 nlohmann-json，编译会直接报错。但如果运行时需要 `bash` 来执行脚本，那就放在 RDEPENDS。

---

### 1.3 变量作用域与展开时机

这是 BitBake 最容易让人困惑的部分。

```python
# 立即展开（:=）vs 延迟展开（=）
A = "hello"
B := "${A} world"   # 立即展开：B = "hello world"（此刻就计算）
C = "${A} world"    # 延迟展开：C 在最终使用时才计算

A = "goodbye"
# 此时 B 仍然是 "hello world"（已经固定了）
# 但 C 变成了 "goodbye world"（延迟展开，取最终值）
```

> **大白话**：立即展开（`:=`）就像拍下快照——"现在这个时刻"的变量值永远固定，之后怎么改都跟你没关系。延迟展开（`=`）就像写了个便利贴"用那个柜子里的东西"——等真正去用的时候才打开柜子，取的是那一刻柜子里最新的内容。所以相同的代码写法，根据赋值符号的不同，可能产生截然相反的结果。

**变量展开的三个阶段**：
1. **解析阶段（Parsing）**：BitBake 读取所有 .conf 和 .bb 文件，构建变量数据库
2. **数据阶段（Data）**：处理 OVERRIDES、:append/:prepend
3. **执行阶段（Execution）**：在 shell/python 函数中展开变量

**致命陷阱**：`:append` 和 `:prepend` 在数据阶段处理，它们在**所有普通赋值（`=`/`?=`/`??=`）完成之后才生效**，因此看起来"不受赋值位置影响"。但注意：多个 `:append` 之间是按**解析顺序**累加的：

```python
VAR = "A"
VAR:append = " B"    # 追加操作被"记住"
VAR = "C"            # 重新赋值为 "C"
# 最终结果：VAR = "C B"
# 因为 :append 在所有 = 赋值之后才应用！
```

> **大白话**：`:append` 就像在合同末尾盖了一个"不可撤销附加条款"的印章——不管你后来怎么改合同正文（`VAR = "C"`），这个附加条款始终会附在最终版本后面。系统在执行时是"先把所有正文写完，再统一贴上所有已盖章的附加条款"，而不是按书写顺序逐行处理。这就是为什么 `:append` 写在哪里都无所谓——最终结果一样。

> **面试必杀**：能解释清楚上面这个例子的人不到 10%。`:append`/`:prepend` 是**后处理操作（post-processing）**，它们在所有普通赋值完成后才生效。这意味着无论你在哪里写 `:append`，它都会追加到变量的最终值上。

---

### 1.4 OVERRIDES 机制深度剖析

OVERRIDES 是 BitBake 实现"条件编译"的核心机制，也是 Yocto 面试的绝对高频考点。

```python
# OVERRIDES 在运行时被设置为一个冒号分隔的列表：
OVERRIDES = "linux:arm:armv7a:evb-2u-egs:poky:class-target"

# 当 BitBake 看到带 override 后缀的变量：
SERIAL_CONSOLES = "115200;ttyS0"               # 默认值
SERIAL_CONSOLES:evb-2u-egs = "115200;ttyS4"    # 仅 evb-2u-egs 生效

# 因为 OVERRIDES 列表中有 "evb-2u-egs"，
# 所以 SERIAL_CONSOLES 的最终值是 "115200;ttyS4"
```

**优先级规则**（从低到高）：
1. 无后缀的默认值：`VAR = "default"`
2. 机器级别：`VAR:evb-2u-egs = "machine_value"`
3. `:append` / `:prepend`（在上述所有值确定后，再追加/前置）

**嵌套 OVERRIDES**：
```python
# 只在 evb-2u-egs 机器上追加
SRC_URI:append:evb-2u-egs = " file://my-patch.patch"
# 这会被解析为：当 OVERRIDES 包含 evb-2u-egs 时，追加这个文件
```

**历史迁移**（面试加分项）：
```python
# 旧语法（Honister 之前）：
SERIAL_CONSOLES_evb-2u-egs = "115200;ttyS4"    # 下划线分隔
SRC_URI_append_evb-2u-egs = " file://patch.patch"

# 新语法（Honister 及之后）：
SERIAL_CONSOLES:evb-2u-egs = "115200;ttyS4"    # 冒号分隔
SRC_URI:append:evb-2u-egs = " file://patch.patch"
```

这个迁移导致了大量老教程和旧代码失效。如果你在面试中能指出这一点，并解释原因（下划线作为分隔符会和变量名中的下划线冲突），面试官会对你刮目相看。

> **大白话**：OVERRIDES 就像一套军衔识别系统——系统运行时会挂着一串"身份标牌"（`OVERRIDES` 列表），比如"我是 ARM 架构、evb-2u-egs 机器、target 类"。每个变量设置就像一张条件命令单，只有命令单上的条件与你的身份标牌匹配，这条设置才生效。`SRC_URI:append:evb-2u-egs` 就是"只对 evb-2u-egs 执行的追加命令"。从下划线改为冒号，是因为原来的体系会把变量名里的下划线误识别为条件分隔符，造成名称冲突。

---

### 1.5 bbclass 继承体系

bbclass 是 BitBake 的"类"，提供可复用的构建逻辑。

```python
# 配方 通过 inherit 关键字继承 bbclass
inherit meson pkgconfig systemd

# 这等于把 meson.bbclass、pkgconfig.bbclass、systemd.bbclass
# 中的所有变量和函数"混入"（mixin）到当前 配方
```

**OpenBMC 核心 bbclass**：

| bbclass | 用途 | 来源 |
|---------|------|------|
| `obmc-phosphor-image` | 定义 IMAGE_FEATURES 到 packagegroup 的映射 | meta-phosphor |
| `obmc-phosphor-systemd` | 自动安装 systemd service 文件 | meta-phosphor |
| `meson` | 使用 meson 构建系统编译 | OE-Core |
| `cmake` | 使用 cmake 构建系统编译 | OE-Core |
| `systemd` | 管理 systemd 服务文件的安装和启用 | OE-Core |

**面试题**："inherit 和 require/include 什么区别？"
**答**：
- `inherit` 加载 `.bbclass` 文件，通常用于引入构建系统逻辑（meson/cmake）
- `require` 强制包含另一个 `.inc` 或 `.conf` 文件（不存在则报错）
- `include` 可选包含（不存在时静默跳过）

> **大白话**：这三个关键字就像三种不同的"引入外部文档"方式——`inherit` 像加载一套岗位工作规范（bbclass），适用于所有担任这个岗位的人；`require` 像强制附录，缺页就直接报废整份合同；`include` 像可选附录，没有也不影响合同生效。bbclass 与 .inc 文件的本质区别是：bbclass 是"行为模板"，.inc 是"数据配置片段"。

---

### 1.6 sstate-cache 与构建加速

sstate-cache（Shared State Cache）是 Yocto 构建系统的性能核心。没有它，每次修改一行代码都要重新编译整个世界。

**工作原理**：
```
1. BitBake 为每个任务计算一个 Hash 签名
   Hash = f(recipe变量, 源码版本, 工具链版本, 依赖包的输出)

2. 执行任务前，检查 SSTATE_DIR 中是否有该 Hash 对应的缓存包
   - 命中 → 直接解压，跳过任务（秒级完成）
   - 未命中 → 正常执行任务，执行完后打包存入缓存

3. 下次构建时，只有 Hash 变化的任务才需要重新执行
```

**配置优化**：
```python
# 在 local.conf 中配置共享的 sstate 目录
SSTATE_DIR = "/opt/yocto-sstate"

# 配置远程 sstate 镜像（团队共享）
SSTATE_MIRRORS = "file://.* http://sstate-server.mycompany.com/PATH"
```

> **大白话**：sstate-cache 就像工厂的半成品仓库——每道工序的中间产物都贴上"原料批次+工艺参数"的条形码存入仓库。下次生产时，先扫一下条形码看仓库里有没有一样的半成品，有就直接取货跳过这道工序；只有原料或工艺参数变了，才需要重新加工。一个团队共用一台 sstate 服务器，就像共用同一个半成品仓库，第一个人编译完，其他人直接取货，整体速度大幅提升。

> **面试要点**：解释为什么 sstate-cache 是"按任务"而不是"按包"缓存。因为一个 配方 有多个任务，可能只有 do_compile 需要重新执行（源码改了），而 do_fetch 的输出可以直接从 sstate-cache 恢复。同时本地 stamp 签名机制确保未变化的任务被直接跳过，不需要访问 sstate。这种两级缓存策略极大减少了不必要的重复工作。

---

### 1.7 镜像构建流程

当你运行 `bitbake obmc-phosphor-image` 时，背后发生了什么？

```
1. 解析 obmc-phosphor-image.bb
   → 它是一个 image 配方，继承了 obmc-phosphor-image.bbclass

2. 计算 IMAGE_INSTALL
   → 根据 IMAGE_FEATURES 展开 FEATURE_PACKAGES
   → 例如 IMAGE_FEATURES 包含 "obmc-fan-control"
   → 对应 FEATURE_PACKAGES_obmc-fan-control = "packagegroup-obmc-apps-fan-control"
   → 这个 packagegroup 最终拉取 phosphor-pid-control 等实际包

3. 构建所有依赖包
   → BitBake 构建依赖图中所有需要的 配方（可能有几百个）
   → 每个 配方 经历 fetch→compile→package 链
   → 产出 .ipk 文件

4. 组装 rootfs
   → do_rootfs 任务将所有 .ipk 安装到临时根目录
   → 安装后执行 post-install 脚本

5. 生成最终镜像
   → 根据 IMAGE_FSTYPES 生成不同格式（ext4/squashfs/mtd/ubi）
   → 对于 OpenBMC 通常是 .static.mtd 或 .ubi.mtd
   → 这就是可以直接烧录到 Flash 的固件文件
```

> **大白话**：镜像构建就像组装一台定制电脑——IMAGE_FEATURES 是你的"硬件配置单"（要装什么功能），FEATURE_PACKAGES 是配置单到零件清单的映射，packagegroup 是零件包的组合清单，最后 do_rootfs 是把所有零件逐一安装到主板上，`IMAGE_FSTYPES` 决定最终打包成哪种格式的系统盘。烧录 .ubi.mtd 就相当于把装好系统的硬盘插进主机。

---

### 1.8 调试 BitBake 构建问题

构建出错是日常。高效的调试能力是区分新手和老手的分水岭。

**常用调试命令**：

```bash
# 查看变量的最终值和来源
bitbake -e phosphor-pid-control | grep ^SERIAL_CONSOLES=

# 查看某个变量在哪些文件中被设置
bitbake -e phosphor-pid-control | grep -B5 "SERIAL_CONSOLES"

# 查看任务执行日志
cat tmp/work/armv7ahf-vfpv4d16-openbmc-linux-gnueabi/phosphor-pid-control/1.0+git*/temp/log.do_compile

# 进入编译环境手动调试
bitbake -c devshell phosphor-pid-control

# 清理后重建
bitbake -c clean phosphor-pid-control && bitbake phosphor-pid-control

# 强制重新执行某个任务（不清理）
bitbake -f -c compile phosphor-pid-control
```

**常见构建错误排查表**：

| 错误类型 | 典型表现 | 排查方法 |
|---------|---------|---------|
| 依赖缺失 | `ERROR: Nothing PROVIDES 'xxx'` | 检查 DEPENDS/RDEPENDS 拼写 |
| 编译错误 | `do_compile failed` | 看 `log.do_compile`，通常是代码或头文件问题 |
| 安装路径错误 | `do_package: files not shipped` | 检查 `do_install` 中的路径是否正确 |
| Layer 冲突 | `Multiple .bb files provide` | 用 `bitbake-layers show-配方` 看优先级 |
| sstate 损坏 | 莫名其妙的编译错误 | 清除 sstate：`bitbake -c cleansstate <配方>` |

> **大白话**：调试 BitBake 构建错误就像维修流水线故障——首先看故障报告（`log.do_compile`），找到是哪道工序卡住了；`devshell` 相当于直接走到出问题的工位上手动操作，绕过所有自动化流程来复现和修复；`bitbake -e` 则像调出控制系统的变量监控面板，看某个参数在哪里被谁改成了什么值。

---

### 1.9 BitBake 面试题速查

**Q1：解释 BitBake 的 配方 版本选择机制。**
A：这是一个两步机制。**第一步**，BitBake 按 `BBFILE_PRIORITY` 对所有提供同名配方的 layer 分组，选出优先级最高的一组候选者（如果最高优先级组内只有一个配方，直接选中）。**第二步**，如果最高优先级组内有多个版本，则比较版本号（PV），选择最高版本。如果需要强制使用特定版本，通过 `PREFERRED_VERSION_xxx = "1.0"` 覆盖上述自动选择。注意：`PREFERRED_VERSION` 的优先级高于上述两步机制。简言之，BBFILE_PRIORITY 先筛选 layer，版本号再决定同 layer 内的具体配方。

> **大白话**：版本选择就像招标采购——先按供应商资质评级（`BBFILE_PRIORITY`）剔除低资质供应商，再从留下的供应商里挑报价最新的型号（最高 PV）。而 `PREFERRED_VERSION` 相当于领导直接指定供应商，绕过整套评标流程，无论评级高低都认这家。

**Q2：`PROVIDES` 和 `RPROVIDES` 的区别是什么？**
A：`PROVIDES` 声明编译时提供的虚拟名称（例如 `PROVIDES = "virtual/kernel"` 表示"我是内核的一种实现"）。`RPROVIDES` 声明运行时提供的虚拟名称。前者用于解析 DEPENDS，后者用于解析 RDEPENDS。

> **大白话**：`PROVIDES` 和 `RPROVIDES` 就像承包商持有的两种资质证书——`PROVIDES` 是"施工许可证"（声明在编译阶段我能顶替某个功能角色），`RPROVIDES` 是"运营许可证"（声明在运行时我能顶替某个功能角色）。`virtual/kernel` 就像"总承包商"这个角色——具体由哪家公司来干，由谁持证谁上岗。

**Q3：什么是 multiconfig？适用场景？**
A：multiconfig 允许在一次 BitBake 调用中同时构建多个目标配置（例如同时构建 ARM 的 BMC 固件和 x86 的 Host 固件）。通过在 `conf/multiconfig/` 下放置不同的配置文件实现。在 OpenBMC 中可以用来同时构建 BMC 镜像和 Host 端工具。（注意：multiconfig 在 OpenBMC 社区中使用较少，大多数平台只构建单一 ARM 目标。但了解这一机制对面试加分。）

> **大白话**：multiconfig 就像同一条生产线同时跑两套规格的产品——工人（BitBake）不下班、不换班，用不同的参数模具（.conf 文件）在同一次开工中生产 ARM 版和 x86 版。好处是可以共享已经缓存好的中间产物，不需要两次单独开工浪费时间。

**Q4：解释 `PACKAGECONFIG` 机制。**
A：`PACKAGECONFIG` 是 配方 级别的编译选项开关。例如：
```python
PACKAGECONFIG ??= "ssl"
PACKAGECONFIG[ssl] = "--enable-ssl,--disable-ssl,openssl"
# 格式：[feature] = "启用configure参数,禁用configure参数,启用时额外DEPENDS,启用时额外RDEPENDS,与本feature冲突的其他feature"
```
在 .bbappend 中可以通过 `PACKAGECONFIG:append = " feature"` 或 `PACKAGECONFIG:remove = "feature"` 来控制。

> **大白话**：`PACKAGECONFIG` 就像汽车的选配清单——基础车型出厂时自带某些配置（`??=` 的默认值），但你可以在订单上勾选"加装天窗""去掉音响"来定制。一旦你勾选了"天窗"，采购部门会自动帮你追加相应物料（额外 DEPENDS），不需要你手动一项项去填。供应商（bbappend）还可以修改这份选配清单，让同一套源码出不同配置的产品。

**Q5：reproducible build（可复现构建）在 Yocto 中如何保证？**
A：Yocto 通过多重机制保证：1) 源码版本通过 SRCREV 锁定（不用 AUTOREV）；2) 编译环境通过交叉编译工具链隔离，避免宿主机污染；3) 时间戳通过 `SOURCE_DATE_EPOCH` 归一化；4) 任务签名（Task Signature）基于所有输入变量的哈希，确保构建的确定性。sstate-cache 利用这些签名来加速构建，但它本身是加速机制而非可复现性的保障。

> **大白话**：可复现构建就像工厂的标准化生产——不管哪条流水线、哪个班次、哪一天生产，零件规格必须完全一致。时间戳归一化就像统一把"出厂日期"打印为同一天，防止同一份代码因为编译时间不同而产生不同二进制。SRCREV 锁定就像用零件批次号而不是"最新到货"来领料，下个月还能复现今天的产品。

**Q6：`inherit` 一个 bbclass 在底层做了什么？**
A：BitBake 会把 bbclass 文件中定义的所有变量和函数"混入"到当前 配方 的命名空间。如果 配方 和 bbclass 都定义了同名函数，配方 的版本优先。bbclass 中的 `:append` 和 `:prepend` 也会被应用到 配方 的变量上。执行顺序是：先 `inherit` 的 bbclass 先加载，后 `inherit` 的可以覆盖前面的。

> **大白话**：`inherit` 就像员工入职时领取标配工具箱——公司给你一套固定的工作流程手册（bbclass），你拿来直接用，但如果你手册里有自己写的特殊步骤，你的版本会盖过公司标准版。继承多个 bbclass 就像同时持有多个部门的工作证，谁后发的证，规则优先级更高。

**Q7：为什么 `LICENSE` 变量在 Yocto 中如此严格？**
A：Yocto 有内置的 License 合规检查。配方 必须声明 `LICENSE` 和 `LIC_FILES_CHKSUM`（许可文件的 MD5 校验和）。如果上游更新了许可文件内容但你没有更新校验和，构建会直接报错。在 OpenBMC 中，meta-phosphor 额外禁止了不带版本号的 GPL/LGPL 声明（例如必须写 `GPL-2.0-only` 而不是 `GPL`）。

> **大白话**：许可证校验就像合同签字后留存副本——上游供应商改了合同条款但你没盖新章，公司法务部会直接叫停交货。`LIC_FILES_CHKSUM` 就是那份原版合同的指纹，一个字节不对就拒绝放行。Yocto 这么严格是因为固件出货时如果许可证不合规，会面临法律风险，宁可构建失败也不能让不确定状态的代码上线。

---

## 第二章：OpenBMC 框架精通

### 2.1 D-Bus：OpenBMC 的神经系统

D-Bus 是 Linux 系统上标准的进程间通信（IPC）机制。在 OpenBMC 中，D-Bus 不仅仅是一个消息通道，它构成了整个系统的基础架构神经网。所有硬件状态、传感器数据、控制指令都在这条总线上流动。

**为什么 OpenBMC 选择 D-Bus**

如果不使用 D-Bus，系统架构师可能会考虑 REST API、gRPC 或是共享内存。共享内存性能最高，但缺乏统一的接口描述和权限隔离。REST API 和 gRPC 会引入庞大的网络栈开销。D-Bus 提供了完美的平衡。它拥有面向对象的接口模型，支持强类型数据，并且被 systemd 原生深度集成。OpenBMC 的核心服务依赖 systemd 进行生命周期管理，D-Bus 让服务之间的依赖关系和状态同步变得非常自然。

> **大白话**：D-Bus 在 OpenBMC 中就像城市地铁系统——各个服务进程是不同的站点，消息就是地铁上流通的乘客。共享内存虽然快（直线飞驰），但谁都能随便上车（无权限隔离）；REST/gRPC 是打网约车（网络栈开销大）；D-Bus 是现代地铁，有固定线路（接口契约）、实名制验票（强类型）、统一调度中心（systemd集成），既快又安全。

**D-Bus 核心概念**

理解 D-Bus 需要掌握以下五个概念。
*   **Bus Name（总线名称）**：服务在总线上的唯一地址，类似网络中的 IP 或域名。例如 `xyz.openbmc_project.State.Host`。
*   **Object Path（对象路径）**：服务内部的层级结构树，类似文件系统路径。例如 `/xyz/openbmc_project/state/host0`。
*   **Interface（接口）**：对象实现的方法和属性集合，类似面向对象编程中的类。例如 `xyz.openbmc_project.State.Host` 接口。
*   **Method（方法）**：可以在接口上调用的函数。
*   **Property（属性）**：接口上保存的状态变量。
*   **Signal（信号）**：广播消息，当属性改变或特定事件发生时发出。

> **大白话**：D-Bus 的五个概念可以用电话系统来类比——Bus Name 是电话号码（如 `xyz.openbmc_project.State.Host`），Object Path 是分机号（精确定位到某个功能模块），Interface 是该分机能处理的业务类型，Method 是你能请求它做的具体操作，Property 是它当前的状态信息，Signal 是它主动向外广播的通知消息（不需要你来问，有事它自己说）。

**dbus-broker 与 dbus-daemon**

传统的 Linux 发行版多使用 dbus-daemon。OpenBMC 默认采用 dbus-broker。dbus-broker 提供了更高的吞吐量和更低的延迟。在面对成百上千个传感器频繁更新数据时，dbus-broker 能够防止总线拥塞，并且它与 systemd 的集成更加紧密。

> **大白话**：dbus-daemon 和 dbus-broker 的差异，就像老式电话交换机和现代数字程控交换机——老式的（dbus-daemon）实现年代久、调度效率较低，消息多了容易排队拥塞；新式的（dbus-broker）架构更现代、资源管理更精细，吞吐量和延迟都更优，且与 systemd 深度集成。BMC 上动辄几百个传感器每秒上报数据，选 dbus-broker 就是为了这条"信息高速公路"不堵车。

**busctl 实战命令**

在 BMC 终端中，`busctl` 是最强大的调试工具。

列出总线上所有的服务：
```bash
busctl list
```

查看特定服务的对象树：
```bash
busctl tree xyz.openbmc_project.Hwmon-1349520443.Hwmon1
```

内省一个对象，查看它拥有的接口、属性和方法：
```bash
busctl introspect xyz.openbmc_project.Hwmon-1349520443.Hwmon1 /xyz/openbmc_project/sensors/temperature/Inlet_Temp
```

调用方法，例如重置主板：
```bash
busctl call xyz.openbmc_project.State.Host /xyz/openbmc_project/state/host0 org.freedesktop.DBus.Properties Set ssv xyz.openbmc_project.State.Host RequestedHostTransition s xyz.openbmc_project.State.Host.Transition.Reboot
```

监控总线上的信号：
```bash
busctl monitor xyz.openbmc_project.State.Host
```

**实战：查看传感器温度**

假设我们需要在 evb-2u-egs 平台上查看进风口 TMP75 的温度。
```bash
busctl get-property xyz.openbmc_project.Hwmon-1349520443.Hwmon1 /xyz/openbmc_project/sensors/temperature/Inlet_Temp xyz.openbmc_project.Sensor.Value Value
```
返回结果可能为 `d 28.5`，代表当前进风口温度为 28.5 摄氏度。

> **大白话**：`busctl` 就是 D-Bus 世界里的"瑞士军刀"——`busctl list` 是查在线名录，`busctl tree` 是看组织架构图，`busctl introspect` 是读某人的完整简历，`busctl call` 是直接打电话下指令，`busctl monitor` 是"搭线监听所有来往电话"。调试 OpenBMC 时，这几条命令能让你在不看任何代码的情况下完整了解系统当前状态。

### 2.2 phosphor-dbus-interfaces：接口契约

OpenBMC 采用契约优先的设计原则。所有的 D-Bus 接口都集中在 `phosphor-dbus-interfaces` 仓库中进行定义。

**什么是 phosphor-dbus-interfaces**

这是一个包含了大量 YAML 文件的仓库。开发者在这里用 YAML 定义接口的属性、方法和信号。在编译阶段，Yocto 构建系统会调用代码生成工具（sdbus++），将这些 YAML 文件自动转换成 C++ 的头文件和绑定代码。开发者只需要在业务逻辑中继承这些自动生成的 C++ 类，就能实现标准化的 D-Bus 服务。

> **为什么这样做**
> 集中管理接口定义避免了不同组件之间出现数据格式不一致的问题。无论是风扇控制器还是 Redfish API 服务器，它们对"温度"的定义完全相同。自动生成 C++ 绑定代码极大地减少了处理 D-Bus 底层封包和解包的繁琐工作。

**核心接口族**

*   `xyz.openbmc_project.Sensor.Value`：所有传感器的基类接口，包含 `Value`、`MaxValue`、`MinValue` 等属性。
*   `xyz.openbmc_project.State.Host`：定义主机的状态（Off、Running、Quiesced）和请求状态转换的方法。
*   `xyz.openbmc_project.State.Chassis`：定义机箱电源状态。

> **大白话**：这三大核心接口族就像三种不同类型的"行业资质证书"——Sensor.Value 是"数据采集从业资质"（凡是传感器都要有，规定了最少要上报哪些数值）；State.Host 是"主机管理操作证"（规定了谁有资格改变主机运行状态，以及状态之间怎么跳转）；State.Chassis 是"机箱电源操作证"（只管"电有没有"这一件事）。三张证书互相独立，但协同工作——没电（Chassis Off），主机当然也跑不起来（Host Off）。

**接口继承和组合模式**

一个 D-Bus 对象可以同时实现多个接口。一个风扇传感器对象可能同时实现 `Sensor.Value`（提供转速）和 `Sensor.Threshold.Warning`（提供告警阈值）。这种组合模式让对象的设计非常灵活。

> **大白话**：D-Bus 对象同时实现多个接口，就像一个人可以同时持有会计证、驾驶证、注册工程师证——每张证代表一种"能力接口"，查不同能力只需查对应的证书。风扇对象实现了"转速汇报接口"和"超温报警接口"，调用方按需选择接口调用，不需要知道同一个对象还实现了哪些其他能力。

**如何阅读 YAML 定义文件**

打开 `xyz/openbmc_project/Sensor/Value.interface.yaml`，结构非常清晰：
```yaml
description: >
    Implement to provide a sensor value.
properties:
    - name: Value
      type: double
      description: >
          The sensor value.
    - name: Unit
      type: enum[self.Unit]
      description: >
          The unit of the value.
```
这明确了 `Value` 属性是双精度浮点数，而 `Unit` 是枚举类型。

> **大白话**：phosphor-dbus-interfaces 的 YAML 文件就像国家标准局颁布的"接口规范书"——定义了温度传感器必须提供哪些字段、用什么数据类型。sdbus++ 工具则是"代码翻译局"，把这份标准书自动翻译成 C++ 代码。开发者只管实现业务逻辑，不需要手写那些枯燥的 D-Bus 消息封包代码，就像工程师直接用标准螺丝规格，不需要自己重新测量螺纹。

### 2.3 phosphor-objmgr (Mapper)：服务注册中心

**Mapper 的作用**

在 D-Bus 上找一个特定的对象往往很困难，因为服务名称（Bus Name）常常是动态生成的。Mapper 提供了一个全局的目录服务。它监听总线上的对象创建和销毁事件，维护一个从 Object Path 到 Service Name 的映射表。

> **为什么这样做**
> 如果没有 Mapper，当 bmcweb 需要获取所有传感器的列表时，它必须逐个询问总线上的每一个服务。有了 Mapper，bmcweb 只需要向 Mapper 发起一次查询，就能得到完整的传感器拓扑。这极大地提升了系统的响应速度。

**核心方法**

*   `GetSubTree`：获取某个路径下的所有对象及其所在的接口和服务名。
*   `GetObject`：根据给定的对象路径，反向查找提供该对象的服务名。

**busctl 调用 Mapper 示例**

查找系统里实现了 `Sensor.Value` 接口的所有对象：
```bash
busctl call xyz.openbmc_project.ObjectMapper /xyz/openbmc_project/object_mapper xyz.openbmc_project.ObjectMapper GetSubTree sias "/" 0 1 xyz.openbmc_project.Sensor.Value
```
这个查询会返回一个庞大的字典，列出每个传感器路径对应的服务名称。

> **大白话**：Mapper 就像写字楼里的前台接待——你要找"温度传感器部门"，前台查一下登记本就知道在几楼哪个房间（哪个 Bus Name），不需要你自己一层层跑上去问。GetSubTree 是"把某个楼层所有部门的分机号表列给我"，GetObject 是"我有这个部门名，查它的电话"。没有 Mapper，每次查询都得靠广播喊话，效率极低。

### 2.4 entity-manager：硬件拓扑发现引擎

早期的 BMC 系统会将硬件拓扑硬编码在 C 代码或者设备树中。OpenBMC 引入了 `entity-manager`，彻底改变了这种模式。

**设计哲学**

硬件配置由 JSON 文件驱动。系统在运行时通过探针（Probe）扫描硬件。如果扫描到的硬件特征与 JSON 文件中的定义匹配，系统就会在 D-Bus 上"暴露"出这个硬件，并触发相应的服务去管理它。

> **大白话**：entity-manager 彻底终结了"把硬件列表写死在代码里"的老做法——就像从"手写名单"升级为"刷脸考勤"。以前要改主板上的传感器，得修改 C 代码重新编译；现在只需改一个 JSON 文件，重启 entity-manager 就能自动识别新硬件并通知相关服务。这种"声明式配置+运行时发现"的模式让同一套固件镜像可以支持硬件配置有差异的多款产品。

**Probe 机制详解**

*   **I2C 扫描**：通过读取特定 I2C 地址的寄存器值来判断芯片类型。
*   **FRU 匹配**：读取 EEPROM 中的 FRU 数据（如产品名称、厂商信息）进行匹配。
*   **TRUE 模式**：无条件匹配，通常用于基础主板的定义。

**Exposes 数组与 D-Bus 对象**

在匹配成功后，`entity-manager` 会解析 JSON 中的 `Exposes` 数组。数组里的每一个元素都会被转化成 D-Bus 上的一个对象。

**evb-2u-egs 示例解析**

我们的平台在总线 21（MUX 展开后的虚拟总线）地址 0x48 有一个 TMP75 进风口温度传感器。在 entity-manager 的 JSON 中会有如下定义：
```json
{
    "Exposes": [
        {
            "Address": "0x48",
            "Bus": 21,
            "Name": "Inlet_Temp",
            "Type": "TMP75",
            "Thresholds": [
                {"Direction": "greater than", "Name": "upper critical", "Severity": 1, "Value": 45},
                {"Direction": "greater than", "Name": "upper non critical", "Severity": 0, "Value": 40}
            ]
        }
    ],
    "Name": "evb-2u-egs Baseboard",
    "Probe": "TRUE"
}
```
总线 7 上的 LM87（0x2d）和 ADT7475（0x2e），总线 20（MUX 展开）上的两颗 AD5593R（0x10, 0x11），以及总线 9 地址 0x22 的 CPLD 风扇控制器也采用类似的方式定义。`dbus-sensors` 会监听 `entity-manager` 的输出。当看到名为 `TMP75` 的配置出现在 D-Bus 上时，相应的 hwmontempsensor 服务就会去初始化这个 I2C 设备，并开始读取温度。

> **大白话**：entity-manager 的 Probe+Exposes 机制就像公司的自动化入职流程——Probe 是"扫描入职证件"（查I2C地址、读EEPROM），匹配成功后 Exposes 是"自动开通工卡权限并通知相关部门"（在D-Bus发布配置对象）。dbus-sensors 就像收到通知的业务部门，看到新员工（TMP75 温度传感器）入职公告，立刻安排专人（hwmontempsensor进程）去对接上岗。整个流程零手动干预，插上新硬件系统自动识别。

### 2.5 dbus-sensors：传感器采集框架

**新老架构对比**

OpenBMC 早期使用 `phosphor-hwmon`。这需要为每一个传感器编写繁琐的 `.conf` 文件，并且所有的传感器数据都集中在一个进程中处理。`dbus-sensors` 是现代的替代方案。它将传感器按类型拆分成独立的进程，如 `fansensor`、`hwmontempsensor`、`adcsensor`。

> **面试要点：为什么从 phosphor-hwmon 迁移到 dbus-sensors**
> 1. 配置管理：dbus-sensors 结合 entity-manager，用集中的 JSON 配置替代了旧的逐传感器 `.conf` 文件机制，大幅简化了配置管理。
> 2. 故障隔离：拆分进程后，一个 I2C 总线挂死导致某个传感器进程崩溃，不会影响其他类型的传感器。
> 3. 性能：单点更新变成了多进程并发更新，降低了单个主循环的负担。

**支持的传感器类型**

*   **hwmon**：标准的 Linux hwmon 接口温度传感器（如 TMP75、LM87、ADT7475）。
*   **PECI**：读取 Intel CPU 内部温度。在 evb-2u-egs 中，CPU0 和 CPU1 分别通过 0x30 和 0x31 地址采集。
*   **ADC**：主板电压采集（如 AD5593R）。
*   **fan tach**：风扇转速。

> **大白话**：这四类传感器的采集方式各有侧重，就像不同类型的仪表盘——hwmon 走的是 Linux 内核标准通道（如同仪表盘走标准 OBD 接口）；PECI 是 Intel 独家协议，专门用来"直接问 CPU 你现在多热"（相当于直连发动机控制芯片读温度，绕过外部传感器）；ADC 是原始模拟量采集（就像万用表直接量电压）；fan tach 是通过数脉冲计算转速（类似自行车测速计数圈数）。四条路互不干扰，并行工作。

> **大白话**：dbus-sensors 按传感器类型拆分进程，就像医院里体温计、心率仪、血压计分属不同科室维护——温度传感器进程挂了，不会连累风扇转速读取也一起瘫痪。每种传感器都有自己的"专属医生"，互相隔离，这是 dbus-sensors 相比 phosphor-hwmon"一个大夫包看所有病"的核心优势。

**Threshold 报警机制**

传感器不仅报告数值，还负责报警。`dbus-sensors` 实现了三个级别的阈值：
*   **Warning**：警告，触发日志。
*   **Critical**：严重，可能触发降频或加大风扇转速。
*   **HardShutdown**：致命级别。传感器发布该级别的 D-Bus 报警信号后，需要配合策略服务（如 `phosphor-state-manager`）执行实际的硬件关机保护。传感器本身不直接断电。

> **大白话**：三级阈值就像高铁的三色信号灯体系——Warning 是"黄灯提醒，注意观察"，Critical 是"红灯限速，减少负载"，HardShutdown 是"紧急叫停，全线封锁"。关键设计是：传感器只负责"吹哨报警"，真正的断电动作由策略服务执行，分工明确，避免传感器进程崩溃时意外触发断电。

### 2.6 phosphor-state-manager vs x86-power-control

电源管理是 BMC 最核心的功能之一。

**状态机模型**

`phosphor-state-manager` 是经典的 OpenBMC 状态机。它将系统状态拆分为三个独立的维度：BMC 状态、Chassis（机箱电源）状态、Host（主机操作系统）状态。它主要通过 systemd 的 target 依赖来控制上电时序。

**x86-power-control**

Intel 开发了 `x86-power-control`。它更加贴近 x86 架构的硬件特性，直接控制 GPIO 引脚（如电源按钮、复位按钮、电源好信号）。它内部维护了一个严密的轮询状态机。

**何时用哪个**

ARM 服务器通常硬件上电流程较短，适合使用原生的 `phosphor-state-manager`。x86 服务器有复杂的上电时序（S0、S5、G3 状态，SLP_S3 等信号），必须精细控制 GPIO，因此几乎全部使用 `x86-power-control`。

> **大白话**：phosphor-state-manager 和 x86-power-control 的区别，就像普通汽车和赛车的起步程序——普通车（ARM）踩油门就走；赛车（x86）得按固定流程：启动点火系统、等涡轮增压就绪、确认变速箱挂挡、等油温达标……每一步都要等上一步确认完成。Intel x86 平台有 SLP_S3、SLP_S4 这些握手信号，漏掉任何一个就可能导致开机失败或损坏硬件。

**evb-2u-egs 的选择**

evb-2u-egs 搭载了 Intel EGS 平台。我们需要处理主板的 GPIO 信号以完成 CPU 的上电握手，因此我们毫无疑问选择 `x86-power-control`。

**状态转换图**

通过按下电源按钮，状态流转如下：
电源状态流转：
Chassis: Off → (power button) → On → (power off request) → Off
Host:    Off → (chassis on) → Running → (graceful shutdown) → Off
                                      → (error/hang) → Quiesced → (recovery/off)

> **大白话**：电源状态机就像一套门禁系统的多层验证——机箱上电（Chassis On）是"刷卡进楼"，主机运行（Host Running）是"坐到工位开电脑"，Quiesced 是"电脑卡死了但人还在座位上"。这三个状态维度（BMC状态、机箱状态、主机状态）相互独立，就像大楼门禁、楼层门禁、工位权限分别管理，一层出问题不会直接影响其他层。

### 2.7 phosphor-pid-control (swampd)：闭环温控

**PID 控制理论**

PID 代表比例（Proportional）、积分（Integral）、微分（Derivative）。在服务器温控中，设定一个目标温度（SetPoint）。当前温度与目标温度的差值就是误差。P 控制误差的当前大小，I 控制误差的累积量，D 控制误差的变化趋势。三者结合计算出风扇所需的 PWM 占空比。

> **大白话**：PID 算法就像有经验的空调操作员——P 是"现在偏差多少就立刻调多少"的当机立断；I 是"偏差虽小但持续了好久，说明有系统误差，得慢慢补偿"的记性好；D 是"温度上升速度很快，说明马上就要超标，提前踩刹车"的未雨绸缪。三者配合，让风扇转速平稳而精确地跟随温度变化。

**swampd 的三层模型**

*   **sensor**：输入源，如 TMP75 采集的进风口/出风口温度或 PECI 采集的 CPU 温度。
*   **pid**：计算模块。接收传感器数据，执行 PID 算法，输出计算结果。
*   **zone**：热区。一个服务器可以划分为多个热区，每个热区包含多组 PID 和多个风扇。最终风扇转速取热区内所有 PID 计算结果的最大值。

> **大白话**：swampd 的三层模型就像城市供暖调度系统——sensor 是各居民楼的室温感应器，pid 是计算每个区域需要多少热量的算法中枢，zone 是一片供暖片区（多个楼共享一个锅炉组）。但这里我们说的是散热（cooling），所以反过来——最终取热区内"最热的那个房间的散热需求"来决定风扇功率，这样确保温度最高的区域也能被充分冷却。

**stepwise vs PID 模式**

*   **stepwise**：阶梯控制。温度在 40 度时转速 30%，50 度时 50%。简单直接，但温度变化时风扇噪音突变明显。
*   **PID**：平滑调节。风扇转速随温度平缓波动。

> **大白话**：stepwise 和 PID 就像两种不同风格的空调控制器——stepwise 是老式空调，23°C 开一档，28°C 自动跳二档，温度穿越临界点时风扇声音突变，像翻书一样有明显跳变感；PID 是新式变频空调，无极调速，风扇转速随温度像水流般平缓增减。服务器数据中心里 PID 是首选，因为频繁的风速突变不仅噪音大，对风扇轴承的机械寿命也有损耗。

**config.json 结构解析**

在 evb-2u-egs 中，总线 9 地址 0x22 的 CPLD 管理着 4 个系统风扇。我们要在配置中定义一个 Zone，将这 4 个风扇绑定进去，并将 TMP75（进风口温度）和 PECI（CPU 温度）的输入给这个 Zone。

**failsafePercent 的安全哲学**

> **为什么这样做**
> 如果某个关键传感器（如 CPU 温度）发生故障或总线挂死，无法读出数据，温控系统必须假设最坏的情况已经发生。系统会立刻将风扇转速提升到 `failsafePercent`（通常为 100%），以巨大的噪音换取硬件的绝对安全。这是温控设计的底线原则。

> **大白话**：failsafePercent 就像核电站的"紧急冷却系统"——平时安静待命，一旦温度监测仪器失联，立刻强制开启全功率冷却，宁可噪声震天也不冒芯片过热烧毁的风险。这是"宁可误报，不可漏报"的硬件安全哲学，传感器数据丢失本身就是异常信号，必须按最坏情况处理。

> **面试要点：如何调 PID 参数**
> 从调参经验来看，先关闭 I 和 D，只调 P，直到系统出现稳定等幅震荡。然后加入 I 消除静差，最后加入 D 抑制超调。服务器中由于热惯性大，I 往往非常小，D 的作用也很有限，主要依靠 P 快速响应。

### 2.8 phosphor-led-manager：LED 抽象层

现代服务器前面板有丰富的 LED 状态指示灯。

**物理引脚到逻辑组的映射**

在底层，LED 只是连接到 AST2600 GPIO 引脚的发光二极管。`phosphor-led-manager` 引入了逻辑组（Group）的概念。例如 `PowerOn` 组可能包含前面板电源灯变绿、后面板定位灯关闭等多个物理动作。

**Action 类型**

配置可以定义每个 LED 在特定组中的动作：On（常亮）、Off（熄灭）、Blink（闪烁）。

**联动机制**

上层应用不需要知道 GPIO 引脚号。当系统进入特定状态时（如开机完成），对应的 systemd target 被激活，LED Manager 监听这些状态变化，自动 assert 对应的 LED 组（如 `power_on`）。底层的 GPIO 操作对上层完全透明。

> **大白话**：phosphor-led-manager 就像大楼的智能照明控制系统——上层只说"现在进入'欢迎模式'"，控制系统自动帮你调亮大厅灯、关掉走廊灯、让门牌灯闪烁，具体哪号灯接哪根线完全不用关心。应用层只需要 assert 一个逻辑组名称，LED Manager 负责把这个指令翻译成一系列 GPIO 写操作。

### 2.9 bmcweb：Redfish 与 Web UI

**双重角色**

bmcweb 是基于 C++ Boost.Asio 开发的高性能 Web 服务器。它既是 Redfish API 的服务端，也是 Web UI 静态文件的托管者。

**Redfish 资源树结构**

Redfish 采用严格的树形结构：
*   `/redfish/v1/Chassis`：机箱相关（风扇、温度、电源）。
*   `/redfish/v1/Systems`：主系统相关（CPU、内存、主板状态）。
*   `/redfish/v1/Managers`：BMC 自身状态和网络配置。

> **大白话**：Redfish 的资源树就像政府部门的公文系统——Chassis 是基础设施局（管风扇电源），Systems 是运营管理局（管 CPU 内存），Managers 是行政办公室（管 BMC 自身）。每个 URL 路径都对应一个真实的硬件实体或服务，标准统一，不同厂商的管理工具都能直接"读懂"这份"政务目录"。

**认证与 WebSocket**

bmcweb 支持 Basic Auth（直接密码校验）和 Session Token（令牌校验）。更高级的环境配置会开启 mTLS，使用客户端证书免密登录。WebSocket 被用来实现网页端的 KVM 控制台和 SOL（Serial Over LAN），提供实时的双向数据流。

> **大白话**：bmcweb 的三种认证方式就像进入安全等级不同的办公区——Basic Auth 是"出示工牌姓名+密码"（最简单），Session Token 是"领到临时通行证，有效期内刷卡进出"（效率更高），mTLS 是"设备本身就是门禁钥匙，芯片内置证书，插上就自动开门"（最安全，无需密码）。WebSocket 则是给 KVM 和 SOL 铺设的"专线光纤"，画面和键盘输入实时双向流动，和普通 HTTP 的"一问一答"模式完全不同。

**curl 实战**

请求机箱热量信息的 Redfish 数据：
```bash
curl -k -u root:0penBmc https://<bmc-ip>/redfish/v1/Chassis/chassis/Thermal
```
系统会返回标准的 JSON 报文，其中包含经过 bmcweb 从 D-Bus 转换而来的传感器温度和风扇转速。

> **大白话**：bmcweb 就像服务器的"对外营业窗口"——它一边对外说 Redfish 这门"国际通用语言"，一边对内用 D-Bus 和各个内部进程沟通。外部管理员发来 `curl` 请求，bmcweb 翻译成 D-Bus 查询，拿到数据后再翻译回 JSON 标准格式。WebSocket 则像一条专属的 VIP 直播通道，KVM 画面和串口输出实时流过来，不需要反复刷新。

### 2.10 IPMI 架构

尽管 Redfish 正在成为行业标准，IPMI 在现阶段依然不可或缺。

**ipmid 进程**

负责处理所有进入 BMC 的 IPMI 请求包，解析命令并分发到各个 handler 函数中执行。

**host vs net**

*   `phosphor-ipmi-host`：处理来自主机操作系统的带内请求。在 evb-2u-egs 中，这通常通过 KCS 接口完成。
*   `phosphor-ipmi-net`：处理来自网络端口的带外请求（LAN+）。

> **大白话**：ipmi-host 和 ipmi-net 的区别，就像公司内网电话和外线电话——内网电话（host）是服务器操作系统直接打给 BMC 的"内部通话"，走的是主板上的 KCS 专线，速度快但只能在机器本地用；外线（net）是网络管理员从远程打过来的，走的是网线，跨过互联网也能管理，但要经过认证。

**SDR/SEL/FRU**

现代 OpenBMC 并不在本地磁盘存储传统的二进制 SDR 文件。ipmid 在启动时或收到查询时，会读取 D-Bus 上的传感器和 entity-manager 数据，动态拼装出 SDR 响应包。

> **大白话**：SDR 动态生成这个设计很妙——就像现代银行不再打印纸质存折，而是每次查询时直接从数据库现场生成账单。传统 BMC 把 SDR 存成 .bin 文件，一旦传感器配置变了就要手动更新文件，容易出现"账本"和"实际"不一致的问题。OpenBMC 让 ipmid 实时从 D-Bus 查询，保证数据永远是最新的。

**OEM 命令**

供应商通常会添加专有指令。比如 evb-2u-egs 定义了 78 条 OEM 命令。只需编写 C++ 代码注册相应的 NetFn 和 Command ID，ipmid 就会自动接管路由。

> **大白话**：OEM 命令的注册机制就像给酒店总机系统添加"本店专属服务号"——标准 IPMI 命令是全行业通用的服务项目（如开机/关机），OEM 命令是酒店独家服务（如"帮我预约私人健身教练"）。只需在总机登记新号码（注册 NetFn + Command ID），之后客人打来这个号码，总机（ipmid）自动转接到对应服务台，完全不影响标准服务流程。

### 2.11 日志与事件系统

**日志栈**

OpenBMC 具有多层次的日志系统：
*   **phosphor-logging**：负责生成 D-Bus 错误日志对象。这些日志拥有详细的元数据，常用于软件内部异常追踪。
*   **SEL (System Event Log)**：专为 IPMI 设计的二进制告警格式。
*   **Redfish EventService**：能够将日志以 JSON 格式推送给订阅的远程管理平台。

> **大白话**：这三种日志面向的受众完全不同。phosphor-logging 是给运维工程师看的"内部报告"，字段详尽但格式自由；SEL 是给IPMI工具看的"标准表格"，每条记录固定16字节，像政府表格一样严格；Redfish EventService 是给数据中心运营平台看的"云端消息推送"，订阅之后出事自动通知，无需轮询。

**journalctl 实战**

底层所有的标准输出都会汇聚到 systemd journal 中。查看内核报错：
```bash
journalctl -k -p err
```
查看 bmcweb 的运行日志：
```bash
journalctl -u bmcweb -f
```

> **大白话**：OpenBMC 的三层日志系统就像医院的病历管理体系——phosphor-logging 是详细的病程记录（供院内医生查阅），SEL 是急诊科的简短病历卡（格式标准、二进制紧凑，方便IPMI工具快速读取），Redfish EventService 则是自动发给上级医院的转诊通知单（主动推送给远程管理平台）。`journalctl -f` 好比在护士站实时盯着监护仪显示屏，日志滚动出现就是患者心跳数据在实时更新。

### 2.12 服务启动顺序

OpenBMC 启动流程高度并行，理解 systemd 的依赖图至关重要。

**关键路径**

1.  内核启动后拉起 systemd。
2.  `dbus-broker` 必须第一时间就绪（所有 D-Bus 服务的前提）。
3.  `phosphor-mapper` 启动，开始构建对象字典。
4.  并行启动多个服务：
    - `entity-manager` 扫描 I2C 设备，生成配置
    - `x86-power-control` 初始化 GPIO，进入状态机监控
    - `phosphor-ipmi-host` 准备 KCS 通道
5.  `dbus-sensors` 各子进程启动，依赖 entity-manager 配置绑定硬件。
6.  `swampd` (pid-control) 启动，依赖传感器数据开始计算风扇转速。
7.  `bmcweb` 对外提供 Redfish/WebUI 服务。

> **大白话**：这7步启动序列就像机场的早晨开航流程：空管塔台（dbus-broker）必须最先就绪，然后地面调度（Mapper）登记停机位，之后地勤保障、海关、值机柜台才能并行就位，最后才轮到登机口开门放行（bmcweb对外服务）。第4步的并行启动就像多个保障团队同时进场，大幅缩短了整体就绪时间。

**性能分析**

如果发现 BMC 启动过慢，可以使用以下命令查看启动瓶颈：
```bash
systemd-analyze blame
systemd-analyze critical-chain
```

> **大白话**：`systemd-analyze blame` 就像给马拉松比赛做赛段计时——哪个选手在哪一段跑得最慢，一目了然。`critical-chain` 则专门找"卡住后续所有人"的那个瓶颈节点，因为串行依赖链上一个慢服务可以让整个启动时间翻倍。找到后通常有三种处理方式：能并行的打断依赖、能预加载的提前启动、实在慢的优化代码本身。

### 2.13 本章面试题速查

1.  **D-Bus 中 Object Path 和 Interface 的区别是什么？**
    Object Path 类似于文件路径，用于定位资源实体。Interface 是一组属性和方法的集合，用于定义实体能做什么。
2.  **为什么 OpenBMC 不再推荐使用 phosphor-hwmon？**
    hwmon 配置静态且集中。dbus-sensors 结合 entity-manager 实现了动态发现配置，进程分离提高了故障隔离能力。
3.  **Mapper 进程挂掉会导致什么现象？**
    上层应用（如 bmcweb）无法查找 D-Bus 对象的服务提供者，导致 Redfish API 返回 500 或空数据，系统管理功能基本瘫痪。
4.  **entity-manager 是如何知道主板上插入了一个新传感器的？**
    通过 Probe 机制，如循环读取特定 I2C 地址。一旦响应数据匹配 JSON 规则，就会在 D-Bus 上创建配置对象。
5.  **在设计风扇 PID 算法时，failsafePercent 参数的作用是什么？**
    安全兜底策略。当获取温度的通道阻塞或传感器丢失时，系统假设芯片面临过热风险，强制风扇以该设定值（通常 100%）狂转。
6.  **ARM 平台和 x86 平台在系统状态管理上有什么核心差异？**
    x86 需要极其精细的 GPIO 状态机握手（使用 x86-power-control）。ARM 流程简单直接，一般用原生的 phosphor-state-manager 即可。
7.  **SDR 在现有的 OpenBMC 架构中存在本地的 .bin 文件里吗？**
    不存在。SDR 是 ipmid 进程通过查询 D-Bus 传感器状态动态构建并转换成二进制格式返回给用户的。
8.  **如何通过命令行迅速知道 /xyz/openbmc_project/state/host0 对象支持哪些方法？**
    使用 `busctl introspect <服务名> /xyz/openbmc_project/state/host0` 命令查看。
9.  **为什么我们在 evb-2u-egs 选用 x86-power-control 而不是原生的状态管理进程？**
    evb-2u-egs 是基于 Intel EGS 处理器的架构，属于典型的 x86 平台，必须严格遵循 x86 的电源引脚握手协议。
10. **bmcweb 支持哪三种认证方式？**
    Basic Auth、Session Token 验证、以及基于客户端证书的 mTLS 双向认证。

> **大白话**：这10道面试题是这章的精华提炼——就像备考驾照时背的"易错题合集"，把考官最爱问的知识点全部集中。D-Bus对象路径好比楼层门牌，接口好比该房间能提供的具体服务；Mapper像物业管理处的住户登记簿；SDR动态生成就像火车站的电子显示屏，不是提前印好的纸质时刻表，而是实时从中央系统拉数据。把这10道题答流利，面试官基本会对你刮目相看。

---

## 第三章：实战篇，手把手创建 meta-evb-2u-egs 机器层

### §3.1 机器层目录结构总览

一个完整的 OpenBMC 机器层（Machine Layer）是所有硬件定制化配置的核心。我们将基于 AST2600 A1 芯片和 evb-2u-egs 硬件定义，从零搭建 `meta-evb-2u-egs`。下面是完整的 20 个文件的目录树结构：

```text
meta-evb-2u-egs/
├── conf/
│   ├── layer.conf
│   ├── machine/
│   │   └── evb-2u-egs.conf
│   └── templates/
│       └── default/
│           ├── bblayers.conf.sample
│           ├── conf-notes.txt
│           └── local.conf.sample
├── recipes-evb-2u-egs/
│   └── packagegroups/
│       └── packagegroup-evb-2u-egs-apps.bb
├── recipes-x86/
│   └── chassis/
│       ├── x86-power-control/
│       │   └── power-config-host0.json
│       └── x86-power-control_%.bbappend
├── recipes-phosphor/
│   ├── configuration/
│   │   ├── entity-manager/
│   │   │   └── evb-2u-egs-baseboard.json
│   │   └── entity-manager_%.bbappend
│   ├── fans/
│   │   ├── phosphor-pid-control/
│   │   │   └── config.json
│   │   └── phosphor-pid-control_%.bbappend
│   ├── leds/
│   │   ├── phosphor-led-manager/
│   │   │   └── led-group-config.json
│   │   └── phosphor-led-manager_%.bbappend
│   └── ipmi/
│       ├── phosphor-ipmi-config/
│       │   └── dev_id.json
│       └── phosphor-ipmi-config.bbappend
├── recipes-kernel/
│   └── linux/
│       ├── linux-aspeed/
│       │   ├── aspeed-bmc-evb-2u-egs.dts
│       │   └── evb-2u-egs.patch
│       └── linux-aspeed_%.bbappend
└── COPYING.MIT
```

> **为什么这样做：层级命名规范**
> 目录结构严格遵循 Yocto 项目的标准规范。`conf/` 目录存放层的元数据和机器全局定义。`recipes-*` 目录按照功能模块或上游组件名划分，例如 `recipes-x86` 存放 x86 平台特有的电源控制逻辑，而 `recipes-phosphor` 存放 OpenBMC 核心应用（LED、风扇、IPMI）的定制文件。`bbappend` 文件用于在不修改上游核心代码的前提下，向镜像注入我们专有的 JSON 配置文件。

> 💡 **大白话**：把这整个目录结构想象成一家装修公司的施工文件夹。`conf/` 是项目总说明书（写明这栋楼用什么材料规格）；`recipes-phosphor/` 是各个工种的施工单（水电工、瓦工、木工各自领自己那份）；`.bbappend` 文件就像施工单旁边贴的便签纸——原始图纸不改，但贴上"这里换个插座型号"的补充说明。BitBake 就是拿着这套文件夹统筹调度的项目经理，总文件夹名（`meta-evb-2u-egs`）就是这栋楼的工程代号。

### §3.2 conf/layer.conf

这是层的主配置文件，告诉 BitBake 如何解析当前目录下的配方（recipes）。

```bash
# conf/layer.conf
# We have a conf and classes directory, add to BBPATH
BBPATH .= ":${LAYERDIR}"

# We have recipes-* directories, add to BBFILES
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
            ${LAYERDIR}/recipes-*/*/*.bbappend"

BBFILE_COLLECTIONS += "evb-2u-egs-layer"
BBFILE_PATTERN_evb-2u-egs-layer := "^${LAYERDIR}/"

LAYERSERIES_COMPAT_evb-2u-egs-layer := "wrynose whinlatter"
```

**逐行讲解：**
*   `BBPATH .= ":${LAYERDIR}"`：将当前层目录追加到 BitBake 的搜索路径中。
*   `BBFILES += ...`：告诉系统去 `recipes-*` 子目录寻找 `.bb`（全新配方）和 `.bbappend`（追加配方）文件。
*   `BBFILE_COLLECTIONS`：为当前层定义一个唯一标识符 `evb-2u-egs-layer`。
*   `BBFILE_PATTERN`：通过正则表达式划定该层包含的目录范围。注意用 `:=`（立即展开）。
*   `LAYERSERIES_COMPAT`：声明兼容的 Yocto 发行版代号。`wrynose` 和 `whinlatter` 是当前 OpenBMC 支持的两个系列。
*   **注意**：这里**没有** `BBFILE_PRIORITY` 和 `LAYERDEPENDS` — 跟模板 s6q 保持一致。简单的机器层不需要这两项，BitBake 使用默认优先级，层依赖通过 `bblayers.conf.sample` 保证。

> 💡 **大白话**：`layer.conf` 就是这栋施工文件夹的"目录索引页"。`BBPATH` 告诉 BitBake"从这里开始找文件"，`BBFILES` 告诉它"所有施工单放在 `recipes-*` 子目录里"，`BBFILE_COLLECTIONS` 给这个层贴上一个唯一工号，`LAYERSERIES_COMPAT` 则像产品认证标签——声明这份文件兼容哪些版本的建筑规范。没有这个索引页，BitBake 进了文件夹就像进了无标识的仓库，找不到任何东西。

### §3.3 conf/machine/evb-2u-egs.conf

这是定义硬件平台规格的最核心文件，BitBake 初始化的起点。

```bash
# conf/machine/evb-2u-egs.conf
KMACHINE = "aspeed"
KERNEL_DEVICETREE = "aspeed/aspeed-bmc-evb-2u-egs.dtb"
UBOOT_MACHINE = "ast2600_openbmc_defconfig"
UBOOT_DEVICETREE = "ast2600a1-evb"

require conf/machine/include/ast2600.inc
require conf/machine/include/obmc-bsp-common.inc

MACHINEOVERRIDES =. "evb-2u-egs:"

FLASH_SIZE = "65536"

SERIAL_CONSOLES = "115200;ttyS4"

MACHINE_FEATURES += "\
        obmc-phosphor-chassis-mgmt \
        obmc-fan-control \
        obmc-phosphor-flash-mgmt \
        obmc-host-ipmi \
        obmc-host-state-mgmt \
        obmc-chassis-state-mgmt \
        obmc-bmc-state-mgmt \
        "

VIRTUAL-RUNTIME_obmc-host-state-manager ?= "x86-power-control"
VIRTUAL-RUNTIME_obmc-chassis-state-manager ?= "x86-power-control"
VIRTUAL-RUNTIME_obmc-discover-system-state ?= "x86-power-control"
VIRTUAL-RUNTIME_obmc-fan-control ?= "phosphor-pid-control"

VIRTUAL-RUNTIME_obmc-inventory-manager = "entity-manager"
PREFERRED_PROVIDER_virtual/obmc-inventory-data = "entity-manager"

PREFERRED_PROVIDER_virtual/obmc-chassis-mgmt = "packagegroup-evb-2u-egs-apps"
PREFERRED_PROVIDER_virtual/obmc-flash-mgmt = "packagegroup-evb-2u-egs-apps"
PREFERRED_PROVIDER_virtual/obmc-system-mgmt = "packagegroup-evb-2u-egs-apps"

PREFERRED_PROVIDER_virtual/obmc-host-ipmi-hw ?= "phosphor-ipmi-kcs"
```

> **面试要点：MACHINEOVERRIDES 的作用是什么？**
> `MACHINEOVERRIDES =. "evb-2u-egs:"`（注意前导点号 `.` 表示前置追加）将具体的机器名压入覆盖栈。当系统解析如 `SRC_URI:evb-2u-egs` 的变量时，由于覆盖机制，它会特异性地选中当前机器的值。注意：如果不手动写 MACHINEOVERRIDES，BitBake 也会自动将 `${MACHINE}` 加入 OVERRIDES。手动写可以添加额外的覆盖名。

> 💡 **大白话**：BitBake 默认已经会把 `${MACHINE}`（如 `evb-2u-egs`）自动加入 OVERRIDES 列表，所以机器专属的变量覆盖天然生效。这里手动写 `MACHINEOVERRIDES =. "evb-2u-egs:"` 的作用是**额外追加一个别名标签**——就像你除了身份证之外又办了一张工牌，两个名字都能用来"刷卡通行"。如果你的机器名和想在配方里使用的覆盖名完全一致，这行甚至可以省略；但如果你想添加额外的覆盖名（比如平台族名 `intel-egs`），就必须手动写。

**逐行讲解：**
*   `require conf/machine/include/ast2600.inc`：引入 ASPEED AST2600 SoC 的基础定义（CPU 架构、编译器优化参数等）。
*   `UBOOT_MACHINE` / `UBOOT_DEVICETREE`：指定 u-boot 的默认配置与设备树。
*   `KERNEL_DEVICETREE`：指定 Linux 内核编译出来的设备树名称，它决定了内核启动时加载的硬件拓扑。
*   `FLASH_SIZE = "65536"`：根据硬件文档，我们有两颗 64MB w25q512 芯片，采用双 bank 主备冗余（总 128MB）。FLASH_SIZE 配置的是单个 bank（= 构建镜像）的大小，65536 KB = 64MB。
*   `SERIAL_CONSOLES = "115200;ttyS4"`：这是系统控制台。AST2600 的 ast2600.inc 已经用 `?=` 设了相同值，这里用 `=` 显式声明使其更清晰，也防止被其他层意外覆盖。
*   `MACHINE_FEATURES`：通过功能标志位，决定在基础镜像中安装哪些包组。特别注意：我们用 `obmc-fan-control`（现代方式，直接映射到 `packagegroup-obmc-apps-fan-control`），而非已弃用的 `obmc-phosphor-fan-mgmt`。Feature 名字的规律：带 `obmc-phosphor-` 前缀的走 COMBINED_FEATURES 间接机制，不带前缀的走直接 FEATURE_PACKAGES 映射。
*   `VIRTUAL-RUNTIME`：这是 OpenBMC 框架留给厂商的扩展点。通过覆盖虚拟运行时，我们将默认的 phosphor-state-manager 替换为 Intel 开发的 `x86-power-control` 服务。同时用 `=`（硬赋值）强制绑定 entity-manager 为库存管理器。
*   `PREFERRED_PROVIDER`：指定功能组的提供者。此处统一定向到我们将要编写的 `packagegroup-evb-2u-egs-apps`，由它集中拉取所有依赖。
*   `PREFERRED_PROVIDER_virtual/obmc-host-ipmi-hw`：使用 KCS（Keyboard Controller Style）作为 IPMI 硬件通道，这是 x86 平台标准。

> 💡 **大白话**：`machine.conf` 是这台服务器的"装机配置单+功能申报表"。`require ast2600.inc` 就是继承父类，把芯片厂的公共参数直接拿来用，不用重写一遍。`MACHINE_FEATURES` 相当于勾选安装哪些 App——勾了 `obmc-fan-control`，系统就自动拉进风扇控制包。`VIRTUAL-RUNTIME` 是个下拉菜单，把"默认风扇管家"替换成"指定的 x86 电源控制服务"。整张表填完，BitBake 就知道要给这台机器组装成什么样子了。

#### 🔬 深入：MACHINE_FEATURES 与 VIRTUAL-RUNTIME/PREFERRED_PROVIDER 的映射关系

上面的 `machine.conf` 中有两组关键配置，它们体现了 Yocto（OpenBMC 构建系统）中 **"需求声明（接口）"** 与 **"具体实现（后端）"** 的分层设计。

**核心思想**：
* **`MACHINE_FEATURES`** 负责举手说：**"我的这块主板需要哪些功能？"**（定义需求）。
* **`VIRTUAL-RUNTIME` / `PREFERRED_PROVIDER`** 负责回答：**"既然你需要这个功能，那具体用哪个软件包来实现它？"**（指定实现）。

OpenBMC 的架构高度模块化。为了让不同的硬件平台能复用同一套代码，它抽象出了很多"虚拟包（virtual packages）"。两部分的配合机制如下：

**第一层：MACHINE_FEATURES — 声明所需功能（What to do）**

在 machine.conf 中，你列出当前 BMC 需要支持的各种顶层特性：
* `obmc-chassis-state-mgmt`：需要"机箱状态管理"功能
* `obmc-host-state-mgmt`：需要"主机（Host）状态管理"功能
* `obmc-fan-control`：需要"风扇控制"功能

当你在 `MACHINE_FEATURES` 中加入这些特性，Yocto 构建系统就会去寻找提供这些功能的虚拟包并安装它们。

**第二层：VIRTUAL-RUNTIME / PREFERRED_PROVIDER — 指定具体包（How to do it）**

如果只有需求声明，Yocto 会使用 OpenBMC 社区标准的默认实现（例如 phosphor-state-manager）。但不同厂商（比如我们的 evb-2u-egs 项目）通常有自己的硬件逻辑或特定软件栈，需要用这些变量去**覆盖（Override）**默认提供者：

* **`VIRTUAL-RUNTIME_...`**：指定运行时执行的守护进程（安装时多选一）
* **`PREFERRED_PROVIDER_...`**：告诉 BitBake 在遇到虚拟包依赖时，编译哪一个具体配方（编译时多选一）

**第三层：两者的具体映射（以我们的 machine.conf 为例）**

| 需求（MACHINE_FEATURES） | 实现（VIRTUAL-RUNTIME / PREFERRED_PROVIDER） | 为什么这样选 |
|---|---|---|
| `obmc-host-state-mgmt` + `obmc-chassis-state-mgmt` | `VIRTUAL-RUNTIME_obmc-host-state-manager ?= "x86-power-control"` | 我们是 x86 主机，需要专为 x86 设计的电源/状态控制，而非默认的 phosphor-state-manager |
| （传感器与资产盘点） | `VIRTUAL-RUNTIME_obmc-inventory-manager = "entity-manager"` + `PREFERRED_PROVIDER_virtual/obmc-inventory-data = "entity-manager"` | 使用 Intel 主导的 entity-manager 动态配置机制管理传感器和硬件资产，而非静态 JSON |
| `obmc-fan-control`、`obmc-flash-mgmt`、`obmc-chassis-mgmt` 等 | `PREFERRED_PROVIDER_virtual/obmc-*-mgmt = "packagegroup-evb-2u-egs-apps"` | 将这些功能统一指向我们的定制包组，由它集中拉取所有依赖 |
| `obmc-host-ipmi` | `PREFERRED_PROVIDER_virtual/obmc-host-ipmi-hw ?= "phosphor-ipmi-kcs"` | x86 平台标准 IPMI 硬件通道是 KCS（Keyboard Controller Style） |

> 💡 **大白话**：打个比方——`MACHINE_FEATURES` 就像餐厅的**菜单分类**（本店提供：汤、主菜、甜点）。`PREFERRED_PROVIDER`/`VIRTUAL-RUNTIME` 则是**厨师的具体菜谱**（主菜上"x86-power-control 牛排"，甜点上"entity-manager 蛋糕"）。菜单上勾了什么品类，厨房就做对应的菜；但同一品类可以换不同的做法——默认菜谱不好吃？换一个就行，前台（MACHINE_FEATURES）完全不用改。这就是"需求与实现解耦"的威力：换硬件平台只需要换菜谱（VIRTUAL-RUNTIME），菜单结构（MACHINE_FEATURES）基本不变。

> **面试加分点**："为什么 OpenBMC 要搞这么复杂的两层映射？直接写死不行吗？"
> **答**：因为 OpenBMC 要支持 76+ 种不同硬件平台。如果把实现写死，每增加一个平台就要改核心层代码。两层映射的好处是：核心层（meta-phosphor）只定义抽象接口，每个厂商层只需要填写自己的"菜谱"即可——互不干扰，独立开发，独立维护。这正是面向接口编程（Interface-based programming）在构建系统中的体现。

#### 🔬 深入：PREFERRED_PROVIDER 与 VIRTUAL-RUNTIME 到底有什么区别？

这两者都是 Yocto 构建系统中处理"抽象接口 → 具体实现"映射的变量，但它们作用的**阶段**和**对象**截然不同。

**最核心的一句话：`PREFERRED_PROVIDER` 决定"编译什么"（Build-time），而 `VIRTUAL-RUNTIME` 决定"安装什么"（Run-time）。**

**PREFERRED_PROVIDER：解决编译时的配方冲突**

当你需要编译一个组件，而这个组件依赖一个通用功能（比如 `virtual/kernel` 或 `virtual/obmc-flash-mgmt`），Yocto 会去寻找谁能提供这个功能。如果有多个配方（Recipe）都声明自己能提供，Yocto 就会报错（冲突）。

* **作用阶段**：BitBake 的解析与编译阶段（Parse & Build）
* **作用对象**：虚拟包（Virtual Packages），通常以 `virtual/` 开头
* **职责**：告诉系统，"当遇到依赖 `virtual/xxx` 时，请去拉取并编译 `yyy` 这个配方的源代码"

```bitbake
PREFERRED_PROVIDER_virtual/kernel = "linux-aspeed"
```
含义：当任何软件在编译时需要依赖 Linux 内核源码头文件或接口时，系统必须去编译 `linux-aspeed` 这个配方，而不是标准的 `linux-yocto` 或 `linux-dummy`。

**VIRTUAL-RUNTIME：决定运行时的实际安装包**

在软件编译完成并打包后（生成 `.ipk` 文件），Yocto 需要把这些包组装成最终烧录到板子上的根文件系统（RootFS）。此时，某些基础组件（如 packagegroup）只定义了系统需要一个"风扇管理器"，但没说具体装哪个。

* **作用阶段**：构建根文件系统镜像阶段（Image Rootfs Generation）
* **作用对象**：软件包（Packages/Daemons），最终在 Linux 系统里跑的守护进程或工具
* **职责**：告诉系统，"在打包最终镜像时，请把 `xxx` 这个实际的二进制软件包安装到系统里"

```bitbake
VIRTUAL-RUNTIME_obmc-inventory-manager = "entity-manager"
```
含义：最终烧录进 BMC 的系统里，负责资产盘点的守护进程是 `entity-manager` 的执行文件，而不是其他默认的守护进程。

**核心对比总结**

| 特性 | `PREFERRED_PROVIDER` | `VIRTUAL-RUNTIME` |
|---|---|---|
| **主要目标** | 决定使用哪个 **源码配方 (Recipe)** 进行编译 | 决定将哪个 **二进制包 (Package)** 安装到镜像 |
| **生效阶段** | 编译期 (Build Time) | 镜像打包期 (Image/Rootfs Time) |
| **通常赋值** | 配方的名字 (如 `phosphor-ipmi-kcs`) | 软件包的名字 (如 `x86-power-control`) |
| **左侧变量名** | 通常包含 `virtual/` (如 `virtual/obmc-chassis-mgmt`) | 通常是一个功能代号 (如 `obmc-host-state-manager`) |

> 💡 **大白话**：假设你要组装一台电脑（构建固件镜像）。`PREFERRED_PROVIDER` 是你在**工厂图纸阶段**的决定："用哪家代工厂的图纸来生产显卡？"（决定源码怎么编译出组件）。`VIRTUAL-RUNTIME` 是你在**最终装箱阶段**的决定："发货给客户的主机箱里，实际插上哪块已经生产好的显卡？"（决定最终安装哪个可运行的程序）。在 OpenBMC 中，这两者经常成对出现——既要编译某个特定的底层实现，又要把编译出来的守护进程实际安装到文件系统中。

#### 🔬 深入：什么时候需要配置？什么时候不需要？

**核心答案：并不是每一项 MACHINE_FEATURES 都需要配置 PREFERRED_PROVIDER / VIRTUAL-RUNTIME。**

到底该配哪个，是由 OpenBMC 底层的 Yocto 类文件（`.bbclass`）和包组（`packagegroup`）的源码写法决定的。

**为什么不需要每一项都配置？**

因为 OpenBMC 社区已经为你准备好了**"默认套餐"**。

当你在 `MACHINE_FEATURES` 里写下 `obmc-host-state-mgmt` 时，Yocto 会去底层配置文件（通常在 `meta-phosphor/conf/distro/include/phosphor-defaults.inc`）中寻找默认值。默认情况下，社区用 `phosphor-state-manager` 来实现它。

**你只有在以下情况才需要配置：**
* 你不想用社区的默认程序（比如不用 phosphor 默认的电源管理，想用 `x86-power-control`）
* 这个功能根本没有默认程序，必须由各厂商自己实现（比如你们自家的特定风扇控制逻辑）

比如 `bonding`（网卡绑定），它依赖 Linux 内核和 systemd-networkd 的原生功能，**完全不需要**配置 `PREFERRED_PROVIDER` 或 `VIRTUAL-RUNTIME`。

**三条判断法则：**

**法则 A：纯运行时守护进程 → 用 `VIRTUAL-RUNTIME`**

如果某个功能只是一支后台运行的程序（Daemon），其他程序不需要在编译时去链接它的源码头文件，只需要它在运行时通过 D-Bus 提供服务。

* **识别标志**：底层配方里写着 `RDEPENDS:${PN} += "${VIRTUAL-RUNTIME_xxx}"`
* **例子**：状态管理 — `x86-power-control` 是独立运行的进程，别的程序只要知道 D-Bus 接口就行。所以用 `VIRTUAL-RUNTIME_obmc-host-state-manager = "x86-power-control"`

**法则 B：需要被其他模块编译依赖的接口 → 用 `PREFERRED_PROVIDER`**

如果某个功能是一组库文件、头文件，或者是一个虚拟的组件分类，其他程序在编译时必须先把它编译出来才能继续。

* **识别标志**：底层配方里写着 `DEPENDS += "virtual/xxx"`。看到 `virtual/` 前缀，就 **100% 必须用** `PREFERRED_PROVIDER`
* **例子**：IPMI 硬件接口 — 底层 IPMI 守护进程编译时必须知道对应哪种硬件通道。所以用 `PREFERRED_PROVIDER_virtual/obmc-host-ipmi-hw = "phosphor-ipmi-kcs"`

**法则 C：大包大揽的"功能包组" → 也用 `PREFERRED_PROVIDER`**

为了方便管理，OpenBMC 会把一类功能定义为虚拟组件（如 `virtual/obmc-chassis-mgmt`），你作为厂商写一个 `packagegroup-evb-2u-egs-apps` 里面打包了风扇、LED、传感器等所有该机箱需要的杂项。

* 将"抽象接口"指向"具体包组"的操作，使用 `PREFERRED_PROVIDER`

> 💡 **大白话**：`MACHINE_FEATURES` 是点菜。只有当你对"默认大厨"做的菜不满意、想换成"自家大厨"时，才需要配置。换的是"运行的独立进程"就用 `VIRTUAL-RUNTIME`（换服务员）；换的是"编译依赖的虚拟包或接口"就用 `PREFERRED_PROVIDER`（换食材供应商，认准 `virtual/` 前缀）。大部分 feature 用社区默认值就够了，你只需要操心那几个确实要定制的。

#### 🔧 实操：授人以渔的排查方法

如果你拿到一个全新的 `MACHINE_FEATURES`（比如 `obmc-phosphor-fan-mgmt`），不知道该怎么配，可以用以下方法在 OpenBMC 源码中排查：

**步骤 1：搜它依赖了什么虚拟包或运行时变量**

```bash
grep -rn "obmc-phosphor-fan-mgmt" meta-phosphor/
```

你通常会找到一个文件叫 `meta-phosphor/classes/obmc-phosphor-fan-mgmt.bbclass`。

**步骤 2：打开这个 bbclass 文件查看**

在里面你会看到类似这样的代码：

```bitbake
# 场景一：看到 VIRTUAL-RUNTIME
VIRTUAL-RUNTIME_obmc-phosphor-fan-ctl ?= "phosphor-fan-control"
RDEPENDS:${PN} += "${VIRTUAL-RUNTIME_obmc-phosphor-fan-ctl}"
```

**解读**：这里用的是 `VIRTUAL-RUNTIME`，默认值是 `phosphor-fan-control`。如果要换掉它，在 `machine.conf` 里写 `VIRTUAL-RUNTIME_obmc-phosphor-fan-ctl = "my-custom-fan-app"`。

```bitbake
# 场景二：看到 virtual/ 前缀
PROVIDES += "virtual/obmc-fan-mgmt"
```

**解读**：这里定义了一个虚拟提供者。如果要完全接管风扇管理，写 `PREFERRED_PROVIDER_virtual/obmc-fan-mgmt = "my-packagegroup"`。

**总结口诀**：
* 搜 `RDEPENDS` + `VIRTUAL-RUNTIME` → 说明是运行时可替换守护进程
* 搜 `DEPENDS` + `virtual/` → 说明是编译时可替换接口实现
* 搜 `PROVIDES` + `virtual/` → 说明这个配方声称自己能提供某虚拟接口

> 💡 **大白话**：你不需要死记硬背哪个 feature 对应哪个变量。拿到一个陌生的 feature 名字，直接在 `meta-phosphor/` 里 `grep` 一把，看它底层用的是 `VIRTUAL-RUNTIME`（换服务员）还是 `virtual/`（换食材），答案自然就出来了。这就是"看源码比看文档靠谱"的嵌入式开发真理。

#### 🔬 深入：Packagegroup — "全家桶"的威力

你可能注意到了，上面的 `machine.conf` 中有好几个 `PREFERRED_PROVIDER` 都指向了同一个目标——`packagegroup-evb-2u-egs-apps`。这不是偷懒，而是一个精心设计的"全家桶"策略。

**Packagegroup 的本质**

在 Yocto 构建系统中，`packagegroup` 是一种非常特殊的配方。它本身**没有任何实质性的代码**（没有 C/C++ 源码，不需要编译生成二进制文件），它的本质就是一张**"购物清单"**——类似于 Ubuntu/Debian 系统里的 meta-package。

**为什么需要"一网打尽"？**

我们的 evb-2u-egs 主板（基于 AST2600）有自己的定制需求，厂商会为它编写一系列专属的小程序：
* 专属的风扇转速调节程序
* 专属的 LED 闪烁控制逻辑
* 专属的固件刷写工具
* 专属的 OEM IPMI 命令处理器

如果在镜像配置里一个个指定这些程序，配置文件会变得又长又难维护。于是，厂商建一个清单叫 `packagegroup-evb-2u-egs-apps`，在里面写上：

> "只要有人安装我这个全家桶，就必须同时安装风扇程序 A、LED 程序 B、刷写工具 C……"

**实际对话过程**

当你在 `machine.conf` 里写了：

```bitbake
PREFERRED_PROVIDER_virtual/obmc-fan-mgmt = "packagegroup-evb-2u-egs-apps"
PREFERRED_PROVIDER_virtual/obmc-flash-mgmt = "packagegroup-evb-2u-egs-apps"
```

Yocto 系统内部的"对话"是这样的：

* **Yocto**："主板老兄，你的 `MACHINE_FEATURES` 里说你需要风扇管理（`obmc-fan-mgmt`），你想装哪个风扇程序？"
* **你的配置**："别麻烦了，直接把我那个叫 `packagegroup-evb-2u-egs-apps` 的**全家桶**提溜进去吧！里面有我要的风扇程序。"
* **Yocto**："那你还需要闪存管理（`obmc-flash-mgmt`），这个装哪个？"
* **你的配置**："还是直接装**全家桶**！里面也有我要的闪存工具。"

**这样做的巨大好处**

1. **极度解耦，方便维护**：如果以后 evb-2u-egs 主板硬件升级了，需要额外加一个温度监控告警工具，工程师**完全不需要**去改 `machine.conf`。只需在 `packagegroup-evb-2u-egs-apps` 的清单里加上新工具的名字，下次编译就自动打包进去。
2. **统一平台级行为**：这种做法在 ODM/OEM 厂商（如 Quanta、Wiwynn 等）中非常常见——把一整块主板特有的业务逻辑打包成一个 group，确保不会漏掉任何一个关键守护进程。
3. **保持 machine.conf 简洁**：machine.conf 只负责"点菜"（声明需要哪些功能），packagegroup 负责"备料"（列出具体程序清单），职责分明。

> 💡 **大白话**：Packagegroup 就是超市的"火锅套餐"——你不用自己挑毛肚、牛肉、蘑菇、豆腐皮，直接拿一个套餐包，里面什么都有。`machine.conf` 只说"我要吃火锅"（MACHINE_FEATURES），`PREFERRED_PROVIDER` 只说"去哪家的套餐"（指向 packagegroup），`packagegroup` 里面才写着"毛肚200g、牛肉300g、蘑菇一盒……"的具体清单。以后想加鱼豆腐？往套餐清单里加一行就行，不用改火锅锅底配方（machine.conf）。

### §3.4 conf/templates/default/

这三个文件用于在开发者运行 `. setup evb-2u-egs` 时，初始化 `build/` 目录中的环境变量。

**文件一：bblayers.conf.sample**

```bash
# conf/templates/default/bblayers.conf.sample
LCONF_VERSION = "8"
BBPATH = "${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \
  ${OEROOT}/meta \
  ${OEROOT}/meta-openembedded/meta-oe \
  ${OEROOT}/meta-openembedded/meta-networking \
  ${OEROOT}/meta-openembedded/meta-python \
  ${OEROOT}/meta-phosphor \
  ${OEROOT}/meta-aspeed \
  ${OEROOT}/meta-evb-2u-egs \
  "
```
这个文件定义了 BitBake 的 layer 搜索路径。注意 OpenBMC 的 `setup` 脚本会根据 TEMPLATECONF 自动生成实际的 `bblayers.conf`，因此此模板必须与 `setup` 脚本兼容。底层 OS 层（meta, meta-oe）在最上，OpenBMC 核心层（meta-phosphor）和 SoC 层（meta-aspeed）之后，我们自己的 `meta-evb-2u-egs` 层在最下。

> 💡 **大白话**：`bblayers.conf.sample` 就像入职时发给新员工的"办公楼平面图"，告诉你各个部门（layer）在哪栋楼哪个楼层。越靠下的层优先级越高（后来者居上），所以我们的 `meta-evb-2u-egs` 放在最后，保证自定义配置能覆盖通用层里的默认值。

**文件二：local.conf.sample**

```bash
# conf/templates/default/local.conf.sample
MACHINE ??= "evb-2u-egs"
DISTRO ?= "openbmc-phosphor"
PACKAGE_CLASSES ?= "package_ipk"
SANITY_TESTED_DISTROS:append ?= " *"
EXTRA_IMAGE_FEATURES ?= "allow-root-login"
USER_CLASSES ?= "buildstats"
PATCHRESOLVE = "noop"
BB_DISKMON_DIRS = "\
    STOPTASKS,${TMPDIR},1G,100K \
    STOPTASKS,${DL_DIR},1G,100K \
    STOPTASKS,${SSTATE_DIR},1G,100K \
    STOPTASKS,/tmp,100M,100K \
    ABORT,${TMPDIR},100M,1K \
    ABORT,${DL_DIR},100M,1K \
    ABORT,${SSTATE_DIR},100M,1K \
    ABORT,/tmp,10M,1K"
CONF_VERSION = "2"
```
`MACHINE ??= "evb-2u-egs"` 是关键：如果环境变量没有特别指定，就默认编译 evb-2u-egs。

> 💡 **大白话**：`local.conf.sample` 是新员工入职后填写的"个人工位偏好表"——指定用哪台机器（MACHINE）、用哪种打包格式（PACKAGE_CLASSES=ipk 就像快递选择顺丰还是圆通）、磁盘快满了停下来别继续构建（BB_DISKMON_DIRS 是低电量自动关机保护）。`??=` 双问号赋值的意思是"环境变量已经有值就不覆盖"，就像偏好表上的默认选项——你不改就用默认值，改了就用你填的。

**文件三：conf-notes.txt**

```text
Common targets are:
     obmc-phosphor-image

You can also run generated qemu images with a command like:
     runqemu qemuarm
```
这是执行 setup 脚本后打印在终端的提示信息，引导新手执行正确的 bitbake 命令。

### §3.5 packagegroup-evb-2u-egs-apps.bb

Packagegroup（包组）是将一堆零散的软件包打包安装的机制，避免让镜像文件（image 配方）变得臃肿。

```bash
# recipes-evb-2u-egs/packagegroups/packagegroup-evb-2u-egs-apps.bb
SUMMARY = "OpenBMC for EVB 2U EGS system - Applications"
PR = "r1"

inherit packagegroup

PROVIDES = "${PACKAGES}"
PACKAGES = " \
        ${PN}-chassis \
        ${PN}-fans \
        ${PN}-flash \
        ${PN}-system \
        "

PROVIDES += "virtual/obmc-chassis-mgmt"
PROVIDES += "virtual/obmc-fan-control"
PROVIDES += "virtual/obmc-flash-mgmt"
PROVIDES += "virtual/obmc-system-mgmt"

RPROVIDES:${PN}-chassis = "virtual-obmc-chassis-mgmt"
RPROVIDES:${PN}-fans = "virtual-obmc-fan-control"
RPROVIDES:${PN}-flash = "virtual-obmc-flash-mgmt"
RPROVIDES:${PN}-system = "virtual-obmc-system-mgmt"

RDEPENDS:${PN}-chassis = " \
        x86-power-control \
        "

RDEPENDS:${PN}-fans = " \
        phosphor-pid-control \
        "

RDEPENDS:${PN}-flash = " \
        phosphor-software-manager \
        "

RDEPENDS:${PN}-system = " \
        entity-manager \
        webui-vue \
        phosphor-ipmi-ipmb \
        phosphor-host-postd \
        "
```

> **为什么这样做：VIRTUAL-RUNTIME 解析链**
> 当我们执行 `bitbake obmc-phosphor-image` 时，镜像配置要求安装 `virtual/obmc-chassis-mgmt`。BitBake 去查 `PREFERRED_PROVIDER` 发现是指向 `packagegroup-evb-2u-egs-apps`，进一步解析它的 `PROVIDES` 列表，最终将 `x86-power-control`、`entity-manager` 等实体包（由 `RDEPENDS` 定义）链入最终的文件系统根目录中。

> 💡 **大白话**：Packagegroup 就是餐厅的"套餐"机制。镜像文件（image 配方）是点了"商务套餐"的客人，它不需要逐一点菜，只要告诉服务员"我要 A 套餐"。服务员（BitBake）查菜单，发现 A 套餐包含了底座管理、风扇控制、固件升级等一系列单品。`RPROVIDES` 是后厨实际出品的品项标签，`RDEPENDS` 是这道套餐依赖哪些原材料（实体软件包）。这样镜像文件只需要一行"点套餐"，而不是列一张几十行的清单。

### §3.6 x86-power-control 配置（电源序列控制）

AMI MegaRAC 中的电源时序由 `PDKHW.c` 里的死循环逻辑控制。在 OpenBMC 中，我们使用由 JSON 驱动的状态机 `x86-power-control`。

```bash
# recipes-x86/chassis/x86-power-control_%.bbappend
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://power-config-host0.json"

do_install:append() {
    install -m 0755 -d ${D}${datadir}/${PN}
    install -m 0644 -p ${UNPACKDIR}/power-config-host0.json ${D}${datadir}/${PN}/
}
```

> 💡 **大白话**：这个 `.bbappend` 文件就像在上游工程师的施工单旁边贴了一张便签纸："在安装 x86-power-control 这个软件时，顺便把我们写的 `power-config-host0.json` 配置文件也一起塞进去。" `FILESEXTRAPATHS:prepend` 告诉 BitBake"先到我这个目录里找文件"，这样我们自己放的 JSON 才能被 `SRC_URI` 找到。`do_install:append` 则是在安装阶段结束时，额外执行"把 JSON 文件复制到目标系统的指定目录"这个动作。

我们要将硬件定义文档里的 GPIO 映射转换成 JSON 格式。非常关键的是 ActiveLow 还是 ActiveHigh。

```json
{
    "Name": "evb-2u-egs power config",
    "GpioConfigs": [
        {
            "Name": "PowerOut",
            "LineName": "power-button-out",
            "Type": "GPIO",
            "Polarity": "ActiveLow"
        },
        {
            "Name": "ResetOut",
            "LineName": "reset-out",
            "Type": "GPIO",
            "Polarity": "ActiveLow"
        },
        {
            "Name": "PowerOk",
            "LineName": "power-ok",
            "Type": "GPIO",
            "Polarity": "ActiveHigh"
        },
        {
            "Name": "PostComplete",
            "LineName": "post-complete",
            "Type": "GPIO",
            "Polarity": "ActiveHigh"
        }
    ],
    "TimingConfigs": {
        "PowerPulseMs": 1000,
        "ResetPulseMs": 1000,
        "ForceOffPulseMs": 6000,
        "PowerCycleMs": 10000
    }
}
```
**JSON 字段解析：**
*   根据硬件定义文档，PowerOut 是 GPIO69（GPIOI5），ResetOut 是 GPIO121（GPIOP1），二者均为拉低有效（ActiveLow）。
*   PowerOk（GPIO47/GPIOF7）则是主板电源好的标志位，ActiveHigh 表示高电平代表电源正常。
*   `TimingConfigs` 中的 `ForceOffPulseMs: 6000` 表示长按电源键强制关机需要 6 秒。

> 💡 **大白话**：这份 JSON 就是电源控制的"遥控器按钮说明书"。每个 GPIO 引脚就是遥控器上的一个按钮，`Polarity: ActiveLow` 意味着"按下去（拉低电平）才有效"，就像某些遥控器的按钮要长按才触发。`TimingConfigs` 则是按钮的时间规则：短按 1 秒开机、长按 6 秒强制关机——这跟你家台式机的电源键逻辑完全一样，只不过现在是用 JSON 配置文件来定义这些规则，而不是固化在硬件里。

### §3.7 entity-manager 配置（传感器与总线设备扫描）

实体管理器通过扫描总线上的 I2C 地址，动态加载对应的传感器配置。

```bash
# recipes-phosphor/configuration/entity-manager_%.bbappend
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://evb-2u-egs-baseboard.json"

do_install:append() {
    install -d ${D}${datadir}/entity-manager/configurations
    install -m 0444 ${UNPACKDIR}/evb-2u-egs-baseboard.json ${D}${datadir}/entity-manager/configurations/
}
```

我们的硬件平台传感器丰富，完整的 `evb-2u-egs-baseboard.json` 约 758 行。这里按类别展示关键片段，帮助理解 JSON 的结构设计。

**① AST2600 内置 ADC 传感器（16 路）：**

前 8 路监控核心电压，带完整告警阈值；后 8 路预留（Spare）。

```json
{
    "Exposes": [
        {
            "Index": 0,
            "Name": "P12V_STBY",
            "ScaleFactor": 0.108696,
            "Thresholds": [
                { "Direction": "greater than", "Name": "upper critical", "Severity": 1, "Value": 13.2 },
                { "Direction": "greater than", "Name": "upper non critical", "Severity": 0, "Value": 12.84 },
                { "Direction": "less than", "Name": "lower non critical", "Severity": 0, "Value": 11.16 },
                { "Direction": "less than", "Name": "lower critical", "Severity": 1, "Value": 10.8 }
            ],
            "Type": "ADC"
        },
        { "Index": 1, "Name": "P5V_STBY", "ScaleFactor": 0.27027, "Type": "ADC", "Thresholds": ["...同上结构..."] },
        { "Index": 2, "Name": "P3V3_STBY", "ScaleFactor": 0.5, "Type": "ADC", "Thresholds": ["..."] },
        { "Index": 3, "Name": "P1V8_STBY", "ScaleFactor": 0.75188, "Type": "ADC", "Thresholds": ["..."] },
        { "Index": 4, "Name": "P1V15_STBY", "Type": "ADC", "Thresholds": ["..."] },
        { "Index": 5, "Name": "P1V05_PCH", "PowerState": "On", "Type": "ADC", "Thresholds": ["..."] },
        { "Index": 6, "Name": "PVCCIN_CPU0", "CPURequired": 1, "PowerState": "On", "Type": "ADC", "Thresholds": ["..."] },
        { "Index": 7, "Name": "PVCCIN_CPU1", "CPURequired": 2, "PowerState": "On", "Type": "ADC", "Thresholds": ["..."] },
        { "Index": 8, "Name": "ADC_CH8_Spare", "Type": "ADC" },
        "... 9~15 均为 Spare ..."
    ],
    "Name": "evb-2u-egs Baseboard",
    "Probe": "TRUE",
    "Type": "Board"
}
```

> 💡 **大白话**：AST2600 芯片自带 16 路模数转换器（ADC），就像万用表可以量 16 个电压。`Index: 0` 是第 0 号探头，量的是 12V 待机电压。`ScaleFactor: 0.108696` 是个分压比——实际 12V 经过电阻分压后变成 ADC 能读的小电压，所以需要乘以这个系数还原成真实值。`Thresholds` 就是报警线：12V 电压如果超过 13.2V 就是"严重超高"（upper critical），低于 10.8V 就是"严重过低"（lower critical）。`PowerState: "On"` 表示这个传感器只在主机开机后才有效——你总不能在关机时去量 CPU 核心电压吧？`CPURequired: 1` 则是说"只有 CPU0 安装了，这个传感器才有意义"。

**② 板载温度传感器（6 颗 TMP75）：**

分布在进风口、主板前后、系统板、排风口和出风口，覆盖整机气流通道。

```json
        { "Address": "0x48", "Bus": 21, "Name": "Inlet_Temp", "Type": "TMP75",
          "Thresholds": [
              { "Direction": "greater than", "Name": "upper critical", "Severity": 1, "Value": 45 },
              { "Direction": "greater than", "Name": "upper non critical", "Severity": 0, "Value": 40 },
              { "Direction": "less than", "Name": "lower non critical", "Severity": 0, "Value": 5 },
              { "Direction": "less than", "Name": "lower critical", "Severity": 1, "Value": 0 }
          ]
        },
        { "Address": "0x4b", "Bus": 22, "Name": "MB_Inlet_Temp", "Type": "TMP75", "Thresholds": ["...85/75/5/0..."] },
        { "Address": "0x4a", "Bus": 22, "Name": "MB_Outlet_Temp", "Type": "TMP75", "Thresholds": ["...85/75/5/0..."] },
        { "Address": "0x48", "Bus": 7,  "Name": "SYS_Board_Temp", "Type": "TMP75", "Thresholds": ["...85/75/5/0..."] },
        { "Address": "0x4d", "Bus": 8,  "Name": "Exhaust_Temp", "Type": "TMP75", "Thresholds": ["...75/65/5/0..."] },
        { "Address": "0x48", "Bus": 13, "Name": "Outlet_Temp", "Type": "TMP75", "Thresholds": ["...75/65/5/0..."] },
```

> 💡 **大白话**：6 颗温度传感器就是 6 个"体温计"，插在服务器不同位置。`Inlet_Temp`（进风口）上限 45°C 很严格——因为进来的风已经热了，说明机房空调有问题。而 `MB_Outlet_Temp`（主板出风侧）允许到 85°C——因为风经过 CPU 加热后自然变烫。`Bus: 21` 是 DTS 中 I2C MUX 展开后的虚拟总线号，不是物理引脚。注意：同一个地址 `0x48` 在不同 Bus 上可以出现多次，因为 I2C 地址只需要在同一条总线上唯一。

**③ 硬件监控芯片（LM87 + ADT7475）和模拟信号采集（AD5593R）：**

```json
        { "Address": "0x2d", "Bus": 7, "Name": "SYS_HWMon_LM87", "Type": "LM87",
          "Thresholds": ["...105/95/5/0..."] },
        { "Address": "0x2e", "Bus": 7, "Name": "SYS_HWMon_ADT7475", "Type": "ADT7475",
          "Thresholds": ["...105/95/5/0..."] },
        { "Address": "0x10", "Bus": 20, "Name": "AD5593R_Board_Voltages", "Type": "AD5593R" },
        { "Address": "0x11", "Bus": 20, "Name": "AD5593R_VR_Voltages", "Type": "AD5593R" },
```

> 💡 **大白话**：LM87 和 ADT7475 是"瑞士军刀"型芯片——一颗芯片同时能量温度、电压、还能控风扇。AD5593R 更灵活，8 个引脚可以自由配置成 ADC/DAC/GPIO 的任意组合。这些芯片的阈值设到 105°C，是因为它们量的是 VRM（稳压模块）附近的温度，VRM 耐热性比 CPU 好。

**④ CPU PECI + PSU PMBus + I2C MUX + EEPROM：**

```json
        { "Address": "0x30", "Bus": 0, "CpuID": 1, "Name": "CPU 0", "Type": "XeonCPU",
          "PresenceGpio": [{ "Name": "SKU_ID0_N", "Polarity": "Low" }] },
        { "Address": "0x31", "Bus": 0, "CpuID": 2, "Name": "CPU 1", "Type": "XeonCPU",
          "PresenceGpio": [{ "Name": "SKU_ID1_N", "Polarity": "Low" }] },

        { "Address": "0x58", "Bus": 7, "Name": "PSU_1", "Type": "pmbus",
          "Thresholds": ["...125/105/5/0..."] },
        { "Address": "0x59", "Bus": 7, "Name": "PSU_2", "Type": "pmbus",
          "Thresholds": ["...125/105/5/0..."] },

        { "Address": "0x73", "Bus": 0, "Name": "Bus0 PCA9546 MUX", "Type": "PCA9546Mux",
          "ChannelNames": ["Front_CPLD_CH0", "Front_CPLD_CH1", "Front_CPLD_CH2", "Front_CPLD_CH3"] },
        { "Address": "0x73", "Bus": 3, "Name": "Bus3 PCA9546 MUX", "Type": "PCA9546Mux",
          "ChannelNames": ["Sensor_ADC_CH", "Inlet_Temp_CH", "MB_Temp_CH", "Spare_CH3"] },
        { "Address": "0x70", "Bus": 3, "Name": "Bus3 PCA9548 NVMe MUX", "Type": "PCA9548Mux",
          "ChannelNames": ["NVMe_CH0", "NVMe_CH1", "...共8通道..."] },

        { "Address": "0x50", "Bus": 2, "FruType": "EEPROM", "Name": "MB FRU", "Type": "EEPROM" },
        { "Address": "0x50", "Bus": 3, "Name": "MAC EEPROM", "Type": "EEPROM" },
```

> 💡 **大白话**：`XeonCPU` 类型的传感器不走 I2C，而是走 PECI（Platform Environment Control Interface）——Intel 专有的单线协议，直接从 CPU 内部读温度和功耗，比外部贴温度传感器精准得多。`CpuID: 1` 对应 PECI 地址 0x30（CPU0），`CpuID: 2` 对应 0x31（CPU1）。`PresenceGpio` 是存在检测——通过 GPIO 引脚判断 CPU 是否安装，没安装就跳过，避免读取超时。
>
> PSU 类型是 `pmbus`（全小写），因为电源自带智能芯片，通过 PMBus 协议汇报功率、温度、电流。阈值 125°C 是电源内部温度的极限。
>
> MUX（多路选通器）是"I2C 总线的交换机"。一条物理 I2C 总线接上 PCA9548，立刻变成 8 条虚拟总线。`ChannelNames` 给每个通道起名字，方便 entity-manager 内部引用。
>
> EEPROM 存的是 FRU（Field Replaceable Unit）数据——主板序列号、型号、制造商等资产信息。`FruType: "EEPROM"` 告诉 entity-manager "这颗 EEPROM 里面存的是 IPMI FRU 格式的数据，请读出来解析"。MAC EEPROM 则存网卡 MAC 地址。

**⑤ PID 风扇控制配置（嵌入 entity-manager JSON，现代做法）：**

entity-manager 的现代配置模式允许把 PID 参数直接写进 baseboard JSON，由 phosphor-pid-control 自动从 D-Bus 拿取，无需独立 config.json。我们同时保留了 `config.json`（传统做法）作为备用。

```json
        { "FailSafePercent": 100, "MinThermalOutput": 30, "Name": "FanZone0", "Type": "Pid.Zone" },

        { "Class": "temp", "Name": "CPU_Temp_PID", "Type": "Pid",
          "Inputs": ["CPU 0*", "CPU 1*"],
          "SetPoint": 85.0,
          "PCoefficient": -10.0,
          "ICoefficient": -1.0,
          "ILimitMax": 100, "ILimitMin": 30,
          "OutLimitMax": 100.0, "OutLimitMin": 30.0,
          "NegativeHysteresis": 5.0, "PositiveHysteresis": 0.0,
          "SlewNeg": -5.0, "SlewPos": 0.0,
          "Zones": ["FanZone0"] },

        { "Class": "temp", "Name": "Inlet_Stepwise", "Type": "Stepwise",
          "Inputs": ["Inlet_Temp"],
          "Reading":  [20, 25, 30, 35, 40, 45],
          "Output":   [30, 40, 50, 60, 80, 100],
          "Zones": ["FanZone0"] },
```

> 💡 **大白话**：这是整个 JSON 最"聪明"的部分。`Pid.Zone` 定义了一个温控区域 `FanZone0`——所有风扇都归这个区管理。`MinThermalOutput: 30` 是最低转速 30%，确保即使系统很凉也不会完全停转（防止结露）。`FailSafePercent: 100` 是传感器失联时的应急全速——宁可吵死，不可烫死。
>
> `CPU_Temp_PID` 是 PID 控制器：目标温度 85°C，偏差越大风扇越猛。注意系数是**负数**（`PCoefficient: -10.0`），这是 OpenBMC 的约定——温度升高时偏差为正，乘以负系数后输出变大（风扇加速）。`SlewNeg: -5.0` 限制降速速率，防止风扇忽快忽慢"打摆子"。
>
> `Inlet_Stepwise` 是阶梯式控制——比 PID 简单粗暴：进风温度 20°C→风扇 30%，25°C→40%，一直到 45°C→100%。这是进风口温度的"安全网"，和 CPU PID 同时生效，取两者中较大的 PWM 值输出。

**⑥ 资产信息标签：**

JSON 末尾的 `Decorator.Asset` 字段提供 IPMI/Redfish 可查询的资产元数据：

```json
    "Probe": "TRUE",
    "Type": "Board",
    "xyz.openbmc_project.Inventory.Decorator.Asset": {
        "Manufacturer": "",
        "Model": "EVB-2U-EGS-MB",
        "PartNumber": "EVB-2U-EGS",
        "SerialNumber": ""
    }
```

> 💡 **大白话**：`Probe: "TRUE"` 表示无条件加载——只要系统启动，就把整个 JSON 里的所有传感器全部注册到 D-Bus。如果将来需要一份固件适配多种主板，可以改成条件表达式（比如 `"BOARD_MATCH(EEPROM) == 'EVB-2U-EGS'"`），让 entity-manager 先读 FRU EEPROM 确认型号再决定是否加载。`Decorator.Asset` 里的 `Manufacturer` 和 `SerialNumber` 留空，量产时由工厂烧录到 FRU EEPROM 中，运行时动态读取。

### §3.8 phosphor-pid-control（闭环风扇控制）

在 AMI 源码中，风扇 PID 算式存在于 `fsit_fsc.c` 中。我们将其转移到 phosphor-pid-control 中处理。

```bash
# recipes-phosphor/fans/phosphor-pid-control_%.bbappend
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://config.json"

do_install:append() {
    install -d ${D}${datadir}/swampd
    install -m 0644 -p ${UNPACKDIR}/config.json ${D}${datadir}/swampd/config.json
}
```

我们的硬件文档显示：4 个系统风扇由 bus9/0x22 的 **CPLD** 控制（PWM 基址寄存器 0x04，转速读取寄存器 0x03，在位检测寄存器 0x05）。**这是本平台风扇控制的核心难点：CPLD 没有标准 Linux hwmon 驱动。**

**架构决策：为什么不能直接用 sysfs 路径？**

```
普通平台（AST2600 内置 PWM/Tach）：
  应用层 → swampd → 写 /sys/class/hwmon/hwmon*/pwm1 → 内核 hwmon 驱动 → AST2600 寄存器
  ✅ 简单，内核已经有现成驱动

我们的平台（外部 CPLD 控制风扇）：
  应用层 → swampd → 写 ??? → 没有 hwmon 驱动 → CPLD 寄存器 0x04
  ❌ 没有现成驱动，需要自己解决
```

我们选择 **D-Bus 路径方案**：开发一个自定义 CPLD 风扇守护进程，通过 `i2c-dev` 直接读写 CPLD 寄存器，并将数据暴露到 D-Bus 上。swampd 读写 D-Bus 路径即可。

> 💡 **大白话**：想象你家空调遥控器（swampd）可以直接控制格力空调（AST2600 内置 PWM），因为遥控器和空调是配套的。但现在你家装了个第三方的中央空调（CPLD），遥控器不认识它。解决办法是加一个"翻译器"（CPLD 风扇守护进程）：遥控器说"调到 60% 风速"，翻译器听到后去拧中央空调的旋钮（写 CPLD 寄存器 0x04）。D-Bus 就是遥控器和翻译器之间的"无线信号"。

**config.json 完整配置（传统文件方式）：**

```json
{
    "_comment_": [
        "EVB-2U-EGS fan control configuration for phosphor-pid-control (swampd).",
        "IMPORTANT: This platform uses a custom CPLD on I2C bus9 addr 0x22 for fan",
        "control. The CPLD provides tach (reg 0x03), PWM (reg 0x04), and presence",
        "(reg 0x05) for 4 system fans with 8 tach channels.",
        "",
        "Since there is no standard Linux hwmon driver for this CPLD, the writePath",
        "and readPath below use D-Bus sensor paths. A custom fan CPLD daemon must be",
        "implemented to:",
        "  1. Read tach RPM from CPLD reg 0x03 via i2c-dev and publish to D-Bus",
        "  2. Accept PWM commands from D-Bus and write to CPLD reg 0x04 via i2c-dev",
        "  3. Monitor fan presence via CPLD reg 0x05",
        "",
        "Alternative: Write a simple hwmon kernel driver for the fan CPLD, then",
        "replace the D-Bus paths below with sysfs hwmon paths."
    ],
    "zones": [
        { "id": 0, "minThermalOutput": 30.0, "failsafePercent": 100.0 }
    ],
    "sensors": [
        { "name": "fan0", "type": "fan",
          "readPath": "/xyz/openbmc_project/sensors/fan_tach/Fan_0",
          "writePath": "/xyz/openbmc_project/control/fanpwm/Fan_0",
          "min": 0, "max": 255 },
        { "name": "fan1", "type": "fan",
          "readPath": "/xyz/openbmc_project/sensors/fan_tach/Fan_1",
          "writePath": "/xyz/openbmc_project/control/fanpwm/Fan_1",
          "min": 0, "max": 255 },
        "... fan2, fan3 结构相同 ...",
        { "name": "cpu0_temp", "type": "temp",
          "readPath": "/xyz/openbmc_project/sensors/temperature/CPU_0_Package_Temp",
          "min": 0, "max": 127, "timeout": 0 },
        { "name": "cpu1_temp", "type": "temp",
          "readPath": "/xyz/openbmc_project/sensors/temperature/CPU_1_Package_Temp",
          "min": 0, "max": 127, "timeout": 0 },
        { "name": "inlet_temp", "type": "temp",
          "readPath": "/xyz/openbmc_project/sensors/temperature/Inlet_Temp",
          "min": 0, "max": 127, "timeout": 0 }
    ],
    "pid": [
        { "name": "fan0", "type": "fan", "inputs": ["fan0"], "setpoint": 40.0,
          "pid": { "samplePeriod": 1.0, "proportionalCoeff": 0.0, "integralCoeff": 0.0,
                   "feedFwdGainCoeff": 1.0, "outLim_min": 30.0, "outLim_max": 100.0 } },
        "... fan1~fan3 结构相同 ...",
        { "name": "cpu_zone", "type": "temp", "inputs": ["cpu0_temp", "cpu1_temp"],
          "setpoint": 85.0,
          "pid": { "samplePeriod": 1.0,
                   "proportionalCoeff": -10.0, "integralCoeff": -1.0,
                   "integralLimit_min": 30.0, "integralLimit_max": 100.0,
                   "outLim_min": 30.0, "outLim_max": 100.0,
                   "slewNeg": -5.0, "slewPos": 0.0 } },
        { "name": "inlet_zone", "type": "temp", "inputs": ["inlet_temp"],
          "setpoint": 40.0,
          "pid": { "samplePeriod": 1.0,
                   "proportionalCoeff": -5.0, "integralCoeff": -0.5,
                   "outLim_min": 30.0, "outLim_max": 100.0,
                   "slewNeg": -5.0, "slewPos": 0.0 } }
    ]
}
```

**关键字段对比解析：**

| 字段 | 旧写法（sysfs，标准 PWM 平台） | 我们的写法（D-Bus，CPLD 平台） |
|------|------|------|
| `writePath` | `/sys/class/hwmon/hwmon*/pwm1` | `/xyz/openbmc_project/control/fanpwm/Fan_0` |
| `readPath` | `/sys/class/hwmon/hwmon*/fan1_input` | `/xyz/openbmc_project/sensors/fan_tach/Fan_0` |
| 驱动依赖 | 内核 hwmon 驱动（内置） | 自定义 CPLD 守护进程（需开发） |

**两套风扇配置共存的原因：**

细心的你可能注意到，我们在 §3.7 的 `baseboard.json` 里已经有了 `Pid.Zone`、`Pid`、`Stepwise` 类型的 PID 配置，而这里的 `config.json` 又有一套。这两者的关系：

- **baseboard.json 中的 PID 配置（现代做法）**：由 entity-manager 写入 D-Bus，phosphor-pid-control 从 D-Bus 自动读取。无需独立文件，是 OpenBMC 社区推荐的新方式。
- **config.json（传统做法）**：直接被 swampd（phosphor-pid-control 的守护进程名）读取。适合调试阶段快速修改。

生产环境中二选一即可。我们两套都保留，是为了在调试阶段对比验证。

> 💡 **大白话**：config.json 这个文件就像你写了一份"空调师傅操作手册"。
>
> **sensors 部分** = 传感器清单："我有哪些温度计（cpu0_temp/cpu1_temp/inlet_temp）和转速表（fan0~fan3）？它们的数据从哪里读？往哪里写？" 注意 `readPath` 和 `writePath` 全是 D-Bus 路径（以 `/xyz/openbmc_project/` 开头），不是 sysfs 路径——因为我们的 CPLD 没有 hwmon 驱动，只能走 D-Bus"翻译层"。
>
> **zones 部分** = 区域策略："所有传感器和风扇归 Zone 0 管。最低转速 30%，出故障就 100%。"
>
> **pid 部分** = 控制算法："cpu_zone 用 PID 算法盯着 CPU 温度，目标 85°C，温度偏高就加速（负系数 = 温度升高→输出增大）。inlet_zone 用 PID 盯着进风口，目标 40°C，作为第二道防线。fan0~fan3 的 PID 是'转速跟随器'——`feedFwdGainCoeff: 1.0` 表示 1:1 跟随温度 PID 的输出，自己不做额外调节。"
>
> 为什么有两套 PID（baseboard.json + config.json）？就像同一道菜有两本菜谱——一本是电子版（D-Bus/entity-manager），一本是纸质版（config.json 文件）。调试阶段两本都留着互相验证，上线后选一本就行。

### §3.9 phosphor-led-manager（LED 状态机）

将零碎的 GPIO LED 引脚收拢成逻辑组（Group）。

```bash
# recipes-phosphor/leds/phosphor-led-manager_%.bbappend
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://led-group-config.json"

do_install:append() {
    install -d ${D}${datadir}/phosphor-led-manager
    install -m 0644 ${UNPACKDIR}/led-group-config.json ${D}${datadir}/phosphor-led-manager/
}
```

```json
{
    "leds": [
        {
            "group": "bmc_booted",
            "members": [
                {
                    "Name": "power_led",
                    "Action": "On",
                    "DutyOn": 50,
                    "Period": 0
                }
            ]
        },
        {
            "group": "power_on",
            "members": [
                {
                    "Name": "power_led",
                    "Action": "Blink",
                    "DutyOn": 50,
                    "Period": 1000
                }
            ]
        }
    ]
}
```
通过上述配置，当 BMC 启动完成（bmc_booted）时，电源灯常亮；当主板开机（power_on）时，转为 1Hz 闪烁。上层应用只需设置 D-Bus 属性 `xyz.openbmc_project.Led.Group` 的 `Asserted = true`，底层物理引脚控制由 LED Manager 接管。

> 💡 **大白话**：LED Manager 的 JSON 文件就像舞台灯光师的"剧本灯效指令表"。每个 `group` 是一场戏的幕（比如"BMC 开机完成"是第一幕），`members` 列出这幕里哪些灯要亮、怎么亮。`Action: "On"` 是常亮，`Action: "Blink"` 配合 `Period: 1000`（毫秒）是 1 秒闪烁一次。上层程序（应用层）只需要说"第二幕开始！"（设置 D-Bus Asserted=true），灯光师（LED Manager）就会自动按指令表操控所有物理引脚，上层完全不需要知道哪个 GPIO 是哪个灯。

### §3.10 phosphor-ipmi-config（IPMI 身份注册）

让上层运维平台通过 `ipmitool mc info` 正确识别该主板。

```bash
# recipes-phosphor/ipmi/phosphor-ipmi-config.bbappend（注意：没有 %，因为上游配方名为 phosphor-ipmi-config.bb，无版本后缀）
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://dev_id.json"
```

```json
{
    "id": 0,
    "revision": 0,
    "addn_dev_support": 141,
    "manuf_id": 12345,
    "prod_id": 100,
    "aux": 0
}
```

> 💡 **大白话**：`dev_id.json` 就是这台服务器 BMC 的"营业执照"。运维人员跑 `ipmitool mc info` 就像工商抽查，需要看到正确的厂商编号（`manuf_id`）和产品型号（`prod_id`）才认可你是合规设备。`manuf_id: 12345` 是开发阶段的占位符，正式产品需要向 IANA 申请一个正式的企业 ID 号填进去。如果这个文件填错了，上层的 IPMI 管理平台就可能把你的板子认成别人家的产品，导致命令发错或监控告警。

### §3.11 linux-aspeed 内核配置（设备树 + 驱动 + Makefile 补丁）

我们在后续的第 4 章中会详细剖析设备树的细节，但此处我们需要先在配方层面打好配置链条的入口。我们在机器层中创建的 `linux-aspeed_%.bbappend` 文件内容如下：

```bitbake
# recipes-kernel/linux/linux-aspeed_%.bbappend
FILESEXTRAPATHS:prepend:evb-2u-egs := "${THISDIR}/${PN}:"
SRC_URI:append:evb-2u-egs = " \
    file://evb-2u-egs.cfg \
    file://aspeed-bmc-evb-2u-egs.dts;subdir=git/arch/arm/boot/dts/aspeed \
    file://0001-ARM-dts-aspeed-Add-EVB-2U-EGS-board.patch \
    "
```

这不仅是一个简单的补丁占位，它实际上引入了 3 个核心文件。这 4 个文件在我们的机器层中构成了如下的真实目录树：

```
meta-evb-2u-egs/
└── recipes-kernel/
    └── linux/
        ├── linux-aspeed/
        │   ├── 0001-ARM-dts-aspeed-Add-EVB-2U-EGS-board.patch
        │   ├── aspeed-bmc-evb-2u-egs.dts
        │   └── evb-2u-egs.cfg
        └── linux-aspeed_%.bbappend
```

这 4 个文件组成了完整的定制链条：
1. `evb-2u-egs.cfg`：内核配置片段（Kernel Config Fragment），用来按需开启硬件驱动（如 ADC、各类 I2C MUX 和温度传感器）。
2. `aspeed-bmc-evb-2u-egs.dts`：完整的机器设备树源码。注意结尾的 `subdir=` 魔法参数，它指示 BitBake：**"在打补丁之前，直接把这个文件放到内核源码树的对应子目录中"**。
3. `0001-ARM-dts-aspeed-Add-EVB-2U-EGS-board.patch`：Makefile 补丁。因为光把 DTS 文件放进目录还不够，如果不修改 `arch/arm/boot/dts/aspeed/Makefile` 把我们的 `.dtb` 目标注册进去，内核构建系统就不会编译它。所以必须**同时提供 DTS 文件和 Makefile 补丁**。

> 💡 **大白话**：`SRC_URI:append:evb-2u-egs` 这行代码使用了 `:evb-2u-egs` 这个机器专属后缀（Override）。意思是**只有在编译目标是 `evb-2u-egs` 时才生效**，编译别的机器时会完全忽略。这就好比公司发通知，主文件是通用流程，但带有"仅限上海分公司执行"标签的补充附件，北京分公司就会自动忽略。
>
> 另外，为什么要同时搞 `DTS文件` 和 `Makefile补丁` 呢？你可以把内核源码树想象成一家庞大的**出版社**，DTS 文件就是你刚写好的一篇**文章**。`subdir=` 技巧就像是你偷偷把文章塞到了编辑部的"待排版文件夹"里。但如果你不改编辑部墙上的**出版总目录**（Makefile），印刷机工作时绝对不会印你的文章。所以 Makefile 补丁的作用，就是在总目录上强行加一行："喂，还有一篇叫《evb-2u-egs》的文章，记得一起印刷！"

### §3.12 首次构建验证

一切准备就绪后，回到 `openbmc-workspace/openbmc/` 根目录。

1.  **环境初始化：**
    ```bash
    . setup evb-2u-egs
    ```
    执行后，脚本会读取 `conf/templates/default/` 里的配置文件，自动生成 `build/evb-2u-egs/conf/` 目录，并注入我们在前面定义的环境变量。

2.  **启动构建：**
    ```bash
    bitbake obmc-phosphor-image
    ```
    这个过程可能会持续数十分钟到几个小时。底层系统会首先交叉编译 glibc、GCC 工具链，接着编译 u-boot、内核，最后打包根文件系统（RootFS）。

3.  **提取固件产物：**
    最终编译好的镜像保存在：`tmp/deploy/images/evb-2u-egs/`。其中的核心文件：
    *   `obmc-phosphor-image-evb-2u-egs.static.mtd`：64MB 的全量 SPI Flash 单 bank 烧录档（物理为双 bank 主备，每 bank 一片 64MB w25q512）。
    *   `fitImage`：包含 Linux 内核与设备树的组合包。

4.  **排错与模拟验证：**
    若遇编译失败，检查 `tmp/work/` 路径下的 `log.do_compile` 查找具体报错。构建成功后，可借助外层目录的 `start-qemu-webui.sh` 启动 QEMU 模拟器（注意：该脚本默认加载 evb-ast2600 镜像，而非 evb-2u-egs 自定义镜像；要测试自定义镜像需要修改脚本中的镜像路径或使用 `runqemu` 命令）。使用 `root` / `0penBmc` 验证 SSH 登录及 Web 页面访问。

> 💡 **大白话**：这四个步骤就是一个工程项目的"交付验收"流程。第一步（`. setup`）是召集所有施工队列队报到，确认每个人都在场；第二步（`bitbake`）是开工建造，就像房子从打地基到封顶的整个施工过程，时间长但几乎不需要人工干预；第三步是检查竣工产物，`static.mtd` 是完整的交付毛坯，`fitImage` 是核心结构件；第四步是验收测试，借助 QEMU 模拟器相当于在"沙盘"里先走一遍，确认房间布局没问题再正式交房——SSH 和 WebUI 能登进去，就说明这套固件是可以开门营业的。

### §3.13 本章总结

在本章中，我们将老旧的巨石型 AMI 源码，按多进程、基于 D-Bus 的解耦服务架构完美拆分。以下是重要的数据流映射总结：

| 功能模块 | AMI 传统实现方式 | OpenBMC 机器层对应文件 |
| :--- | :--- | :--- |
| 电源时序控制 | `PDKHW.c` 宏定义死循环 | `x86-power-control_%.bbappend` + JSON |
| 风扇转速曲线 | `fsit_fsc.c` RPM表 | `phosphor-pid-control` + `config.json` |
| 传感器探测总线 | 固化在 HAL 生成代码中 | `entity-manager` + `evb-2u-egs-baseboard.json` |
| IPMI 厂商信息 | OEM 私有 IPMI 命令 | `phosphor-ipmi-config` + `dev_id.json` |
| 硬件拓扑/设备树 | `ast2600evb.c` (62,693行HAL) | `aspeed-bmc-evb-2u-egs.dts` (547行) |
| 内核驱动开关 | AMI 内核 defconfig 全量编译 | `evb-2u-egs.cfg` 配置片段 (59行) |
| DTS 编译注册 | AMI 构建系统自动包含 | `0001-ARM-dts-aspeed-Add-EVB-2U-EGS-board.patch` |
| 内核定制入口 | 修改内核源码树 | `linux-aspeed_%.bbappend` (6行) |

至此，基础软件架构层已完备挂载。

> 💡 **大白话**：本章做的事情，可以用一句话概括：把一栋旧式"大平层"（AMI 巨石型 C 代码，所有功能混在一起）改造成了现代"精装分户式公寓"（OpenBMC 微服务架构，每个服务住一间）。电源控制、风扇调速、传感器采集、LED 状态、IPMI 身份——每个功能现在都有自己独立的门牌号（D-Bus 路径）和配置文件（JSON），互不干扰。改某个功能只需要替换对应的 JSON 或 bbappend，不会牵一发动全身。这就是现代 BMC 固件架构"配置驱动、数据与逻辑分离"的精髓。


---

## 第四章：Linux 内核与设备树

### 4.1 设备树基础

设备树 (Device Tree) 是一种描述硬件配置的数据结构，取代了以前将硬件细节硬编码在内核源码中的做法。内核启动时通过解析设备树文件来加载相应的驱动程序。

在开发中经常遇到三个关键缩写：
*   **DTS (Device Tree Source)**：人类可读的设备树源码文件。
*   **DTB (Device Tree Blob)**：编译后的二进制文件，引导加载程序 (Bootloader) 传递给内核的就是这个文件。
*   **DTC (Device Tree Compiler)**：将 DTS 编译为 DTB 的工具。

设备树的基本语法由节点 (node) 和属性 (property) 构成。节点可以嵌套，形成树状结构。

> 💡 **大白话**：设备树就像一套建筑蓝图。**DTS 是设计师手绘的施工图纸**，人类可以读懂上面写的"这里放一台空调（I2C 传感器），那里开一扇门（GPIO）"。**DTC 是公证处的翻译员**，把图纸翻译成施工队能执行的标准格式。**DTB 就是加盖公章的施工文件**，只有它才能交给工地（内核）去指导施工。没有这份文件，内核根本不知道板子上接了什么硬件。

```dts
/ {
    model = "My Board Name";
    compatible = "vendor,my-board", "vendor,soc-model";

    chosen {
        stdout-path = &uart5;
    };

    memory@80000000 {
        device_type = "memory";
        reg = <0x80000000 0x40000000>;
    };
};
```

**关键属性解析**：
*   **compatible**：设备与驱动匹配的核心属性。它是一个字符串列表，内核会按顺序查找匹配的驱动。
*   **reg**：定义设备的地址和长度。对于 I2C 设备，它通常代表 I2C 从设备地址。对于内存映射设备，它代表寄存器的物理地址段。（`reg` 的格式由父节点的 `#address-cells` 和 `#size-cells` 属性决定。）
*   **status**：指示设备的状态。通常设为 `"okay"` 来启用设备，设为 `"disabled"` 来禁用设备。
*   **phandle**：节点引用的机制。在 DTS 中使用 `&node_label` 可以引用其他节点。DTC 编译器会在背后为目标节点生成一个唯一的整型标识 (phandle)，供引用节点使用。

> 💡 **大白话**：`compatible` 属性就是设备的**简历上的岗位名称**，比如写"ti,tmp421"。内核在开机时就像一个 HR，手里拿着所有驱动的"招聘需求表"，逐一对照简历。一旦找到名字匹配的驱动，就立刻"录用"它（调用 `probe` 函数）去管这个硬件。`status = "disabled"` 则是在简历上盖了"暂不录用"，驱动根本不会搭理这个设备。

> **面试要点**
> 
> *   **问题**：内核是如何通过 `compatible` 属性找到对应驱动的？
> *   **解答**：内核驱动代码中会定义一个 `of_device_id` 结构体数组，包含该驱动支持的 `compatible` 字符串。内核在解析设备树节点时，会遍历所有注册的平台驱动，将节点中的 `compatible` 字符串与驱动声明的字符串进行比对，匹配成功则调用该驱动的 `probe` 函数。

### 4.2 AST2600 设备树结构

AST2600 是一款非常复杂的 SoC，它的设备树通过包含关系组织成继承链，层次分明。

最底层的是 SoC 级别的文件，位于内核源码的 `arch/arm/boot/dts/aspeed/aspeed-g6.dtsi`。这个文件定义了 CPU 核心、内存控制器、中断控制器、AHB/APB 总线上的所有外设模块 (包含 I2C 控制器、GPIO 控制器、MAC 接口等)。这个文件通常由 ASPEED 原厂维护，我们**绝对不要**修改它。

中间层通常是原厂提供的公板配置，例如 `aspeed-ast2600-evb.dts`。它包含了 `.dtsi` 文件，并通过节点覆盖 (Node Override) 的方式启用特定的外设，或者修改某些引脚复用 (Pinmux) 设置。

顶层是我们的具体主板文件，例如 `aspeed-bmc-evb-2u-egs.dts`。我们的文件将包含 `aspeed/aspeed-g6.dtsi` 或公板 `.dts`，并在其基础上添加我们主板特有的硬件配置。

**设备树继承链示例**：
`aspeed-bmc-evb-2u-egs.dts` -> 包含 -> `aspeed/aspeed-g6.dtsi` -> 包含 -> `skeleton.dtsi`

> 💡 **大白话**：这三层继承关系就像一个家族族谱。**`aspeed-g6.dtsi` 是祖宗族谱**，记录了全家共有的基因（SoC 所有外设的基础定义）；**原厂公板 `.dts` 是父辈履历表**，在族谱基础上写明"我家开了 16 条 I2C，这几条已经用起来了"；**我们的 `evb-2u-egs.dts` 是自己的个人档案**，只记录"我这台机器独有"的东西——挂了哪些传感器、哪个 GPIO 控制电源按钮。族谱不能改，只有个人档案可以随意定制。

> **为什么这样做**
> 
> 将 SoC 定义和板级定义分离，最大限度地实现了代码复用。当 ASPEED 修复了某个 I2C 控制器的底层 bug 时，只需更新 `aspeed/aspeed-g6.dtsi`，所有基于该 SoC 的主板都能自动受益，而无需逐一修改板级配置。

### 4.3 I2C 子系统

在 OpenBMC 中，I2C 是连接各类传感器、EEPROM 和 CPLD 的核心总线。理解 I2C 控制器、I2C 多路复用器 (Mux) 和 I2C 从设备的区别至关重要。

*   **I2C Controller**：SoC 内部的硬件 I2C 控制器，负责生成 I2C 时序信号。AST2600 有 16 个硬件 I2C 控制器。
*   **I2C Mux (如 PCA9548)**：由于地址冲突或总线电容限制，我们经常使用 Mux 将一条 I2C 总线扩展为多条逻辑总线。内核将其抽象为多个下游 adapter/bus。
*   **I2C Slave Device**：挂载在总线上的终端设备，如温度传感器、风扇控制器等。

> 💡 **大白话**：把 I2C 体系想象成城市道路交通系统。**I2C Controller 是高速公路的收费入口**，所有车辆（数据包）都从这里上路，AST2600 有 16 条这样的高速路。**I2C Mux（PCA9548）是一座立交桥分叉**，一条主路在这里分成 8 条支路，每次只能通一条，避免不同目的地的车辆互相打架（地址冲突）。**I2C Slave Device 是路上的目的地**——温度传感器就像加油站，EEPROM 就像仓库，风扇控制器就像收费停车场，各有各的门牌地址（7-bit 地址）。

**实例：在 bus21（MUX 虚拟总线）上挂载 TMP75 进风口温度传感器 (地址 0x48)**

```dts
/* 在 MUX PCA9546 的 channel 1 下定义 */
&i2c3 {
    status = "okay";

    i2c-mux@73 {
        compatible = "nxp,pca9546";
        reg = <0x73>;
        #address-cells = <1>;
        #size-cells = <0>;

        i2c@1 {     /* MUX channel 1 → 虚拟总线 21 */
            reg = <1>;
            #address-cells = <1>;
            #size-cells = <0>;

            tmp75@48 {
                compatible = "national,lm75";  /* TMP75 使用 lm75 驱动 */
                reg = <0x48>;
            };
        };
    };
};
```

在这里，`&i2c3` 是对 SoC 级别 `.dtsi` 文件中 `i2c3` 节点的引用。TMP75 挂在 PCA9546 MUX 的 channel 1 下，内核会自动为它分配虚拟总线号（如 bus 21）。

> 💡 **大白话**：这段 DTS 展示了一个 I2C 层级结构：物理总线 i2c3 → MUX 地址 0x73 → 通道 1 → TMP75 地址 0x48。就像在写邮寄地址："`i2c3` 是省份，`i2c-mux@73` 是城市，`i2c@1` 是街道，`tmp75@48` 是门牌号"。`compatible = "national,lm75"` 告诉内核"这颗芯片用 lm75 驱动来管"——TMP75 和 LM75 是引脚兼容的，共用同一个驱动。

**实例：在 bus9 上挂载 Fan CPLD (地址 0x22)**

我们的 evb-2u-egs 平台使用了一颗挂在 bus9 地址 0x22 的 CPLD 来控制 4 个系统风扇。

```dts
&i2c9 {
    status = "okay";

    fan_cpld: cpld@22 {
        compatible = "intel,egs-fan-cpld"; /* 假设我们编写了此驱动 */
        reg = <0x22>;
    };
};
```

> 💡 **大白话**：注意 `fan_cpld: cpld@22` 这个语法——冒号前面的 `fan_cpld` 是**标签（Label）**，相当于给这个设备起了个外号。DTS 文件的其他地方可以直接用 `&fan_cpld` 来引用它，就像在公司通讯录里给同事起了个常用简称，以后找人直接叫外号，不用每次报全名和工位号了。

### 4.4 hwmon 传感器子系统

Linux 内核使用 Hardware Monitoring (hwmon) 框架来统一管理温度、电压、电流和风扇转速传感器。

当 TMP75 设备的驱动成功加载后，它会向内核的 hwmon 子系统注册自己。内核会在 sysfs 文件系统中创建相应的目录和文件，路径通常在 `/sys/class/hwmon/hwmonX/` 下。

在这个目录下，你会看到标准化的文件：
*   `temp1_input`：以毫摄氏度为单位的温度值。
*   `temp1_max`：温度告警阈值。
*   `name`：传感器名称 (如 lm75)。

OpenBMC 的 `phosphor-hwmon` 和 `dbus-sensors` 服务会监听并在启动时扫描这些 sysfs 目录，将底层的数据转化为 D-Bus 上的对象，供上层协议 (IPMI、Redfish) 读取。

> 💡 **大白话**：hwmon 框架就像医院的**体检中心护士站**。每台传感器设备（温度计、血压计）做完测量，不直接告诉病人，而是把数据写在标准化的体检表格里（`/sys/class/hwmon/hwmonX/temp1_input`）。`dbus-sensors` 服务就像负责收集体检报告的护士，定期巡视各个护士站，把数据汇总到一个统一的电子病历系统（D-Bus），这样 IPMI 和 Redfish "医生"随时可以查阅，不用直接跑去每台仪器前读数字。

> **面试要点**
> 
> *   **问题**：如果在 DTS 中配置了 TMP75，但内核中 `/sys/class/hwmon/` 下没有出现对应设备，如何排查？
> *   **解答**：
>     1. 检查 I2C 总线上是否真的有设备响应：`i2cdetect -y 21`（注意是 MUX 展开后的虚拟总线号）。
>     2. 检查内核是否编译了 LM75 驱动（TMP75 使用 lm75 驱动）：`zcat /proc/config.gz | grep CONFIG_SENSORS_LM75`。
>     3. 检查驱动是否加载并报错：`dmesg | grep lm75`。
>     4. 确认 DTS 中的 compatible 字符串是否与驱动源码中的 `of_match_table` 完全一致（TMP75 应使用 `"national,lm75"`）。

### 4.5 GPIO 子系统

AST2600 提供了大量的通用输入输出引脚。GPIO 控制器负责配置引脚的输入输出方向、电平状态和中断触发方式。

内核中常用的两个 GPIO 辅助驱动：
1.  **gpio-keys**：将 GPIO 输入映射为 Linux 输入事件，常用于电源按钮、复位按钮。
2.  **gpio-leds**：将 GPIO 输出映射为 LED 设备，可以通过 `/sys/class/leds/` 统一控制闪烁频率。

> 💡 **大白话**：GPIO 就是主板上一排排的**电气开关插口**，高电平是"开"，低电平是"关"。`gpio-keys` 驱动相当于给每个开关插口装了个**门铃**——有人按电源按钮（GPIO 电平变化），内核就响铃通知上层"有人按铃了"。`gpio-leds` 则相当于给插口接了**指示灯**，你只需要向 `/sys/class/leds/` 里写个"闪烁频率"，内核的定时器会自动帮你控制灯的亮灭，不用手动翻转电平。

**GPIO Line Naming (引脚命名)**

在 evb-2u-egs 项目中，我们有多达 47 个 GPIO 信号。如果不进行命名，在用户空间通过 `libgpiod` 操作时将面对难以记忆的编号。DTS 提供了 `gpio-line-names` 属性，可以直接给物理引脚赋予易读的名字。

```dts
&gpio0 {
    status = "okay";
    /* AST2600 GPIO 按 Bank 组织，每个 Bank 8 个引脚（A=0-7, B=8-15, ..., I=64-71） */
    /* 我们定义 GPIOI5 (GPIO69) 为电源按钮输出，GPIOF7 (GPIO47) 为 Power OK */
    gpio-line-names =
    /*A0-A7*/   "","","","","","","","",
    /*B0-B7*/   "","","","","","","","",
    /*C0-C7*/   "","","","","","","","",
    /*D0-D7*/   "","","","","","","","",
    /*E0-E7*/   "","","","","","","","",
    /*F0-F7*/   "","","","","","","","power-ok",
    /*G0-G7*/   "","","","","","","","",
    /*H0-H7*/   "","","","","","","","",
    /*I0-I7*/   "","","","","","power-button-out","","";
};
```

用户空间服务可以通过引脚名称直接获取并操作这些 GPIO，显著提高了代码的可读性和可维护性。

> 💡 **大白话**：`gpio-line-names` 就是给每个电气插口钉上**办公室门牌号**。没有命名之前，程序员要操作"电源按钮"，只能去查文档："哦，在第 69 号线"，然后写代码 `gpio_get(69)`，换个人来根本不知道 69 号是干什么的。有了命名后，代码直接写 `gpiod_find("power-button-out")`，一目了然——就像办公室门上直接贴着"人事部"，不用记走廊第几扇门了。

### 4.6 PECI 子系统

PECI (Platform Environment Control Interface) 是 Intel 开发的一种单线总线接口，主要用于读取 CPU 核心温度、内存温度以及执行一些带外 (OOB) 管理命令。

AST2600 内部集成了硬件 PECI 控制器。在 evb-2u-egs 这样的双路 EGS 平台上，我们需要配置 PECI 接口来监控两颗 CPU 的状态。

> 💡 **大白话**：PECI 就是 BMC 和 CPU 之间的**内线电话直通体温计**。普通温度传感器是"贴在外面量"，PECI 则是 CPU 把自己的核心温度数据直接"说"给 BMC 听，数据来自 CPU 内部的 DTS（数字温度传感器），比外部测量更准确、更及时。对于双路服务器，CPU0 接内线分机 0x30，CPU1 接 0x31，BMC 分别打电话就能同时知道两颗 CPU 的"体温"。

**DTS 中的 PECI 配置**

```dts
&peci0 {
    status = "okay";
};
```

在这个配置中，启用 `peci0` 后，内核的 PECI 总线核心驱动会自动扫描地址 0x30-0x37。对于我们的双路 EGS 平台，CPU0 (0x30) 和 CPU1 (0x31) 会被自动发现。PECI hwmon 驱动随即将 CPU 温度暴露到 sysfs 中，供 `dbus-sensors` 的 `pecisensor` 进程读取。

> 💡 **大白话**：PECI 驱动的"自动扫描"就像公司的**全员考勤打卡机**——开机后自动轮流呼叫 0x30、0x31……0x37 各个"员工号"，谁应答就登记谁在场。对于双路服务器，CPU0 和 CPU1 各自应答，驱动就自动创建两个温度传感器条目。不用你在 DTS 里手动一个个列出 CPU，系统启动时自己就发现了。

### 4.7 为 evb-2u-egs 创建自定义 DTS

基于硬件定义文档，我们实际编写的 `aspeed-bmc-evb-2u-egs.dts` 高达 540 多行。以下是核心结构的逐段剖析：

**1. 头部声明与内存配置**
```dts
/dts-v1/;
#include "aspeed-g6.dtsi"
#include <dt-bindings/gpio/aspeed-gpio.h>
#include <dt-bindings/i2c/i2c.h>
/ {
	model = "EVB-2U-EGS BMC";
	compatible = "evb-2u-egs-bmc", "aspeed,ast2600";
    /* ... 别名配置 ... */
	memory@80000000 {
		device_type = "memory";
		reg = <0x80000000 0x40000000>; /* 1GB RAM */
	};
	reserved-memory {
		#address-cells = <1>;
		#size-cells = <1>;
		ranges;
		video_engine_memory: framebuffer@9f000000 {
			no-map;
			reg = <0x9f000000 0x01000000>; /* 16MB */
		};
	};
};
```
这里引入了底层的 `aspeed-g6.dtsi`。`compatible` 是设备的"身份证"，内核凭此判断是否能运行在这个板子上。`reserved-memory` 专门为 BMC 视频引擎（KVM 功能）以 `no-map` 方式预留了 16MB 内存（地址 `0x9f000000`），标记为不可被内核使用。

> 💡 **大白话**：这部分就是告诉内核："我叫 evb-2u-egs，是 AST2600 家族的。我兜里有 1GB 内存，但我已经把其中 16MB（从地址 0x9f000000 开始）划给远程桌面（KVM）的视频帧缓冲专用了，用 `no-map` 彻底隔离，你别碰！"

**2. ADC 与 LED 节点**
```dts
&adc0 {
	status = "okay";
};
&adc1 {
	status = "okay";
};

/ {
	iio-hwmon {
		compatible = "iio-hwmon";
		io-channels = <&adc0 0>, <&adc0 1>, /* ... 16个通道全列出 ... */;
	};

	leds {
		compatible = "gpio-leds";
		identify {
			label = "identify";
			gpios = <&gpio0 ASPEED_GPIO(B, 7) GPIO_ACTIVE_LOW>;
			default-state = "off";
		};
        /* 还有 status-green, status-amber, fan-fault 等共 6 个 LED */
	};
};
```
开启两个 ADC 控制器后，利用 `iio-hwmon` 虚拟设备把这些模拟通道转换成标准温度/电压传感器接口。LED 节点定义了 6 个面板灯，并与具体的 GPIO 针脚绑定。

> 💡 **大白话**：`iio-hwmon` 就像一个**翻译官**，ADC 测出来的只是一堆数字电压，翻译官把它们打包成标准的传感器读数，供上层系统随时调用。LED 节点则是给系统开了一个"面板控制中心"，你只需写"打开 UID 灯"，内核就会自动去把对应的 GPIOB7 引脚拉低。

**3. GPIO 命名与引脚霸占 (Hog)**
```dts
&gpio0 {
	gpio-line-names =
	/*A0-A7*/ "","","","","GPIO_BMC_CPLD_LIQUID","","","",
	/*B0-B7*/ "","","","GPIO_SYS_PWROK","","","FM_BMC_BMCINIT","FP_ID_LED_N",
    /* ... 总共 208 个引脚，其中 49 个被命名 ... */
	/*V0-V7*/ "SLP_S3","SLP_S4","","","","FW_CONFIG_DONE_N","CPU0_MEMHOT_N","";

	phy-reset-hog {
		gpio-hog;
		gpios = <ASPEED_GPIO(N, 7) GPIO_ACTIVE_LOW>;
		output-high;
		line-name = "RST_RGMII_PHYRST_N";
	};

	bmc-ready-hog {
		gpio-hog;
		gpios = <ASPEED_GPIO(Q, 7) GPIO_ACTIVE_LOW>;
		output-high;
		line-name = "BMC_READY";
	};
};
```
AST2600 有大量的 GPIO，我们通过 `gpio-line-names` 数组给物理引脚贴上标签。`gpio-hog` 则用于在系统启动的极早期强制设定引脚状态，例如复位网络 PHY 和宣告 BMC 启动就绪。注意 `bmc-ready-hog` 使用了 `GPIO_ACTIVE_LOW` + `output-high`，意思是"引脚输出高电平"，由于是 active-low 逻辑，此时信号处于"非激活"状态（BMC 尚未准备好），等系统完全就绪后由用户态服务拉低引脚来宣告 ready。

> 💡 **大白话**：`gpio-line-names` 是给每个插座贴上"电源开关"、"休眠信号"的标签，免得写代码时还要翻几百页的硬件手册查引脚号。`gpio-hog` 就像是**开机保安**，系统刚通电，保安就冲过去把"PHY 复位"开关死死按住（保证网络芯片正常初始化），谁也不能抢。

**4. 存储、网络与 PECI**
```dts
&fmc {
	status = "okay";
	flash@0 {
		status = "okay";
		m25p,fast-read;
		label = "bmc";
		spi-max-frequency = <50000000>;
#include "openbmc-flash-layout-64.dtsi"
	};
	flash@1 {
		status = "okay";
		m25p,fast-read;
		label = "bmc-backup";
		spi-max-frequency = <50000000>;
	};
};

&mac2 {
	status = "okay";
	phy-mode = "rgmii-rxid";
	phy-handle = <&ethphy1>;
};

&mac3 {
	status = "okay";
	use-ncsi;
};

&peci0 {
	status = "okay";
	peci-client@30 {
		compatible = "intel,peci-client";
		reg = <0x30>;
	};
	peci-client@31 {
		compatible = "intel,peci-client";
		reg = <0x31>;
	};
};
```
这里定义了双 64MB SPI Flash（`flash@0` 包含标准分区表，`flash@1` 标记为 `bmc-backup` 作为纯备用）。网络方面启用了两路，`mac2` 走 RGMII 连接外部 PHY（网卡1），`mac3` 则走 NCSI 直接连接主机网卡（网卡2）。PECI 总线挂载了两个 CPU 客户端以便热量监控。

> 💡 **大白话**：为什么代码里写的是 `mac2` 和 `mac3`，硬件文档却叫网卡1和网卡2？因为 AST2600 内部有 4 个 MAC 控制器（编号 0-3），主板工程师挑了第 3 个和第 4 个接出去。`use-ncsi` 是一项神奇的技术，它允许 BMC 像"搭便车"一样，借用服务器主板上的大网卡联网，省掉一根专用的管理网线。

**5. I2C 总线与设备树校验**
我们的板子接满了各种 I2C 传感器和 MUX，以下是精简片段：
```dts
&i2c0 { /* Bus 0: 前置面板 CPLD MUX */
	status = "okay";
	i2c-mux@73 {
		compatible = "nxp,pca9546";
		reg = <0x73>;
        /* ... 分出 4 个子通道 ... */
	};
};

&i2c2 { /* Bus 2: 主板 EEPROM */
	status = "okay";
	mb_fru: eeprom@50 {
		compatible = "atmel,24c64";
		reg = <0x50>;
	};
};

&i2c5 { /* Bus 5: IPMB 接口 */
	status = "okay";
	ipmb@10 {
		compatible = "ipmb-dev";
		reg = <(0x10 | I2C_OWN_SLAVE_ADDRESS)>;
		i2c-protocol;
	};
};

&i2c7 { /* Bus 7: 系统核心传感器与 PSU */
	status = "okay";
	lm87@2d { compatible = "ti,lm87"; reg = <0x2d>; };
	adt7475@2e { compatible = "adi,adt7475"; reg = <0x2e>; };
	psu@58 { compatible = "pmbus"; reg = <0x58>; };
};

&i2c9 { /* Bus 9: 风扇 CPLD */
	status = "okay";
	/* Fan CPLD @ 0x22 (Lattice/Altera)
	 * 目前仅用作注释说明，实际由用户层应用通过 I2C 读写
	 */
};
```
在编写这一段时，**最容易踩坑的就是 compatible 字符串**。例如，必须查阅内核源码确认 `lm87` 的前缀是 `ti,lm87` 而不是 `national,lm87`；虽然硬件上用了 ADT7468 风扇芯片，但因为内核驱动兼容性，应该写 `adi,adt7475`。对于 `bus9` 的风扇 CPLD，因为它是非标芯片，没有现成的内核驱动，所以我们只保留了注释，留给上层应用（通过用户态 I2C）直接控制。

> 💡 **大白话**：创建自定义 DTS 的过程就像**装修租来的公寓**。你要按着自己买的家具清单（硬件定义文档）一件件摆进去——EEPROM 放 I2C2、传感器放 I2C7、门铃接 GPIO。最折磨人的环节是"找对应插座"（compatible 字符串），插座买错了（名字写错），内核驱动死活不认。对于风扇 CPLD 这种没通用插座的"奇葩家具"，我们干脆不装标准驱动，直接让顶楼的业务系统自己拉根电线（用户态 I2C）去管它。

### 4.8 内核补丁在 Yocto 中的管理

OpenBMC 使用 Yocto Project 进行构建。我们不直接在原始内核代码库中工作，而是通过 Yocto 的配方 (Recipe) 系统来定制和编译内核。我们在 `meta-evb-2u-egs` 层中创建的 4 个文件构成了完整的内核定制链条。

**实际目录结构**：
```
meta-evb-2u-egs/
└── recipes-kernel
    └── linux
        ├── linux-aspeed
        │   ├── 0001-ARM-dts-aspeed-Add-EVB-2U-EGS-board.patch
        │   ├── aspeed-bmc-evb-2u-egs.dts
        │   └── evb-2u-egs.cfg
        └── linux-aspeed_%.bbappend
```

**1. 内核驱动开启 (evb-2u-egs.cfg)**
我们在 DTS 里定义了传感器，但如果内核没有编译对应驱动，它们依然无法工作。通过内核配置片段（Config Fragment）可以精准按需开启驱动：
```bash
# EVB-2U-EGS kernel configuration fragment
# Platform: AST2600 A1, Intel EGS 2U rack server

# 内存分割：3G 用户 / 1G 内核（3G_OPT 变体）
# 真机有 2GB DRAM，默认 VMSPLIT_2G 会导致 vmalloc 空间不足，
# SPI FMC 驱动无法映射 256MB AHB 窗口 → Kernel Panic。
# 配合 U-Boot bootargs vmalloc=512M 使用。详见 §9.10。
CONFIG_VMSPLIT_3G_OPT=y

# I2C MUX: PCA9546 (bus0, bus3) + PCA9548 (bus3 NVMe)
CONFIG_I2C_MUX=y
CONFIG_I2C_MUX_PCA954x=y

# Temperature sensors: LM75 (bus3-mux, bus7, bus8, bus13)
CONFIG_SENSORS_LM75=y
# ADT7475 fan controller / sensor
CONFIG_SENSORS_ADT7475=y
# PSU PMBus (bus7: 0x58, 0x59)
CONFIG_PMBUS=y
CONFIG_SENSORS_PMBUS=y
# PECI: CPU thermal (CPU0@0x30, CPU1@0x31)
CONFIG_PECI=y
CONFIG_PECI_ASPEED=y
CONFIG_SENSORS_PECI_CPUTEMP=y
# NC-SI (mac3 BMC management NIC)
CONFIG_NCSI_OEM_CMD_GET_MAC=y
```
这段配置就像一份**"驱动采购单"**，确保 `pca954x`、`lm75`、`pmbus`、`peci` 和 `ncsi` 这些我们在硬件和 DTS 里用到的底层能力，真正被编译进内核镜像中。

**2. Makefile 注册补丁 (0001-ARM-dts-aspeed-Add-EVB-2U-EGS-board.patch)**
```diff
--- a/arch/arm/boot/dts/aspeed/Makefile
+++ b/arch/arm/boot/dts/aspeed/Makefile
@@ -22,6 +22,7 @@
 	aspeed-bmc-bytedance-g220a.dtb \
 	aspeed-bmc-delta-ahe50dc.dtb \
+	aspeed-bmc-evb-2u-egs.dtb \
 	aspeed-bmc-facebook-anacapa.dtb \
```
这不仅是个文本差异文件，更是内核构建系统的**"准生证"**。没有这一行，哪怕 DTS 文件已经放进源码树，`make dtbs` 也会无视它。

**定制链条的完整运作流程**：
1. **获取源码**：BitBake 下载上游的 Linux-ASPEED 内核源码。
2. **注入 DTS**：由于 `linux-aspeed_%.bbappend` 里的 `subdir=` 参数，BitBake 把我们的 DTS 文件直接解压塞进 `arch/arm/boot/dts/aspeed/` 目录。
3. **打补丁**：BitBake 应用上面的 `.patch` 文件，修改 `Makefile` 注册我们的 DTB。
4. **合并配置**：把 `evb-2u-egs.cfg` 和原本的内核 `.config` 合并，开启所需的传感器驱动。
5. **编译组装**：完成编译，并在最后生成固件镜像时打包。

> 💡 **大白话**：`FILESEXTRAPATHS:prepend` 就是告诉 BitBake **"去哪个抽屉里找文件"**。加了这行之后，它会先来我们机器层的目录里拿这 4 样法宝。这套流程极其优雅——我们既不用去维护一个包含无数文件的庞大内核分叉（Fork），又完美实现了自己板子的硬件适配。上游内核修了安全漏洞，我们只要重新 `bitbake` 就能直接享受，什么冲突都不用解。

此外，我们还需要在机器配置文件 `meta-evb-2u-egs/conf/machine/evb-2u-egs.conf` 中指定内核使用这个新生成的设备树：

```bitbake
KERNEL_DEVICETREE = "aspeed/aspeed-bmc-evb-2u-egs.dtb"
```

> 💡 **大白话**：`KERNEL_DEVICETREE` 这一行就像快递单上的**"请将此文件随货附上"**标签。BitBake 编译好内核和 DTB 之后，会看这个变量，把对应的 `.dtb` 文件打包进固件镜像里，引导程序（U-Boot）启动时才知道去加载哪份"施工文件"给内核。少了这一行，DTB 文件虽然编译出来了，却没有被装进快递箱，内核启动时找不到，硬件就无法正常初始化。

### 4.9 面试题速查

1.  什么是设备树，它的主要作用是什么？
2.  解释 DTS、DTB 和 DTC 之间的关系。
3.  设备树节点中的 `compatible` 属性有什么作用？内核是如何利用它的？
4.  如何在设备树中引用另一个节点？什么是 phandle？
5.  在 Linux 下，如何从用户空间查看当前加载的设备树结构？(提示：`/sys/firmware/devicetree/base`)
6.  简述 I2C Controller、I2C Mux 和 I2C Slave 的区别，并在 DTS 中如何表现？
7.  内核通过什么机制将温度传感器的读数暴露给用户空间服务？
8.  为什么要使用 GPIO Line Naming 技术？
9.  Yocto 中 `FILESEXTRAPATHS:prepend` 的作用是什么？
10. 当一个 I2C 设备的驱动无法加载，你将按什么步骤进行排查？

---

## 第五章：IPMI 与 Redfish 协议精通

### 5.1 IPMI 协议基础

智能平台管理接口 (IPMI) 是一套用于计算机带外管理和监控的标准化消息传递规范。尽管它被认为是一项老旧的技术，但在现有的服务器生态系统中依然不可替代。IPMI 经历了 1.5 到 2.0 的重大演进，2.0 引入了增强的安全性、VLAN 支持以及加密的 Serial Over LAN (SOL)。

IPMI 通信的基础是消息结构，每个消息包含两个核心标识符：
*   **NetFn (Network Function)**：一个 6 位的字段，对命令进行逻辑分类。例如 0x04 对应 Sensor/Event 相关命令，0x06 对应 App 级别命令。
*   **Cmd (Command)**：一个 8 位的字段，标识具体的执行动作。例如在 NetFn 0x04 下，Cmd 0x2D 代表获取传感器读数 (Get Sensor Reading)。

> 💡 **大白话**：IPMI 就像一套公司内部的快递系统。NetFn 是"部门编号"——你要往财务部发件就写 0x04，往行政部发就写 0x06；Cmd 是"具体办事单号"——同样是财务部，0x2D 是"查工资单"，0x2C 是"申请报销"。BMC 就是收发室，看到信封上的部门+单号，就知道转交给谁处理，处理完再把回执送回来。

通信机制基于 Request 和 Response 模式。Host 或远程客户端发送带有参数的 Request 消息，BMC 处理后返回包含完成代码 (Completion Code) 的 Response 消息。

**IPMI 的主要传输通道**：
1.  **KCS (Keyboard Controller Style)**：最常见的带内接口，Host CPU 通过 I/O 端口与 BMC 通信。
2.  **SSIF (SMBus System Interface)**：使用 I2C/SMBus 作为主机和 BMC 之间的传输介质。
3.  **BT (Block Transfer)**：适用于大块数据传输的硬件接口。
4.  **LAN (RMCP/RMCP+)**：带外网络接口，通过 UDP 端口 623 传输，支持远程管理。

> 💡 **大白话**：这四种传输通道就像从北京给外地朋友送东西的四种方式——KCS 是在同一栋楼里面对面递文件（带内，直连）；SSIF 是走小区内部信报箱（I2C，近距离低速）；BT 是托运大行李箱（适合大数据块）；LAN 是顺丰跨城发件（带外网络，人在外地也能操控）。平时最顺手的当然是快递，但楼内沟通有时候更快。

### 5.2 OpenBMC IPMI 实现

在 OpenBMC 中，IPMI 的处理架构高度模块化。核心守护进程是 `ipmid` (通常由 `phosphor-ipmi-host` 提供)。

**命令注册机制**

`ipmid` 本身并不实现所有的命令。它采用共享库 (Shared Library Plugin) 架构。在启动时，`ipmid` 会扫描特定的目录 (如 `/usr/lib/ipmid-providers/`)，动态加载以 `.so` 结尾的提供者库。值得注意的是，你可能还会在代码中看到 `/usr/lib/host-ipmid/` 和 `/usr/lib/net-ipmid/` 这两个目录——它们实际上是指向 `../ipmid-providers/` 的**符号链接**，由 `obmc-phosphor-ipmiprovider-symlink.bbclass` 在构建时创建。三个路径最终指向同一组 `.so` 文件。

每个共享库会向 `ipmid` 的路由表中注册自己支持的 NetFn 和 Cmd 组合，并绑定一个回调函数。这种设计极其灵活，不同硬件厂商可以打包自己的特定命令实现，而无需修改核心代码。

> 💡 **大白话**：`ipmid` 就像一家大型百货商场的物业管理处。它自己不卖任何商品，但负责管理整栋楼的公共秩序和路由。各个品牌的专卖店（`.so` 插件）入驻后，向物业登记"我这里卖NetFn=0x30、Cmd=0x42的商品"。顾客（IPMI请求）来了，物业（ipmid）查路由表，直接把顾客领到对应的专卖店，自己并不参与买卖。不同厂商随时可以新开店或关店，完全不影响整栋楼的其他商家。

**通道守护进程**

处理不同物理传输层的服务是分离的：
*   **phosphor-ipmi-host**：运行 `ipmid` 守护进程，是 IPMI 命令的中央路由器和处理器。它加载 `.so` 插件并分发命令，但自身**不直接**处理任何物理传输层。
*   **phosphor-ipmi-kcs**：KCS 通道桥接服务，监控字符设备 `/dev/ipmi-kcs3`（默认，可通过 `KCS_DEVICE` 配置）。当 Host CPU 通过 KCS 端口写入 IPMI 请求时，本服务将其转换为 D-Bus 消息转发给 `ipmid`。
*   **phosphor-ipmi-net**：RMCP+ 网络通道桥接服务，运行加密握手和完整性校验栈，提取出 IPMI 净荷后，通过 D-Bus 转发给 `ipmid` 处理。

`ipmid` 处理完成后，通过 D-Bus 将响应返回给对应的通道守护进程，进而传回客户端。

### 5.3 SDR/SEL/FRU

这三个缩写构成了 IPMI 信息管理的核心。在传统的固件架构中，这些数据通常静态编译或预烧录在特定的 NVRAM 区域。但在 OpenBMC 中，做法完全不同。

*   **SDR (Sensor Data Record)**：描述传感器的元数据 (类型、阈值、名称等)。OpenBMC 不预存 SDR，而是通过 `ipmid` 中的传感器提供者。它会遍历 D-Bus 上所有实现了特定传感器接口的对象，在收到请求时**动态生成** SDR 记录返回给查询者。
*   **SEL (System Event Log)**：系统事件日志记录了严重的硬件异常。在 OpenBMC 中，IPMI SEL 与系统日志系统相连。`phosphor-logging` 负责捕获和存储日志，当收到 IPMI SEL 查询请求时，相关的 provider 会解析 `phosphor-logging` 的条目，转换为严格遵守 IPMI 规范格式的字节数据。
*   **FRU (Field Replaceable Unit)**：包含部件的生产商、序列号和资产标签。数据通常以二进制格式存放在 I2C EEPROM 芯片中。`fru-device` 服务会在总线上扫描这些设备，解析格式并将信息发布到 D-Bus。IPMI FRU provider 则负责响应读取请求，必要时也支持写操作以更新资产信息。

> 💡 **大白话**：SDR 就像"传感器身份证档案馆"——不是提前把每个身份证复印件锁进柜子，而是有人来查时，临时去户籍系统（D-Bus）扫一圈现场生成；SEL 就像物业保安室的"事故报告本"，每次发生严重事件（温度超标、电源掉电）就记一笔，有人来查IPMI日志时把记录翻译成标准格式给他看；FRU 就像设备背面贴的"资产标签"，存着生产商、序列号，数据藏在一颗小EEPROM芯片里，系统启动时自动读取并上报给管理平台。

### 5.4 OEM 命令开发

标准 IPMI 规范定义了数百个标准命令，但在实际项目中往往不够用。厂商通过使用特定的 NetFn (0x2C/0x2E/0x30/0x32) 和组扩展机制来实现自定义的 OEM 命令。

在我们的 evb-2u-egs 项目中，需要迁移多达 78 个 OEM 命令。这些命令用于特定的电源策略控制、风扇曲线调整和工厂测试握手。

**如何编写 OEM IPMI 命令处理器**

现代 OpenBMC 提供了一套基于现代 C++ 特性的 API 来注册 IPMI 处理函数。

```cpp
#include <ipmid/api.hpp>

// 定义请求和响应的结构
ipmi::RspType<uint8_t, uint8_t> handleMyOemCommand(
    ipmi::Context::ptr ctx,
    uint8_t param1,
    uint8_t param2)
{
    // 参数验证
    if (param1 > 100) {
        return ipmi::responseInvalidFieldRequest();
    }

    // 执行硬件操作或 D-Bus 调用
    uint8_t status = doSomething(param1, param2);
    uint8_t errorCode = 0;

    // 返回成功代码 (隐式 0x00) 以及所需的数据
    return ipmi::responseSuccess(status, errorCode);
}

// 注册回调
void registerOemFunctions()
{
    // 三种注册 API：
    //   ipmi::registerHandler()      — 标准 IPMI 命令（如 Chassis、Sensor 等标准 NetFn）
    //   ipmi::registerGroupHandler() — Group Extension 命令（NetFn 0x2C/0x2D，需 1 字节 Group Defining Body ID）
    //   ipmi::registerOemHandler()   — OEM/Group 命令（NetFn 0x2E/0x2F，需 3 字节 IANA Enterprise Number）
    // 注意：旧版 API ipmi_register_callback() 已弃用，新代码不要使用

    // registerGroupHandler — 用于 Group Extension (NetFn 0x2C/0x2D)
    // 签名：registerGroupHandler(prio, Group group, Cmd cmd, Priv, Handler)
    // 注意：Group 是 1 字节的 Group Defining Body ID，不是 IANA
    ipmi::registerGroupHandler(ipmi::prioOemBase, ipmi::groupDCMI,
                               0x42, ipmi::Privilege::User, handleMyOemCommand);

    // registerOemHandler — 用于 OEM/Group (NetFn 0x2E/0x2F)
    // 签名：registerOemHandler(prio, Iana iana, Cmd cmd, Priv, Handler)
    // 这里才用 IANA Enterprise Number
    // ipmi::registerOemHandler(ipmi::prioOemBase, myIanaId,
    //                          0x42, ipmi::Privilege::User, handleMyOemCommand);
}
```

> **为什么这样做**
> 
> 旧版 API 要求手动进行指针转换和长度计算，极易引发内存越界错误。新的 `RspType` API 利用 C++ 模板在编译期自动推导和解包有效载荷大小，这使得我们能以极高的安全性和极少的代码量重写 evb-2u-egs 的 78 个 OEM 命令。

迁移策略应该是：将 78 个命令按逻辑分组，每个组创建一个 `.cpp` 文件。将其编译为一个单独的 `libevb-egs-oem.so` 共享库，并在 BitBake 配方 中将其安装到 `/usr/lib/ipmid-providers/` 目录下。

> 💡 **大白话**：OEM 命令分两大类，别搞混。**Group Extension（NetFn 0x2C/0x2D）**像行业协会的"公共扩展表单"——比如 DCMI 节能管理命令，各厂商共用同一套规范，只需带 1 字节的组 ID 来区分是哪个协会的。**OEM/Group（NetFn 0x2E/0x2F）**则像企业的"私有内部审批单"——每家公司用自己的 3 字节 IANA 企业编号做门牌，外人完全看不懂。此外还有 NetFn 0x30/0x32 等额外的 OEM 保留 NetFn，可用 `registerHandler` 按标准方式注册。`registerGroupHandler` 注册 0x2C 类，`registerOemHandler` 注册 0x2E 类，选错了 API 就像把公文投错了窗口，命令直接被驳回。

### 5.5 ipmitool 实战

`ipmitool` 是工程师日常调试的首选工具。掌握它的用法是基础功。

**关键命令**：
*   `ipmitool mc info`：获取管理控制器信息（版本号、厂商 ID）。
*   `ipmitool sensor list`：列出所有传感器读数及阈值。对于我们的平台，你可以看到 TMP75（如 Inlet_Temp、Exhaust_Temp）和 CPU PECI 的读数。
*   `ipmitool sdr list`：列出传感器的元数据记录。
*   `ipmitool sel list`：打印系统事件日志。
*   `ipmitool sel clear`：清空日志仓库。
*   `ipmitool fru print`：打印出格式化后的部件信息。

**Raw 命令发送**

遇到我们编写的未被工具原生支持的 OEM 命令时，必须使用 raw 模式手动发送十六进制数据：
`ipmitool raw 0x30 0x42 0x05 0x0A`
这个指令向 NetFn 0x30 发送 Cmd 0x42，后跟参数 0x05 和 0x0A。

> 💡 **大白话**：`ipmitool raw` 就像直接给保安室打内线电话，按分机号（NetFn）加座机号（Cmd）直拨，不走前台转接。普通员工打电话可能只说"帮我订个会议室"，raw 模式是直接说"按0x30、0x42、0x05、0x0A这四个键"，适合测试那些还没有"名字"的自定义命令。

**LAN 模式访问**

通过网络远程调试时，需要指定主机 IP、用户名和密码：
`ipmitool -I lanplus -H 192.168.1.100 -U root -P 0penBmc mc info`

### 5.6 Redfish 协议基础

随着现代数据中心规模的急剧膨胀，基于 UDP 且消息体缺乏自我描述的 IPMI 越来越难以满足需求。DMTF 组织因此推出了 Redfish 规范。

**为什么 Redfish 是未来**：
1.  **基于 HTTP/HTTPS**：与现代网络架构完美契合，穿越防火墙毫无压力。
2.  **数据格式 RESTful + JSON**：机器易读，人类也易读。前端工程师无需了解底层协议即可开发管理界面。
3.  **Schema 驱动**：数据模型严格标准化，从服务器、交换机到 PDU 都可以使用统一的接口抽象。

> 💡 **大白话**：IPMI 就像老式的BB机——只能发数字，还得对着密码本才能读懂，跨公司的人根本看不懂你发的什么；Redfish 则像微信公众号的开放API——走标准HTTPS、返回JSON，会用浏览器的人都能理解，第三方开发者两小时就能写出管理界面。更重要的是，Schema驱动就像有统一的插座国家标准，全球所有品牌的服务器都用同一套接口，再也不需要每换一台机器就重新学一套暗语了。

Redfish 将资源按照树状结构组织，统一入口为 `/redfish/v1/`。在此之下分为三大分支：Systems (系统信息)、Chassis (物理外壳与供电/散热)、Managers (管理控制器本身)。

### 5.7 bmcweb 深度解析

`bmcweb` 是 OpenBMC 提供 Redfish 接口的核心 HTTP 服务器守护进程。它基于 C++23 标准开发，底层使用 Boost.Beast 异步网络库，性能极高。

**路由注册机制**

`bmcweb` 不将整个 JSON 响应静态保存在磁盘上，而是通过路由回调来实时组装响应。当收到针对某个 URI 的 GET 请求时，它会拦截请求，发起一系列异步 D-Bus 调用去收集底层服务的数据，然后拼接成 JSON 返回。

> 💡 **大白话**：`bmcweb` 就像一个网页版的"银行客服机器人"。它没有提前把每个账户的余额打印出来存档，而是你一问"查余额"，它马上后台调用几个服务（D-Bus）去拼数据，实时组装成JSON网页返回给你。`BMCWEB_ROUTE` 宏就像在机器人的菜单里注册"第3项=查机箱信息"，指定由哪个函数来处理，哪类用户（权限）才能访问。

在代码中，路由通常通过宏定义进行注册：

```cpp
BMCWEB_ROUTE(app, "/redfish/v1/Chassis/<str>/")
    .privileges(redfish::privileges::getChassis)
    .methods(boost::beast::http::verb::get)(
        [](const crow::Request& req,
           const std::shared_ptr<bmcweb::AsyncResp>& asyncResp,
           const std::string& chassisId) {
            
            // 初始化标准字段
            asyncResp->res.jsonValue["@odata.type"] = "#Chassis.v1_xx_0.Chassis";  // 版本号随上游更新
            asyncResp->res.jsonValue["@odata.id"] = "/redfish/v1/Chassis/" + chassisId;
            asyncResp->res.jsonValue["Name"] = "evb-2u-egs Chassis";
            
            // 发起 D-Bus 调用获取物理信息...
        });
```

**错误处理模式**

当 D-Bus 调用失败时，`bmcweb` 不会直接崩溃或返回空对象，而是调用框架自带的 `messages::internalError(asyncResp->res)`，这会向客户端返回符合 Redfish 规范的标准 `InternalError` JSON 响应。注意，真正的故障根因通常只记录在服务端日志 (`journalctl -u bmcweb`) 中，不会直接暴露给客户端。

> 💡 **大白话**：这就像网上银行出错后，页面只显示"系统繁忙，请稍后重试"（标准的InternalError），而不是直接把内部报错堆栈甩到你脸上。真正的出错日志藏在银行的后台服务器（journalctl）里，工程师要排查才去看，绝不能让客户看到——既规范又安全。

### 5.8 curl 实战

由于 Redfish 基于标准 REST，开发者可以使用最基础的 `curl` 命令行工具与之交互。

**1. 忽略证书验证并读取根服务目录**
```bash
curl -k -u root:0penBmc https://192.168.1.100/redfish/v1/
```

以下是 evb-2u-egs 在 QEMU 中**实际返回**的 ServiceRoot 响应（已验证）：
```json
{
  "@odata.id": "/redfish/v1",
  "@odata.type": "#ServiceRoot.v1_15_0.ServiceRoot",
  "Id": "RootService",
  "Name": "Root Service",
  "RedfishVersion": "1.17.0",
  "Chassis": { "@odata.id": "/redfish/v1/Chassis" },
  "Managers": { "@odata.id": "/redfish/v1/Managers" },
  "Systems": { "@odata.id": "/redfish/v1/Systems" },
  "UpdateService": { "@odata.id": "/redfish/v1/UpdateService" },
  "AccountService": { "@odata.id": "/redfish/v1/AccountService" },
  "EventService": { "@odata.id": "/redfish/v1/EventService" },
  "TelemetryService": { "@odata.id": "/redfish/v1/TelemetryService" }
}
```

**2. 查询 BMC 管理器详情**
```bash
curl -k -u root:0penBmc https://192.168.1.100/redfish/v1/Managers/bmc
```

evb-2u-egs 实际返回的关键字段（QEMU 验证）：
```json
{
  "@odata.type": "#Manager.v1_19_0.Manager",
  "Id": "bmc",
  "ManagerType": "BMC",
  "PowerState": "On",
  "Status": { "Health": "OK", "State": "Enabled" },
  "Links": {
    "ManagerForChassis": [
      { "@odata.id": "/redfish/v1/Chassis/evb_2u_egs_Baseboard" }
    ]
  }
}
```

> 💡 **大白话**：注意 Chassis ID 不是固定的 "chassis"——在我们的平台上它是 `evb_2u_egs_Baseboard`，因为这个 ID 来自 Entity Manager 的 JSON 配置文件中的 `"Name"` 字段。不同平台的 Chassis ID 不同，千万不要硬编码。正确做法：先 GET `/redfish/v1/Chassis` 拿到成员列表，再用实际 ID 去查。

**3. 读取 evb-2u-egs 传感器的集合**
```bash
curl -k -u root:0penBmc https://192.168.1.100/redfish/v1/Chassis/evb_2u_egs_Baseboard/Sensors
```

**4. 修改设置 (以更改电源状态为例)**
使用 POST 方法向动作 (Action) 端点发送负载，重置系统：
```bash
curl -k -u root:0penBmc -H "Content-Type: application/json" -X POST \
-d '{"ResetType": "ForceRestart"}' \
https://192.168.1.100/redfish/v1/Systems/system/Actions/ComputerSystem.Reset
```

**EventService 订阅**

区别于 IPMI 的陷阱 (Trap) 机制，Redfish 提供了基于目标投递的事件订阅。客户端可以发送 POST 请求到 `/redfish/v1/EventService/Subscriptions` 注册一个接收告警的 Webhook URL。当温度过高或电源发生异常时，`bmcweb` 会主动推送 JSON 事件到该地址，彻底摆脱了被动轮询的低效机制。

> 💡 **大白话**：IPMI 的 Trap（PET）机制本身也是主动推送——BMC 有事就往预配置的管理站 IP 发一条 UDP 消息，像发短信一样"喊一嗓子就完事"，不保证对方收到，也没有订阅管理。Redfish EventService 则像微信公众号关注机制——你先发 POST 注册一个 Webhook 地址（"关注"），之后每有告警 bmcweb 会主动推送格式完整的 JSON 事件到你的地址，带重试、带认证、带订阅生命周期管理，比 UDP 喊话可靠得多。

### 5.9 面试题速查

1.  简述 IPMI 的 NetFn 和 Cmd 概念，以及它们在消息路由中的作用。
2.  OpenBMC 中 `ipmid` 进程和硬件通道 (如 KCS) 之间是如何交互数据的？
3.  为什么 OpenBMC 不采用静态配置来存储 SDR，而是选择动态生成策略？
4.  如果你需要添加一个新的 OEM NetFn (例如 0x3E)，并实现一个重启 BMC 的命令，简要描述代码开发流程。
5.  列举使用 `ipmitool` 诊断传感器状态和查看事件日志的具体命令。
6.  解释为什么在现代超大规模数据中心中，Redfish 逐渐取代 IPMI 成为管理协议的标准。
7.  `bmcweb` 服务在收到 `/redfish/v1/Systems/system` 的 GET 请求后，其内部执行的逻辑流程是怎样的？
8.  使用 `curl` 向 Redfish API 发送 POST 请求执行关机操作时，需要指定哪些关键的 HTTP Header 和 JSON 参数？

---

## 第六章：调试与验证

§6.1 QEMU 模拟环境

QEMU 是开发 OpenBMC 的核心工具，能在没有实体硬件的情况下进行完整的功能开发和验证。这大大加快了迭代速度。

OpenBMC 对 QEMU 的支持非常完善。底层依赖 `qemu-system-arm`，可以模拟基于 ASPEED SoC 的设备，例如 `romulus` 或 `evb-ast2600`。在 `openbmc-workspace` 目录下有一个预先配置好的启动脚本 `start-qemu-webui.sh`，它是启动模拟环境的最佳入口。

这个脚本会自动处理网络端口映射：
*   **SSH 2222端口**：映射到虚拟机的 22 端口，用于终端登录。
*   **WebUI 2443端口**：映射到 443 端口，可以直接在浏览器访问 BMC 的图形界面。
*   **IPMI 2623端口**：映射到 623 端口，用于通过 `ipmitool` 发送网络 IPMI 命令。

> 💡 **大白话**：QEMU 就是一台"飞行模拟器"。飞行员正式驾驶真飞机之前，先在地面模拟舱里练所有操作——紧急降落、发动机故障处理。这里的"飞机"是真实的AST2600服务器，QEMU是地面模拟舱，外观一摸一样但摔了也没关系。端口映射就像模拟舱把不同接口模拟成飞机各类仪表——2222是驾驶舱门（SSH），2443是导航仪表屏（WebUI），2623是通话系统（IPMI）。

默认的系统登录账号和密码分别是 `root` 和 `0penBmc`。请牢记，生产环境中绝不允许使用这个硬编码的默认密码。

**evb-2u-egs 实际验证过的 QEMU 启动命令**

以下是经过完整调试、可直接启动并成功运行 SSH + BMCWeb 的命令：

```bash
QEMU=/path/to/build/evb-2u-egs/tmp/work/x86_64-linux/qemu-helper-native/1.0/recipe-sysroot-native/usr/bin/qemu-system-arm
MTD=/path/to/build/evb-2u-egs/tmp/deploy/images/evb-2u-egs/obmc-phosphor-image-evb-2u-egs.static.mtd

$QEMU -machine ast2600-evb,execute-in-place=true,fmc-model=w25q512jv -m 1G \
  -drive file=$MTD,if=mtd,format=raw \
  -netdev user,id=usernet,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:2443-:443 \
  -net nic -net nic -net nic,netdev=usernet \
  -serial mon:stdio -serial null -nographic
```

**关键参数解释**：
*   `execute-in-place=true`：模拟 SPI NOR Flash XIP（就地执行），U-Boot SPL 直接从 Flash 读取而不需要先拷贝到 RAM。
*   `fmc-model=w25q512jv`：指定 Flash 芯片型号为 64MB 的旺宏 W25Q512JV，匹配我们的硬件定义。
*   `-net nic -net nic -net nic,netdev=usernet`：这是一个**关键技巧**。AST2600 有 4 个 ftgmac100 以太网控制器（mac0~mac3），QEMU 按顺序分配 `-net nic`。我们的 DTS 只启用了 mac2 和 mac3（因为实际硬件只有这两个口接了物理网线），所以需要前两个空的 `-net nic` 占掉 mac0 和 mac1，让带端口转发的 `netdev=usernet` 落到 mac2 上。

> 💡 **大白话**：三条 `-net nic` 就像排队取号——前两个"空号"（没有 netdev 后端）占掉 mac0 和 mac1 的位置，第三个"实号"（带着 hostfwd 端口转发的网络后端）刚好排到 mac2。因为 Linux 内核只会为 DTS 中 `status = "okay"` 的 NIC 创建网络接口，mac0/mac1 被 DTS 禁用了，即使 QEMU 硬件模型创建了它们，内核也看不见。这种"QEMU 设备模型层 vs Linux 设备树层"的分离概念，是调试虚拟化环境的核心认知。

§6.2 systemd 调试

OpenBMC 所有的用户态服务都由 systemd 管理。熟练掌握 systemd 命令是排查启动和运行问题的基石。

查看单个服务的状态和日志，最常用的组合是 `systemctl status <service>` 和 `journalctl -u <service>`。如果某个进程意外退出，`journalctl` 通常能捕捉到最后的错误输出。

分析系统启动性能或排查卡顿，使用 `systemd-analyze blame` 可以列出按耗时排序的服务列表。结合 `systemd-analyze critical-chain`，能直观看到哪些服务阻塞了关键启动路径。

常见的启动失败往往源于依赖循环 (dependency cycle) 或缺失服务文件 (missing service file)。当你修改了 `phosphor-state-manager` 或添加了自定义服务时，如果 `systemctl` 报错 "Job for xxx failed"，第一步永远是查看 `journalctl -xe`。

> 💡 **大白话**：systemd 调试就像在医院里给病人（服务）看病。`systemctl status` 是问诊——问病人"你哪里不舒服"；`journalctl -u` 是查病历——翻看最近的就诊记录找线索；`systemd-analyze blame` 是做体检报告——列出每个器官（服务）的启动耗时，一眼看出谁拖了后腿；`critical-chain` 是绘制"手术依赖图"——找到哪条血管堵塞导致整个手术室卡住了。

添加自定义 systemd service 需要在 Yocto 的 配方 中放入 `.service` 文件，并在 `do_install` 阶段将其安装到 `${D}${systemd_system_unitdir}/`。同时，别忘了在 配方 中声明 `inherit systemd` 和 `SYSTEMD_SERVICE:${PN} = "your-service.service"`。

§6.3 D-Bus 调试

OpenBMC 的组件间通信几乎全部依赖 D-Bus。可以说，不懂 D-Bus 就无法在 OpenBMC 中寸步难行。

`busctl tree` 用于查看当前总线上所有的对象路径。加上具体的服务名，例如 `busctl tree xyz.openbmc_project.State.Host0`（注意服务名通常带实例编号），能清晰看到对象树。也可以先通过 `busctl list | grep State` 查找实际的服务名。

`busctl introspect` 是最强大的探针命令。通过 `busctl introspect <service> <object_path>`，你可以列出该对象支持的所有接口、属性、方法及其签名。

> 💡 **大白话**：`busctl tree` 就像查公司组织架构图——先看总线上有哪些"部门"（服务）；`busctl introspect` 是看某个员工的详细简历——他会什么技能（方法）、负责哪些指标（属性）、按什么格式汇报（签名）；`busctl monitor` 则是在开放式办公室里安了一台录音机——所有人的对话实时播放，谁调用了谁、传了什么数据，一清二楚。

如果需要实时监控某个服务的状态变化，`busctl monitor <service>` 是不二之选。它会以流式输出打印所有相关的 D-Bus 消息包，包括方法调用和属性变更信号 (PropertiesChanged)。

另一个强大的工具是 `dbus-monitor`。配合过滤规则，它可以精准捕获特定的信号。

D-Bus activation 机制允许服务在收到请求时按需启动。排查这类问题时，重点检查 `/usr/share/dbus-1/system-services/` 下的 `.service` 文件名是否与 D-Bus 的 well-known name 一致。

§6.4 I2C 调试

硬件交互离不开 I2C。`i2c-tools` 包提供了基础的调试能力。

使用 `i2cdetect -y <bus>` 扫描指定 I2C 总线上的所有设备地址。这是确认硬件连接是否正常的第一步。接着，可以用 `i2cget -y <bus> <chip-address> <data-address>` 读取寄存器值，或者用 `i2cset` 写入数据验证控制逻辑。`i2cdump` 能一次性导出芯片的所有寄存器数据，非常适合调试传感器或 EEPROM。

在实际开发中，常见的 I2C 问题包括 NACK (无响应)、地址冲突和总线挂死 (bus hang)。NACK 通常意味设备未上电或地址错误。总线挂死则可能是从设备将 SDA 拉低，需要通过 GPIO 模拟时钟 (bit-banging) 或直接复位 I2C 控制器来恢复总线。

> 💡 **大白话**：I2C 调试就像排查小区单元楼的门禁系统。`i2cdetect` 是"住户普查"——按门牌号（地址）挨家挨户敲门，看哪家有人（有设备响应）；`i2cget` 是"抄水表"——读某家某个计量表的数值；`i2cset` 是"远程调节暖气阀"——往某家某个控制节点写数据。总线挂死就像有个住户把公共门锁住了不放手，其他所有人都进不了单元楼，得叫物业（手动bit-bang时钟）把门别开。

§6.5 GPIO 调试

新版内核推荐使用基于字符设备的 libgpiod 工具链，淘汰了旧的 sysfs 接口。

`gpioinfo` 用于查看系统中所有 GPIO 控制器的引脚状态、配置以及被哪些进程占用。`gpioget <chip> <line>` 读取特定引脚的电平，而 `gpioset <chip> <line>=<value>` 可以强制改变输出电平。

虽然 `/sys/class/gpio/` 接口已被标记为废弃 (deprecated)，但在旧版本内核或临时脚本中依然常见。你需要向 `export` 节点写入引脚编号，然后操作 `direction` 和 `value` 文件。

排查 GPIO 问题时，如果引脚方向无法改变或读取值与预期不符，首先检查设备树 (Device Tree) 中是否有其他驱动占用了该引脚 (pinmux 冲突)，然后利用 `gpioinfo` 确认资源归属。

> 💡 **大白话**：GPIO 就像宿舍楼里的电灯开关——每个引脚要么是"输出"（你控制开关）要么是"输入"（你观察状态）。`gpioinfo` 是查"开关使用权登记表"——看哪个开关被哪个室友（驱动）注册了；`gpioget` 是去看一眼开关现在是开还是关；`gpioset` 是伸手去拨。如果你发现开关拨不动，八成是有人在设备树里提前注册了这个开关的控制权，产生了"谁先抢到谁先用"的pinmux冲突。

§6.6 内核调试

`dmesg` 是查看内核日志的基础。如果信息过多或过少，可以通过 `echo <level> > /proc/sys/kernel/printk` 动态调整日志级别。

针对驱动开发的疑难杂症，动态调试 (dynamic_debug) 是一把利器。只需确保内核开启了 `CONFIG_DYNAMIC_DEBUG`，即可通过向 `/sys/kernel/debug/dynamic_debug/control` 写入特定字符串，针对单独的文件、函数或行号开启 debug 级别的输出，而无需重新编译内核。

> 💡 **大白话**：动态调试就像医院里的"床旁监护仪"——不用把病人送回手术室重新开刀（重新编译内核），就能现场打开某个指定器官（驱动文件/函数）的实时监测。你只需要往控制文件里写一句话，就像给监护仪设一个新的监测项，立刻开始输出心电图（debug日志），用完再关掉，完全不影响其他病人（其他模块）。

设备树覆盖 (device tree overlay) 允许在运行时动态加载和修改硬件描述。在调试复杂的外设时，可以编译一个 `.dtbo` 文件并通过 configfs (`/sys/kernel/config/device-tree/overlays/`) 加载，避免了频繁刷写整个镜像的痛苦。

> 💡 **大白话**：设备树覆盖就像给手机系统打"补丁包"——不用重装整个系统（刷写整个镜像），只需要额外安装一个小包（.dtbo 文件），系统就认识了新接的硬件。调试时试错成本极低，装了不对，卸载掉重来，跟给手机安装/卸载App一样方便。

§6.7 网络调试

OpenBMC 使用 `systemd-networkd` 管理网络。发行版默认配置文件位于 `/usr/lib/systemd/network/`，本地覆盖配置位于 `/etc/systemd/network/`。

VLAN 的配置需要创建对应的 `.netdev` 和 `.network` 文件，将虚拟网络接口绑定到物理网卡上。

常见的网络问题涵盖 MAC 地址未正确烧录 (显示为全零或随机分配)、DHCP 获取失败或防火墙阻断。排查 DHCP 问题时，检查 `journalctl -u systemd-networkd` 即可找到租约请求的日志。

> 💡 **大白话**：BMC 的网络问题就像新员工入职时的门禁卡出错。MAC 地址全零就像门禁卡没有工号，物业系统（DHCP）根本认不出你；DHCP 失败就像你拿着卡刷了很多次都没响应，去查门禁日志（journalctl -u systemd-networkd）才能知道到底是卡坏了、系统宕机了，还是被物业拉黑了。

**QEMU 环境的网络特殊性**

在 QEMU 开发环境中，网络行为与实机有几个重要差异：

*   **SLIRP 用户态网络**：QEMU 的 `-netdev user` 使用内置的 SLIRP 网络栈，BMC 获得的 IP 通常是 `10.0.2.15/24`，网关 `10.0.2.2`。这是 QEMU 内置的虚拟 NAT 网络，不需要宿主机上任何网桥配置。
*   **端口转发**：通过 `hostfwd=tcp:127.0.0.1:2222-:22` 等参数，将宿主机端口映射到 QEMU 内部端口。注意 SLIRP 模式下 BMC 无法主动连接宿主机，只能通过端口转发实现宿主机→BMC 的入站连接。
*   **DHCP 自动获取**：OpenBMC 的默认网络配置文件 `/usr/lib/systemd/network/60-phosphor-networkd-default.network` 为所有以太网接口启用了 `DHCP=true`。在 QEMU SLIRP 环境中，QEMU 内置的 DHCP 服务器会自动为 BMC 分配 IP，无需手动配置。
*   **NIC 选择陷阱**：如 §6.10 案例 B3 所述，QEMU 设备模型层的 NIC 分配和 DTS 启用的 NIC 是两个独立层次。务必确保端口转发的网络后端连接到 DTS 中 `status = "okay"` 的那个 NIC 上。

> 💡 **大白话**：QEMU 的 SLIRP 网络就像酒店里的 Wi-Fi——你一插上网线（启动 QEMU）自动就有 IP 了（10.0.2.15），不需要去前台（手动配置网络）。但这个 Wi-Fi 有个限制：房间里（BMC）不能主动打电话给前台（宿主机），只能前台通过房间号（端口转发）打给你。实机部署时 BMC 直接插网线获得真实 IP，就没有这个限制了。

§6.8 固件更新调试

固件更新是 BMC 的核心能力之一，由 `phosphor-software-manager` 统筹。

通过 Redfish 接口触发的更新采用**推送模式 (Push)**：客户端将固件镜像直接上传到 bmcweb 的 `HttpPushUri` 或 `MultipartHttpPushUri` 端点，bmcweb 再通过 D-Bus 将镜像交给 `phosphor-software-manager` 处理。注意：远程 HTTPS 拉取模式 (`SimpleUpdate`) 目前在上游**尚未实现**。签名校验是否执行取决于 `phosphor-software-manager` 是否启用了 `verify_signature` PACKAGECONFIG 选项（默认未启用）。

部分 OpenBMC 平台（如 evb-2u-egs 的双 64MB Flash 主备架构，总 128MB）采用双 bank 机制保障安全。主备两个 Flash 芯片（Bank A / Bank B）轮流作为启动介质。当新版本写入备用 bank 并通过校验后，系统修改 U-Boot 环境变量，将下一次启动指向新 bank。

> 💡 **大白话**：双 bank 固件更新就像手机的双系统备份机制——手机有A区和B区两套系统，平时用A区跑，更新时把新版本悄悄写到B区，写完校验OK了再把"下次开机启动哪个区"的标签贴到B区。如果新系统开机后未通过看门狗测试（相当于开机自检失败），看门狗复位后 U-Boot 根据 bootcount 将启动指针切回A区。不过，自动回滚能力取决于 U-Boot 和平台是否实现了 bootcount 逻辑——这不是硬件自带的魔法，需要软件配合。

如果更新失败或新固件崩溃，看门狗 (watchdog) 会在超时后复位系统。**双 bank 回滚策略是平台和 bootloader 具体实现**，并非 OpenBMC 通用层统一保证的行为。通用层提供了 dual-image 和 update hook 机制，但具体的回滚阈值、自动切换逻辑需要在各平台的 U-Boot 配置中实现。

§6.9 性能分析

资源受限是 BMC 环境的常态。使用 `top` 或更易读的 `htop` 实时观察 CPU 和内存消耗情况。`vmstat` 能快速评估系统的整体负载和虚拟内存交换情况。

SPI Flash 的写入速度极慢。使用 `iotop` 能精确定位哪些进程在频繁落盘，导致系统出现卡顿。通常应将高频写入的日志定向到内存文件系统 (tmpfs)。

> 💡 **大白话**：BMC 的 SPI Flash 写入就像在用墨水笔往石头上刻字——每写一行都极慢，写完还不能反复横跳（擦写次数有限）。如果你的服务每5秒往Flash里写一次日志，迟早把Flash刻穿。`iotop` 就是找出谁在疯狂刻字的"监控摄像头"，发现之后把那个服务的日志改写到内存（tmpfs）——内存写字就像在白板上写，快而且不伤板子。

`strace` 是终极的黑盒调试工具。在没有源码的情况下，用 `strace -p <pid>` 跟踪进程的系统调用，观察它卡在哪个文件读取、网络 socket 还是锁竞争上。

> 💡 **大白话**：`strace` 就像给一个"沉默的仓库工人"安了个窃听器。不用看他的合同（源码），只要听他干活时喊的每一句话（系统调用）——"我现在开这个文件"、"我等那个网络回复"、"我在等人释放这把锁"——哪里停顿太久，哪里就是问题所在。对付那些没有源码的闭源二进制也同样好使。

针对更深层次的性能瓶颈，`perf` 工具能进行 CPU 采样并导出调用栈数据。配合 `perf script` 输出和 FlameGraph 等可视化工具，可以生成火焰图 (flamegraph)，直观暴露耗时最长的函数调用栈。

> 💡 **大白话**：火焰图就像给程序做"CT扫描"。`perf` 每隔几毫秒戳一下程序问"你现在在干嘛"，收集几千次答案，最后把"谁最频繁被戳到"画成一张图——越宽的色块代表越耗时的函数，一眼就能看出哪块"肌肉"在疯狂运转。找到那块最胖最宽的色块，就找到了性能优化的主战场。

§6.10 实战 Troubleshooting 案例集 — evb-2u-egs 项目真实战报

以下 13 个案例全部来自 evb-2u-egs 项目的真实开发过程。每一个都是实际遇到并解决的问题，不是教科书上编出来的"示例"。按开发阶段分为三组：构建阶段（A 组）、QEMU 启动阶段（B 组）。

> 💡 **大白话**：这一节相当于项目的"踩坑日记"。大厂面试最爱问"你遇到过最棘手的 bug 是什么，怎么解决的"——能从现象到根因到修复讲清楚一个真实案例，比背 100 道八股文值钱 10 倍。下面 13 个案例就是你面试时的弹药库。

---

**A 组：构建阶段（10 个案例）**

**案例 A1：entity-manager do_fetch 网络拉取失败**

现象：
```
ERROR: entity-manager-1.0+git...: do_fetch: Fetcher failure: Unable to find revision ...
```
BitBake 在 `do_fetch` 阶段尝试从 GitHub 克隆 entity-manager 仓库时失败，提示无法找到指定的 git revision。

根因分析：
构建环境的网络无法直接访问 GitHub（可能是代理、防火墙或 DNS 问题）。BitBake 的 git fetcher 需要在线克隆仓库到 `DL_DIR`，网络不通就直接挂掉。

修复方法：
在网络畅通的环境手动执行 `git clone --bare --mirror` 克隆仓库到 `DL_DIR/git2/` 对应路径下。BitBake 发现本地已有缓存后会跳过网络拉取。
```bash
# 在 DL_DIR/git2/ 下建立 bare mirror
git clone --bare --mirror https://github.com/openbmc/entity-manager.git \
    ${DL_DIR}/git2/github.com.openbmc.entity-manager.git
```

> 💡 **大白话**：BitBake 下载代码就像网购——下单（do_fetch）后快递（git clone）送货上门。网不通就等于快递被拦在小区门口。解决方案是自己跑去仓库把货搬回来放在"菜鸟驿站"（DL_DIR/git2/），BitBake 发现驿站里已经有了就不再下单。这个技巧在公司内网开发环境里非常常见。

**案例 A2：内核补丁文件格式损坏**

现象：
```
ERROR: linux-aspeed-6.18.21+git...: do_patch: ... patch file corrupt at line 16
```
自定义的 DTS 补丁（`0001-ARM-dts-aspeed-Add-EVB-2U-EGS-board.patch`）在 `do_patch` 阶段被 `git apply` 拒绝。

根因分析：
补丁文件不是由 `git format-patch` 生成的标准格式，而是手工拼凑的。Git 的补丁解析器对格式要求极其严格，包括 header 中的 `From`、`Date`、`Subject` 行，以及 diff 中的空格/制表符对齐。手工拼接的补丁很容易在行尾空格、空行数量、diff header 格式上出错。

修复方法：
用标准 Git 工作流重新生成补丁：先在一个干净的内核源码树中 `git add` 改动的文件，`git commit`，再用 `git format-patch -1` 导出标准补丁文件。
```bash
# 在内核源码目录中
git add arch/arm/boot/dts/aspeed/aspeed-bmc-evb-2u-egs.dts
git commit -m "ARM: dts: aspeed: Add EVB-2U-EGS board"
git format-patch -1 --output-directory /path/to/recipe/
```

> 💡 **大白话**：Git 补丁格式就像写公文——有固定的行文格式，标题、日期、正文、签名，一个都不能错。自己手打的补丁就像用 Word 排版去投正式公文，格式一定对不上。`git format-patch` 就是自动排版机，保证输出的每一行格式都符合 Git 的"公文标准"。记住：**永远不要手写补丁文件。**

**案例 A3：补丁缺少 Upstream-Status 标签（内核补丁）**

现象：
```
ERROR: linux-aspeed: QA Issue: Patch ... does not have a valid Upstream-Status
```
BitBake 的 QA 检查（`insane.bbclass`）拒绝了补丁文件，因为缺少 `Upstream-Status` 标签。

根因分析：
OpenBMC 的构建系统强制要求每个补丁文件在 commit message 中包含 `Upstream-Status:` 标签。这是为了追踪每个补丁与上游社区的关系状态。合法的值包括 `Pending`（计划提交上游）、`Backport`（从上游版本回移）、`Inappropriate`（不适合上游）等。

修复方法：
在补丁文件的 commit message 区域（`---` 分隔线之前）添加：
```
Upstream-Status: Pending
```

> 💡 **大白话**：`Upstream-Status` 就像论文的"参考文献标注"——每个补丁都要声明"这段改动跟上游社区是什么关系"。`Pending` = 我写的，还没往上游投；`Backport` = 从上游新版本抄回来的；`Inappropriate` = 这是我们自己的私有改动，不适合给上游。Yocto 社区靠这个标签来管理几千个补丁的来源追溯，漏了就不让你编译。

**案例 A4：phosphor-pid-control 打包遗漏文件**

现象：
```
ERROR: phosphor-pid-control: installed-vs-shipped: files installed but not shipped:
  /usr/share/swampd/config.json
```
编译安装成功，但 BitBake 的打包阶段（`do_package`）发现有文件被安装到了 image 目录但没有被任何包声明。

根因分析：
bbappend 中通过 `do_install:append` 安装了自定义的 `config.json` 到 `/usr/share/swampd/`，但没有在 `FILES:${PN}` 中声明这个路径。BitBake 的 `installed-vs-shipped` QA 检查会捕捉这种"安装了但没人认领"的文件。

修复方法：
在 bbappend 中追加文件声明：
```bitbake
FILES:${PN}:append = " /usr/share/swampd/config.json"
```
注意 `append` 前面的空格——这是 BitBake 字符串拼接的经典陷阱，缺少空格会导致路径粘连。

> 💡 **大白话**：BitBake 打包就像搬家公司清点行李。`do_install` 把东西搬进新房子（image 目录），`FILES:${PN}` 是搬家清单。搬进去的东西如果不在清单上，搬家公司就会报警："这箱子谁的？没人认领！"。解决方案就是在清单上补一行。注意 `:append` 后面那个空格——没有它就变成`/usr/bin/xxx/usr/share/yyy`，两个路径粘在一起了。

**案例 A5：DTS 文件未被内核编译系统拾取**

现象：
编译成功，但生成的 FIT Image 中不包含自定义的 `aspeed-bmc-evb-2u-egs.dtb`。内核编译日志中没有任何编译该 DTS 的记录。

根因分析：
最初尝试通过 `do_configure:append` 复制 DTS 文件到内核源码树，但时机太早——`do_compile` 开始时内核的 Makefile 已经确定了要编译哪些 DTB。正确的做法是在 `do_patch:append` 阶段（编译前的最后修改窗口）将 DTS 文件复制到位，确保内核的构建系统能发现它。

修复方法：
```bitbake
# linux-aspeed_%.bbappend
do_patch:append() {
    cp ${WORKDIR}/aspeed-bmc-evb-2u-egs.dts \
       ${S}/arch/arm/boot/dts/aspeed/
}
```
同时确保内核的 `arch/arm/boot/dts/aspeed/Makefile` 中有对应的 `dtb-$(CONFIG_ARCH_ASPEED) += aspeed-bmc-evb-2u-egs.dtb` 条目（通过补丁添加）。

> 💡 **大白话**：这就像考试交卷的时机问题。`do_configure` 阶段老师已经在数卷子了（确定编译列表），你这时候才把答题纸塞进去，老师已经不看了。`do_patch` 阶段是老师还没开始数卷子的最后窗口，这时候塞进去才能被计入成绩。**时机就是一切。**

**案例 A6：U-Boot smbios.c 编译错误 — 未声明的宏**

现象：
```
error: 'U_BOOT_DMI_DATE' undeclared
```
U-Boot 编译到 `lib/smbios.c` 时报错，某个时间戳宏未定义。

根因分析：
上游 U-Boot 代码中 `smbios.c` 引用了 `U_BOOT_DMI_DATE` 宏，这个宏应该由构建系统在编译时通过 `-D` 传入或由 `timestamp.h` 提供。但特定版本的代码中缺少了 `#include "timestamp.h"` 这一行，导致宏未声明。

修复方法：
创建 U-Boot bbappend 和补丁，在 `lib/smbios.c` 中添加缺失的 `#include`：
```c
// 补丁内容
+#include "timestamp.h"
```

> 💡 **大白话**：这就像写代码引用了一个变量但忘了 `import` 对应的头文件。C 语言里宏定义藏在头文件中，编译器看不到 `#include` 就不知道那个宏是什么。修复就是一行 `#include`——但要在 Yocto 里用补丁的方式加，不能直接改上游代码。

**案例 A7：U-Boot 补丁缺少 Upstream-Status 标签**

现象：
与 A3 相同的 QA 报错，但这次是 U-Boot 的补丁文件。

根因分析/修复方法：
与 A3 完全一致。每个补丁文件都需要 `Upstream-Status` 标签，无论是内核补丁还是 U-Boot 补丁。OpenBMC 的 QA 策略是全局生效的。

> 💡 **大白话**：同一个坑踩两次说明这不是偶然——是系统性要求。写完补丁后的检查清单应该包含"Upstream-Status 标签"这一项。好的工程师不是不踩坑，而是踩过一次就把坑记到检查清单里，再也不踩第二次。

**案例 A8：SOCSEC/OTPTOOL 签名配置为空导致构建失败**

现象：
```
ERROR: ... OTPTOOL_CONFIGS is empty
```
构建系统在处理安全签名相关的任务时失败，因为 `OTPTOOL_CONFIGS` 变量为空。

根因分析：
ASPEED 的安全启动（Secure Boot）功能需要 OTP（One-Time Programmable）配置文件来生成签名后的固件。如果机器配置中启用了 `SOCSEC_SIGN_ENABLE` 但没有提供 OTP 配置文件，就会报错。在开发阶段不需要安全签名。

修复方法：
在 `machine.conf` 中显式关闭签名功能：
```bitbake
SOCSEC_SIGN_ENABLE = "0"
```

> 💡 **大白话**：这就像新车出厂前要求贴防伪标签，但你连标签打印机都还没买。`SOCSEC_SIGN_ENABLE = "0"` 就是告诉产线："这台是工程样机，不用贴标签。"等产品要量产出货时再打开签名、配置好 OTP 密钥。开发阶段跳过签名是业界标准做法。

**案例 A9：phosphor-hostlogger systemd 模板实例化失败**

现象：
```
ERROR: phosphor-hostlogger: postinst failed: systemctl: could not find template unit
```
打包阶段的 `postinst` 脚本尝试 enable 一个 systemd 模板单元（`phosphor-hostlogger@.service`），但找不到模板文件。

根因分析：
`phosphor-hostlogger` 使用 systemd 模板单元（`@.service`），允许为每个串口实例化不同的日志服务。但默认的 `SYSTEMD_SERVICE` 声明和实际安装的文件不匹配——可能是模板名变了或者 bbappend 中的覆盖逻辑不完整。

修复方法：
在 bbappend 中完整覆盖 `SYSTEMD_SERVICE` 变量，确保声明的单元名与实际安装的文件精确匹配：
```bitbake
SYSTEMD_SERVICE:${PN} = "phosphor-hostlogger@.service"
```

> 💡 **大白话**：systemd 模板就像"万能遥控器模板"——`@.service` 是模板，`@ttyS0.service` 是对着某个串口生成的实例。BitBake 的 `SYSTEMD_SERVICE` 变量就是告诉打包系统"我有哪些遥控器模板"，名字写错一个字母，打包系统就找不到模板，实例化就失败。

**案例 A10：phosphor-hostlogger installed-vs-shipped（模板单元文件）**

现象：
与 A4 类似的 `installed-vs-shipped` 错误，但这次是 systemd 模板单元文件没被包声明。

根因分析：
systemd 模板单元文件安装到了 `/lib/systemd/system/`，但 `FILES:${PN}` 没有覆盖到这个路径下的模板文件。

修复方法：
```bitbake
FILES:${PN}:append = " ${systemd_system_unitdir}/phosphor-hostlogger@.service"
```

> 💡 **大白话**：又是"搬家清单"问题（参见 A4）。这次不是 config 文件，是 systemd 的模板单元文件。同样的道理：安装了就必须认领，否则 QA 检查不放行。

---

**B 组：QEMU 启动阶段（3 个案例）**

**案例 B1：U-Boot 无串口输出 — defconfig 选错了**

现象：
QEMU 启动后串口完全无输出，黑屏。没有 U-Boot banner，没有任何字符。

根因分析：
`machine.conf` 中配置了 `UBOOT_MACHINE = "ast2600_openbmc_defconfig"`。这个 defconfig 是为 **Intel 实体硬件** 准备的，它把串口路由到了 `UART5`（对应 ASPEED 的 ttyS4），而不是 QEMU 默认映射的 `UART1`（ttyS0）。QEMU 的 `-serial` 参数连接的是第一个 UART（UART1/ttyS0），所以完全看不到输出。

另外，`ast2600_openbmc_defconfig` 不启用 SPL（Secondary Program Loader），而 QEMU 的 `execute-in-place=true` 模式需要 SPL 来正确初始化内存控制器。

修复方法：
```bitbake
# machine.conf
UBOOT_MACHINE = "ast2600_openbmc_spl_defconfig"
SPL_BINARY = "spl/u-boot-spl.bin"
```
`ast2600_openbmc_spl_defconfig` 是 OpenBMC 社区所有 AST2600 机器在 QEMU 中使用的标准配置，它将串口输出路由到 UART1，并启用 SPL。

> 💡 **大白话**：这就像你买了个电视机但遥控器是别的型号——按了开机键电视没反应，不是电视坏了，是遥控器发射的红外频率不对。`ast2600_openbmc_defconfig` 是 Intel 实机的"遥控器"，把信号发到了 UART5（实机上的调试串口）；QEMU 只"听" UART1。换成 `spl_defconfig` 就是拿对了遥控器。**教训：QEMU 调试和实机调试可能需要不同的 U-Boot 配置，这不是 bug，是架构设计。**

**案例 B2：内核启动 panic — SPI Flash 内存映射失败（QEMU 环境）**

现象：
U-Boot 正常启动，内核开始引导，但很快 kernel panic：
```
aspeed-smc 1e620000.spi: Can't map window for chip 0
Kernel panic - not syncing: VFS: Unable to mount root fs
```

根因分析：
ASPEED AST2600 的 FMC（Flash Memory Controller）需要通过 AHB（Advanced High-speed Bus）将 SPI Flash 映射到 CPU 的虚拟地址空间。这个映射窗口最大需要 256MB 的 vmalloc 空间。

这个问题的解决方案取决于 **RAM 大小**：

| 环境 | RAM | 最佳方案 | 原因 |
|------|-----|---------|------|
| QEMU | 1GB | 使用默认 `VMSPLIT_2G` | 1GB RAM 直接映射只占一半内核空间，vmalloc 有 ~960MB，完全够用 |
| 真机 | 2GB | `VMSPLIT_3G_OPT` + `vmalloc=512M` | 2GB RAM 把 VMSPLIT_2G 的内核空间挤满，必须改变分割比例并显式预留 vmalloc |

在 QEMU 阶段，我们去掉了 `CONFIG_VMSPLIT_3G_OPT=y`，用默认的 `VMSPLIT_2G` 即可正常启动。但上真机后（2GB RAM），必须**反过来加回** `VMSPLIT_3G_OPT` 并配合 U-Boot bootargs `vmalloc=512M`。完整的真机故障排查过程见 §9.8 案件 8，原理详解见 §9.10。

> 💡 **大白话**：ARM 32 位 Linux 把 4GB 虚拟地址空间切成两半，上面给内核用，下面给用户程序用。QEMU 只有 1GB RAM，默认切法（各 2GB）绰绰有余。但真机有 2GB RAM，2GB 的货要塞进 2GB 的仓库，SPI 驱动那 256MB 的"大件"就没地方放了。解决办法：换一种切法（VMSPLIT_3G_OPT），让多出的 RAM 走"二级仓库"（Highmem），主仓库里腾出空间给大件。**教训：同一个固件在 QEMU 和真机上的表现可能截然不同，RAM 大小就是最常见的差异源。**

**案例 B3：SSH/BMCWeb 无法连接 — QEMU NIC 映射不匹配**

现象：
QEMU 中 BMC 启动到登录界面，但从宿主机无法 SSH（端口 2222）也无法访问 BMCWeb（端口 2443），连接直接被拒绝。BMC 内部 `ip addr` 显示所有网络接口都没有 IP 地址。

根因分析：
这是一个 QEMU 虚拟网络与 DTS 网络设备启用状态不匹配的问题。

AST2600 有 4 个 ftgmac100 以太网控制器（mac0~mac3）。我们的 DTS 只启用了 `mac2`（`&mac2 { status = "okay"; }`）和 `mac3`（`&mac3 { status = "okay"; }`），因为实际硬件上只有这两个口接了物理网线。

QEMU 的 `-net nic` 参数按顺序创建虚拟 NIC 并连接到设备模型中的下一个可用网卡。**关键细节**：QEMU 的 `ast2600-evb` 机器模型总是创建 4 个 ftgmac100 实例（mac0~mac3），不管 DTS 是否启用它们。`-net nic` 连接的是设备模型层面的 NIC，不是 Linux 内核层面的。

所以一条 `-net nic,netdev=usernet` 只会连到 mac0 —— 但 mac0 在 DTS 中是 `status = "disabled"`，Linux 内核根本不会为它创建网络接口。用户网络后端（hostfwd 端口转发）就浪费了。

修复方法：
用多条 `-net nic` 跳过前两个禁用的 NIC，让带有 `netdev=usernet` 的 NIC 落到 mac2 上：
```bash
-net nic -net nic -net nic,netdev=usernet
```
前两个 `-net nic`（无 netdev）分别占用 mac0 和 mac1（无网络后端，等于空连接）。第三个 `-net nic,netdev=usernet` 连到 mac2，这才是 DTS 启用的、内核能看到的网卡。

> 💡 **大白话**：想象一排 4 个停车位（mac0~mac3），你的车（用户网络后端，带端口转发的那个）需要停在 3 号位（mac2），因为只有 3 号和 4 号位有充电桩（DTS 启用）。但 QEMU 默认把车停在 1 号位（mac0）——1 号位没充电桩（DTS 禁用），你的车充不了电（内核看不到网卡），自然上不了网。解决方案：先放两辆"占位车"（空的 `-net nic`）占掉 1 号和 2 号位，你的真车自然排到 3 号位。**教训：QEMU 设备模型和 Linux 设备树是两个独立的层次。QEMU 不管你 DTS 启没启用，它照样创建所有硬件实例。理解这种"硬件模型 vs. 软件配置"的分层关系，是调试虚拟化环境的关键能力。**

---

**案例集总结**

| 阶段 | 案例数 | 核心教训 |
|------|--------|---------|
| 构建 — 网络/资源获取 | 1 | DL_DIR 本地缓存是离线开发的关键 |
| 构建 — 补丁格式/标签 | 3 | 永远用 `git format-patch`，永远加 `Upstream-Status` |
| 构建 — 打包声明 | 3 | 安装了就必须在 `FILES` 中声明 |
| 构建 — 编译错误 | 1 | 上游代码的 bug 用补丁修，不改源码 |
| 构建 — 平台配置 | 2 | 开发阶段关闭签名；systemd 模板名必须精确匹配 |
| QEMU — 串口/U-Boot | 1 | QEMU 和实机可能需要不同的 defconfig |
| QEMU — 内核内存 | 1 | 嵌入式内存分割必须考虑外设映射需求 |
| QEMU — 网络 | 1 | QEMU 设备模型和 DTS 是独立的两层 |

> 💡 **大白话**：回头看这 13 个案例，真正"难"的不超过 3 个（B1、B2、B3），其他都是"知道规矩就不会犯"的低级错误。但这恰恰说明了一个残酷的事实：嵌入式开发 80% 的时间不是花在写代码上，而是花在跟构建系统、工具链、硬件怪癖搏斗上。能把这些"搏斗经验"系统性地总结出来，就是你和刚毕业的人之间的核心差距。面试官问你"遇到最难的 bug"，你能从构建系统讲到设备模型讲到内存映射，层层递进，这就是大厂想要的系统性思维。

## 第七章：面试杀手锏

§7.1 项目包装：STAR 法则

在面试中，讲好一个项目比罗列技术名词更重要。你需要把 `evb-2u-egs` 这个项目包装成一个展现深度与广度的故事。

> 💡 **大白话**：面试讲项目就像写工作年终总结汇报——光说"我今年很努力"没用，要说"公司去年面临什么问题，领导给我派了什么任务，我具体怎么搞定的，最后带来了多少效益"，STAR 就是这套结构的标准模板，让评委一听就能判断你的层次。

**Situation (情境)**
公司计划将基于 Intel EGS 平台的 `evb-2u-egs` (AST2600 A1) 从传统的 AMI MegaRAC SPX 4.0 闭源架构迁移到 OpenBMC 现代开源生态。闭源方案代码庞大 (约 3.5 万个文件、2.1GB)，定制困难，且无法满足新一代的数据中心自动化运维需求。

**Task (任务)**
作为核心研发，我需要独立完成新平台的硬件驱动适配、机器层 (machine layer) 的从零构建，并确保原有 IPMI 协议的平滑过渡，同时引入 Redfish 支持。

**Action (行动)**
首先，我从海量的遗留代码和长达 1967 行的硬件定义文档中，提取出精确的 GPIO (47根引脚)、I2C 拓扑 (26个设备) 和电源时序控制逻辑，重构为整洁的 Device Tree。
其次，我在 Yocto 环境中规划并创建了包含 26 个文件的定制机器层，覆盖机器配置、内核 DTS、U-Boot 补丁、Entity Manager 传感器配置、PID 风扇控制、LED 分组、电源控制等全部子系统。针对散热挑战，基于旧版的风扇 RPM 表格，我在 `phosphor-pid-control` 中重新实现了精准的 PID 温控策略。
最后，解析约 2152 行的 OEM IPMI 规范文档，将 78 条专有命令通过 `phosphor-ipmi-host` 框架重新以 C++ 实现。

**Result (结果)**
项目从 AMI 遗留代码的分析到 OpenBMC 机器层的完整交付，全部独立完成并通过验证。构建系统在解决 10 个不同类别的构建错误后成功编译出 64MB 固件镜像（7164 个 BitBake 任务全部通过）。固件在 QEMU 模拟环境中完成了从 U-Boot SPL 引导到 Linux 内核启动再到 systemd 全服务就绪的完整启动链验证，40+ 个 D-Bus 服务正常运行，Entity Manager 成功加载全部 37 个设备配置。SSH 远程管理和 BMCWeb Redfish API 均验证通过，BMC 状态达到 Ready。基于 OpenBMC 的多进程、D-Bus 解耦架构，平台定制代码量相比 AMI 的 3.5 万个文件大幅精简至 26 个文件的机器层。新架构完全保留了原有 78 个 OEM IPMI 命令的迁移方案，并原生支持 Redfish 现代化管理接口（包括 WebUI 图形界面）。

> 💡 **大白话**：STAR 答题法的精髓不是背台词，而是把技术经历转化成"侦探破案"的故事线——我遇到了什么谜题，手头有什么约束，一步步如何推理破局，最终案件侦破的战果如何。让面试官感觉在听一部有起伏的短剧，而不是在读简历流水账。

§7.2 技术深度问题 (30+ 题)

> **面试要点**
> 大厂面试不仅要答案正确，更要求能延伸出底层的原理。回答时务必遵循核心概念 + 实际项目例子的结构。

**Yocto/BitBake**

Q: 解释 BitBake 的 task 依赖机制是如何工作的？
A: BitBake 通过解析 recipe 文件生成任务图 (task graph)。任务之间存在先后顺序，例如 `do_compile` 必须在 `do_configure` 之后执行。它通过计算输入文件和任务签名 (task signature) 来决定是否需要重新执行特定任务，这就是 sstate-cache 能够加速构建的核心原理。

> 💡 **大白话**：BitBake 的任务图就像公司的项目甘特图——人力资源（配置）不到位就不能开工（编译），打包必须等安装完成。而签名机制就像每个任务都贴了一张"工单摘要"，只要材料和工序描述没变，下次直接从仓库里取成品，不用重新走一遍流水线，省工省时。

Q: `.bb` 文件和 `.bbappend` 有何区别？项目里如何运用？
A: `.bb` 是基础配方，定义软件的下载、编译和安装规则。`.bbappend` 是追加文件，用于修改或覆盖同名 `.bb` 的配置。在 `evb-2u-egs` 项目中，绝不直接修改 `meta-phosphor` 的原生配方，而是通过在厂家层添加 `.bbappend` 注入定制补丁或覆盖 systemd 服务文件。

> 💡 **大白话**：`.bb` 就是总公司发下来的"标准操作手册"，`.bbappend` 就是我们分公司自己写的"地区附加细则"。总公司的手册我们不能改，但细则可以补充覆盖。这样总公司升级手册时，我们的细则不受影响，完美解耦。

Q: `PREFERRED_PROVIDER_virtual/kernel` 的作用是什么？
A: 它是一个虚拟包机制，允许 Yocto 发行版在多个提供相同功能的配方中做出选择。比如 ASPEED 平台可能有多个内核分支版本，通过设定这个变量，我们在 `evb-2u-egs` 的 `machine.conf` 中明确指定使用 Linux-ASPEED 这个特定的源码树来提供内核功能。

Q: `IMAGE_INSTALL` 和 `IMAGE_FEATURES` 的设计理念差异在哪？
A: `IMAGE_INSTALL` 直接硬编码要安装的包列表，不够灵活。OpenBMC 采用特性驱动模式，使用 `IMAGE_FEATURES`。你可以声明需要 "obmc-fan-control" 或 "obmc-bmcweb" 特性，系统会自动映射并引入对应的 `packagegroup` 集合，提高了不同平台间配置的复用率。

Q: 如何调试一个总是触发重新编译的 配方？
A: 使用 `bitbake -S printdiff <配方>` 对比任务签名的差异。这会显示具体的哪个变量、环境变量或输入文件哈希发生了改变，从而打破了 sstate-cache 的缓存命中。

**D-Bus/IPC**

Q: System Bus 和 Session Bus 的区别？BMC 使用哪种？
A: System Bus 全局唯一，用于系统级服务通信和硬件状态广播。Session Bus 是用户登录后创建的，针对单个桌面会话。OpenBMC 作为没有传统用户的守护进程系统，所有通信都在 System Bus 上进行。

Q: 解释 D-Bus 中的 Object Manager 接口。
A: 它的核心是 `GetManagedObjects` 方法，允许客户端一次性批量获取某个服务对象树下所有子对象及其接口和属性，极大地减少了 D-Bus IPC 往返次数。同时配合 `InterfacesAdded/InterfacesRemoved` 信号反映对象的增删变化。注意，属性的实时变更通常仍通过 `PropertiesChanged` 信号传递。在 OpenBMC 中，bmcweb 的 Redfish 实现大量使用 `GetManagedObjects` 来批量收集传感器、库存等数据。

Q: PropertiesChanged 信号的应用场景？
A: 这是 D-Bus 原生的订阅/发布机制。当设备状态变化 (如温度超标) 时，服务端发送该信号。在 `evb-2u-egs` 中，PID 散热服务订阅传感器的 PropertiesChanged 信号，从而在不轮询的情况下实时调整风扇转速。

Q: D-Bus 的 well-known name 是怎么分配的？
A: 类似于域名系统，它是一个逆向 DNS 风格的字符串，如 `xyz.openbmc_project.State.Host`。这种命名机制防止了服务名冲突，并确保客户端能够通过唯一标识找到对应的总线连接。

> 💡 **大白话**：D-Bus 的 well-known name 就像公司里每个部门的固定工位号——财务部永远在 3F-101，不会和 IT 部门的 4F-208 撞号。反向 DNS 格式（`xyz.openbmc_project.xxx`）相当于先写楼层、再写房间号，层级越来越具体，全球唯一，谁都不会认错门。

Q: busctl introspect 命令背后发生了什么？
A: 客户端向目标服务发送了标准的 `org.freedesktop.DBus.Introspectable.Introspect` 方法调用。服务端收到后，返回一段 XML 格式的数据，描述自己暴露的接口、方法和属性，这就是自省 (introspection) 机制的实现。

**Linux 内核/驱动**

Q: 什么是 Device Tree？为什么 ARM 架构需要它？
A: Device Tree 是一种描述硬件拓扑结构的数据结构，脱离内核硬编码代码。早期 ARM 内核充斥着特定平台的 C 结构体。引入 DT 后，同一个内核镜像可以根据传入的 `.dtb` 文件动态识别引脚、I2C 挂载情况和中断分配，大大简化了内核维护。

> 💡 **大白话**：没有 Device Tree 的时代，就像每入职一家新公司，IT 都要给你重装一遍定制版系统——换一块主板就要重新编一遍内核。有了 Device Tree，就像系统通用了，入职时只需交给 IT 一张"硬件说明卡"（.dtb 文件），系统启动时自动读卡认配，同一个系统镜像跑在不同型号的主板上完全没压力。

Q: 内核发生 Oops 或 Panic 时如何提取现场信息？
A: Panic 发生时，控制台会打印包含寄存器和调用栈的回溯信息。如果系统完全死机，需要依赖之前配置的 `kdump` 机制将内存转储到外部存储，或者借助串口捕获日志。对于 BMC，通常依靠看门狗在规定时间后执行硬件复位。

Q: sysfs 和 procfs 的核心区别？
A: `procfs` 主要用于暴露进程信息和系统全局状态 (如内存、CPU)。`sysfs` 专门设计用于展现内核设备驱动模型。在调试硬件如 GPIO 或 I2C 时，操作的接口基本都在 `/sys` 目录下。

Q: 内核驱动中的中断上下文有什么限制？
A: 不能睡眠，不能调用会导致阻塞的函数 (如 `mutex_lock` 或 `kmalloc` 且指定等待标志)。中断处理程序必须尽速执行。如果需要进行耗时操作，必须利用工作队列 (workqueue) 或软中断将任务推迟到进程上下文执行。

Q: 解释虚拟内存中的缺页中断 (Page Fault)？
A: 进程访问一块映射过但尚未真正分配物理页框的内存时，MMU 会触发中断。内核拦截后，分配物理内存并更新页表，然后恢复进程执行。在 BMC 这种内存拮据的环境中，过多的缺页会严重拖累性能。

**IPMI/Redfish**

Q: IPMI 的 NetFn 和 Cmd 字节代表什么？
A: NetFn (Network Function) 用于对命令进行大类划分，如机箱控制或传感器管理。Cmd (Command) 则指明该分类下的具体操作。这种两级索引结构确保了协议的紧凑和高效解析。

Q: `evb-2u-egs` 中实现了 78 个 OEM 命令，如何注册这些命令？
A: 在 `phosphor-ipmi-host` 框架中，我编写了对应的 C++ 处理器函数，并根据命令类型选择正确的注册 API：对于 NetFn 0x2C（Group Extension 命令，1 字节 Group Defining Body ID），使用 `ipmi::registerGroupHandler()`；对于 NetFn 0x2E（OEM/Group 命令，3 字节 IANA Enterprise Number），使用 `ipmi::registerOemHandler()`；对于 NetFn 0x30/0x32 等额外 OEM NetFn，使用 `ipmi::registerHandler()` 按标准方式注册；对于标准 NetFn，同样使用 `ipmi::registerHandler()`。注意旧版 `ipmi_register_callback()` 已弃用。由于涉及敏感底层操作，还会根据请求来源的通道和权限级别校验访问权限。

Q: IPMI 的局限性在哪里？Redfish 解决了什么问题？
A: IPMI 设计年代久远，安全性差 (哈希弱)，使用基于字节流的协议，扩展性差且无法表示复杂的对象嵌套关系。Redfish 基于 HTTPs 和 RESTful 架构，数据负载使用 JSON 格式，可读性极强，且与现代 IT 运维工具链完美结合。

Q: Redfish Schema 的作用是什么？
A: Schema 是数据格式的字典和契约。它定义了诸如 "ComputerSystem" 必须包含哪些属性、数据类型是什么。客户端通过解析 Schema，可以动态理解未知设备的结构，实现代码解耦。

Q: 解释 IPMB 桥接 (Bridging) 的概念。
A: 当存在多个 BMC 或控制节点时，IPMB 提供了在 I2C 物理层之上传输 IPMI 消息的通道。桥接功能允许用户发送一条特殊的命令，指示接收端的 BMC 将命令原样转发给挂在另一条总线上的微控制器，并将响应传回。

**嵌入式系统设计**

Q: 解释 Watchdog (看门狗) 的工作原理和重要性。
A: 看门狗是一个硬件定时器。软件必须定期重置它 (喂狗)。一旦系统跑飞或死锁导致未能及时重置，定时器溢出便会拉低系统的复位引脚。这对 BMC 这个负责拯救整个服务器的主控节点来说，是容错的最后一道防线。

Q: I2C 和 SPI 的主要区别与应用场景。
A: I2C 是两线制总线，支持多主机，通过设备地址寻址，速度相对较慢，适合连接大量低速传感器。SPI 是四线制同步总线，全双工传输，速度极快，靠独立的片选线选中设备，专用于连接 Flash 存储芯片或高速外设。

Q: BMC 如何控制主机 (Host) 的上电时序？
A: BMC 的 GPIO 引脚连接到主板的关键电源控制引脚 (如 CPLD 或 PCH)。通过精准控制拉高或拉低的时延序列，例如先拉高 3.3V 待机电源，等待 Power Good 信号，再释放 CPU 复位信号，完成一套标准的上电状态机。

Q: 为什么需要双 bank 固件架构？
A: 固件烧录中途一旦掉电，芯片数据会损坏。双 bank 使用两颗物理独立的 Flash 芯片（如 evb-2u-egs 的双 w25q512），或将单芯片分成两个逻辑区域。更新时先将新固件写入备用 bank，校验签名无误后再修改启动指针。这样任何单点失败都不会导致设备无法启动。

> 💡 **大白话**：双 bank 固件就像手机的"系统升级不怕失败"功能——升级时先把新系统悄悄写进另一块存储区，写完校验没问题了才切换过去。万一升级到一半断电，老系统还完好地待在原来那块区域，重启照样能用。不过，"自动回退到旧版"需要 bootloader 配合实现 bootcount 逻辑，并非所有平台都天然具备。

Q: GPIO 中断的触发方式有哪些？
A: 电平触发 (高电平或低电平) 和边沿触发 (上升沿、下降沿或双边沿)。在处理主机系统断电的紧急警告信号时，通常配置为边沿触发，以确保 BMC 能够瞬间捕获到电压跌落事件。

**调试/排错**

Q: 遇到总线上 I2C 设备随机丢失，如何排查？
A: 首先通过示波器检查 SDA 和 SCL 信号完整性，排除上拉电阻或电容带来的波形畸变。软件层面上，查看内核日志是否有总线恢复事件。如果在高负载时出现，可能是 I2C 控制器驱动的中断处理存在竞态条件。

Q: top 显示进程占用极高 CPU，但没有崩溃，怎么定位瓶颈？
A: 使用 `strace` 附加到该进程，观察是否陷入了紧凑的系统调用循环 (例如疯狂轮询)。接着用 `perf top -p <pid>` 查看具体热点函数。在 D-Bus 架构中，极有可能是收到了巨量的无关信号广播而忙于解析。

Q: 设备树修改后启动直接卡在 U-Boot 阶段，可能是什么原因？
A: 大概率是修改的节点语法错误破坏了二进制 DTB 结构，或者指定了与 Bootloader 冲突的内存区域配置。此时应该通过串口连接设备，在 U-Boot 交互模式下使用 `fdt print` 检查内存中的设备树结构。

Q: 某个 systemd 服务启动无限循环报错并不断重启，如何打破？
A: 在服务文件里设置 `StartLimitIntervalSec` 和 `StartLimitBurst`，配置短时间连续失败次数上限即可强制将其置为 failed 状态。然后检查 `journalctl` 查看具体崩溃原因，往往是因为依赖的 D-Bus 服务还未准备好就发起了调用。

Q: 网络完全不通，既 ping 不通外网也拿不到 IP，排查步骤？
A: 先用 `ip link` 确认网卡状态是否为 UP，并且是否存在 MAC 地址。使用 `ethtool eth0` 查看物理链路是否检测到载波 (Link detected)。如果物理层没问题，查阅 `systemd-networkd` 日志看看 DHCP 发出的 Discover 包是否收到了 Offer。

Q: 在 QEMU 中 BMC 的网络接口没有 IP 地址，但宿主机端口转发配置正确，可能是什么原因？
A: 这是一个典型的"设备模型层 vs 设备树层"不匹配问题。QEMU 的 `-net nic` 按顺序连接到硬件模型的 NIC（mac0→mac1→mac2→mac3），但 Linux 内核只为 DTS 中 `status = "okay"` 的 NIC 创建网络接口。如果 DTS 只启用了 mac2/mac3 而 `-net nic,netdev=usernet` 连接到了 mac0，端口转发的网络后端就浪费了——Linux 内核根本看不见 mac0。解决方案是用多条空的 `-net nic` 跳过禁用的 NIC，让带后端的 NIC 落到 DTS 启用的位置上。这个问题揭示了虚拟化调试中硬件抽象层和软件配置层的分离本质。

Q: 内核 panic 提示 SPI Flash 映射失败 ("Can't map window for chip")，但 U-Boot 阶段 Flash 读写正常，如何分析？
A: U-Boot 运行在物理地址模式下，直接访问 SPI Flash 的 AHB 映射窗口。但 Linux 内核运行在虚拟地址模式下，需要通过 vmalloc 区域建立映射。如果物理 RAM 很大（如 2GB），默认的 `VMSPLIT_2G` 会导致直接映射占满内核空间，vmalloc 区域不足以容纳 Flash 映射窗口（AST2600 需要 ~256MB）。U-Boot 正常只是因为它根本不走 MMU 虚拟地址映射。解决方案是双管齐下：内核配置使用 `CONFIG_VMSPLIT_3G_OPT=y` 改变内存分割比例，同时 U-Boot bootargs 添加 `vmalloc=512M` 显式预留 vmalloc 空间。完整分析见 §9.10。这个问题的核心是理解 bootloader 和内核的地址空间模型差异，以及物理 RAM 大小对虚拟地址布局的影响。

> 💡 **大白话**：这两道题是面试中展示"系统性思维"的绝佳素材。NIC 映射那题考的是"你是否理解虚拟化环境中硬件模拟和软件驱动是两个独立的层"；VMSPLIT 那题考的是"你是否理解 U-Boot 物理寻址和 Linux 虚拟寻址的根本区别"。两题都不是靠背答案能搞定的，面试官一追问就能看出你是真懂还是背的。

**安全**

Q: 安全启动 (Secure Boot) 的核心机制是什么？
A: 建立信任根 (Root of Trust)。系统上电执行的第一段代码 (通常固化在 ROM 里) 是不可篡改的，它包含一把公钥。每一阶段的启动代码 (如 u-boot、内核) 必须带有数字签名，由前一阶段的代码使用公钥校验成功后才能执行。

> 💡 **大白话**：安全启动就像多道门禁——第一道门用焊死的钥匙开（ROM 里的公钥），只有持对应私钥签发的"通行证"（数字签名）才能进下一道门。每道门严格审查下一道门的合法性，从源头锁死，伪造的程序连第一道门都过不了。

Q: 发现一个包含远程执行漏洞的 CVE，应该如何修补 OpenBMC？
A: 找到问题对应的源码仓库，通常上游已经有了补丁。在 Yocto 环境中，找到该包的 配方 文件，将修补的 `.patch` 文件放到同级目录下，并在 `.bb` 或 `.bbappend` 中的 `SRC_URI` 列表中加入该 patch 文件，重新编译镜像即可。

Q: 什么是基于角色的访问控制 (RBAC)？在 BMC 中如何体现？
A: 将权限绑定到角色而非特定用户。OpenBMC 定义了 Administrator、Operator、ReadOnly 等角色。在 Redfish 或 IPMI 接口收到请求时，系统会校验发出该请求的用户所绑定的角色级别，只有拥有对应权限才能修改风扇转速或执行重启操作。

> 💡 **大白话**：RBAC 就像公司门禁卡和权限系统——不是按"张三/李四"来开权限，而是按"职位"来开。运维岗位的人员可以查看监控、执行例行操作；HR 绝对不能随意修改服务器配置。这样某员工离职了，只需吊销其职位卡，不用挨个系统去改，管理省心多了。

§7.3 系统设计题

> **面试要点**
> 考察你从宏观架构到微观实现的统筹能力，尤其注重容灾、扩展性和安全性设计。

**题目：设计一个 BMC 固件的远程大批量更新系统**

*   **架构描述**：采用推拉结合模式。管理节点下发更新指令包 (包含固件版本和下载链接)，BMC 收到后向中央镜像仓库发起 HTTPS GET 请求拉取固件。
*   **通信协议**：基于 Redfish 的 UpdateService API 触发更新。
*   **安全性**：传输层采用 TLS 加密，固件镜像本身必须使用 RSA-2048/SHA-256 离线签名。BMC 端通过 `phosphor-software-manager` 使用板载公钥对镜像进行强制签名校验。
*   **容灾设计**：实行 A/B 分区策略 (双 Bank)。主区正常运行，后台静默将镜像解压并写入备用区。更新完毕后更新 U-Boot 环境变量标记新分区优先级并重启。回滚策略（如启动失败计数和阈值）由各平台的 U-Boot 配置决定。
*   **进度反馈**：BMC 通过 D-Bus 暴露下载和刷写进度，并通过 Redfish 的 Task 机制异步向中央节点汇报。

> 💡 **大白话**：批量固件更新就像手机 App 的 OTA 推送——应用商店（管理节点）告诉你有新版，手机（BMC）自己去服务器下载，下载完先验证安装包没被篡改（签名校验），然后悄悄装进备用空间，装好了下次开机再切换。万一安装出问题，自动退回老版本，这就是 A/B 双 Bank 的精髓。

**题目：设计一个支持 1000 台服务器的集中 BMC 管理平台**

*   **接入层**：部署负载均衡器分发流量。各机架部署前置采集网关，通过 Redfish 的 SSE (Server-Sent Events) 机制维持与数百台 BMC 的长连接，避免高频短连接压垮网络。
*   **消息总线**：前置网关将硬件告警、温度读数转化为统一 JSON 格式，推送到 Kafka 集群。
*   **数据处理层**：Flink 实时计算节点消费 Kafka 数据，一旦发现特定机柜温度斜率超标，立即生成报警动作。
*   **存储层**：时序数据库 (如 InfluxDB 或 Prometheus) 存储历史遥测数据供报表展示，关系型数据库存储服务器资产清单和账号权限信息。

> 💡 **大白话**：管理 1000 台服务器就像快递公司管理全国网点——总部不可能挨个电话问每个站点"有没有包裹"（轮询），而是每个片区设立驿站（网关）统一汇总；信息统一走流水线（Kafka）流转；发现某条线路积压超标立即预警。时序数据库存每天的温度走势，关系型数据库存资产台账，各司其职。

§7.4 行为面试题 (STAR 原则实战)

**题目："讲述一次极具挑战的 Debug 经历。"**
**回答**：在将 `evb-2u-egs` 从 AMI 迁移到 OpenBMC 的过程中 (Situation)，我发现系统满载运行时风扇转速总是剧烈波动，发出巨大噪音 (Task)。我起初怀疑是硬件传感器的噪声，但通过 `busctl monitor` 捕获 D-Bus 信号后发现，温度数据非常平稳。进一步分析 `phosphor-pid-control` 的日志并结合源码，我发现配置的 PID 积分系数 (Ki) 严重过大，且未设置积分限幅 (Windup)，导致轻微温差累积出了巨大的补偿输出 (Action)。我重新查阅了约 1967 行的硬件定义规范，提取了正确的转速阈值，修改了温控 JSON 配置文件，引入了积分分离算法，最终显著降低了风扇转速波动，彻底解决了噪音问题 (Result)。

**题目："当你在技术方案上与团队产生分歧时，你是如何处理的？"**
**回答**：在决定是否放弃旧有的大量 OEM IPMI 命令时，团队产生了严重分歧 (Situation)。部分成员认为应一步到位全面转向 Redfish 丢弃历史包袱，但我认为客户的老旧管理平台完全依赖那 78 个 IPMI 命令 (Task)。我没有直接争论，而是花了一个周末，编写了一个概念验证 (PoC) 原型 (Action)，展示了如何通过极少的代码量，在 `phosphor-ipmi-host` 框架内利用现有的 D-Bus 接口重新实现最复杂的 5 个核心 OEM 命令。通过具体的代码量和极低的维护成本演示，我成功说服了团队采取平滑过渡方案，既兼容了旧系统，又赢得了业务方的时间窗口 (Result)。

§7.5 各大厂侧重点

*   **Meta (Facebook)**：重点考察底层系统编程 (C/C++)、内存管理、高并发架构和基于 Linux 的性能剖析。他们拥有极其复杂的 3 级嵌套机型树，重视大规模机群的自动部署与自动化诊断能力。
*   **Google**：除了必备的底层知识，非常强调基础算法和系统设计。对代码质量、单元测试覆盖率有着极其严苛的要求，高度关注你在开源社区 (如 gBMC) 的活跃度和代码贡献记录。
*   **Microsoft**：围绕 Azure 数据中心的嵌入式生态建设，极度重视安全链条 (Cerberus/Titan) 的理解。强调跨团队跨地域的沟通协作能力，经常会有关于接口契约设计的问题。
*   **Intel / NVIDIA**：偏重固件的极度底层。考察平台初始化顺序、PCIe 拓扑、IPMI/Redfish 细节、各种高速总线的调试经验。NVIDIA 还会额外关注 GPU 带外管理模块的温度调度算法。

## 第八章：进阶主题与职业发展

§8.1 安全启动

在现代数据中心，仅仅软件正确是不够的，还需要防范物理层面的固件篡改。安全启动 (Secure Boot) 构筑了信任链 (Chain of Trust)。

一切信任始于处理器内部无法篡改的 Boot ROM。ROM 读取熔断丝 (eFuses) 中固化的公钥哈希，验证第一段加载代码 (SPL)。验证通过后，SPL 再验证 U-Boot，U-Boot 使用配置好的证书验证 Linux 内核镜像 (FIT image)，内核最终可通过 dm-verity 等技术（如果启用）校验 RootFS 文件系统的完整性。

对于 `evb-2u-egs` 所用的 AST2600，它内置了硬件加密加速引擎和安全的 Boot ROM，原生支持完整的硬件信任根 (RoT) 校验。理解这条链条并在 Yocto 中集成密钥签名流程，是高级工程师的必备技能。

§8.2 固件签名与验证

仅仅依赖硬件链还不够，网络下发的更新包也必须经过验证。在 OpenBMC 中，`phosphor-software-manager` 承担了这一重任。

固件包被设计为一个 tarball，里面不仅包含镜像本身，还有通过 OpenSSL 私钥生成的数字签名文件。如果启用了固件签名验证，你需要通过 Yocto 的 bbclass 机制，在打包镜像时自动调用私钥进行签名，同时将公钥打包进最终的根文件系统中。每次发起 Redfish 更新请求时，验证逻辑会在解压后立即校验签名，防止恶意固件被写入 Flash。

§8.3 认证与授权

控制 BMC 等同于掌握了整台服务器的生杀大权。

OpenBMC 利用 Linux 标准的 PAM (Pluggable Authentication Module) 模块处理本地和远端的身份验证。通过配置 PAM，BMC 可以轻松接入企业级的 LDAP 或 Active Directory 服务器，实现账号的集中管控。

除了密码，针对自动化脚本调用，普遍采用 mTLS (双向 TLS 认证)，客户端和服务器互相验证对方的数字证书。同时结合 RBAC 权限管控模型，确保即便凭证泄露，其破坏范围也严格受限于所属角色的只读或部分执行权限。

§8.4 CI/CD 流水线

优秀的开源项目离不开坚如磐石的 CI/CD 流水线。OpenBMC 社区使用 Jenkins (`jenkins.openbmc.org`) 作为官方 CI 系统。

任何一次代码提交 (Patch) 都会触发自动化构建流程，系统会在 Docker 环境中针对多个核心平台并行编译。编译成功后，镜像会被下发到真实的 QEMU 模拟器或物理机房中，由 CI 系统执行 Robot Framework 自动化测试套件（涵盖 IPMI 连通性、Redfish Schema 验证以及传感器读取测试等）。学习如何在本地模拟这套流水线，能大幅降低提交代码被驳回的概率。

> 💡 **大白话**：CI/CD 流水线就像工厂的质检传送带——你提交代码就像往传送带上放零件，系统自动针对多条产线同时检验（多平台并行编译），质检通过后再送到专门的测试工位（QEMU/物理机）跑功能验证。一旦某个环节亮红灯，你能立刻看到哪道工序出了问题，比人工审核快一百倍，还不会漏检。

§8.5 向上游贡献代码

向 OpenBMC 贡献代码不仅是回馈社区，更是打造个人技术品牌的绝佳路径。

项目摒弃了传统的 GitHub Pull Request 模式，全面采用 Gerrit 系统 (`gerrit.openbmc-project.xyz:29418`)。你需要安装 `git-review` 工具，并在提交信息 (commit message) 的底部自动生成独一无二的 `Change-Id`。

Commit Message 的格式极其严格：第一行必须是简短的标题前缀 (如 `ipmi: fix sensor offset`)，空一行后是详尽的修改背景、原因和测试方法，最后是 `Signed-off-by` 声明。补丁上传后，各模块的 Maintainer 会在网页端逐行点评 (Code Review)。耐心接受批评，迅速迭代补丁，是融入社区的第一课。

> 💡 **大白话**：向 Gerrit 提交 patch 就像给社区期刊投稿——不能随手写篇文章直接发，得按固定格式排版：标题、摘要、正文背景、测试记录，还要在结尾签名背书。编辑（Maintainer）审稿时会在稿子上做批注，你收到批注后需要迅速修改再投第二稿、第三稿。这个过程磨的是你的耐性和表达能力，也是在社区建立口碑的必经之路。

§8.6 社区参与

活跃的社区是技术生命力的源泉。OpenBMC 有非常活跃的邮件列表 (`openbmc@lists.ozlabs.org`) 和 Discord 频道。

遇到难题时，提问前先搜索邮件归档列表。在提问时，务必提供详尽的系统日志、重现步骤和具体的代码行号。此外，积极参加每年的 OpenBMC 峰会 (通常与开源固件大会 OCP 联合举办)，是了解大厂最新动向、结交顶尖极客的最高效途径。

> 💡 **大白话**：在技术社区提问就像在专业论坛发帖求解——你只写一行"我的系统跑不起来怎么办？"基本没人理。有效提问需要附上"案发现场"（日志）、"作案过程"（复现步骤）、"嫌疑人"（相关代码行号），让大神们一眼看出问题所在，才能快速得到高质量回答。

§8.7 职业路线图

固件工程师的发展路径广阔而深邃：
*   **Junior (初级)**：熟练配置编译环境，能照猫画虎添加传感器，编写简单的 IPMI 命令，处理简单的内核报错。
*   **Senior (高级)**：能独立从零完成类似 `evb-2u-egs` 的全平台移植，深谙 Yocto 原理，精通 D-Bus 异步编程，能主导攻坚系统卡顿或内核崩溃等复杂 Debug 场景。
*   **Staff / Principal (专家/首席)**：视野不再局限于单台设备，着眼于数据中心级别的管理架构设计。参与制定下一代硬件规范 (如 OCP 规范)，在 BIOS/UEFI、CPLD/FPGA 和 BMC 的协同设计上拥有绝对话语权。

> 💡 **大白话**：固件工程师的成长路径就像游戏里的角色升级——Junior 是新手村萌新，照着任务引导做；Senior 是独当一面的精英玩家，能自己开荒新地图（全平台移植）；Staff/Principal 是服务器端的策划级别，制定玩法规则（硬件规范和行业标准），别人都在按你设计的机制打游戏。每一级的跨越都需要真实的战役历练，没有捷径。

职业发展上，技术 IC (Individual Contributor) 路线在硅谷非常吃香，资深固件专家的薪资往往与高阶前端或后端工程师持平甚至反超，因为这一领域的护城河极深，对底层硬件体系结构的深刻理解需要漫长岁月的沉淀。

> 💡 **大白话**：固件领域的护城河就像一个需要同时精通"古文阅读"和"机械维修"的冷门工种——前端可能每隔几年就换一套新框架，而固件底层知识是几十年都不过时的硬通货。愿意沉下去学这些的人本就不多，资深者更是稀缺，市场供需关系决定了薪资天花板反而更高。

§8.8 本教程总结

从最初的一片迷茫，到理解了完整的 OpenBMC 架构并创建出包含 26 个文件的定制机器层，成功编译 64MB 固件镜像（7164 个 BitBake 任务），在 QEMU 中完成 U-Boot → 内核 → systemd 全链路启动，验证 SSH 远程管理、BMCWeb Redfish API 和 WebUI 图形界面全部正常工作——你已经走过了一段从零到能交活的完整旅程。

这个过程中踩过的 13 个真实的坑（10 个构建错误 + 3 个 QEMU 调试问题），每一个都是你面试时的实战弹药。从 BitBake 补丁格式到内核虚拟内存分割，从 QEMU 设备模型到 systemd 模板实例化，这些经验覆盖了嵌入式全栈工程师日常工作的核心场景。

但这只是我们在虚拟世界（QEMU）的里程碑。真正的挑战在真实的物理世界。第九章，我们将把编译好的 64MB 固件烧录到真实的 evb-2u-egs 物理硬件中，开启真机烧录与调试的新篇章。

> 💡 **大白话**：学到这里就像在驾校的模拟机上以满分通关了，你从一个看见 BitBake 就头疼的小白，慢慢点亮了 Yocto 构建、D-Bus 通信等技能树，打通了“编译→启动→SSH→WebUI”的模拟器最终关。但这只是驾考的科目二，真正的老司机都是在真实的马路上喂出来的。带上我们编译好的 64MB 镜像地图，系好安全带，第九章我们正式上实车路考！

---

## 第九章：实机烧录与硬件调试

### §9.1 从 QEMU 到真机——心态准备与工具清单

QEMU 是一个纯净的理想国。我们在第六章的虚拟环境中，不用担心引脚短路，不用担心电平波动，甚至系统挂了只需一条命令就能原地复活。但在真实的 `evb-2u-egs`（Intel EGS 双路 + AST2600 A1，2U 机架服务器）物理硬件上，代码要面对的是真实世界的混沌：电平的翻转、SPI 走线的干扰、引脚的虚焊，甚至是被静电击穿的芯片。

在物理设备上，如果固件跑飞了，屏幕不会弹框告诉你。你需要学会通过唯一的"生命线"——串口，去听硬件在死机前喊出的最后一句遗言。真机调试要求你把视角从单纯的代码层，下沉到电流和寄存器的物理层。

> 💡 **大白话**：在 QEMU 里调试就像在带护栏的游乐场里玩碰碰车，撞墙了随时可以重置。真机调试则像是在野外拉力赛，车子（板子）随时可能抛锚，你得自己带上千斤顶和万用表去修。从这一章开始，我们要学会听懂机器的心跳声。

**你需要准备的实战工具清单**：
- **USB-to-UART 转换器**：这是你和 BMC 沟通的唯一途径（推荐 FTDI FT232R 或 CP2102）。
- **SPI 编程器**：如 Dediprog SF600/SF100、CH341A、FlashCAT 等。
- **SOP8 测试夹**：或者用于拆焊 Flash 芯片的工具，夹具能免去很多痛苦。
- **杜邦线**：至少 3 根（TX、RX、GND）。
- **一台编译好的固件**：即前几章我们构建在 `build/evb-2u-egs/tmp/deploy/images/evb-2u-egs/` 下的 `obmc-phosphor-image-evb-2u-egs.static.mtd`。

本次实机烧录的平台基础信息如下：
- **平台**：evb-2u-egs（Intel EGS 双路 + AST2600 A1，2U 机架服务器）
- **Flash**：2× w25q512jv（各 64MB），FMC CS0（Bank A 主用）+ CS1（Bank B 备用），Quad SPI 50MHz
- **固件**：OpenBMC（Yocto whinlatter，distro openbmc-phosphor/styhead）

---

### §9.2 串口连接与调试控制台

在真实的物理机中，你需要找到 BMC 的控制台引脚，把串口线接上去，才能看到系统日志。串口是我们在硬件世界中除万用表外的唯一抓手。

#### 1. UART 映射总表

| Linux 设备 | 硬件 UART | 功能 | 波特率 | 用途 |
|-----------|----------|------|--------|------|
| `/dev/ttyS4` | UART5 | **BMC 调试控制台** | 115200 8N1 | U-Boot + kernel + shell 输出 |
| `/dev/ttyS3` | UART4 | **SOL（Serial over LAN）** | 115200 8N1 | IPMI SOL 访问主机串口 |
| `/dev/ttyS2` | UART3 | 共享主机串口 | 115200 8N1 | Host 与 BMC 共享的串口通道 |
| `/dev/ttyS0` | UART1 | Host 串口（QEMU 用） | 115200 8N1 | QEMU 环境下的 Host 侧 |

#### 2. 配置文件依据链

在代码体系里，串口配置从 4 个层级一致指向 ttyS4：

```
1. DTS (内核设备树):
   chosen { stdout-path = &uart5; bootargs = "console=ttyS4,115200n8 earlycon"; };
   → 文件: meta-evb-2u-egs/recipes-kernel/linux/linux-aspeed/aspeed-bmc-evb-2u-egs.dts

2. U-Boot 环境变量:
   bootargs=console=ttyS4,115200n8
   → 文件: meta-aspeed/recipes-bsp/u-boot/files/u-boot-env-ast2600.txt

3. machine.conf:
   SERIAL_CONSOLES = "115200;ttyS4"
   → 文件: meta-evb-2u-egs/conf/machine/evb-2u-egs.conf

4. SoC 默认 (ast2600.inc):
   SERIAL_CONSOLES ?= "115200;ttyS4"
   → 文件: meta-aspeed/conf/machine/include/ast2600.inc
```

> 💡 **大白话**：串口就像是医生听诊器连着的听筒。DTS、U-Boot 和 Yocto 配置就是告诉系统，无论在哪一层，统一把声音从第 5 号管子（UART5 即 ttyS4）传出来，不让声音漏到别的管子里去。

#### 3. 硬件接线步骤

**接线方式**：

```
USB-UART 转换器          EVB 板上 UART5 排针
  TX  ───────────────→  RX
  RX  ←───────────────  TX
  GND ────────────────── GND
```

> **注意**：TX/RX 交叉连接。如果没有输出，先尝试交换 TX 和 RX。

> 💡 **大白话**：接串口线就像打电话，你的嘴巴（TX 发送）必须对准对面的耳朵（RX 接收），两边必须接上同一个地线（GND）作为共同的参考基准，不然就是鸡同鸭讲。

**串口终端软件配置**：

```bash
# Linux (推荐 minicom)
sudo minicom -D /dev/ttyUSB0 -b 115200

# 或者用 screen
sudo screen /dev/ttyUSB0 115200

# 或者用 picocom (最简单)
sudo picocom -b 115200 /dev/ttyUSB0

# macOS
screen /dev/tty.usbserial-* 115200

# Windows
# 使用 PuTTY: Serial, COMx, 115200, 8-N-1, No flow control
```

**minicom 详细设置**（首次使用）：

```bash
sudo minicom -s
# → Serial port setup
#   A - Serial Device: /dev/ttyUSB0
#   E - Bps/Par/Bits: 115200 8N1
#   F - Hardware Flow Control: No    ← 重要！必须关掉
#   G - Software Flow Control: No
# → Save setup as dfl
# → Exit
```

> ⚠️ **Hardware Flow Control 必须设为 No**，否则可能看不到输出或者输入无响应。

> 💡 **大白话**：Hardware Flow Control 就像是交通灯，如果开了这个，而硬件板子根本没接对应的控制线（RTS/CTS），你的终端就会一直傻等绿灯，就算里面喊破喉咙你也听不见。

#### 4. 确认排针位置

串口排针的物理位置需要查看 EVB 板的丝印标注或原理图。通常 AST2600 EVB 板上会标注：
- `J_UART5` 或 `BMC_CONSOLE` — 这是你要接的 BMC 调试口
- `J_UART4` 或 `SOL` — 这是 SOL 口
- 某些板子直接提供 micro-USB 调试口（板载 FTDI/CP2102 芯片），此时直接插 USB 线即可

---

### §9.3 Flash 分区布局详解

要想把代码灌进芯片，必须搞懂芯片的"地皮"是怎么划分的。我们的固件使用 `mtd-static` 布局（固定偏移），定义在 `meta-phosphor/classes/image_types_phosphor.bbclass`。

#### 1. OpenBMC 64MB 静态分区布局

64MB（65536KB）Flash 的分区映射：

```
偏移地址(KB)   偏移地址(Hex)   大小(KB)    分区名称            内容
─────────────────────────────────────────────────────────────────────────
0              0x00000000     64         u-boot SPL          SPL 引导程序
64             0x00010000     824        u-boot               U-Boot proper (FIT 格式)
888            0x000DE000     8          manifest             固件清单 (JSON)
896            0x000E0000     128        u-boot-env           U-Boot 环境变量
1024           0x00100000     9216       kernel (fitImage)    Linux 内核 + initramfs + DTB
10240          0x00A00000     32768      rofs (squashfs-xz)   只读根文件系统
43008          0x02A00000     22528      rwfs (jffs2)         读写持久存储
65536          0x04000000     ---        Flash 结束           ---
```

#### 2. 分区偏移量来源

这些值定义在 `image_types_phosphor.bbclass` 中，针对 `flash-65536` override：

```python
# 64MB Flash 的偏移量（单位：KB）
FLASH_UBOOT_SPL_SIZE = "64"         # SPL: 0 ~ 64KB
FLASH_UBOOT_OFFSET = "0"            # U-Boot 起始
FLASH_MANIFEST_OFFSET:flash-65536 = "888"    # Manifest: 888KB
FLASH_UBOOT_ENV_OFFSET:flash-65536 = "896"   # Env: 896KB = 0xE0000
FLASH_KERNEL_OFFSET:flash-65536 = "1024"     # Kernel: 1024KB = 0x100000
FLASH_ROFS_OFFSET:flash-65536 = "10240"      # RootFS: 10240KB = 0xA00000
FLASH_RWFS_OFFSET:flash-65536 = "43008"      # RWFS: 43008KB = 0x2A00000
FLASH_SIZE = "65536"                          # 总大小: 65536KB = 64MB
```

#### 3. U-Boot 环境变量区配置

```
# U-Boot 编译期配置 (u-boot_flash_64M.cfg):
CONFIG_ENV_SIZE=0x20000        # 128KB
CONFIG_ENV_OFFSET=0xE0000      # 偏移 896KB

# Linux 下 fw_printenv/fw_setenv 配置 (fw_env.config):
/dev/mtd/u-boot-env    0x00000    0x10000    # 主环境，前64KB
/dev/mtd/u-boot-env    0x10000    0x10000    # 冗余副本，后64KB
```

#### 4. static.mtd 镜像拼装过程

构建系统通过 `dd` 命令将各组件按偏移写入一个全 0xFF 的 64MB 文件：

```bash
# 伪代码 (实际在 image_types_phosphor.bbclass 的 do_generate_static 中):
dd if=/dev/zero bs=1k count=65536 | tr '\000' '\377' > image.static.mtd   # 全FF
dd if=u-boot-spl.bin   of=image.static.mtd bs=1k seek=0     conv=notrunc  # SPL
dd if=u-boot.bin        of=image.static.mtd bs=1k seek=64    conv=notrunc  # U-Boot
dd if=fitImage           of=image.static.mtd bs=1k seek=1024  conv=notrunc  # Kernel
dd if=rootfs.squashfs-xz of=image.static.mtd bs=1k seek=10240 conv=notrunc # RootFS
dd if=rwfs.jffs2         of=image.static.mtd bs=1k seek=43008 conv=notrunc # RWFS
```

最终产物：`obmc-phosphor-image-evb-2u-egs.static.mtd`（精确 64MB = 67,108,864 字节）。

> 💡 **大白话**：Flash 就像是一块没有文件系统的裸硬盘。构建系统就是严格按照划好的地皮，把 SPL、U-Boot、内核等建筑直接丢到对应的空地上。哪块地被盖错了一点，整条街的启动逻辑就会当场瘫痪。

#### 5. 双 Flash 物理映射

```
SPI Flash 0 (FMC CS0) — Bank A（主用启动 Flash）
├── 地址范围: 0x2000_0000 ~ 0x23FF_FFFF (CPU 视角)
├── MTD 设备: /dev/mtd0 (bmc) 及其子分区
├── DTS label: "bmc"
└── 内容: u-boot-spl + u-boot + env + fitImage + rofs + rwfs

SPI Flash 1 (FMC CS1) — Bank B（备用 Flash）
├── 地址范围: 0x2400_0000 ~ 0x27FF_FFFF (CPU 视角)
├── MTD 设备: /dev/mtdN (bmc-backup)
├── DTS label: "bmc-backup"
└── 内容: 应烧入相同的 static.mtd 作为备份
```

#### 6. U-Boot defconfig 决策

当前 `machine.conf` 配置：

```
UBOOT_MACHINE = "ast2600_openbmc_spl_defconfig"
SPL_BINARY = "spl/u-boot-spl.bin"
```

这个 SPL defconfig 是为 QEMU 环境优化的，**在真实硬件上也完全能正常工作**。

原因在于：
- **U-Boot SPL 阶段**：AST2600 SPL defconfig 默认使用 UART5（uart5），与我们的硬件一致。
- **U-Boot proper 阶段**：环境变量 `bootargs=console=ttyS4,115200n8` 已经正确指向 UART5，且被设备树 `chosen { stdout-path = &uart5; }` 控制。
- **Linux 内核阶段**：完全由 DTS 的 `bootargs` 和 `stdout-path` 控制，已正确配置为 `ttyS4@115200`。

> 💡 **大白话**：就像你的车在模拟机里调好了所有的仪表盘指针，只要真车的接口没变，这套仪表盘搬过来照样能看，完全不需要拆了重装。

如果刷入后在 UART5 上完全没有输出，可以尝试以下备选方案排查：

```
步骤1: 检查接线（TX/RX是否交叉、GND是否连接）
步骤2: 尝试其他 UART 排针（可能 UART5 的物理连接器不是你接的那个）
步骤3: 换 defconfig — 修改 machine.conf:
       UBOOT_MACHINE = "ast2600_openbmc_defconfig"
       # 同时删除 SPL_BINARY 行（非 SPL 模式不需要）
       然后重新构建:
       bitbake -c clean u-boot-aspeed-sdk && bitbake obmc-phosphor-image
步骤4: 如果用了非 SPL defconfig 后有输出，则确认是 SPL 启动链的问题
```

---

### §9.4 初次烧录实战

纸上得来终觉浅。万事俱备，我们要开始给这块崭新的板子注入灵魂了。

#### 1. 准备工作

**固件文件位置**：

```
/home/dev/openbmc-workspace/openbmc/build/evb-2u-egs/tmp/deploy/images/evb-2u-egs/
├── obmc-phosphor-image-evb-2u-egs.static.mtd     # ← 就刷这个！64MB 完整镜像
├── fitImage-obmc-phosphor-image-evb-2u-egs-evb-2u-egs  # FIT image (单独)
├── u-boot-spl.bin                                  # SPL (单独)
├── u-boot.bin                                      # U-Boot proper (单独)
└── aspeed-bmc-evb-2u-egs.dtb                       # DTB (单独)
```

**将镜像传输到工作电脑**：

```bash
# 从开发主机下载镜像到本地
scp dev@<开发机IP>:/home/dev/openbmc-workspace/openbmc/build/evb-2u-egs/tmp/deploy/images/evb-2u-egs/obmc-phosphor-image-evb-2u-egs.static.mtd .

# 确认文件大小（必须是精确 64MB = 67108864 字节）
ls -la obmc-phosphor-image-evb-2u-egs.static.mtd
# -rw-r--r-- 1 user user 67108864 ... obmc-phosphor-image-evb-2u-egs.static.mtd

# 计算 SHA256 校验和（记录下来，烧录后对比）
sha256sum obmc-phosphor-image-evb-2u-egs.static.mtd
```

#### 🔬 实操：方法 A —— SPI 编程器直刷（推荐首次使用）

这是最可靠的首次烧录方法，不依赖板上任何软件。

**需要的工具**：
- SPI 编程器：Dediprog SF600/SF100、CH341A、FlashCAT 等
- SOP8 测试夹或拆焊 Flash 芯片

**操作步骤**：

```bash
# === 步骤1：断电、连接编程器 ===
# 1. 关闭服务器电源（包括 BMC 待机电源！拔掉电源线）
# 2. 用 SOP8 测试夹夹住 Flash 芯片 CS0 (Bank A)
#    注意引脚方向：芯片1脚（有圆点标记）对应测试夹的红线/标记线

# === 步骤2：读取原始固件（备份！） ===
# Dediprog 命令行 (Linux):
dpcmd --auto detect              # 自动检测 Flash 型号
dpcmd -r original_firmware.bin   # 读取并保存原始固件
sha256sum original_firmware.bin  # 记录原始固件校验和

# CH341A + flashrom:
sudo flashrom -p ch341a_spi -r original_firmware.bin
sha256sum original_firmware.bin

# === 步骤3：写入 OpenBMC 固件 ===
# Dediprog:
dpcmd -e                         # 全片擦除
dpcmd -p obmc-phosphor-image-evb-2u-egs.static.mtd  # 编程
dpcmd -v obmc-phosphor-image-evb-2u-egs.static.mtd  # 校验

# CH341A + flashrom:
sudo flashrom -p ch341a_spi -w obmc-phosphor-image-evb-2u-egs.static.mtd

# === 步骤4（可选）：对 Bank B 也刷入相同固件 ===
# 移动测试夹到 Flash 芯片 CS1
# 重复步骤3

# === 步骤5：断开编程器，上电 ===
# 1. 取下测试夹
# 2. 接上串口线（UART5）
# 3. 打开串口终端（115200 8N1）
# 4. 接通电源
# 5. 观察串口输出
```

> ⚠️ **关键注意事项**：
> - **必须完全断电**再操作编程器，否则可能损坏 Flash 或编程器。
> - **先备份原始固件**，以便随时回退到 AMI。
> - CH341A 是 3.3V 供电，与 w25q512jv 兼容；如果用 5V 编程器需要电平转换。
> - w25q512jv 是 64MB 超大容量 Flash，确保编程器支持（某些老旧的 CH341A 固件不支持 >16MB）。

> 💡 **大白话**：编程器直刷就像给昏迷的病人做脑电波强制灌输。不需要系统有意识，直接绕过一切软件机制把新记忆装进去。但唯一要注意的是，必须等他彻底睡着（完全断电），不然就很容易两方打架，直接烧坏元件。

#### 方法 B：U-Boot TFTP 恢复（板上已有可用 U-Boot 时）

如果板上已有一个能启动的 U-Boot，可以通过网络刷写：

```bash
# === 步骤1：在工作电脑上启动 TFTP 服务器 ===
# 将固件放到 TFTP 根目录
sudo apt install tftpd-hpa        # Ubuntu/Debian
sudo cp obmc-phosphor-image-evb-2u-egs.static.mtd /srv/tftp/image.bin
sudo systemctl restart tftpd-hpa

# === 步骤2：在 U-Boot 控制台操作 ===
# 按住任意键进入 U-Boot 命令行（在 bootdelay 倒计时内按键）

# 设置网络
ast# setenv ipaddr 192.168.1.100       # BMC 的 IP
ast# setenv serverip 192.168.1.1       # TFTP 服务器 IP
ast# setenv netmask 255.255.255.0

# 下载固件到内存
ast# tftp 0x83000000 image.bin
# 等待下载完成...显示 "Bytes transferred = 67108864 (4000000 hex)"

# 写入 Flash（全片擦除+写入）
ast# sf probe 0                         # 选择 Flash 0 (CS0/Bank A)
ast# sf erase 0 0x4000000               # 擦除 64MB
ast# sf write 0x83000000 0 0x4000000    # 写入 64MB

# （可选）写入 Bank B
ast# sf probe 1                         # 选择 Flash 1 (CS1/Bank B)
ast# sf erase 0 0x4000000
ast# sf write 0x83000000 0 0x4000000

# 重启
ast# reset
```

> ⚠️ **注意**：
> - AST2600 默认 DRAM 是 1GB，`0x83000000` 地址留出了足够空间
> - `sf erase` + `sf write` 会花费数分钟（64MB Flash 擦写较慢）
> - 不要在写入过程中断电，否则 Flash 会变成 brick

#### 方法 C：UART Xmodem 恢复（最后手段）

当 Flash 完全为空或损坏、没有 SPI 编程器时。原理是 AST2600 ROM Bootloader 在检测不到有效 SPI Flash 镜像时，会进入 UART 恢复模式，通过 xmodem 协议从串口接收 SPL。

```bash
# === 步骤1：确保 Flash 为空或损坏 ===

# === 步骤2：串口连接 UART5，上电 ===
# ROM Bootloader 会输出提示信息并等待 xmodem 传输

# === 步骤3：通过 xmodem 发送 SPL ===
# 在 minicom 中: Ctrl-A → S → xmodem → 选择 u-boot-spl.bin
# 或者用命令行工具:
sx u-boot-spl.bin < /dev/ttyUSB0 > /dev/ttyUSB0

# === 步骤4：SPL 启动后加载 U-Boot ===
# SPL 初始化 DRAM 后，可以继续用 xmodem 或 TFTP 加载完整 U-Boot
# 然后用 方法B 的 TFTP 流程刷写 Flash
```

> ⚠️ **注意**：此方法速度极慢（115200 baud xmodem），只适合紧急恢复。

> 💡 **大白话**：方法 B 像是医生给病人打点滴，系统本身得有脉搏（U-Boot 活着）才能吸收。方法 C 则是病危抢救，一口一口地慢慢喂药（xmodem 慢如蜗牛），不到走投无路绝对别用。

#### 方法对比

| 方法 | 速度 | 需要 | 适用场景 |
|------|------|------|----------|
| A: SPI 编程器 | 快（5-10分钟） | SPI 编程器 + 测试夹 | **首次烧录（推荐）**、完全 brick |
| B: U-Boot TFTP | 中（3-5分钟） | 可用的 U-Boot + 网络 | 已有 U-Boot 时升级 |
| C: UART Xmodem | 极慢（30+分钟） | 仅串口线 | 紧急恢复、无编程器 |

---

### §9.5 首次启动验证清单

刷好开机，盯着串口控制台，我们就像在看一场多级火箭的发射。必须盯紧每一个阶段的特征输出。

#### 1. 串口观察：启动阶段输出

正常启动时，你应该在 UART5 上依次看到：

```
=== 阶段1: SPL (约1-2秒) ===
U-Boot SPL 2019.04 (日期)
Trying to boot from SPI

=== 阶段2: U-Boot proper (约2-3秒) ===
U-Boot 2019.04 (日期)
DRAM: 1 GiB
Model: AST2600 EVB
...
Hit any key to stop autoboot: 2

=== 阶段3: Linux 内核 (约10-30秒) ===
## Loading kernel from FIT Image at 20100000 ...
   Image Type:   ARM Linux Kernel Image (uncompressed)
...
Starting kernel ...
[    0.000000] Booting Linux on physical CPU 0x0
[    0.000000] Linux version 6.x.x ...
[    0.000000] Machine model: EVB-2U-EGS BMC
...

=== 阶段4: systemd 启动 (约30-120秒) ===
[  OK  ] Started BMC health monitor.
[  OK  ] Started Phosphor IPMI BT daemon.
[  OK  ] Started bmcweb.
...

=== 阶段5: Login prompt ===
evb-2u-egs login:
```

#### 2. 分阶段检查清单

就像卫星发射，前一阶段没成，绝对不可能跳到下一阶段。

**✅ 阶段 A：上电后 5 秒内**

| 检查项 | 期望结果 | 异常处理 |
|--------|---------|---------|
| 串口有任何输出 | 看到 "U-Boot SPL" 文字 | → §9.8 无串口输出 |
| SPL 找到 Flash | "Trying to boot from SPI" | → §9.8 SPL 启动失败 |
| U-Boot 找到 DRAM | "DRAM: 1 GiB" | → §9.8 内存初始化失败 |

**✅ 阶段 B：U-Boot 倒计时**

| 检查项 | 期望结果 | 异常处理 |
|--------|---------|---------|
| 看到 `ast#` 或 bootdelay | "Hit any key to stop autoboot: 2" | → §9.8 U-Boot 挂起 |
| 能按键中断进 U-Boot | 按回车后出现 `ast#` | 正常 |

**✅ 阶段 C：内核启动**

| 检查项 | 期望结果 | 异常处理 |
|--------|---------|---------|
| FIT Image 加载成功 | "## Loading kernel from FIT Image" | → §9.8 FIT 加载失败 |
| DTB 正确 | "Machine model: EVB-2U-EGS BMC" | → §9.8 DTB 不匹配 |
| MTD 分区创建 | 看到 mtd0~mtd5 分区列表 | → §9.8 MTD 分区异常 |
| 无 kernel panic | 不出现 "Kernel panic" | → §9.8 内核崩溃 |

**✅ 阶段 D：系统就绪**

看到登录符后，马上敲指令验证基本盘：

```bash
# 登录（默认密码: 0penBmc — 注意是零不是O）
evb-2u-egs login: root
Password: 0penBmc

# 检查系统基本信息
cat /etc/os-release
# → PRETTY_NAME="OpenBMC Phosphor ..."

hostname
# → evb-2u-egs

# 检查 D-Bus 服务数量
busctl list | wc -l
# → 应该 > 30

# 检查关键服务运行状态
systemctl status bmcweb
systemctl status xyz.openbmc_project.Ipmi.Channel.Ipmb.service
systemctl status phosphor-pid-control
systemctl status xyz.openbmc_project.EntityManager

# 查看 MTD 分区
cat /proc/mtd
# mtd0: 00010000 00001000 "u-boot-spl"
# mtd1: 000d8000 00001000 "u-boot"
# mtd2: 00002000 00001000 "manifest"
# mtd3: 00020000 00001000 "u-boot-env"
# mtd4: 00900000 00001000 "kernel"
# mtd5: 02000000 00001000 "rofs"
# mtd6: 01600000 00001000 "rwfs"

# 查看 U-Boot 环境变量
fw_printenv
# → bootside=a  bootargs=console=ttyS4,115200n8 ...

# 检查网络
ip addr show
# → 应该有 eth0 或 eth1 获取到 IP（如果有 DHCP）
# 或者手动配置:
ip addr add 192.168.1.100/24 dev eth1
ip link set eth1 up

# 测试 BMCWeb
curl -k https://localhost:18080/redfish/v1/
# → 返回 Redfish ServiceRoot JSON
```

> 💡 **大白话**：火箭发射一旦第一级解体，火箭绝不会自己走到第二级。如果你只看到 SPL 却看不到 U-Boot 倒计时，那就不可能进内核。顺藤摸瓜，卡在哪一节，就死查那一节的代码，这是硬件排错的黄金法则。

#### 3. 网络配置（静态 IP）

如果没有 DHCP，手动配置 BMC 网口：

```bash
# 查看网络接口
ip link show
# 通常 eth0 = mac2 (RGMII, 外部PHY)
#       eth1 = mac3 (RMII/NC-SI, 管理口)

# 临时配置（重启后失效）
ip addr add 192.168.1.100/24 dev eth0
ip link set eth0 up
ip route add default via 192.168.1.1

# 持久配置（通过 D-Bus/Redfish）
busctl call xyz.openbmc_project.Network /xyz/openbmc_project/network/eth0/ipv4/addr0 \
  xyz.openbmc_project.Network.IP.Create sssq "192.168.1.100" "255.255.255.0" "192.168.1.1" 4
```

#### 4. 远程访问验证

```bash
# 从工作电脑测试
ssh root@192.168.1.100    # 密码: 0penBmc

# BMCWeb (Redfish)
curl -k -u root:0penBmc https://192.168.1.100/redfish/v1/

# BMCWeb (WebUI)
# 浏览器打开: https://192.168.1.100/
# 登录: root / 0penBmc

# IPMI (如果安装了 ipmitool)
ipmitool -I lanplus -H 192.168.1.100 -U root -P 0penBmc mc info
```

---

### §9.6 运行时固件更新

当 BMC 已经在运行 OpenBMC 时，可以通过以下方式更新固件。不用每次都去找夹子。

#### 🔬 实操：方法 A —— Redfish 固件更新（推荐）

这是 OpenBMC 官方推荐的更新方式，通过 `phosphor-software-manager` 实现。

**步骤**：

```bash
# === 步骤1：准备更新包 ===
# 构建系统会生成 tar 包:
ls build/evb-2u-egs/tmp/deploy/images/evb-2u-egs/*.all.tar
# → obmc-phosphor-image-evb-2u-egs-XXXXXX.static.mtd.all.tar

# === 步骤2：通过 Redfish 上传固件 ===
curl -k -u root:0penBmc \
  -H "Content-Type: application/octet-stream" \
  -X POST \
  -T obmc-phosphor-image-evb-2u-egs.static.mtd.all.tar \
  https://<BMC_IP>/redfish/v1/UpdateService

# === 步骤3：查看上传状态 ===
curl -k -u root:0penBmc \
  https://<BMC_IP>/redfish/v1/UpdateService/FirmwareInventory
# 找到新出现的 image ID

# === 步骤4：激活固件 ===
curl -k -u root:0penBmc \
  -H "Content-Type: application/json" \
  -X PATCH \
  -d '{"RequestedActivation": "xyz.openbmc_project.Software.Activation.RequestedActivations.Active"}' \
  https://<BMC_IP>/redfish/v1/UpdateService/FirmwareInventory/<IMAGE_ID>

# === 步骤5：重启 BMC 使新固件生效 ===
curl -k -u root:0penBmc \
  -H "Content-Type: application/json" \
  -X POST \
  -d '{"ResetType": "GracefulRestart"}' \
  https://<BMC_IP>/redfish/v1/Managers/bmc/Actions/Manager.Reset
```

> 💡 **大白话**：这就像给一辆正在高速行驶的赛车换备胎。系统会在后台默默把新版本写入备用磁盘。一切就绪后，通过一个从容的重启命令，赛车无缝切换到了新轮胎上狂飙。

#### 方法 B：SCP + 手动 flashcp（开发阶段快速更新）

适合开发迭代阶段，跳过签名验证：

```bash
# === 步骤1：将固件传到 BMC ===
scp obmc-phosphor-image-evb-2u-egs.static.mtd root@<BMC_IP>:/tmp/

# === 步骤2：在 BMC 上写入 Flash ===
ssh root@<BMC_IP>

# 查看当前 MTD 设备
cat /proc/mtd
# 找到 "bmc" 对应的 mtd 设备号（通常是 mtd0 的父设备）

# 方法1：用单个分区逐个更新
# 更新内核:
flashcp -v /tmp/fitImage /dev/mtd4      # mtd4 = kernel
# 更新根文件系统:
flashcp -v /tmp/image-rofs /dev/mtd5    # mtd5 = rofs

# 方法2：通过 initramfs 更新整个 Flash
# 将镜像组件放到 /run/initramfs/ 目录
cp /tmp/image-u-boot /run/initramfs/image-u-boot
cp /tmp/image-kernel /run/initramfs/image-kernel
cp /tmp/image-rofs   /run/initramfs/image-rofs
cp /tmp/image-rwfs   /run/initramfs/image-rwfs

# 触发 reboot 进入 initramfs 更新模式
reboot
# initramfs 会自动检测 /run/initramfs/image-* 文件并 flashcp 到对应分区
```

#### 方法 C：BMCWeb WebUI 更新

1. 浏览器打开 `https://<BMC_IP>/`
2. 登录 → Operations → Firmware → Update firmware
3. 选择 `.all.tar` 文件上传
4. 等待上传和验证完成
5. 点击 "Activate" 激活
6. 点击 "Reboot BMC"

#### 更新后验证

```bash
# 检查固件版本
cat /etc/os-release

# 通过 Redfish
curl -k -u root:0penBmc \
  https://<BMC_IP>/redfish/v1/Managers/bmc | python3 -m json.tool | grep -i version

# 通过 U-Boot 环境
fw_printenv bootside
# → 应该是 a（除非你配置了 A/B 切换）
```

---

### §9.7 双 Flash A/B Bank 策略

为了保证高可用，这套硬件挂了 2 块各 64MB 的芯片。一块在 CS0（Bank A），一块在 CS1（Bank B）。

#### 1. 架构概述

```
Flash CS0 (Bank A)                Flash CS1 (Bank B)
┌──────────────────┐              ┌──────────────────┐
│ SPL              │              │ SPL              │
│ U-Boot           │              │ U-Boot           │
│ Env              │              │ Env              │
│ fitImage         │              │ fitImage         │
│ rootfs           │              │ rootfs           │
│ rwfs             │              │ rwfs             │
└──────────────────┘              └──────────────────┘
        ↑                                 ↑
   bootside=a (默认)               bootside=b (备用)
```

#### 2. U-Boot A/B 启动逻辑

U-Boot 环境变量定义了完整的 A/B 启动链：

```bash
# 来自 u-boot-env-ast2600.txt:
bootside=a                    # 默认从 A 启动
bootcmd=setenv origbootargs ${bootargs}; run bootconfcmd; run bootsidecmd
bootsidecmd=if test ${bootside} = b; then run bootb; run boota; else run boota; run bootb; fi
boota=setenv bootpart 2; setenv rootfs rofs-a; run bootmmc
bootb=setenv bootpart 3; setenv rootfs rofs-b; run bootmmc
```

**启动逻辑**：
1. `bootcmd` 调用 `bootsidecmd`
2. `bootsidecmd` 检查 `bootside` 变量
3. 如果 `bootside=a`：先尝试 `boota`，失败则 fallback 到 `bootb`
4. 如果 `bootside=b`：先尝试 `bootb`，失败则 fallback 到 `boota`

> 💡 **大白话**：A/B Bank 就是为了防止系统变砖的双保险。这就像你存了两条游戏进度档。打 Boss 失败把当前档弄坏了？没关系，重启自动跌落加载上一个安全档继续玩，永远不会前功尽弃。

#### 3. 手动切换 Bank

```bash
# === 在 BMC Linux 中切换 ===
# 查看当前 bootside
fw_printenv bootside
# → bootside=a

# 切换到 Bank B
fw_setenv bootside b
reboot

# 切换回 Bank A
fw_setenv bootside a
reboot
```

#### 4. 初次部署与生产更新

**建议首次部署时两个 Flash 都烧入相同固件**，这样可以确保即使 Bank A 损坏，U-Boot 会自动尝试 Bank B。

**生产环境更新流程**：
```
1. BMC 从 Bank A 正常运行
2. 收到新固件，写入 Bank B
3. fw_setenv bootside b
4. reboot → 从 Bank B 启动
5. 验证新固件正常
6. 如果异常：fw_setenv bootside a && reboot → 回退到 Bank A
7. 如果正常：将新固件也写入 Bank A 作为双备份
```

#### 5. 恢复出厂设置

```bash
# 擦除 rwfs 分区（清除所有持久化数据：密码、网络配置、日志）
fw_setenv openbmconce copy-files-to-ram copy-base-filesystem-to-ram
fw_setenv rwreset true
reboot
# initramfs 会检测 rwreset=true 并格式化 rwfs
```

---

### §9.8 实机常见故障排查

真机调试就是一次又一次侦探破案的过程，以下是高发案件现场。

#### 案件 1：上电后串口完全没有输出

**可能原因与排查**：

| # | 原因 | 排查方法 |
|---|------|---------|
| 1 | 串口线 TX/RX 没有交叉 | 交换 TX 和 RX 线 |
| 2 | 接错了 UART 口 | 确认接的是 UART5（BMC console），不是 UART1/UART4 |
| 3 | 波特率不对 | 确认终端设置为 115200 8N1，无流控 |
| 4 | Hardware Flow Control 开着 | minicom 里关掉 Hardware Flow Control |
| 5 | USB-UART 转换器驱动问题 | `dmesg | tail` 检查是否识别到 ttyUSB0 |
| 6 | Flash 烧录失败/为空 | 重新用 SPI 编程器烧录，读回校验 |
| 7 | BMC 没上电 | 检查 BMC 3.3V 待机电源是否正常（有些板子需要插 PSU 才有待机电） |

#### 案件 2：SPL 启动失败

**现象**：看到 "U-Boot SPL" 后卡住或重启循环。

**排查**：
```bash
# 1. SPL 找不到 Flash：
#    "spi_xfer: spi_xfer: timeout" → Flash 芯片接触不良或型号不支持
#    解决: 检查 Flash 焊接，确认 w25q512jv 兼容性

# 2. SPL 加载 U-Boot 失败：
#    "## Checking hash(es) for FIT Image at ..." → U-Boot 镜像损坏
#    解决: 重新烧录，确保完整 64MB 写入

# 3. SPL DRAM 初始化失败：
#    卡在 "Trying to boot from SPI" → 可能是 DRAM 配置不匹配
#    解决: 确认 UBOOT_DEVICETREE = "ast2600a1-evb" 与实际硬件匹配
```

#### 案件 3：内核启动后 Kernel Panic

**常见 panic 类型**：

```
# 类型1: "VFS: Unable to mount root fs"
# 原因: rootfs 分区未正确写入或 mtdparts 不匹配
# 解决: 确认 static.mtd 完整烧入，fw_printenv 检查 bootargs

# 类型2: "vmalloc_node_range for size XXXXXXX failed" → SPI 驱动 probe 失败 → rootfs 挂载失败
# 原因: 物理 RAM 大于 1GB 时，默认 VMSPLIT_2G 导致 vmalloc 空间不足，
#       无法映射 AST2600 SPI FMC 的 256MB AHB 窗口
# 解决: 
#   1. 内核配置添加 CONFIG_VMSPLIT_3G_OPT=y（改变内存分割比例）
#   2. U-Boot bootargs 添加 vmalloc=512M（显式预留 vmalloc 空间）
#   详见 §9.10 ARM32 内存管理深度解析

# 类型3: "Kernel panic - not syncing: Attempted to kill init!"
# 原因: systemd/init 启动失败
# 解决: 检查 rootfs 是否完整，尝试单独挂载 squashfs 验证
```

#### 案件 4：网络不通

```bash
# === 在 BMC 上排查 ===

# 1. 确认网口 link 状态
ip link show
# eth0 应该是 UP 状态，如果 NO-CARRIER 说明没有网线连接

# 2. 确认是哪个网口
# eth0 通常对应 mac2 (RGMII, 需要外部 PHY)
# eth1 通常对应 mac3 (RMII/NC-SI, 带内管理)
# 连接电脑调试用 eth0，连 NC-SI 用 eth1

# 3. 手动设置 IP
ip addr flush dev eth0
ip addr add 192.168.1.100/24 dev eth0
ip link set eth0 up

# 4. 检查 PHY 状态
ethtool eth0
# → Link detected: yes 表示物理连接正常

# 5. ping 测试
ping 192.168.1.1    # ping 网关

# 6. 如果 RGMII 不通
# 检查 PHY reset GPIO：DTS 中配置了 gpio-hog RST_RGMII_PHYRST_N (GPIO_N7)
# 确认 PHY 芯片供电和 MDIO 总线正常
cat /sys/bus/mdio_bus/devices/*/phy_id    # 查看 PHY 是否被检测到
```

#### 案件 5：BMCWeb 无法访问

```bash
# 1. 确认 bmcweb 在运行
systemctl status bmcweb
# 如果 failed，查看日志:
journalctl -u bmcweb --no-pager -n 50

# 2. 确认监听端口
ss -tlnp | grep bmcweb
# 默认监听 443 (HTTPS)

# 3. 从 BMC 本地测试
curl -k https://localhost/redfish/v1/
# 如果本地能访问但远程不行，是网络/防火墙问题

# 4. 首次登录修改密码
# 如果使用默认密码 0penBmc 无法登录:
# 某些版本首次登录需要先修改密码
busctl call xyz.openbmc_project.User.Manager \
  /xyz/openbmc_project/user/root \
  xyz.openbmc_project.User.ChangePassword \
  ss "root" "新密码"
```

#### 案件 6：I2C 设备不可见

```bash
# 1. 扫描 I2C 总线
i2cdetect -l                    # 列出所有 I2C 总线
i2cdetect -y 7                  # 扫描 bus7 (PSU)
i2cdetect -y 9                  # 扫描 bus9 (Fan CPLD)

# 2. 如果总线上看不到设备
# 检查 I2C MUX 是否正确切换:
i2cdetect -y 0                  # 扫描 bus0，应该能看到 0x73 (PCA9546)
i2cget -y 0 0x73 0x00           # 读取 MUX 当前通道选择

# 3. 如果 entity-manager 没有加载设备
journalctl -u xyz.openbmc_project.EntityManager --no-pager -n 50
# 查看是否有 JSON 配置解析错误
```

#### 案件 7：传感器读数异常

```bash
# 1. 查看 hwmon 设备
ls /sys/class/hwmon/
# 每个目录对应一个传感器芯片

# 2. 读取原始值
cat /sys/class/hwmon/hwmon*/temp1_input    # 温度（毫摄氏度）
cat /sys/class/hwmon/hwmon*/in1_input      # 电压（毫伏）

# 3. 通过 D-Bus 查看传感器
busctl tree xyz.openbmc_project.HwmonTempSensor
busctl introspect xyz.openbmc_project.HwmonTempSensor \
  /xyz/openbmc_project/sensors/temperature/inlet_temp
```

#### 紧急恢复流程

当 BMC 完全无法启动时，切忌慌乱，按以下标准抢救流程走：

```
1. 断电
2. 用 SPI 编程器连接 Flash CS0
3. 读取当前 Flash 内容保存（用于事后法医分析）
4. 写入已知正常的 static.mtd 镜像
5. 断开编程器
6. 上电，观察串口
7. 如果 CS0 的 Flash 芯片物理损坏：
   - 切换到 CS1 (Bank B) 启动
   - 或者联系硬件工程师更换 Flash 芯片
```

> 💡 **大白话**：真机报错就像病人描述症状。肚子痛（Kernel panic）可能是吃坏东西（分区烧错），也可能是阑尾炎（DTS配置不对）。我们千万不要只盯着一个错误盲猜，要学会开出 `dmesg`、`ethtool` 和 `i2cdetect` 这些化验单辅助定位，才能精确下刀。

#### 案件 8：真实案例 — vmalloc 空间耗尽导致 Kernel Panic（本项目实录）

这是我们在 evb-2u-egs 真机上遇到的真实故障，完整还原排障过程。

**现象**：
- 固件在 QEMU 上完美启动，SSH、BMCWeb 全部正常
- 烧录到真机后，内核加载成功但立即 Kernel Panic，WDT 触发无限重启
- 串口日志关键错误：

```
[    1.696292] vmalloc_node_range for size 268439552 failed:
               Address range restricted to 0xf0800000 - 0xff800000
[    1.709498] spi-aspeed-smc 1e620000.spi: missing AHB mapping window
[    1.715876] spi-aspeed-smc 1e620000.spi: probe with driver spi-aspeed-smc failed with error -12
...
[    2.449]+  Kernel panic - not syncing: Attempted to kill init!
```

**分析过程**：

| 步骤 | 操作 | 发现 |
|------|------|------|
| 1 | 对比 QEMU 和真机环境 | QEMU 默认: 1GB RAM / 真机: 2GB RAM |
| 2 | 计算 vmalloc 可用空间 | `0xff800000 - 0xf0800000` = 240MB |
| 3 | 查看 SPI 驱动请求大小 | `268439552` bytes = 256MB |
| 4 | **256MB > 240MB → 分配失败！** | 根因确认 |
| 5 | 搜索社区解决方案 | Facebook 16 个 AST2600 平台都用 `VMSPLIT_3G_OPT` + `vmalloc=768M` |

**为什么 QEMU 没问题**：
QEMU 只配了 1GB RAM，在 `VMSPLIT_2G`（内核空间 2GB）下，1GB 直接映射只占一半内核空间，vmalloc 有近 ~960MB 可用，256MB 轻松放下。真机 2GB RAM 把内核空间几乎挤满，vmalloc 只剩 240MB。

**修复（两步缺一不可）**：

```bash
# 1. 内核配置 (recipes-kernel/linux/linux-aspeed/evb-2u-egs.cfg)
#    添加:
CONFIG_VMSPLIT_3G_OPT=y

# 2. U-Boot 配置 (recipes-bsp/u-boot/u-boot-aspeed-sdk/evb-2u-egs.cfg)
#    新建文件:
CONFIG_USE_BOOTARGS=y
CONFIG_BOOTARGS="console=ttyS4,115200n8 root=/dev/ram rw vmalloc=512M"

# 3. 重新构建
bitbake -c clean linux-aspeed u-boot-aspeed-sdk
bitbake obmc-phosphor-image
```

**教训**：
1. **QEMU 不能替代真机测试** — 内存大小差异就能导致完全不同的行为（但可以调整 QEMU 参数来复现，详见 §9.10.8）
2. **看社区怎么做** — Facebook 十几个平台踩过的坑，就是最好的参考
3. **错误信息要逐字分析** — `268439552` 和 `0xf0800000-0xff800000` 这些数字才是破案关键
4. **先复现再修复** — 我们将 QEMU 调为 2G 后完美复现了 Panic，修复后同样在 QEMU 2G 下验证通过，给真机烧录提供了信心

> 💡 **大白话**：这个 bug 就像租了个小仓库（vmalloc 240MB）去放一整集装箱的货（SPI 映射 256MB），门都塞不进去。解决办法：换个大仓库（VMSPLIT_3G_OPT 改变内存布局），再挂个"此处预留 512MB"的牌子（vmalloc=512M bootargs）。详细原理见 §9.10。

---

#### 案件 9：真实案例 — QEMU 验证通过，真机仍然 Panic（U-Boot 环境变量覆盖问题）

这是案件 8 的**续集**。案件 8 的修复在 QEMU 上验证通过，但烧录到真机后，**同样的 Panic 再次出现**。

**现象**：

- 案件 8 的修复（`VMSPLIT_3G_OPT` + `CONFIG_BOOTARGS` 加入 `vmalloc=512M`）在 QEMU 2G 下验证通过
- 烧录到真机，串口日志显示**完全相同的 Panic**，一字不差
- 仔细对比内核命令行，发现关键差异：

```
# QEMU 启动时的内核命令行（正常）：
Kernel command line: console=ttyS4,115200n8 root=/dev/ram rw vmalloc=512M

# 真机启动时的内核命令行（有问题）：
Kernel command line: console=ttyS4,115200n8 root=/dev/ram rw
```

`vmalloc=512M` 在真机上**凭空消失了**！

**分析过程**：

| 步骤 | 操作 | 发现 |
|------|------|------|
| 1 | 对比 QEMU 和真机的内核命令行 | 真机少了 `vmalloc=512M` |
| 2 | 查看真机 U-Boot 启动日志 | `Loading Environment from SPI Flash... OK` |
| 3 | 理解 U-Boot 环境变量机制 | Flash 里保存的旧 `bootargs` 覆盖了编译进去的默认值 |
| 4 | 确认根因 | `CONFIG_BOOTARGS` 只是"默认值"，Flash 里有保存值时会被覆盖 |
| 5 | 搜索可靠的修复方案 | 内核的 `CONFIG_CMDLINE_EXTEND` 在内核侧追加，不受 U-Boot 影响 |

**根因详解——U-Boot 环境变量是怎么工作的**：

U-Boot 有两套 bootargs 来源，优先级从高到低：

```
优先级 1（最高）：Flash 里保存的环境变量（env save 写入的）
优先级 2（最低）：编译时写死的 CONFIG_BOOTARGS 默认值
```

真机上，Flash 里保存着**旧固件（AMI MegaRAC）时代的 bootargs**，没有 `vmalloc=512M`。U-Boot 一启动就从 Flash 读出这个旧值，直接覆盖了我们编译进去的新默认值。QEMU 没有这个问题，因为 QEMU 的 Flash 镜像是全新的，没有保存过任何环境变量，所以 U-Boot 只能用编译时的默认值。

```
真机启动流程：
  U-Boot 上电
    → 从 SPI Flash 读取环境变量（Loading Environment from SPI Flash... OK）
    → 找到旧的 bootargs = "console=ttyS4,115200n8 root=/dev/ram rw"
    → 用这个旧值启动内核（CONFIG_BOOTARGS 被忽略）
    → 内核没有 vmalloc=512M → vmalloc 不够 → Panic

QEMU 启动流程：
  U-Boot 上电
    → 从 Flash 读取环境变量（Flash 是全新的，没有保存值）
    → 找不到保存的 bootargs → 使用 CONFIG_BOOTARGS 默认值
    → 默认值里有 vmalloc=512M → 正常启动
```

**修复方案——让内核自己追加 vmalloc=512M**：

不依赖 U-Boot 传参，改为在内核侧通过 `CONFIG_CMDLINE_EXTEND` 追加：

```
# 文件：meta-evb-2u-egs/recipes-kernel/linux/linux-aspeed/evb-2u-egs.cfg
CONFIG_CMDLINE="vmalloc=512M"
CONFIG_CMDLINE_EXTEND=y
```

`CONFIG_CMDLINE_EXTEND` 的作用：内核启动时，把 `CONFIG_CMDLINE` 里的内容**追加**到 U-Boot 传来的 bootargs 后面。无论 U-Boot 传什么、Flash 里保存了什么旧值，内核都会自己加上 `vmalloc=512M`。

```
修复后的真机启动流程：
  U-Boot 上电
    → 从 Flash 读取旧 bootargs = "console=ttyS4,115200n8 root=/dev/ram rw"
    → 传给内核
  内核启动
    → 接收 U-Boot 的 bootargs
    → 追加 CONFIG_CMDLINE = "vmalloc=512M"
    → 最终命令行 = "console=ttyS4,115200n8 root=/dev/ram rw vmalloc=512M"
    → 正常启动 ✅
```

**同时修复的问题——I2C bus10 引脚冲突**：

真机日志里还有另一个错误：

```
[    1.228210] aspeed-g6-pinctrl: pin M24 already requested by 1e650010.mdio;
               cannot claim for 1e78a580.i2c
```

这是 DTS 里 `&i2c10` 和 `&mdio2` 同时启用，但它们共用了同一个物理引脚 M24。`&mdio2` 是 mac2 网口的 PHY 管理总线，必须保留；`&i2c10` 是内部背板 CPLD 的访问总线，暂时禁用。

修复：

```dts
/* 文件：aspeed-bmc-evb-2u-egs.dts */
&i2c10 {
    status = "disabled";  /* 原来是 "okay"，与 mdio2 引脚冲突，暂时禁用 */
};
```

**教训**：

1. **QEMU 通过 ≠ 真机通过** — QEMU 的 Flash 是全新的，真机的 Flash 可能有旧固件留下的环境变量
2. **`CONFIG_BOOTARGS` 只是默认值** — 只要 Flash 里有保存的环境变量，它就会被覆盖
3. **内核侧的修复比 U-Boot 侧更可靠** — `CONFIG_CMDLINE_EXTEND` 不受 U-Boot 环境变量影响
4. **看内核命令行是排查 bootargs 问题的第一步** — 日志里 `Kernel command line:` 那一行，是 U-Boot 实际传给内核的值，和你以为的可能完全不同

> 💡 **大白话**：你在工厂里给机器预设了一套操作参数（`CONFIG_BOOTARGS`），但这台机器之前被别人用过，他们把自己的参数保存在机器的记忆卡里（Flash 环境变量）。机器一开机，先读记忆卡，发现有保存的参数，就直接用了，完全无视你的预设。解决办法：不要依赖机器的记忆卡，改成在操作系统层面（内核）强制追加你需要的参数，这样不管记忆卡里存了什么，都能生效。

---

### §9.9 面试加分点：实机经验总结

面试官很清楚 QEMU 和真实硬件的巨大鸿沟。如果你的经验只停留在模拟器上，那在硬核的硬件架构提问前很容易露怯。这一章的每一个细节，在面试时都能让你脱颖而出，证明你不仅会敲键盘，还闻过松香的味道。

- **构建与产物的深度**：你能清晰背出 64MB 静态分区的 offset 怎么拼凑的（涉及 `image_types_phosphor.bbclass`），甚至解释为什么 Env 要留出 128KB 空间。这证明你懂得构建产物落到物理载体上的真实形态。
- **底层初始化的细节**：你能说出 SPL 负责初始化 DRAM、U-Boot 负责读取环境变量切换 A/B bank。这证明你的知识下探到了 Bootloader 的最核心。
- **排雷与侦探思维**：面试官问"板子没网怎么查"，你可以滔滔不绝地从 `ip link` 讲到 `ethtool` 检查 PHY 状态，再深挖到 GPIO 重置引脚和 MDIO 总线检测。问到"串口无输出"，你可以马上抛出硬件流控（Flow Control）和波特率的排查。这些全都是真正的实战烙印。

硬件不会说谎，万用表的电平骗不了人。当你把一手定制的 OpenBMC 固件成功在这块冷冰冰的板子上跑起来，让风扇转动、让指示灯闪烁的时候，你就已经是一名真正合格的嵌入式全栈开发工程师了。

> 💡 **大白话**：简历上写"熟悉 OpenBMC"和"在多款服务器主板上完成 OpenBMC 从零移植与硬排障"，就像简历上写"会背菜谱"和"能一个人炒出一桌国宴"。面试官随便抛出个实操的边角料问题，你脱口而出的排障思路，就是最好的实力敲门砖。

---

### §9.10 ARM32 内存管理深度解析（面试杀手锏）

本节将深入探讨上文 Case 8 中 vmalloc 耗尽导致 Kernel Panic 的根本原因。这不仅是解决问题的记录，更是面试中证明你**懂底层**的杀手锏。

#### §9.10.1 32 位地址空间分割

ARM32 CPU 的总虚拟地址空间是 4GB（$2^{32}$ 字节）。Linux 内核将其划分为**用户空间**（User Space）和**内核空间**（Kernel Space）。

不同的内核配置选项决定了这个 4GB 空间的分割比例：

| 配置选项 | PAGE_OFFSET | 用户空间大小 | 内核空间大小 | 说明 |
|----------|-------------|--------------|--------------|------|
| **VMSPLIT_3G** | `0xC0000000` | 3GB | 1GB | 标准 Linux 默认，适合小内存设备 |
| **VMSPLIT_2G** | `0x80000000` | 2GB | 2GB | OpenBMC ASPEED 默认，为了容纳更多设备映射 |
| **VMSPLIT_3G_OPT** | `0xB0000000` | 2816MB | 1280MB | **我们的救星**，平衡了用户空间和内核空间的需求 |

当设置 `CONFIG_VMSPLIT_3G_OPT=y` 时，内核空间从 `0xB0000000` 开始，大小为 1280MB。

#### §9.10.2 内核虚拟地址空间完整布局

在内核的这部分空间中，并非所有地址都用来映射物理内存。以 VMSPLIT_2G 为例，内核的 2GB 虚拟地址空间典型布局如下：

```text
0xFFFFFFFF ┬─────────────────────────┬
           │  Vectors (异常向量表)    │
           ├─────────────────────────┤
           │  Fixmap (固定映射区)     │
           ├─────────────────────────┤
           │  PKMAP (永久内核映射)    │
           ├─────────────────────────┤
           │  kmap_atomic (临时映射)  │
           ├─────────────────────────┤
           │  VMALLOC 区             │ ← ioremap() 和 vmalloc() 分配于此！
           ├─────────────────────────┤
           │  Guard Hole (安全隔离带) │
           ├─────────────────────────┤
           │  Lowmem (直接映射区)     │ ← 大小取决于物理 RAM
PAGE_OFFSET┴─────────────────────────┴
```

**重点注意**：`vmalloc` 区域（图中 VMALLOC 区）是内核用来分配**虚拟地址连续但物理地址不一定连续**的内存，同时也是 **设备寄存器映射（ioremap）** 的专用区域。加载内核模块（.ko）也在这里。

#### §9.10.3 直接映射 (Lowmem) vs 高端内存 (Highmem)

核心矛盾在于：**如果物理 RAM 的大小超过了内核直接映射区（Lowmem）的容量，多出来的内存该怎么办？**

1. **直接映射 (Lowmem)**：
   - 虚拟地址 = 物理地址 + `PAGE_OFFSET`。
   - 映射是永久的，访问零开销。

2. **高端内存 (Highmem)**：
   - 当物理内存过大（如 2GB），无法全部塞进直接映射区时，超出部分成为 Highmem。
   - Highmem **没有永久的虚拟地址**。内核需要访问它时，必须临时借用 PKMAP 或 `kmap_atomic` 区域映射，用完立刻释放（kunmap）。
   - Highmem 的映射槽位极其有限（比如 PKMAP 只有 1024 个页），频繁映射会带来性能损耗，甚至死锁风险。

> 💡 **大白话**：内核空间就像是员工的固定工位，物理内存就像是公司招的员工。如果工位够多（物理内存少），每个员工发一个固定工位（Lowmem）。如果员工太多（2GB RAM），工位坐不下了，多出来的员工只能当"走读生"（Highmem），需要用电脑时就临时去公共机房借用一台（kmap），用完马上让给别人。

#### §9.10.4 AST2600 SPI FMC AHB 窗口机制

AST2600 内部有一个 FMC（Flash Memory Controller），负责管理 SPI Flash。

```text
┌───────────────── AST2600 SoC ─────────────────┐
│                                               │
│  ┌──────────┐          ┌───────────────┐      │
│  │   CPU    ├───AHB────┤     FMC       │      │
│  └──────────┘          └─┬─┬─┬─┬───────┘      │
│                          │ │ │ │              │
└──────────────────────────┼─┼─┼─┼──────────────┘
                           │ │ │ │
                  CE0 ─────┘ │ │ └───── CE3
                             ▼ ▼
                       SPI Flash 芯片
```

为了让 CPU 能像读写普通内存一样读写 Flash，FMC 提供了一个**AHB Decode Window（内存映射 I/O 窗口）**。AST2600 支持多达 4 个片选（CE0-CE3），每个片选最大可分配 64MB 的寻址空间。

4 个片选 × 64MB = **256MB**。

当 `spi-aspeed-smc` 驱动加载时，它极其霸道地要求一次性 `ioremap()` 映射这完整的 256MB 窗口，以便完全控制所有可能的 Flash 区域。而 `ioremap()` 会从 `vmalloc` 区域划走这 256MB 的虚拟地址空间！

#### §9.10.5 QEMU vs 真机内存差异

为什么 QEMU（默认 1G）下风平浪静，真机却 Kernel Panic？因为它们的物理 RAM 大小不同，导致了 VMSPLIT_2G 下内存布局的剧变！（注：将 QEMU 内存调为 2G 后，同样会 Panic——详见 §9.10.8 的复现实验。）

**QEMU (1GB RAM) + VMSPLIT_2G：**
- 内核空间总量 = 2GB
- 直接映射区 (Lowmem) 占去 1GB（存放物理内存）
- 剩下的 1GB 空间，分配给 PKMAP、kmap 等杂项后，**vmalloc 区域还有约 960MB**。
- SPI 驱动申请 256MB？随便拿，毫无压力！

**真机 (2GB RAM) + VMSPLIT_2G：**
- 内核空间总量 = 2GB
- 直接映射区 (Lowmem) 试图映射整个 2GB 物理内存，把内核虚拟地址空间**直接撑爆**！
- 系统不得不强行压缩直接映射区，勉强挤出一点点缝隙给 vmalloc。
- 最终，**vmalloc 区域只剩下区区 240MB**（`0xf0800000 - 0xff800000`）。
- SPI 驱动申请 256MB？直接越界报错：`vmalloc_node_range for size 268439552 failed`。

如果 QEMU 启动时也加上 `-m 2G` 的参数，它同样会当场 Panic。

#### §9.10.6 两个修复为什么缺一不可

面对 vmalloc 空间不足，我们祭出了组合拳：

1. **`CONFIG_VMSPLIT_3G_OPT=y` (内核编译时)**
   - 这改变了红线（`PAGE_OFFSET`），将内核空间从 2GB 缩小到 1280MB。
   - 听起来很矛盾？内核空间变小了，vmalloc 怎么反而够了？
   - 因为在 1280MB 内核空间下，直接映射区（Lowmem）最多只能占不到 1GB（通常 700MB 左右）。剩下的 1.3GB 物理内存被无情地赶到了高端内存（Highmem）当走读生。
   - 正因为大部分物理内存变成了无需永久映射的 Highmem，内核虚拟地址空间反而**腾出了一大块空地**。

2. **`vmalloc=512M` (U-Boot 启动时)**
   - 这是给内核下达的**强制圈地令**。
   - 告诉内核："不管你直接映射区想占多大，必须给我死死划出 512MB 的虚拟地址空间留给 vmalloc 专用！"
   - 这确保了即使内存布局发生波动，那 256MB 的 SPI AHB 窗口也绝对有地可落。

社区中的老玩家 Facebook，在他们的 16 款 AST2600 平台上，清一色使用了 `VMSPLIT_3G_OPT=y` 配合更宽裕的 `vmalloc=768M`。这证明了这是业界标准的解决路径。

#### §9.10.7 面试话术

如果面试官问："你在嵌入式项目里，遇到过什么有趣的内存问题吗？"

你可以这样娓娓道来：
> "在我负责将 OpenBMC 移植到 evb-2u-egs 实机时，遇到了一个经典的内存空间布局问题。
>
> 现象是固件在 QEMU 里完美运行，但烧到实机后，内核刚启动就直接 Panic。我抓取了串口日志，发现是一行 `vmalloc_node_range failed`，紧接着是 spi-aspeed-smc 驱动报 `missing AHB mapping window`。
>
> 我立刻意识到这是虚拟地址空间耗尽了。AST2600 的 SPI 控制器为了支持全容量 Flash，要求映射高达 256MB 的 AHB 窗口。
>
> 可是为什么 QEMU 不报错？我对比了硬件配置，发现 QEMU 只有 1GB 内存，而我们的真机板载了 2GB。OpenBMC 默认使用了 `VMSPLIT_2G`，在 1GB RAM 下，直接映射区只吃掉一半的内核空间，vmalloc 有近 1GB 富余；但在 2GB RAM 下，直接映射区把 2GB 内核空间撑爆了，系统拼死挤出的 vmalloc 空间只剩 240MB，根本放不下 SPI 驱动要求的 256MB，所以当场挂掉。
>
> 我的修复方案是双管齐下：首先在内核配置加上 `CONFIG_VMSPLIT_3G_OPT=y`，将内核空间压缩到 1280MB，迫使超出的物理内存进入 Highmem，从而腾出虚拟地址空间；其次，在 U-Boot bootargs 里强行加上 `vmalloc=512M`，硬性划出安全区。
>
> 事后我查阅了 Meta 的 meta-facebook 源码，发现他们十几台 AST2600 机器全部采用了这个组合方案，这让我更加确信了这是 32位大内存 ARM 系统的标准解法。这个问题让我深刻理解了 Lowmem、Highmem 和 vmalloc 之间的此消彼长关系。"

> 💡 **大白话**：这就像是你有一张 4 米长的办公桌（4GB虚拟空间）。
>
> 原来规定：左边 2 米给工人办公（用户空间），右边 2 米当仓库堆货（内核空间）。
> 后来进了一大批货（2GB 物理内存），把右边 2 米全堆满了。这时候又来了一个必须放一起的超大号快递（SPI 256MB 连续映射），放不下了，系统直接崩溃。
> 
> 怎么办？
> 第一步（VMSPLIT_3G_OPT）：重新划线！左边工人多占点（2.8米），右边仓库留少点（1.2米）。同时规定，大部分散货不能长期占位子了，统统搬去流动寄存柜（Highmem 高端内存）。
> 第二步（vmalloc=512M）：在空出来的右边区域，用警戒线死死圈出一块半米长的区域（512MB），挂上牌子"超大号快递专用，闲杂货物禁止占用！"。
> 
> 这样，不管散货怎么折腾，大快递永远有地方放，问题完美解决。

---

#### §9.10.8 QEMU 2G 验证——修复确认

修复方案提出后，我们不急着烧录真机。科学的做法是先在 QEMU 中**复现问题**，再**验证修复**。

**第一步：复现（旧固件 + 2G RAM）**

将 QEMU 内存从 1G 提升到 2G（`-m 2G`），运行修复前的旧固件：

```
vmalloc_node_range for size 268439552 failed: Address range restricted to 0xf0800000 - 0xff800000
spi-aspeed-smc 1e620000.spi: missing AHB mapping window
...
Kernel panic - not syncing: Attempted to kill init!
```

✅ 与真机串口日志**完全一致**！这证明问题 100% 是内存布局导致，与硬件外设无关。

**第二步：验证（新固件 + 2G RAM）**

编译包含 `VMSPLIT_3G_OPT=y` + `vmalloc=512M` 的新固件，同样在 QEMU 2G 下运行：

```
Kernel command line: console=ttyS4,115200n8 root=/dev/ram rw vmalloc=512M
Zone ranges:
  Normal   [mem 0x80000000-0xaeffffff]     ← ~768MB Lowmem
  HighMem  [mem 0xaf000000-0xfeffffff]     ← 剩余进 Highmem
...
spi-aspeed-smc 1e620000.spi: CE0 read buswidth:2 [0x203c0641]   ← SPI 驱动加载成功！
5 fixed-partitions partitions found on MTD device bmc             ← MTD 分区正常！
...
Welcome to Phosphor OpenBMC!
Hostname set to <evb-2u-egs>.
...
evb-2u-egs login:                                                 ← 系统正常启动！
```

✅ 所有核心服务正常运行：bmcweb、D-Bus、Entity Manager、Fan Control、SSH 全部就绪。

**对比总结**：

| 测试场景 | SPI 驱动 | MTD 分区 | rootfs 挂载 | systemd | 结果 |
|----------|----------|----------|-------------|---------|------|
| 旧固件 + 2G RAM | ❌ vmalloc 失败 | ❌ 无 | ❌ Panic | ❌ 未到达 | 💀 |
| 新固件 + 2G RAM | ✅ CE0 正常 | ✅ 5 个分区 | ✅ 成功 | ✅ 全部正常 | 🎉 |

> 💡 **大白话**：在真机上动烙铁之前，先在 QEMU 里把问题复现出来，再验证修复方案。这样做有三个好处：一是省去了每次烧录的等待时间（几分钟 vs 几秒钟），二是消除了"是不是其他硬件问题"的干扰因素，三是给你的分析增加了**铁证**——面试时说"我先在模拟器中复现，确认根因后再上真机验证"，这比"我直接改了烧了试了"高出不止一个段位。

---

### §9.11 QEMU vs 真机——配置差异全解析

很多同学问：QEMU 和真机的配置到底有哪些差异？哪些测试结果在真机上仍然有效？这里做一个系统性的全面对比。

#### 一致项（QEMU 验证结果可直接迁移到真机）

| 项目 | QEMU | 真机 | 说明 |
|------|------|------|------|
| DRAM 大小 | 2 GiB (`-m 2G`) | 2 GiB | 已对齐，是本次 vmalloc 修复的关键 |
| Flash 型号 | w25q512jv | w25q512jv | `fmc-model` 参数匹配 |
| 串口控制台 | ttyS4@115200 | UART5/ttyS4@115200 | 一致 |
| Kernel cmdline | `vmalloc=512M` | `vmalloc=512M` | 同一个固件 |
| Kernel config | `VMSPLIT_3G_OPT=y` | `VMSPLIT_3G_OPT=y` | 同一个固件 |
| 内核版本 | 6.18.21 | 6.18.21 | 同一个固件 |
| systemd 服务栈 | 全部正常 | 预期正常 | 软件层完全相同 |

#### 差异项（需要真机验证）

| 项目 | QEMU | 真机 | 影响 |
|------|------|------|------|
| SoC 版本 | 通用 AST2600 | AST2600-**A3** | QEMU 不区分 A1/A3，功能等效 |
| Flash 数量 | 1 颗 (64MB) | 2 颗 (128MB, A/B bank) | QEMU 不支持双 bank 切换 |
| I2C 设备 | **无** | 26+ 设备 | 温度传感器、PSU、CPLD 全部需真机验证 |
| GPIO | 基本寄存器模拟 | 47 个引脚 | 电源控制、LED 物理输出需真机 |
| PECI | 不模拟 | CPU0=0x30, CPU1=0x31 | CPU 温度读取需真机 |
| 网络 PHY | 虚拟 ftgmac100 | RTL8211E + NCSI | 真实网络拓扑需真机 |
| x86-power-control | FAILED (无硬件) | 应正常 | 依赖 GPIO 硬件 |

#### 面试加分话术

> "在我的开发流程中，QEMU 验证和真机验证是互补的两个阶段。QEMU 擅长验证**软件栈层面**的正确性——内核启动、内存布局、文件系统挂载、systemd 服务启动。而真机验证覆盖**硬件交互层面**——I2C 设备通信、GPIO 电平控制、PECI 温度读取、网络 PHY 协商。我会先在 QEMU 中快速迭代，确认软件层面没有问题后，再烧录真机进行硬件集成测试。这种分层验证策略大大提升了开发效率，也减少了在真机上反复烧录的次数。"

> 💡 **大白话**：QEMU 就像驾校的模拟器——方向盘、油门、刹车的操作逻辑和真车一模一样，但你不会真的撞到路灯。真机就像路考——你得应对真实的路况、红绿灯和行人。先在模拟器里练到不会犯低级错误，再上路考，通过率就高多了。

---

### §9.12 U-Boot 环境变量机制深度解析——为什么"修好了"还会 Panic

本节是案件 9 的配套深度讲解。如果你只看案件 9 的结论，可能会觉得"加个 CONFIG_CMDLINE_EXTEND 就完了"。但如果你不理解背后的机制，下次遇到类似问题还是会懵。这一节把 U-Boot 环境变量的完整工作原理讲清楚。

#### §9.12.1 U-Boot 的"记忆"在哪里

U-Boot 是一个 Bootloader，它在内核启动之前运行，负责初始化硬件、加载内核、传递启动参数。它有一套自己的"配置系统"，叫做**环境变量（Environment Variables）**。

这些环境变量存储在 Flash 的一个专用分区里（在我们的平台上是 `u-boot-env` 分区，64KB）。你可以把它理解成 U-Boot 的"记事本"——它会把用户设置过的所有配置都写在这里，下次开机时读出来继续用。

```
Flash 分区布局（简化版）：
┌─────────────────┐ 0x00000000
│   u-boot        │  512KB  ← U-Boot 程序本体
├─────────────────┤ 0x00080000
│   u-boot-env    │   64KB  ← 环境变量保存在这里 ★
├─────────────────┤ 0x00090000
│   kernel        │         ← 内核
├─────────────────┤
│   rootfs        │         ← 根文件系统
└─────────────────┘
```

#### §9.12.2 bootargs 的两个来源和优先级

内核启动时需要一个"启动参数"（bootargs），告诉内核用哪个串口、挂载哪个根文件系统等。这个参数有两个来源：

**来源1：编译时写死的默认值（`CONFIG_BOOTARGS`）**

在 U-Boot 的配置文件里（我们的 `evb-2u-egs.cfg`）：

```
CONFIG_USE_BOOTARGS=y
CONFIG_BOOTARGS="console=ttyS4,115200n8 root=/dev/ram rw vmalloc=512M"
```

这个值被编译进 U-Boot 的二进制文件里。如果 Flash 里没有保存过环境变量，U-Boot 就用这个默认值。

**来源2：Flash 里保存的环境变量**

如果有人曾经在 U-Boot 命令行里执行过：

```
setenv bootargs "console=ttyS4,115200n8 root=/dev/ram rw"
saveenv
```

那么这个值就被写入了 Flash 的 `u-boot-env` 分区。下次开机，U-Boot 读到这个保存的值，就会**忽略编译时的默认值**，直接用 Flash 里的。

**优先级规则**：

```
Flash 里有保存的值？
  ├── 是 → 用 Flash 里的值（忽略 CONFIG_BOOTARGS）
  └── 否 → 用 CONFIG_BOOTARGS 默认值
```

#### §9.12.3 为什么 QEMU 和真机行为不同

这就是案件 9 的核心谜题。

**QEMU 的情况**：

我们给 QEMU 提供的 Flash 镜像（`obmc-phosphor-image-evb-2u-egs.static.mtd`）是刚构建出来的全新镜像。`u-boot-env` 分区里全是 `0xFF`（Flash 擦除后的默认值），没有任何保存的环境变量。

U-Boot 读取 `u-boot-env` 分区，发现全是 `0xFF`，判断"没有保存过环境变量"，于是使用 `CONFIG_BOOTARGS` 默认值，其中包含 `vmalloc=512M`。

**真机的情况**：

真机的 Flash 里之前运行的是 AMI MegaRAC 固件。AMI 的 U-Boot 在某个时刻执行过 `saveenv`，把它自己的 bootargs 写入了 `u-boot-env` 分区。

我们烧录新固件时，烧录的是 `static.mtd` 镜像，这个镜像**不包含 `u-boot-env` 分区**（因为 `u-boot-env` 是运行时动态写入的，不在静态镜像里）。所以 Flash 里的 `u-boot-env` 分区保持原样，里面还是 AMI 时代保存的旧 bootargs，没有 `vmalloc=512M`。

```
真机 Flash 状态（烧录新固件后）：
┌─────────────────┐
│   u-boot        │  ← 新固件的 U-Boot（有 CONFIG_BOOTARGS 含 vmalloc=512M）
├─────────────────┤
│   u-boot-env    │  ← 旧 AMI 时代保存的 bootargs（没有 vmalloc=512M）★ 问题在这里
├─────────────────┤
│   kernel        │  ← 新固件的内核
├─────────────────┤
│   rootfs        │  ← 新固件的根文件系统
└─────────────────┘
```

U-Boot 启动，读取 `u-boot-env`，发现有保存的值，直接用旧 bootargs，`vmalloc=512M` 消失，Panic。

#### §9.12.4 三种修复思路的对比

遇到这类问题，有三种思路，各有优劣：

**思路1：擦除 Flash 里的旧环境变量**

在 U-Boot 命令行里执行：

```
env default -a    # 恢复所有环境变量为默认值
saveenv           # 把默认值写回 Flash
```

或者用 SPI 编程器直接擦除 `u-boot-env` 分区。

- 优点：干净彻底，Flash 里的旧值被清除
- 缺点：需要能进入 U-Boot 命令行（需要在倒计时时按任意键），或者需要 SPI 编程器；每次换新板子都要手动操作

**思路2：修改 U-Boot 配置，强制不从 Flash 读取环境变量**

在 U-Boot 配置里禁用 Flash 环境变量：

```
# 不推荐，会丢失 A/B bank 切换等功能
CONFIG_ENV_IS_NOWHERE=y
```

- 优点：彻底解决问题
- 缺点：U-Boot 的 A/B bank 切换、MAC 地址保存等功能依赖环境变量，禁用后这些功能全部失效

**思路3（我们采用的方案）：在内核侧追加参数**

在内核配置里加：

```
CONFIG_CMDLINE="vmalloc=512M"
CONFIG_CMDLINE_EXTEND=y
```

`CONFIG_CMDLINE_EXTEND` 的工作原理：内核启动时，先接收 U-Boot 传来的 bootargs，然后把 `CONFIG_CMDLINE` 里的内容**追加**到末尾。

```
U-Boot 传来：console=ttyS4,115200n8 root=/dev/ram rw
内核追加：   vmalloc=512M
最终结果：   console=ttyS4,115200n8 root=/dev/ram rw vmalloc=512M
```

- 优点：不依赖 U-Boot 环境变量，不需要手动操作，对所有板子都有效
- 缺点：如果 U-Boot 传来的 bootargs 里已经有 `vmalloc=XXX`，会出现两个 vmalloc 参数（内核取最后一个，所以不会出错，但不够干净）

对于我们的场景，思路3是最合适的：不需要手动操作每块板子，对新板子和旧板子都有效。

#### §9.12.5 如何验证修复是否生效

烧录新固件后，通过串口观察内核启动日志，找到这一行：

```
Kernel command line: console=ttyS4,115200n8 root=/dev/ram rw vmalloc=512M
```

如果 `vmalloc=512M` 出现在命令行里，修复生效。如果没有，说明 `CONFIG_CMDLINE_EXTEND` 没有编译进内核，需要检查 `.cfg` 文件是否被正确应用。

也可以在 BMC 启动后登录，执行：

```bash
cat /proc/cmdline
```

输出应该包含 `vmalloc=512M`。

#### §9.12.6 面试话术

> "我们在 evb-2u-egs 移植过程中遇到过一个典型的 QEMU 通过、真机失败的案例。根因是 U-Boot 环境变量的优先级机制：Flash 里保存的旧 bootargs 会覆盖编译时的 CONFIG_BOOTARGS 默认值。QEMU 使用全新 Flash 镜像所以没有这个问题，但真机 Flash 里有旧固件留下的环境变量。我们的修复方案是使用内核的 CONFIG_CMDLINE_EXTEND，在内核侧追加必要的参数，完全绕过 U-Boot 环境变量的影响，对所有板子都有效，不需要手动操作。"

> 💡 **大白话**：你给新员工发了一本操作手册（`CONFIG_BOOTARGS`），但这台机器之前的操作员在便利贴上写了自己的操作步骤，贴在机器上（Flash 里保存的旧环境变量）。新员工一来，先看到便利贴，就按便利贴操作了，根本没翻你的手册。解决办法：不要依赖手册，改成在机器的操作系统里写死一条规则（`CONFIG_CMDLINE_EXTEND`），不管便利贴写了什么，这条规则永远生效。

---

## §10. 真机调试实战：evb-2u-egs 第一次开机（2026-04-16）

本章记录 evb-2u-egs 真机首次成功启动 OpenBMC 后的调试过程，涵盖网络不通、传感器 probe 失败等典型问题的完整诊断和修复流程。

---

### §10.1 真机首次启动状态

烧录固件后，真机串口日志（`com20_3.log`）显示系统**成功启动**，无 Kernel Panic。核心服务全部正常：

```
[  OK  ] Started bmcweb server.
[  OK  ] Started Phosphor-Pid-Control Margin-based Fan Control Daemon.
[  OK  ] Started Entity Manager.
[  OK  ] Started Intel Power Control for the Host 0.
```

但存在以下问题需要修复：

| 问题 | 日志 | 严重程度 |
|------|------|---------|
| BMC 网口灯不亮，无法联网 | `ftgmac100 1e670000: Failed to connect to phy` | P1 |
| ADT7468 传感器 probe 失败 | `adt7475 7-002e: probe failed with error -110` | P1 |
| lm75@7-0048 超时 | `lm75 7-0048: probe failed with error -110` | P2 |
| Flash CS1 无法识别 | `spi-nor spi0.1: unrecognized JEDEC id bytes: 00 00 00 00 00 00` | P3 |

---

### §10.2 问题一：BMC 网口灯不亮

#### §10.2.1 诊断过程

**第一步：确认网络接口状态**

```bash
root@evb-2u-egs:~# ip link show
# 只有 eth0（NCSI 口），没有 eth1（RGMII 独立管理口）
# eth0 的 carrier=1 是 NCSI fixed PHY 的假链路，主机关机时无法通信

root@evb-2u-egs:~# ls /sys/bus/mdio_bus/devices/
fixed-0:00   # 只有 fixed PHY，没有真实 PHY
```

**第二步：确认 MDIO 总线上没有 PHY**

```bash
root@evb-2u-egs:~# for i in $(seq 0 7); do
    echo -n "PHY addr $i: "
    cat /sys/bus/mdio_bus/devices/1e650010.mdio-1\:0$i/phy_id 2>/dev/null || echo "not found"
done
# 全部 not found → PHY 不响应 MDIO
```

**第三步：尝试读取 PHY reset GPIO**

```bash
root@evb-2u-egs:~# gpioget gpiochip0 111
gpioget: error reading GPIO values: Device or resource busy
# GPIO 111 被 gpio-hog 占用，无法直接读取
```

**第四步：审查 DTS 中的 gpio-hog 配置**

```dts
/* 错误配置 */
phy-reset-hog {
    gpio-hog;
    gpios = <ASPEED_GPIO(N, 7) GPIO_ACTIVE_LOW>;
    output-high;   ← BUG：逻辑高 + 低电平有效 = 物理低 = PHY 复位！
    line-name = "RST_RGMII_PHYRST_N";
};
```

#### §10.2.2 根因分析：GPIO 极性陷阱

`GPIO_ACTIVE_LOW` 表示该信号**低电平有效**（active-low）。`output-high/low` 描述的是**逻辑电平**，不是物理电平。

| DTS 配置 | 逻辑电平 | 物理电平 | 效果 |
|---------|---------|---------|------|
| `GPIO_ACTIVE_LOW` + `output-high` | 逻辑高 | **物理低** | PHY 持续复位 ❌ |
| `GPIO_ACTIVE_LOW` + `output-low` | 逻辑低 | **物理高** | PHY 正常工作 ✅ |
| `GPIO_ACTIVE_HIGH` + `output-high` | 逻辑高 | 物理高 | PHY 正常工作 ✅ |
| `GPIO_ACTIVE_HIGH` + `output-low` | 逻辑低 | 物理低 | PHY 持续复位 ❌ |

**规律**：信号名带 `_N` 后缀（active-low）时，要让 PHY 正常工作（物理高电平），应该写 `output-low`。

#### §10.2.3 修复

```dts
/* 修复后 */
phy-reset-hog {
    gpio-hog;
    gpios = <ASPEED_GPIO(N, 7) GPIO_ACTIVE_LOW>;
    output-low;   ← 逻辑低 = 物理高 = PHY 正常工作
    line-name = "RST_RGMII_PHYRST_N";
};
```

#### §10.2.4 AST2600 MDIO/MAC 架构说明

AST2600 有 4 个 MAC（mac0-mac3）和 4 个独立 MDIO 控制器（mdio0-mdio3）。命名存在偏移：

| DTS 标签 | 硬件地址 | 对应 MDIO | 说明 |
|---------|---------|---------|------|
| `&mac0` | `1e660000` | mdio0 | 通常禁用 |
| `&mac1` | `1e680000` | mdio1 | 通常禁用 |
| `&mac2` | `1e670000` | mdio2 | **BMC 独立管理口（RGMII）** |
| `&mac3` | `1e690000` | mdio3 | **NCSI 共享口（RMII）** |

`ftgmac100` 驱动的 PHY 连接流程：
1. 检查 DTS 是否有 `use-ncsi` → 是则注册 fixed PHY，走 NCSI 路径
2. 检查 DTS 是否有 `phy-handle` → 是则通过 `of_phy_get_and_connect()` 连接外部 PHY
3. 外部 PHY 通过 MDIO 总线发现，PHY 必须处于非复位状态才能响应 MDIO 读写

#### §10.2.5 NCSI 协议说明

NCSI（Network Controller Sideband Interface）是一种让 BMC 通过主机 NIC 的 sideband 通道访问网络的协议。

```
主机 NIC ←→ NCSI 通道 ←→ BMC mac3
```

**主机关机时 NCSI 不可用的原因**：
- NCSI 通道由主机 NIC 的固件维护
- 主机关机时 NIC 固件停止运行，NCSI 通道消失
- BMC 的 `ftgmac100 eth0: NCSI: No channel found to configure!` 就是这个原因

**结论**：BMC 的管理 IP 应该配置在独立管理口（RGMII/eth1）上，不依赖主机状态。NCSI 口（eth0）可以作为备用或用于带内管理。

---

### §10.3 问题二：ADT7468 传感器 probe 失败（-110 超时）

#### §10.3.1 诊断过程

串口日志时序：

```
[  6.5s] adt7475 7-002e: Error configuring attenuator bypass
[  18.0s] adt7475 7-002e: ADT7475 device, revision 2   ← 11.5秒后才检测到
[  19.0s] adt7475 7-002e: probe with driver adt7475 failed with error -110
```

11.5 秒的间隔是 I2C 写操作超时的典型特征（多次重试）。

真机 `i2cdetect -y 7` 结果：

```
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:
20:                               UU
50: 50                   58
```

- `0x2d`（UU）= LM87，已被驱动占用，地址正确
- `0x2e` = **不存在**（adt7475 probe 失败后设备被释放）
- `0x50` = PSU FRU EEPROM（i2cdump 确认为 "GREAT WALL CRPS1600D"）
- `0x58` = PSU1 PMBus

#### §10.3.2 根因：compatible 字符串错误

硬件文档记录 bus7/0x2e 是 **ADT7468** 芯片。查看内核 `adt7475.c` 的 `detect()` 函数：

```c
devid = adt7475_read(REG_DEVID);
if (devid == 0x73)
    name = "adt7473";
else if (devid == 0x75 && client->addr == 0x2e)
    name = "adt7475";
else if (devid == 0x76)
    name = "adt7476";    ← ADT7468 的 devid = 0x76
else if ((devid2 & 0xfc) == 0x6c)
    name = "adt7490";
```

ADT7468 的 devid = 0x76，对应驱动中的 `adt7476`。DTS 中写 `adi,adt7475` 会让驱动用 adt7475 的 probe 路径，写 REG_CONFIG2 时芯片行为不同，导致 I2C 超时（-110）。

#### §10.3.3 如何通过 i2cdump 确认芯片型号

```bash
# 读取 ADT74xx 系列的关键寄存器
# REG_VENDID = 0x3E（Analog Devices = 0x41）
# REG_DEVID  = 0x3D（0x73=adt7473, 0x75=adt7475, 0x76=adt7476/ADT7468）
# REG_DEVID2 = 0x3F

i2cget -y 7 0x2e 0x3E   # Vendor ID，应为 0x41
i2cget -y 7 0x2e 0x3D   # Device ID，0x76 = ADT7468/ADT7476
i2cget -y 7 0x2e 0x3F   # Device ID2，低3位为 revision
```

#### §10.3.4 ADT74xx 系列寄存器差异

| 芯片 | devid | 主要差异 | DTS compatible |
|------|-------|---------|---------------|
| ADT7473 | 0x73 | 3通道温度，3路PWM | `adi,adt7473` |
| ADT7475 | 0x75 | 同上 + 电压监控 | `adi,adt7475` |
| ADT7476/ADT7468 | 0x76 | 同上 + in0/in4 电压 | `adi,adt7476` |
| ADT7490 | devid2[7:2]=0x6c | 最全功能版本 | `adi,adt7490` |

#### §10.3.5 修复

```dts
/* 修复前 */
adt7475@2e {
    compatible = "adi,adt7475";
    reg = <0x2e>;
};

/* 修复后 */
adt7468@2e {
    compatible = "adi,adt7476";   ← ADT7468 与 ADT7476 寄存器兼容
    reg = <0x2e>;
};
```

---

### §10.4 问题三：lm75@7-0048 地址不存在

真机 `i2cdetect -y 7` 确认 bus7 上 0x48 地址无设备。

根据硬件定义文档，`lm75@0x48` 实际在 **bus3 MUX 下游 CH1**（需要先切换 PCA9546 MUX 到 CH1 才能访问），不在 bus7 直连。DTS 中 bus7 直接配置 `lm75@48` 是错误的。

**修复**：删除 bus7 中的 `lm75@48` 节点。bus3 MUX 下游的 lm75 已在 `i2c3_mux0_ch1` 中正确配置。

---

### §10.5 真机调试方法论总结

#### §10.5.1 诊断工具链

```bash
# 1. 查看内核启动日志（最重要）
dmesg | grep -E "i2c|phy|eth|mac|ftgmac|adt|lm75|pmbus"

# 2. 确认 I2C 总线上的实际设备
i2cdetect -y <bus>
# UU = 被驱动占用（地址正确）
# 数字 = 设备存在，无驱动
# 空白 = 无设备

# 3. 读取设备寄存器（确认芯片型号）
i2cdump -y <bus> <addr> b
i2cget -y <bus> <addr> <reg>

# 4. 查看网络接口
ip link show
ls /sys/bus/mdio_bus/devices/

# 5. 查看 GPIO 状态
gpioinfo gpiochip0 | grep -v "unnamed"
# gpio-hog 占用的引脚会显示 "kernel" 标志
```

#### §10.5.2 串口日志时序分析

| 时序特征 | 含义 |
|---------|------|
| 设备检测到但 probe 失败，间隔 10+ 秒 | I2C 写操作超时（多次重试） |
| 设备立即 probe 失败（< 1秒） | 地址不存在或 compatible 不匹配 |
| `UU` 出现在 i2cdetect | 驱动已加载，设备正常 |
| `probe failed with error -110` | ETIMEDOUT，I2C 总线超时 |
| `probe failed with error -22` | EINVAL，参数错误（如 PHY 找不到） |
| `probe failed with error -6` | ENXIO，设备不存在 |

#### §10.5.3 GPIO hog 调试技巧

gpio-hog 占用的引脚无法用 `gpioget` 读取，但可以通过以下方式间接判断：

```bash
# 查看 gpio-hog 配置（内核启动时打印）
dmesg | grep "gpio-hog\|hog"

# 查看 GPIO 占用情况
gpioinfo gpiochip0 | grep "kernel"

# 通过外设行为推断（如 PHY 不响应 MDIO → PHY 在复位）
ls /sys/bus/mdio_bus/devices/
```

#### §10.5.4 面试话术

> "在 evb-2u-egs 真机调试中，我遇到过一个 GPIO 极性陷阱：DTS 中 PHY reset 信号配置了 `GPIO_ACTIVE_LOW` + `output-high`，看起来是'输出高电平'，但实际上 `GPIO_ACTIVE_LOW` 表示低电平有效，`output-high` 是逻辑高，对应的物理电平是低，导致 PHY 芯片持续处于复位状态，MDIO 总线上找不到任何 PHY，网口灯完全不亮。诊断过程是：串口日志看到 `Failed to connect to phy` → 扫描 MDIO 总线确认无 PHY → 尝试读取 GPIO 发现被 hog 占用 → 审查 DTS 发现极性配置错误。修复只需要把 `output-high` 改成 `output-low`。"

> 💡 **大白话**：信号名叫 `RST_PHYRST_N`，`_N` 说明低电平才是'复位'。你想让 PHY 工作，就要让引脚保持高电平。但 DTS 里写的是'逻辑高'，而这个引脚是'低电平有效'，逻辑高对应物理低，结果 PHY 一直被按着复位键。改成'逻辑低'，物理引脚就变成高电平，PHY 才能正常工作。

---

## §11. entity-manager 配置深度解析

本章以 evb-2u-egs 为例，系统讲解 entity-manager JSON 配置的工作机制、传感器类型映射、以及常见陷阱。

---

### §11.1 entity-manager 的角色

entity-manager 是 OpenBMC 的**系统配置管理器**，负责：
1. 读取 JSON 配置文件，发布到 D-Bus（`xyz.openbmc_project.Configuration.*` 接口）
2. 对于需要动态实例化的设备，写入 `/sys/bus/i2c/devices/i2c-$Bus/new_device` 来创建内核驱动
3. 作为 dbus-sensors 守护进程的配置源

```
JSON 文件 → entity-manager → D-Bus 配置接口
                                    ↓
                    hwmontempsensor / psusensor / adcsensor / intelcpusensor
                                    ↓
                    /xyz/openbmc_project/sensors/* (传感器值)
                                    ↓
                    Redfish / IPMI SDR / phosphor-pid-control
```

---

### §11.2 JSON 文件结构

```json
{
    "Name": "evb-2u-egs Baseboard",
    "Probe": "TRUE",
    "Type": "Board",
    "Exposes": [
        {
            "Type": "TMP75",
            "Name": "Inlet_Temp",
            "Bus": 21,
            "Address": "0x48",
            "Thresholds": [...]
        },
        ...
    ],
    "xyz.openbmc_project.Inventory.Decorator.Asset": {
        "Manufacturer": "",
        "Model": "EVB-2U-EGS-MB"
    }
}
```

**关键字段：**

| 字段 | 说明 |
|------|------|
| `Probe` | 触发条件。`"TRUE"` 表示始终加载；也可以是 D-Bus 路径或 FRU 匹配条件 |
| `Type`（顶层） | 板卡类型，通常为 `"Board"` |
| `Exposes` | 该板卡暴露的所有设备/传感器列表 |
| `Exposes[].Type` | 设备类型，决定由哪个 dbus-sensors 守护进程处理 |
| `Exposes[].Name` | 传感器名称，出现在 D-Bus 路径中 |
| `Exposes[].Bus` | I2C 总线号（对应 `/dev/i2c-N`） |
| `Exposes[].Address` | I2C 设备地址（十六进制字符串） |
| `Exposes[].Thresholds` | 告警阈值（upper/lower critical/non-critical） |

---

### §11.3 两种设备实例化路径

#### 路径1：DTS 已实例化 + dbus-sensors 读取（主流路径）

对于 DTS 中已配置的设备（如 `lm75@4d`, `adt7476@2e`），内核启动时已自动创建 hwmon 目录。dbus-sensors 守护进程扫描 D-Bus 上的 entity-manager 配置，找到匹配的 Bus/Address，读取 hwmon 文件。

```
DTS: lm75@4d → 内核驱动 → /sys/class/hwmon/hwmon2/temp1_input
JSON: {"Type": "TMP75", "Bus": 8, "Address": "0x4d"}
hwmontempsensor: 扫描 D-Bus → 找到 TMP75 配置 → 读取 hwmon 文件 → 发布到 D-Bus
```

#### 路径2：entity-manager 主动实例化（`devices.hpp` ExportTemplate）

对于 DTS 中**没有**配置的设备，entity-manager 通过写 `new_device` 来动态创建内核驱动。`devices.hpp` 中定义了支持的类型：

```cpp
// entity-manager/src/entity_manager/devices.hpp
constexpr auto exportTemplates = std::to_array<ExportTemplate>({
    {"PCA9546Mux", "pca9546 $Address", "/sys/bus/i2c/devices/i2c-$Bus",
     "new_device", "delete_device", createsHWMon::noHWMonDir},
    {"EEPROM", "eeprom $Address", "/sys/bus/i2c/devices/i2c-$Bus",
     "new_device", "delete_device", createsHWMon::noHWMonDir},
    // ... 约30种类型
});
```

**注意**：`ADT7475`, `LM87`, `TMP75`, `pmbus` **不在** `devices.hpp` 中，因为这些设备通过 DTS 实例化，不需要 entity-manager 动态创建。

---

### §11.4 dbus-sensors 守护进程与 Type 的对应关系

| JSON Type | 处理守护进程 | 说明 |
|-----------|------------|------|
| `TMP75`, `LM75A`, `TMP112`, `TMP421`, `MAX31725`, `EMC1412` 等 | `hwmontempsensor` | 通过 hwmon 读取温度 |
| `ADC` | `adcsensor` | 内部 ADC，通过 IIO 读取 |
| `pmbus` | `psusensor` | PMBus 电源传感器 |
| `XeonCPU` | `intelcpusensor` | PECI 接口 CPU 温度 |
| `Pid`, `Pid.Zone`, `Stepwise` | `phosphor-pid-control` | 风扇 PID 控制 |
| `PCA9546Mux`, `PCA9548Mux` | entity-manager 直接处理 | 写 new_device 实例化 |
| `EEPROM` | entity-manager 直接处理 | 写 new_device 实例化 |
| `AD5593R` | 无标准守护进程 | 需要自定义传感器读取 |

**重要陷阱**：`ADT7475` 和 `LM87` **不在** hwmontempsensor 的支持列表中！如果 JSON 中写 `"Type": "ADT7475"`，hwmontempsensor 会忽略它，传感器数据不会出现在 D-Bus 上。

**正确做法**：对于 DTS 中已实例化的 ADT7476/LM87，JSON 中应使用 `"Type": "TMP75"`，hwmontempsensor 会通过 Bus/Address 找到对应的 hwmon 目录并读取温度。

---

### §11.5 MUX 下游总线编号

evb-2u-egs DTS 中定义了 I2C 别名：

```dts
aliases {
    i2c20 = &i2c3_mux0_ch0; /* bus3 mux0x73 CH0: AD5593R sensors */
    i2c21 = &i2c3_mux0_ch1; /* bus3 mux0x73 CH1: LM75 inlet */
    i2c22 = &i2c3_mux0_ch2; /* bus3 mux0x73 CH2: MB LM75 in/out */
    i2c23 = &i2c0_mux0_ch0; /* bus0 mux0x73 CH0: front CPLD */
    ...
};
```

entity-manager JSON 中使用这些别名编号：

```json
{"Type": "TMP75", "Bus": 21, "Address": "0x48", "Name": "Inlet_Temp"}
// Bus 21 = i2c21 = bus3 MUX CH1 下游
```

**规律**：MUX 下游总线的编号 = DTS aliases 中定义的 i2cN 编号。

---

### §11.6 evb-2u-egs JSON 配置说明

当前 `evb-2u-egs-baseboard.json` 包含 37 个 Exposes：

| 类型 | 数量 | 说明 |
|------|------|------|
| `ADC` | 16 | 内部 ADC 通道（adc0/adc1 各8路） |
| `TMP75` | 7 | 温度传感器（含 LM87@0x2d 和 ADT7468@0x2e 用 TMP75 类型） |
| `pmbus` | 2 | PSU1/PSU2 PMBus |
| `XeonCPU` | 2 | CPU0/CPU1 PECI |
| `PCA9546Mux` | 2 | bus0 和 bus3 的 PCA9546 MUX |
| `PCA9548Mux` | 1 | bus3 的 PCA9548 NVMe MUX |
| `AD5593R` | 2 | 板级/VR 电压 ADC |
| `EEPROM` | 2 | MB FRU + MAC EEPROM |
| `Pid` + `Pid.Zone` + `Stepwise` | 3 | 风扇 PID 控制 |

**注意**：`SYS_Board_Temp`（bus7/0x48）已删除，真机 i2cdetect 确认该地址不存在。

---

### §11.7 传感器数据流验证

烧录新固件后，可以通过以下命令验证传感器是否正常工作：

```bash
# 查看 hwmon 设备
ls /sys/class/hwmon/

# 查看某个 hwmon 的温度
cat /sys/class/hwmon/hwmon*/temp1_input  # 单位：毫摄氏度

# 通过 D-Bus 查看传感器（需要 busctl）
busctl tree xyz.openbmc_project.HwmonTempSensor

# 查看具体传感器值
busctl get-property xyz.openbmc_project.HwmonTempSensor \
    /xyz/openbmc_project/sensors/temperature/Inlet_Temp \
    xyz.openbmc_project.Sensor.Value Value

# 查看所有温度传感器
busctl call xyz.openbmc_project.ObjectMapper \
    /xyz/openbmc_project/object_mapper \
    xyz.openbmc_project.ObjectMapper \
    GetSubTree sias / 0 1 xyz.openbmc_project.Sensor.Value
```

---

### §11.8 面试话术

> "entity-manager 在 OpenBMC 中扮演系统配置中心的角色。它读取 JSON 配置文件，把硬件拓扑发布到 D-Bus，然后各个 dbus-sensors 守护进程（hwmontempsensor、psusensor、adcsensor 等）订阅这些配置，找到对应的 hwmon 文件或 PECI 接口，把传感器值发布到 D-Bus 传感器树上。Redfish 和 IPMI SDR 再从传感器树读取数据。"

> "一个常见的陷阱是 JSON 中的 Type 字段。不是所有芯片型号都被 hwmontempsensor 支持——它只认识自己 sensorTypes 列表里的类型。比如 ADT7475 和 LM87 就不在列表里，如果 JSON 里写这些类型，传感器数据不会出现在 D-Bus 上。正确做法是用 TMP75 类型，hwmontempsensor 会通过 Bus/Address 找到对应的 hwmon 目录读取温度，不管底层芯片是什么型号。"

> 💡 **大白话**：entity-manager 就像一个'设备登记处'，你把所有硬件都登记在 JSON 里。各个传感器守护进程来登记处查询'我负责的设备有哪些'，然后去读取对应的硬件数据。但登记处只认识特定的设备类型——如果你登记了一个它不认识的类型，它就当没看见。所以要用它认识的类型名（TMP75）来登记，即使底层芯片是 ADT7468。

---

## §12. 网络口不通的完整调试过程（evb-2u-egs 真实案例）

本章记录 evb-2u-egs 网络口调试的完整过程，包括三次错误假设和最终正确答案。这是一个典型的"参考原厂代码"解决问题的案例。

---

### §12.1 问题现象

真机烧录 OpenBMC 后，BMC 网口灯完全不亮，无法通过网络访问 BMC。

串口日志显示：
```
[    1.124090] mdio_bus 1e650010.mdio-1: MDIO device at address 0 is missing.
[    1.141400] ftgmac100 1e670000.ethernet: Failed to connect to phy
[    1.148305] ftgmac100 1e670000.ethernet: probe with driver ftgmac100 failed with error -22
```

> 💡 **大白话**：BMC 有一个专用的网口（RGMII 管理口），用来让运维人员远程管理服务器。这个网口不亮，说明 BMC 根本没有找到网口芯片（PHY），就像插了网线但网卡没有驱动一样。

---

### §12.2 第一次假设：PHY 被锁在复位状态

**假设**：DTS 中 `phy-reset-hog` 配置了 `GPIO_ACTIVE_LOW` + `output-high`，导致 PHY 持续复位。

**验证**：
```bash
cat /sys/kernel/debug/gpio | grep -A2 "RST_RGMII"
# 输出：gpio-111 (RST_RGMII_PHYRST_N) out hi ACTIVE LOW
```

**结果**：`out hi` 说明 GPIO 111 物理高电平，PHY **不在复位状态**。假设错误。

但 `output-high` + `GPIO_ACTIVE_LOW` 的逻辑确实有问题（逻辑高 = 物理低），所以仍然修复了极性（改为 `output-low`），使逻辑更清晰。

> 💡 **大白话**：我们以为是"复位按钮一直被按着"，但检查发现按钮其实是松开的。PHY 没有被复位，但还是找不到。

---

### §12.3 第二次假设：PHY 不存在

**假设**：MDIO 总线 0-31 全部无响应，可能这块板子没有焊接外部 PHY。

**验证**：用户明确告知这是真机，有独立 RGMII 管理口。假设错误。

> 💡 **大白话**：我们以为是"网卡芯片没有焊接"，但用户说这是真机，肯定有网卡。

---

### §12.4 第三次假设（正确）：用了错误的 MAC/MDIO

**关键突破**：查看 AMI 原厂 DTS（`ast2600evb_r1b.dts`）：

```dts
/* AMI 原厂配置 */
&mdio1 { status = "okay"; ethphy1@0 { ... }; };  /* RGMII PHY 在 mdio1 */
&mac1 { status = "okay"; phy-mode = "rgmii-rxid"; phy-handle = <&ethphy1>; };  /* RGMII 管理口 */
&mac2 { status = "okay"; phy-mode = "rmii"; use-ncsi; };  /* NCSI 口 */
```

**我们的错误配置**：
```dts
/* 我们的错误配置 */
&mdio2 { status = "okay"; ethphy1@0 { ... }; };  /* 错！PHY 不在 mdio2 */
&mac2 { status = "okay"; phy-mode = "rgmii-rxid"; };  /* 错！RGMII 不是 mac2 */
&mac3 { status = "okay"; use-ncsi; };  /* 错！NCSI 不是 mac3 */
```

**AST2600 MAC/MDIO 对应关系（evb-2u-egs 实际使用）：**

| DTS 标签 | 硬件地址 | 功能 | 状态 |
|---------|---------|------|------|
| `&mac0` | 1e660000 | 未使用 | disabled |
| **`&mac1`** | **1e680000** | **RGMII 独立管理口（外部 PHY）** | **okay** |
| **`&mac2`** | **1e670000** | **RMII + NCSI（共享管理网）** | **okay** |
| `&mac3` | 1e690000 | 未使用 | disabled |
| `&mdio0` | 1e650000 | 未使用 | disabled |
| **`&mdio1`** | **1e650008** | **RGMII PHY 所在总线** | **okay** |
| `&mdio2` | 1e650010 | 未使用（释放 M24 引脚） | disabled |
| `&mdio3` | 1e650018 | 未使用 | disabled |

> 💡 **大白话**：AST2600 有 4 个网口控制器（mac0-mac3）和 4 个 MDIO 总线（mdio0-mdio3）。我们一直在用 mac2+mdio2，但实际上这台机器的独立管理口接在 mac1+mdio1 上。就像你家有 4 个网口，你一直在插第 3 个口，但网线其实接在第 2 个口上。

---

### §12.5 修复方案

```dts
/* 修复后的网络配置 */
&mdio1 {
    status = "okay";
    ethphy1: ethernet-phy@0 {
        compatible = "ethernet-phy-ieee802.3-c22";
        reg = <0>;
    };
};

/* mac1: RGMII 独立管理口（BMC 专用，不依赖主机） */
&mac1 {
    status = "okay";
    phy-mode = "rgmii-rxid";
    phy-handle = <&ethphy1>;
    pinctrl-names = "default";
    pinctrl-0 = <&pinctrl_rgmii2_default>;
};

/* mac2: RMII + NCSI（通过主机 NIC 的 sideband 通道） */
&mac2 {
    status = "okay";
    phy-mode = "rmii";
    use-ncsi;
    pinctrl-names = "default";
    pinctrl-0 = <&pinctrl_rmii3_default>;
};
```

**额外收益**：mdio2 不再使用，释放了 M24 引脚，i2c10（后置 CPLD）可以重新启用。

---

### §12.6 如何避免这类错误

**核心方法：遇到硬件相关问题，先查原厂代码。**

```bash
# 在 AMI 源码中找 DTS
find /home/dev/openbmc-workspace/AMI_bmc_code/ -name "*.dts" | xargs grep -l "mac\|mdio\|phy"

# 对比原厂 MAC/MDIO 配置
grep -n "mac\|mdio\|phy\|rgmii\|rmii\|ncsi" \
    /home/dev/openbmc-workspace/AMI_bmc_code/src/core/Kernel_5_Config-ARM-AST2600-AST2600EVB-src/data/ast2600evb_r1b.dts
```

**AST2600 MAC 命名规律**：

AST2600 的 MAC 编号在不同文档中有不同叫法，容易混淆：

| 文档/代码 | 叫法 | 硬件地址 |
|---------|------|---------|
| 硬件手册 | MAC1, MAC2, MAC3, MAC4 | 1e660000, 1e680000, 1e670000, 1e690000 |
| Linux DTS | mac0, mac1, mac2, mac3 | 同上（从0开始） |
| AMI 代码 | MAC0, MAC1, MAC2, MAC3 | 同上 |

**注意**：硬件手册的 MAC1 = Linux DTS 的 mac0，以此类推。**不要混用不同来源的编号**。

---

### §12.7 面试话术

> "在 evb-2u-egs 移植中，我遇到过一个 BMC 网口完全不通的问题。调试过程经历了三个阶段：第一，怀疑 PHY 被 GPIO 锁在复位状态，通过 `/sys/kernel/debug/gpio` 确认 GPIO 是高电平，排除；第二，怀疑 PHY 芯片没有焊接，被用户否定；第三，通过对比 AMI 原厂 DTS 发现，我们用的是错误的 MAC/MDIO 组合——独立管理口是 mac1+mdio1，而我们配置的是 mac2+mdio2。修复后不仅网口通了，还顺带解决了 i2c10 的引脚冲突问题。"

> 💡 **大白话**：这个问题的教训是——遇到硬件不通的问题，不要只靠猜，要去找原厂代码对比。原厂工程师已经把正确答案写在 DTS 里了，直接抄就行。我们花了很多时间猜测，最后发现答案就在 AMI 代码里，5分钟就能找到。
