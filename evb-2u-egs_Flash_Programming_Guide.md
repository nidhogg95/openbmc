# evb-2u-egs 实机烧录与调试操作指南

> **平台**：evb-2u-egs（Intel EGS 双路 + AST2600 A1，2U 机架服务器）
> **Flash**：2× w25q512jv（各 64MB），FMC CS0（Bank A 主用）+ CS1（Bank B 备用），Quad SPI 50MHz
> **固件**：OpenBMC（Yocto whinlatter，distro openbmc-phosphor/styhead）
> **构建产物**：`build/evb-2u-egs/tmp/deploy/images/evb-2u-egs/`

---

## 目录

- [§1 串口连接设置](#1-串口连接设置)
- [§2 Flash 分区布局](#2-flash-分区布局)
- [§3 U-Boot defconfig 决策](#3-u-boot-defconfig-决策)
- [§4 初次烧录方法](#4-初次烧录方法)
- [§5 首次启动验证清单](#5-首次启动验证清单)
- [§6 运行时固件更新](#6-运行时固件更新)
- [§7 双 Flash A/B Bank 策略](#7-双-flash-ab-bank-策略)
- [§8 实机常见故障排查](#8-实机常见故障排查)

---

## §1 串口连接设置

### 1.1 UART 映射总表

| Linux 设备 | 硬件 UART | 功能 | 波特率 | 用途 |
|-----------|----------|------|--------|------|
| `/dev/ttyS4` | UART5 | **BMC 调试控制台** | 115200 8N1 | U-Boot + kernel + shell 输出 |
| `/dev/ttyS3` | UART4 | **SOL（Serial over LAN）** | 115200 8N1 | IPMI SOL 访问主机串口 |
| `/dev/ttyS2` | UART3 | 共享主机串口 | 115200 8N1 | Host 与 BMC 共享的串口通道 |
| `/dev/ttyS0` | UART1 | Host 串口（QEMU 用） | 115200 8N1 | QEMU 环境下的 Host 侧 |

### 1.2 配置文件依据链

串口配置从 4 个层级一致指向 ttyS4：

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

### 1.3 硬件接线步骤

**你需要的硬件**：
- USB-to-UART 转换器（推荐 FTDI FT232R 或 CP2102）
- 杜邦线 3 根（TX、RX、GND）

**接线方式**：

```
USB-UART 转换器          EVB 板上 UART5 排针
  TX  ───────────────→  RX
  RX  ←───────────────  TX
  GND ────────────────── GND
```

> **注意**：TX/RX 交叉连接。如果没有输出，先尝试交换 TX 和 RX。

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

### 1.4 确认排针位置

串口排针的物理位置需要查看 EVB 板的丝印标注或原理图。通常 AST2600 EVB 板上会标注：
- `J_UART5` 或 `BMC_CONSOLE` — 这是你要接的 BMC 调试口
- `J_UART4` 或 `SOL` — 这是 SOL 口
- 某些板子直接提供 micro-USB 调试口（板载 FTDI/CP2102 芯片），此时直接插 USB 线即可

---

## §2 Flash 分区布局

### 2.1 OpenBMC 64MB 静态分区布局

我们的固件使用 `mtd-static` 布局（固定偏移），定义在 `meta-phosphor/classes/image_types_phosphor.bbclass`。

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

### 2.2 分区偏移量来源

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

### 2.3 U-Boot 环境变量区配置

```
# U-Boot 编译期配置 (u-boot_flash_64M.cfg):
CONFIG_ENV_SIZE=0x20000        # 128KB
CONFIG_ENV_OFFSET=0xE0000      # 偏移 896KB

# Linux 下 fw_printenv/fw_setenv 配置 (fw_env.config):
/dev/mtd/u-boot-env    0x00000    0x10000    # 主环境，前64KB
/dev/mtd/u-boot-env    0x10000    0x10000    # 冗余副本，后64KB
```

### 2.4 static.mtd 镜像拼装过程

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

最终产物：`obmc-phosphor-image-evb-2u-egs.static.mtd`（精确 64MB = 67,108,864 字节）

### 2.5 双 Flash 物理映射

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

---

## §3 U-Boot defconfig 决策

### 3.1 问题背景

当前 `machine.conf` 配置：

```
UBOOT_MACHINE = "ast2600_openbmc_spl_defconfig"
SPL_BINARY = "spl/u-boot-spl.bin"
```

这个 SPL defconfig 是为 QEMU 环境优化的，**在真实硬件上也应该能正常工作**，原因如下：

### 3.2 关键分析

**U-Boot SPL 阶段**：
- SPL 的串口输出由 defconfig 中的 `CONFIG_CONS_INDEX` 决定
- AST2600 SPL defconfig 默认使用 UART5（uart5），与我们的硬件一致
- SPL 阶段的输出很短（几行初始化信息），即使看不到也不影响启动

**U-Boot proper 阶段**：
- U-Boot proper 启动后，会读取环境变量
- 环境变量 `bootargs=console=ttyS4,115200n8` 已经正确指向 UART5
- U-Boot 的 stdout/stderr 由设备树 `chosen { stdout-path = &uart5; }` 控制

**Linux 内核阶段**：
- 完全由 DTS 的 `bootargs` 和 `stdout-path` 控制
- 已正确配置为 `ttyS4@115200`

### 3.3 结论：当前 defconfig 可直接用于真机

**不需要更换 defconfig。** 当前的 `ast2600_openbmc_spl_defconfig` + 我们的 U-Boot env + DTS 配置已经完整覆盖了：
- SPL → UART5
- U-Boot → UART5
- Linux → ttyS4 (UART5)

### 3.4 如果确实没有串口输出的备选方案

如果刷入后在 UART5 上完全没有输出，可以尝试以下排查顺序：

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

## §4 初次烧录方法

### 4.1 准备工作

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

### 4.2 方法 A：SPI 编程器直刷（推荐首次使用）

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
> - **必须完全断电**再操作编程器，否则可能损坏 Flash 或编程器
> - **先备份原始固件**，以便随时回退到 AMI
> - CH341A 是 3.3V 供电，与 w25q512jv 兼容；如果用 5V 编程器需要电平转换
> - w25q512jv 是 64MB 超大容量 Flash，确保编程器支持（某些老旧的 CH341A 固件不支持 >16MB）

### 4.3 方法 B：U-Boot TFTP 恢复（板上已有可用 U-Boot 时）

如果板上已有一个能启动的 U-Boot（例如 AMI 的或者之前刷过的 OpenBMC），可以通过网络刷写：

**前提条件**：
- 板上有可用的 U-Boot（能看到 `ast#` 提示符）
- BMC 网口已连接网络
- 局域网内有 TFTP 服务器

**操作步骤**：

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

### 4.4 方法 C：UART Xmodem 恢复（最后手段）

当 Flash 完全为空或损坏、没有 SPI 编程器时：

**原理**：AST2600 ROM Bootloader 在检测不到有效 SPI Flash 镜像时，会进入 UART 恢复模式，通过 xmodem 协议从串口接收 SPL。

**操作步骤**：

```bash
# === 步骤1：确保 Flash 为空或损坏 ===
# （已经是这种状态才会用这个方法）

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

### 4.5 方法对比

| 方法 | 速度 | 需要 | 适用场景 |
|------|------|------|----------|
| A: SPI 编程器 | 快（5-10分钟） | SPI 编程器 + 测试夹 | **首次烧录（推荐）**、完全 brick |
| B: U-Boot TFTP | 中（3-5分钟） | 可用的 U-Boot + 网络 | 已有 U-Boot 时升级 |
| C: UART Xmodem | 极慢（30+分钟） | 仅串口线 | 紧急恢复、无编程器 |

---

## §5 首次启动验证清单

### 5.1 串口观察：启动阶段输出

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

### 5.2 分阶段检查清单

**✅ 阶段 A：上电后 5 秒内**

| 检查项 | 期望结果 | 异常处理 |
|--------|---------|---------|
| 串口有任何输出 | 看到 "U-Boot SPL" 文字 | → §8.1 无串口输出 |
| SPL 找到 Flash | "Trying to boot from SPI" | → §8.2 SPL 启动失败 |
| U-Boot 找到 DRAM | "DRAM: 1 GiB" | → §8.3 内存初始化失败 |

**✅ 阶段 B：U-Boot 倒计时**

| 检查项 | 期望结果 | 异常处理 |
|--------|---------|---------|
| 看到 `ast#` 或 bootdelay | "Hit any key to stop autoboot: 2" | → §8.4 U-Boot 挂起 |
| 能按键中断进 U-Boot | 按回车后出现 `ast#` | 正常 |

**✅ 阶段 C：内核启动**

| 检查项 | 期望结果 | 异常处理 |
|--------|---------|---------|
| FIT Image 加载成功 | "## Loading kernel from FIT Image" | → §8.5 FIT 加载失败 |
| DTB 正确 | "Machine model: EVB-2U-EGS BMC" | → §8.6 DTB 不匹配 |
| MTD 分区创建 | 看到 mtd0~mtd5 分区列表 | → §8.7 MTD 分区异常 |
| 无 kernel panic | 不出现 "Kernel panic" | → §8.8 内核崩溃 |

**✅ 阶段 D：系统就绪**

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

### 5.3 网络配置（静态 IP）

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

### 5.4 远程访问验证

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

## §6 运行时固件更新

当 BMC 已经在运行 OpenBMC 时，可以通过以下方式更新固件。

### 6.1 方法 A：Redfish 固件更新（推荐）

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

### 6.2 方法 B：SCP + 手动 flashcp（开发阶段快速更新）

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

### 6.3 方法 C：BMCWeb WebUI 更新

1. 浏览器打开 `https://<BMC_IP>/`
2. 登录 → Operations → Firmware → Update firmware
3. 选择 `.all.tar` 文件上传
4. 等待上传和验证完成
5. 点击 "Activate" 激活
6. 点击 "Reboot BMC"

### 6.4 更新后验证

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

## §7 双 Flash A/B Bank 策略

### 7.1 架构概述

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

### 7.2 U-Boot A/B 启动逻辑

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

### 7.3 手动切换 Bank

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

### 7.4 初次部署：两个 Bank 都烧入

**建议首次部署时两个 Flash 都烧入相同固件**，这样可以确保：
- 即使 Bank A 损坏，U-Boot 会自动尝试 Bank B
- 运行时更新可以先写 Bank B 再切换

### 7.5 生产环境更新流程

```
1. BMC 从 Bank A 正常运行
2. 收到新固件，写入 Bank B
3. fw_setenv bootside b
4. reboot → 从 Bank B 启动
5. 验证新固件正常
6. 如果异常：fw_setenv bootside a && reboot → 回退到 Bank A
7. 如果正常：将新固件也写入 Bank A 作为双备份
```

### 7.6 恢复出厂设置

```bash
# 擦除 rwfs 分区（清除所有持久化数据：密码、网络配置、日志）
fw_setenv openbmconce copy-files-to-ram copy-base-filesystem-to-ram
fw_setenv rwreset true
reboot
# initramfs 会检测 rwreset=true 并格式化 rwfs
```

---

## §8 实机常见故障排查

### §8.1 上电后串口完全没有输出

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

### §8.2 SPL 启动失败

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

### §8.3 内核启动后 Kernel Panic

**常见 panic 类型**：

```
# 类型1: "VFS: Unable to mount root fs"
# 原因: rootfs 分区未正确写入或 mtdparts 不匹配
# 解决: 确认 static.mtd 完整烧入，fw_printenv 检查 bootargs

# 类型2: "Unable to handle kernel paging request"
# 原因: 可能是 CONFIG_VMSPLIT 设置问题
# 解决: 确认 evb-2u-egs.cfg 中没有 CONFIG_VMSPLIT_3G_OPT=y
#       （我们在 QEMU 调试阶段已经移除了这个选项）

# 类型3: "Kernel panic - not syncing: Attempted to kill init!"
# 原因: systemd/init 启动失败
# 解决: 检查 rootfs 是否完整，尝试单独挂载 squashfs 验证
```

### §8.4 网络不通

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

### §8.5 BMCWeb 无法访问

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

### §8.6 I2C 设备不可见

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

### §8.7 传感器读数异常

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

### §8.8 紧急恢复流程

当 BMC 完全无法启动时：

```
1. 断电
2. 用 SPI 编程器连接 Flash CS0
3. 读取当前 Flash 内容保存（用于分析）
4. 写入已知正常的 static.mtd 镜像
5. 断开编程器
6. 上电，观察串口
7. 如果 CS0 的 Flash 芯片物理损坏：
   - 切到 CS1 (Bank B) 启动
   - 或者更换 Flash 芯片
```

---

## 附录 A：命令速查卡

```bash
# === 构建 ===
cd /home/dev/openbmc-workspace/openbmc
. setup evb-2u-egs                           # 首次配置
. openbmc-env                                 # 恢复已有环境
bitbake obmc-phosphor-image                   # 构建完整固件

# === 镜像文件 ===
ls build/evb-2u-egs/tmp/deploy/images/evb-2u-egs/*.static.mtd    # 完整Flash镜像
ls build/evb-2u-egs/tmp/deploy/images/evb-2u-egs/*.all.tar       # Redfish更新包

# === 串口 ===
sudo picocom -b 115200 /dev/ttyUSB0          # 连接BMC console

# === 编程器 (CH341A) ===
sudo flashrom -p ch341a_spi -r backup.bin    # 备份
sudo flashrom -p ch341a_spi -w image.mtd     # 写入

# === BMC 在线操作 ===
fw_printenv                                   # 查看U-Boot环境
fw_setenv bootside b                          # 切换启动bank
cat /proc/mtd                                 # 查看Flash分区
i2cdetect -y 7                                # 扫描I2C总线

# === 远程访问 ===
ssh root@<IP>                                 # SSH (密码: 0penBmc)
curl -k -u root:0penBmc https://<IP>/redfish/v1/   # Redfish
ipmitool -I lanplus -H <IP> -U root -P 0penBmc mc info   # IPMI
```

## 附录 B：需要重新构建的场景

| 修改内容 | 重新构建命令 |
|---------|------------|
| 改 DTS | `bitbake -c clean linux-aspeed && bitbake obmc-phosphor-image` |
| 改 U-Boot defconfig | `bitbake -c clean u-boot-aspeed-sdk && bitbake obmc-phosphor-image` |
| 改 machine.conf | `bitbake obmc-phosphor-image` （通常自动检测到变化） |
| 改 entity-manager JSON | `bitbake -c clean entity-manager && bitbake obmc-phosphor-image` |
| 改 phosphor-pid-control JSON | `bitbake -c clean phosphor-pid-control && bitbake obmc-phosphor-image` |
| 改 packagegroup | `bitbake obmc-phosphor-image` |
| 全部重建 | `bitbake -c clean obmc-phosphor-image && bitbake obmc-phosphor-image` |

> **提醒**：所有 bitbake 命令请在已执行 `. setup evb-2u-egs` 或 `. openbmc-env` 的终端中运行。
