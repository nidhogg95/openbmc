# evb-2u-egs BMC OEM IPMI 命令规范

> **来源文档**：V3R4 BMC OEM 命令规范（2023-12-19）
> **适用平台**：evb-2u-egs 服务器，原厂 BMC 固件框架
> **版本**：V0.1 初稿
> **NetFn**：所有OEM命令统一使用 **0x2E**

---

## 目录

1. [OEM命令汇总表](#oem命令汇总表)
2. [命令详细说明（3.1–3.78）](#命令详细说明)
3. [统计信息](#统计信息)

---

## OEM命令汇总表

> 按功能类别分组排列。

### 风扇（Fan）

| # | 命令名称 | NetFn | CMD | 权限 | 类别 |
|---|----------|-------|-----|------|------|
| 3.1 | 设置风扇PWM | 0x2E | 0x30 | Admin | Fan |
| 3.2 | 查询风扇PWM | 0x2E | 0x31 | User | Fan |
| 3.8 | 设置风扇资产信息 | 0x2E | 0x2E | Admin | Fan |
| 3.9 | 获取风扇资产信息 | 0x2E | 0x2F | Admin | Fan |

### 密码/安全（Password/Security）

| # | 命令名称 | NetFn | CMD | 权限 | 类别 |
|---|----------|-------|-----|------|------|
| 3.3 | 设置密码有效期信息 | 0x2E | 0x03 | Admin | Password/Security |
| 3.4 | 获取密码有效期信息 | 0x2E | 0x04 | Operator | Password/Security |
| 3.36 | 设置密码复杂度 | 0x2E | 0xA7 | Admin | Password/Security |
| 3.37 | 查询密码复杂度 | 0x2E | 0xA6 | Admin | Password/Security |
| 3.68 | 设置密码安全 | 0x2E | 0x11 | Admin | Password/Security |
| 3.69 | 获取密码安全 | 0x2E | 0x12 | Admin | Password/Security |
| 3.70 | 检查密码 | 0x2E | 0xF8 | Admin | Password/Security |

### 串口/SOL（SOL/Serial）

| # | 命令名称 | NetFn | CMD | 权限 | 类别 |
|---|----------|-------|-----|------|------|
| 3.5 | 串口共享控制 | 0x2E | 0x38 | User | SOL/Serial |
| 3.6 | 获取串口共享状态 | 0x2E | 0x37 | User | SOL/Serial |
| 3.61 | SOL切换输出串口 | 0x2E | 0xAF | Admin | SOL/Serial |

### 传感器（Sensor）

| # | 命令名称 | NetFn | CMD | 权限 | 类别 |
|---|----------|-------|-----|------|------|
| 3.7 | 设置Sensor Scanning状态 | 0x2E | 0x10 | Admin | Sensor |

### 网络/SNMP（Network/SNMP）

| # | 命令名称 | NetFn | CMD | 权限 | 类别 |
|---|----------|-------|-----|------|------|
| 3.10 | 设置SNMP团体名信息 | 0x2E | 0x3D | Admin | Network/SNMP |
| 3.11 | 读取SNMP团体名信息 | 0x2E | 0x3F | Admin | Network/SNMP |
| 3.14 | 设置NTP时间同步周期 | 0x2E | 0x90 | Admin | Network/SNMP |
| 3.15 | 获取NTP时间同步周期 | 0x2E | 0x91 | Admin | Network/SNMP |
| 3.16 | 获取网络连接状态 | 0x2E | 0x92 | Admin | Network/SNMP |
| 3.22 | 获取所有网卡mac地址 | 0x2E | 0x9B | Admin | Network/SNMP |
| 3.23 | 设置SNMP端口号信息 | 0x2E | 0x49 | Admin | Network/SNMP |
| 3.24 | 读取SNMP端口号信息 | 0x2E | 0x44 | Admin | Network/SNMP |
| 3.53 | 设置防火墙 | 0x2E | 0x3C | Admin | Network/SNMP |
| 3.71 | 设置SNMP trap告警等级、上报标识、trap端口号 | 0x2E | 0x45 | Admin | Network/SNMP |
| 3.72 | 获取SNMP trap告警等级、上报标识、trap端口号 | 0x2E | 0x46 | Admin | Network/SNMP |
| 3.73 | 设置SNMPV1\V2c版本使能状态 | 0x2E | 0x47 | Admin | Network/SNMP |
| 3.74 | 读取SNMPV1\V2c版本使能状态 | 0x2E | 0x48 | Admin | Network/SNMP |
| 3.75 | 设置SNMP团体名复杂度 | 0x2E | 0xB5 | Admin | Network/SNMP |
| 3.76 | 读取SNMP团体名复杂度 | 0x2E | 0xB6 | Admin | Network/SNMP |

### 电源/功耗（Power）

| # | 命令名称 | NetFn | CMD | 权限 | 类别 |
|---|----------|-------|-----|------|------|
| 3.12 | 设置poweron delay参数 | 0x2E | 0x32 | Admin | Power |
| 3.13 | 获取poweron delay参数 | 0x2E | 0x33 | Admin | Power |
| 3.21 | 配置vrm极限性能模式 | 0x2E | 0x9A | Admin | Power |
| 3.27 | 设置功耗封顶修正值 | 0x2E | 0x62 | Admin | Power |
| 3.28 | 获取功耗封顶修正值 | 0x2E | 0x63 | Admin | Power |
| 3.32 | 获取功耗封顶策略 | 0x2E | 0xC2 | Admin | Power |
| 3.33 | 设置功耗封顶最大值 | 0x2E | 0xC1 | Admin | Power |
| 3.42 | 获取电源状态信息 | 0x2E | 0x20 | Admin | Power |
| 3.43 | 获取电源基本信息 | 0x2E | 0x21 | Admin | Power |
| 3.44 | 获取电源当前功率 | 0x2E | 0x22 | Admin | Power |
| 3.48 | 获取功耗统计数据 | 0x2E | 0x13 | Admin | Power |
| 3.49 | 清除功耗统计数据 | 0x2E | 0x14 | Admin | Power |
| 3.55 | 锁定电源物理按键 | 0x2E | 0xB8 | Admin | Power |

### PSU

| # | 命令名称 | NetFn | CMD | 权限 | 类别 |
|---|----------|-------|-----|------|------|
| 3.50 | 设置PSU自动模式 | 0x2E | 0x9D | Admin | PSU |
| 3.51 | 设置PSU自动模式的阈值 | 0x2E | 0x9E | Admin | PSU |
| 3.52 | 获取PSU自动模式 | 0x2E | 0x9F | Admin | PSU |
| 3.58 | 获取PSU最大功率 | 0x2E | 0xA8 | Admin | PSU |
| 3.59 | 获取BBU告警开关 | 0x2E | 0xA2 | Admin | PSU |
| 3.60 | 设置BBU告警开关 | 0x2E | 0xA3 | Admin | PSU |
| 3.66 | 设置PSU配置 | 0x2E | 0x3A | Admin | PSU |
| 3.67 | 获取PSU配置 | 0x2E | 0x3B | Admin | PSU |

### 固件（Firmware）

| # | 命令名称 | NetFn | CMD | 权限 | 类别 |
|---|----------|-------|-----|------|------|
| 3.17 | 获取BMC发布时间 | 0x2E | 0x95 | Admin | Firmware |
| 3.25 | 获取用户选择运行的flash的标记位 | 0x2E | 0x60 | Admin | Firmware |
| 3.26 | 用户设置默认启动的flash | 0x2E | 0x61 | Admin | Firmware |
| 3.29 | 获取当前机器BMC flash个数 | 0x2E | 0x64 | Admin | Firmware |

### 日志（Log）

| # | 命令名称 | NetFn | CMD | 权限 | 类别 |
|---|----------|-------|-----|------|------|
| 3.18 | 清除审计日志 | 0x2E | 0x97 | Admin | Log |
| 3.19 | 压缩BMC后台程序相关日志文件 | 0x2E | 0x98 | Admin | Log |
| 3.20 | 导出BMC后台程序相关日志文件 | 0x2E | 0x99 | Admin | Log |
| 3.34 | 获取Syslog配置信息 | 0x2E | 0xAC | Admin | Log |
| 3.35 | 修改syslog配置信息 | 0x2E | 0xAB | Admin | Log |
| 3.54 | 触发bmc打包后台配置与日志 | 0x2E | 0xA4 | Admin | Log |

### 系统（System）

| # | 命令名称 | NetFn | CMD | 权限 | 类别 |
|---|----------|-------|-----|------|------|
| 3.30 | 获取当前机器CPLD信息 | 0x2E | 0x65 | Admin | System |
| 3.38 | 设置USB0使能 | 0x2E | 0x15 | Admin | System |
| 3.39 | 查询USB0使能 | 0x2E | 0x16 | Admin | System |
| 3.40 | 设置OCP热插拔 | 0x2E | 0xA1 | Admin | System |
| 3.41 | 查询OCP上电状态 | 0x2E | 0xA0 | Admin | System |
| 3.62 | 获取inventory相关信息 | 0x2E | 0xB0 | Admin | System |
| 3.65 | 删除Redis数据库里的inventory CRC数据 | 0x2E | 0xAA | Admin | System |

### 存储（Storage）

| # | 命令名称 | NetFn | CMD | 权限 | 类别 |
|---|----------|-------|-----|------|------|
| 3.63 | 设置板载硬盘的点灯状态 | 0x2E | 0xF6 | Admin | Storage |
| 3.64 | 获取板载硬盘的点灯状态 | 0x2E | 0xF7 | Admin | Storage |

### 液冷（Liquid Cooling）

| # | 命令名称 | NetFn | CMD | 权限 | 类别 |
|---|----------|-------|-----|------|------|
| 3.45 | 获取液冷机型信息 | 0x2E | 0xB2 | Admin | Liquid Cooling |
| 3.46 | 设置液冷机型漏液检测策略（告警动作） | 0x2E | 0xB3 | Admin | Liquid Cooling |
| 3.47 | 设置液冷机型漏液检测策略（持续检测时间） | 0x2E | 0xB4 | Admin | Liquid Cooling |

### DPU

| # | 命令名称 | NetFn | CMD | 权限 | 类别 |
|---|----------|-------|-----|------|------|
| 3.56 | DPU单独上下电 | 0x2E | 0xB9 | Admin | DPU |
| 3.57 | DPU协同下电命令 | 0x2E | 0xBA | Admin | DPU |

### BIOS

| # | 命令名称 | NetFn | CMD | 权限 | 类别 |
|---|----------|-------|-----|------|------|
| 3.31 | 设置BIOS DEBUG模式 | 0x2E | 0xAE | Admin | BIOS |
| 3.77 | 读取开机自检码post code | 0x2E | 0xB7 | Admin | BIOS |
| 3.78 | BIOS升级前备份bios配置 | 0x2E | 0xBC | Admin | BIOS |

---

## 命令详细说明

### 3.1 设置风扇PWM (Set Fan PWM)

此命令用来设置风扇PWM Duty Value。

- **NetFn**: 0x2E
- **CMD**: 0x30
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Fan Mode | 00h = Manual mode (需要Byte2、Byte3); 01h = Optimal mode（不需要Byte2、Byte3）; 02h = Powersaving mode（不需要Byte2、Byte3）; 03h = Half mode（不需要Byte2、Byte3） |
| 2 | Fan Index | 00h = All FANs; 01h = FAN1; …; 04h = FAN4; 05h = FAN5-6 (4U only); 06h = FAN7-8 (4U only) |
| 3 | PWM Duty Value | 00h ~ FFh: PWM duty value |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 80h = Parameter not support; C7h = Request data length invalid; C9h = Parameter out of range |

---

### 3.2 查询风扇PWM (Query Fan PWM)

此命令用来查询风扇PWM Duty Value。

- **NetFn**: 0x2E
- **CMD**: 0x31
- **Privilege**: User

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 80h = Parameter not support |
| 2 | Fan Mode | 00h = Manual mode; 01h = Optimal mode; 02h = Powersaving mode; 03h = Half mode |
| 3 | FAN1 PWM duty value | FAN1当前PWM占空比 |
| … | … | … |
| 6 | FAN4 PWM duty value | FAN4当前PWM占空比 |
| 7 | FAN5-6 PWM duty value | FAN5-6当前PWM占空比（4U机型） |
| 8 | FAN7-8 PWM duty value | FAN7-8当前PWM占空比（4U机型） |

---

### 3.3 设置密码有效期信息 (Set Password Expiry Info)

此命令用来设置密码有效期信息。

- **NetFn**: 0x2E
- **CMD**: 0x03
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | UserID | 用户ID |
| 2:3 | Password Valid Days | 密码有效天数 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.4 获取密码有效期信息 (Get Password Expiry Info)

此命令用来获取密码有效期信息。

- **NetFn**: 0x2E
- **CMD**: 0x04
- **Privilege**: Operator

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | UserID | 用户ID |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2:3 | Password Valid Days | 密码有效天数 |

---

### 3.5 串口共享控制 (Serial Port Share Control)

该命令用来将SOL的log重定向到BMC的console。

- **NetFn**: 0x2E
- **CMD**: 0x38
- **Privilege**: User

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Control Data | 0: normal status; 5: redirect BIOS serial port to BMC serial port; 6: redirect BMC serial port to BIOS serial port |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.6 获取串口共享状态 (Get Serial Share Status)

该命令用来获取串口共享状态。

- **NetFn**: 0x2E
- **CMD**: 0x37
- **Privilege**: User

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Status | 0: normal status; 5: redirect BIOS serial port to BMC serial port; 6: redirect BMC serial port to BIOS serial port |

---

### 3.7 设置Sensor Scanning状态 (Set Sensor Scanning State)

该命令用来设置sensor scanning状态。

- **NetFn**: 0x2E
- **CMD**: 0x10
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Control Data | 00h = disable sensor scanning; 01h = enable sensor scanning |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Status | 00h = sensor scanning disabled; 01h = sensor scanning enabled |

---

### 3.8 设置风扇资产信息 (Set Fan Asset Info)

该命令用来设置风扇资产信息。

- **NetFn**: 0x2E
- **CMD**: 0x2E
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | FAN index | 风扇序号 |
| 2 | Parameter selector | 00h = Model; 01h = Serial; 02h = Manufacturer |
| 3:18 | Inventory data | 资产信息数据（16字节） |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.9 获取风扇资产信息 (Get Fan Asset Info)

该命令用来获取风扇资产信息。

- **NetFn**: 0x2E
- **CMD**: 0x2F
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | FAN index | 风扇序号，范围 0 - 7 |
| 2 | Parameter selector | 00h = Model; 01h = Serial; 02h = Manufacturer |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | FAN index | 风扇序号 |
| 3 | Set selector | 00h = Model; 01h = Serial; 02h = Manufacturer |
| 4:19 | Inventory data | 资产信息数据（16字节） |

---

### 3.10 设置SNMP团体名信息 (Set SNMP Community Name)

该命令用来设置SNMP团体名信息。

- **NetFn**: 0x2E
- **CMD**: 0x3D
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1:18 | rocommstr | Read-only 团体名字符串 |
| 19:36 | rwcommstr | Read-write 团体名字符串 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.11 读取SNMP团体名信息 (Get SNMP Community Name)

该命令用来获取SNMP团体名信息。

- **NetFn**: 0x2E
- **CMD**: 0x3F
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2:19 | rocommstr | Read-only 团体名字符串 |
| 20:37 | rwcommstr | Read-write 团体名字符串 |

---

### 3.12 设置poweron delay参数 (Set Power-on Delay Parameters)

该命令用来设置poweron delay参数。

- **NetFn**: 0x2E
- **CMD**: 0x32
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Poweron Delay Enable | 0b: Poweron Delay disable; 1b: Poweron Delay enable |
| 2 | Delay Time Enable | 0b: disable setting delay time; 1b: enable setting delay time |
| 3 | Delay Time | 延迟时间（0s~30s） |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.13 获取poweron delay参数 (Get Power-on Delay Parameters)

该命令用来获取poweron delay参数。

- **NetFn**: 0x2E
- **CMD**: 0x33
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Poweron Delay Enable | 0b: Poweron Delay disable; 1b: Poweron Delay enable |
| 3 | Delay Time Enable | 0b: disable setting delay time（延时为随机值）; 1b: enable setting delay time |
| 4 | Delay Time | 延迟时间（0s~30s） |

---

### 3.14 设置NTP时间同步周期 (Set NTP Sync Period)

该命令用来设置NTP时间同步周期。

- **NetFn**: 0x2E
- **CMD**: 0x90
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Maxpoll | NTP最大轮询间隔 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

> **注意**：根据原厂《OEM Commands Specification》33.1 Set NTP Configuration Command定义，要想保存NTP时间同步周期，用户需要使用框架级命令 `raw 0x32 0xA8 0x04` 使NTP重启（注：0x32为框架级NetFn，非平台OEM NetFn 0x2E）。

---

### 3.15 获取NTP时间同步周期 (Get NTP Sync Period)

该命令用来获取NTP时间同步周期。

- **NetFn**: 0x2E
- **CMD**: 0x91
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Maxpoll | NTP最大轮询间隔 |

---

### 3.16 获取网络连接状态 (Get Network Link Status)

该命令用来获取网络连接状态。

- **NetFn**: 0x2E
- **CMD**: 0x92
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | NIC Describe | 网卡描述符（内部映射为 NCSI Channel ID） |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2-3 | Response Code | NCSI 响应码（16-bit） |
| 4-5 | Reason Code | NCSI 原因码（16-bit） |
| 6-9 | Link Status | 链路状态（32-bit bitmask）：bit0=Link Up, bit1=Auto-Neg Enabled, bit5=Auto-Neg Complete, bit16-19=链路速率 |
| 10-13 | Other Indications | 其他指示（32-bit bitmask） |
| 14-17 | OEM Link Status | OEM 扩展链路状态（32-bit） |

> **实现说明**: 底层通过 NCSI GET_LINK_STATUS 命令获取，返回结构体为 `LinkStatusRes_T`。Link Status 字段为位掩码而非枚举值。

---

### 3.17 获取BMC发布时间 (Get BMC Release Time)

该命令用来获取BMC当前版本发布时间。

- **NetFn**: 0x2E
- **CMD**: 0x95
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2:3 | Year of Build Date | 发布年份，LS byte first |
| 4 | Month of Build Date | 发布月份 |
| 5 | Day of Build Date | 发布日期 |
| 6 | Hour of Build Date | 发布小时 |
| 7 | Minute of Build Date | 发布分钟 |
| 8 | Second of Build Date | 发布秒 |

---

### 3.18 清除审计日志 (Clear Audit Log)

该命令用来清除审计日志。

- **NetFn**: 0x2E
- **CMD**: 0x97
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Result | 0 means delete log successfully |

---

### 3.19 压缩BMC后台程序相关日志文件 (Compress BMC Log Files)

该命令用来压缩BMC后台程序运行的相关LOG文件。由于压缩时间会大于IPMI默认响应时间，使用过程中请在IPMI命令中加上参数 `-N 30`，建议设置30秒的返回时间。

- **NetFn**: 0x2E
- **CMD**: 0x98
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Result | 0 means compress log successfully |

---

### 3.20 导出BMC后台程序相关日志文件 (Export BMC Log Files)

该命令用来导出BMC后台程序运行的相关LOG文件，请配合TFTP使用。由于导出时间会大于IPMI默认响应时间，使用过程中请在IPMI命令中加上参数 `-N 30`。

- **NetFn**: 0x2E
- **CMD**: 0x99
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | IP Address Byte 1 | First byte of IP address |
| 2 | IP Address Byte 2 | Second byte of IP address |
| 3 | IP Address Byte 3 | Third byte of IP address |
| 4 | IP Address Byte 4 | Fourth byte of IP address |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Result | 0 means export log successfully |

---

### 3.21 配置vrm极限性能模式 (Configure VRM Extreme Performance Mode)

该命令用来配置vrm极限性能模式。

- **NetFn**: 0x2E
- **CMD**: 0x9A
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Scale value | 范围 0 - 15 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.22 获取所有网卡mac地址 (Get All NIC MAC Addresses)

该命令用来获取带内所有网卡接口的MAC地址。

- **NetFn**: 0x2E
- **CMD**: 0x9B
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2-7 | MAC Address 1 | 6字节MAC地址 |
| 8-N | Additional MAC Addresses | 如存在其他网卡，每个地址6字节 |

---

### 3.23 设置SNMP端口号信息 (Set SNMP Port Number)

该命令用来设置SNMP TRAP端口号信息。

- **NetFn**: 0x2E
- **CMD**: 0x49
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1:2 | Port | SNMP TRAP端口号 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.24 读取SNMP端口号信息 (Get SNMP Port Number)

该命令用来读取SNMP TRAP端口号信息。

- **NetFn**: 0x2E
- **CMD**: 0x44
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2:3 | Port | SNMP TRAP端口号 |

---

### 3.25 获取用户选择运行的flash的标记位 (Get User-Selected Flash Flag)

该命令用来获取当前用户选择使用的flash。

- **NetFn**: 0x2E
- **CMD**: 0x60
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | FRU EEPROM device ID | FRU EEPROM设备ID |
| 2:3 | OFFSET | 偏移地址 |
| 4 | Read count | 读取数量 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Flash user select | 1: primary flash; 2: secondary flash |

---

### 3.26 用户设置默认启动的flash (Set Default Boot Flash)

该命令用来设置默认的BMC启动flash。

- **NetFn**: 0x2E
- **CMD**: 0x61
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | FRU EEPROM device ID | FRU EEPROM设备ID |
| 2:3 | OFFSET | 偏移地址 |
| 4 | Flash select | 1: primary flash; 2: secondary flash |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Write Count | 写入计数 |

---

### 3.27 设置功耗封顶修正值 (Set Power Cap Correction Value)

该命令用来设置功耗封顶的修正值。

- **NetFn**: 0x2E
- **CMD**: 0x62
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Power limit Correct value | 功耗封顶修正值 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.28 获取功耗封顶修正值 (Get Power Cap Correction Value)

该命令用来获取功耗封顶的修正值。

- **NetFn**: 0x2E
- **CMD**: 0x63
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Power limit Correct value | 功耗封顶修正值 |

---

### 3.29 获取当前机器BMC flash个数 (Get BMC Flash Count)

该命令用来获取当前机型安装的BMC flash的个数。

- **NetFn**: 0x2E
- **CMD**: 0x64
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | BMC flash count | BMC flash数量 |

---

### 3.30 获取当前机器CPLD信息 (Get CPLD Info)

该命令用来获取当前机器CPLD的信息。

- **NetFn**: 0x2E
- **CMD**: 0x65
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | CPLD count | CPLD数量 |
| 3:N | CPLD info entries | 每条记录包含6字节：Byte 3: CPLD bus no.; Byte 4: CPLD slave addr; Byte 5: CPLD vendor; Byte 6: CPLD version; Byte 7: CPLD board id; Byte 8: CPLD mux |

---

### 3.31 设置BIOS DEBUG模式 (Set BIOS Debug Mode)

该命令用来设置BIOS debug模式。

- **NetFn**: 0x2E
- **CMD**: 0xAE
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Mode | 1: enable，other: disable |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.32 获取功耗封顶策略 (Get Power Cap Policy)

该命令用来获取功耗封顶策略。

示例：`ipmitool -I lanplus -H xxxxxx -U xxx -P xxx -t 0x2c -b 0x06 raw 0x2e 0xc2 0x57 0x01 0x00 0x00 0x01`

- **NetFn**: 0x2E
- **CMD**: 0xC2
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1:3 | Manufacturer ID | 000157h |
| 4 | Domain ID | 域ID |
| 5 | Policy ID | 策略ID |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2:4 | Manufacturer ID | 000157h |
| 5 | Domain ID | 域ID |
| 6 | Policy Type / Policy Trigger Type | 策略类型 / 触发类型 |
| 7 | Policy Exception Actions | 异常动作 |
| 8:9 | Power Limit | 功耗封顶值（单位W） |
| 10:13 | Correction Time Limit | 修正时间限制 |
| 14:15 | Policy Trigger Limit | 策略触发限制 |
| 16:17 | Statistics Reporting Period | 统计上报周期 |

---

### 3.33 设置功耗封顶最大值 (Set Power Cap Maximum Value)

该命令用来设置功耗封顶最大值。

示例：`ipmitool -I lanplus -H xxxxxx -U xxx -P xxx -t 0x2c -b 0x06 raw 0x2e 0xc1 0x57 0x01 0x00 0x10 0x01 0x10 0x00 0x05 0x02 0x20 0x4e 0x00 0x00 0x64 0x00 0x01 0x00`

其中 0x05 0x02 为设置的功耗封顶值，组合十六进制数为 0x0205，转化为十进制为517W。Domain ID: 0x00 = 关闭功耗封顶，0x10 = 打开功耗封顶。

- **NetFn**: 0x2E
- **CMD**: 0xC1
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1:3 | Manufacturer ID | 000157h |
| 4 | Domain ID | 0x00: 关闭功耗封顶功能，0x10: 打开功耗封顶功能 |
| 5 | Policy ID | 策略ID |
| 6 | Policy Type / Policy Trigger Type | 策略类型 / 触发类型 |
| 7 | Policy Exception Actions | 0x00: 无操作，0x01: 仅记录日志，0x02: 仅关机，0x03: 记录日志并关机 |
| 8:9 | Power Limit | 功耗封顶值（单位W，LS byte first） |
| 10:13 | Correction Time Limit | 修正时间限制 |
| 14:15 | Policy Trigger Limit | 策略触发限制 |
| 16:17 | Statistics Reporting Period | 统计上报周期 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2:4 | Manufacturer ID | 000157h |

---

### 3.34 获取Syslog配置信息 (Get Syslog Configuration)

该命令用来获取Syslog告警配置。

- **NetFn**: 0x2E
- **CMD**: 0xAC
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Parameter selector | 0: 获取 syslog 状态、协议和告警等级; 1: 获取 syslog 条目的目标地址、端口及告警类型（需 Byte 2 指定条目编号） |
| 2 | Syslog entry index | 仅当 selector=1 时有效，取值 0 或 1 |

**Response (Parameter selector = 0):**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Syslog status | 1: remote syslog disable; 3: remote syslog enable |
| 3 | Protocol | 1: UDP; 2: TCP; 3: TLS |
| 4 | Alarm level | Info: 1; warning: 2; critical: 4 |
| 5 | Host Identity | Host Name: 0; Serial Number: 1; Asset Identification: 2 |

**Response (Parameter selector = 1):**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2-5 | Port | 端口号 |
| 6 | Alarm type | Event log: 1; Audit log: 2 |
| 7-70 | Destination address | 目标地址 |

---

### 3.35 修改syslog配置信息 (Set Syslog Configuration)

该命令用来修改syslog配置信息。

- **NetFn**: 0x2E
- **CMD**: 0xAB
- **Privilege**: Admin

**Request (Parameter selector = 0):**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Parameter selector | 0: 设置 syslog 状态、协议和告警等级; 1: 设置目标地址、端口及告警类型; 2: 删除 syslog 条目 |
| 2 | Syslog status | 1: remote syslog disable; 3: remote syslog enable |
| 3 | Protocol | 仅当 req[2]=3 时有效。1: UDP，2: TCP，3: TLS |
| 4 | Alarm level | 仅当 req[2]=3 时有效。Info: 1，warning: 2，critical: 4 |
| 5 | Host Identity | Host Name: 0，Serial Number: 1，Asset Identification: 2 |

**Request (Parameter selector = 1):**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Parameter selector | 1 |
| 2 | Syslog entry | 0 或 1 |
| 3 | Alarm type | Event log: 1，Audit log: 2 |
| 4-7 | Port | 端口号 |
| 8-n | Destination address | 目标地址（n < 82） |

**Request (Parameter selector = 2):**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Parameter selector | 2 |
| 2 | Syslog entry | 0 或 1 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.36 设置密码复杂度 (Set Password Complexity)

该命令用来设置密码复杂度。

- **NetFn**: 0x2E
- **CMD**: 0xA7
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Complexity Enable | 1: on，other: off |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.37 查询密码复杂度 (Get Password Complexity)

该命令用来查询密码复杂度。

- **NetFn**: 0x2E
- **CMD**: 0xA6
- **Privilege**: Admin

> 该命令为查询命令，无请求数据，响应返回密码复杂度状态。

**Request:**

无请求数据。

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Complexity status | 1: on，other: off |

---

### 3.38 设置USB0使能 (Set USB0 Enable)

该命令用来设置USB0使能。

- **NetFn**: 0x2E
- **CMD**: 0x15
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Enable | 0x1: SET ON; 0x0: SET OFF |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Result | 0x0: Set done without error; 0xN: error in step 0xN |

---

### 3.39 查询USB0使能 (Get USB0 Enable Status)

该命令用来查询USB0使能。

- **NetFn**: 0x2E
- **CMD**: 0x16
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Status | 0x1: ON; 0x0: OFF |

---

### 3.40 设置OCP热插拔 (Set OCP Hot-plug)

该命令用来设置OCP热插拔（该功能依赖系统侧响应，请进入系统侧后再使用）。

- **NetFn**: 0x2E
- **CMD**: 0xA1
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | OCP Index | 0x0: OCP0 (SLOT 11); 0x1: OCP1 (SLOT 12) |
| 2 | Power Control | 0x0: POWER OFF; 0x1: POWER ON |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Result | 0x0: Set done without error; 0xN: error in step 0xN |

---

### 3.41 查询OCP上电状态 (Get OCP Power Status)

该命令用来查询OCP上电状态。

- **NetFn**: 0x2E
- **CMD**: 0xA0
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | CtrlReg | OCP 控制寄存器：bit定义见下方 |
| 3 | CtrlReg0 | OCP 控制寄存器0 |
| 4 | CtrlReg1 | OCP 控制寄存器1 |
| 5 | PowerReg | OCP 电源寄存器 |

> **位域定义**（来自源码）：
> - `OCP_CTRL_PLUG_IN` / `OCP_CTRL_PLUG_OUT`：热插拔事件标志
> - `NCSI_SELECT_MUSK` / `NCSI_EN_MUSK`：NCSI 选择/使能掩码
> - `BMC_OCP_SEL_MUSK` / `BMC_NCSI_EN_MUSK`：BMC 侧 OCP 选择/NCSI 使能掩码
> - `OCP_PLUG_BIT`：OCP 在位检测位
> - `OCP_EXIST_MUSK` / `OCP_MAIN_POWER_MUSK` / `OCP_POWER`：OCP 存在/主电源/电源状态掩码
>
> **实现说明**: BMC 先读取 MB_STATUS_REG 获取基址，再加 OCP_REG_OFFSET 计算实际 OCP 状态寄存器地址，一次读回 4 字节（CtrlReg + CtrlReg0 + CtrlReg1 + PowerReg）。

---

### 3.42 获取电源状态信息 (Get PSU Status Info)

该命令用来获取电源状态信息。

- **NetFn**: 0x2E
- **CMD**: 0x20
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | PSU Index | PSU序号，0 ~ 1 |
| 2 | Parameter | 0: 在位状态; 1: 健康状态 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | PSU Index | PSU序号，0 ~ 1 |
| 3 | Parameter | 0: 在位状态; 1: 健康状态 |
| 4~19 | Data | 16字节 ASCII 字符串：Param=0 时返回 `"On"`；Param=1 时返回 `"OK"` / `"Critical"` / `"NA"` |

---

### 3.43 获取电源基本信息 (Get PSU Basic Info)

该命令用来获取电源基本信息。

- **NetFn**: 0x2E
- **CMD**: 0x21
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | PSU Index | PSU序号，0 ~ 1 |
| 2 | Parameter | 0: 电源名称; 1: 电源厂商; 2: 电源类型; 3: 固件版本; 4: 额定功率; 5: 供电类型 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | PSU Index | PSU序号，0 ~ 1 |
| 3 | Parameter | 0: 电源名称; 1: 电源厂商; 2: 电源类型; 3: 固件版本; 4: 额定功率; 5: 供电类型 |
| 4~19 | Data | 16字节 ASCII 字符串：Param=0→PSU名称; 1→厂商名; 2→`"Switching"`; 3→固件版本; 4→额定功率(十进制瓦特); 5→`"AC"` / `"DC"` / `"AC/DC"` |

---

### 3.44 获取电源当前功率 (Get PSU Current Power)

该命令用来获取电源当前功率。

- **NetFn**: 0x2E
- **CMD**: 0x22
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | PSU Index | PSU序号，0 ~ 1 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | PSU Index | PSU序号，0 ~ 1 |
| 3 | Reserved | 保留，0 |
| 4~19 | Data | 16字节 ASCII 字符串：当前功率的十进制瓦特值，或 `"NA"` 表示不可用 |

---

### 3.45 获取液冷机型信息 (Get Liquid Cooling Machine Info)

该命令用来获取当前设备是否为液冷机型，及漏液检测策略、漏液告警持续检测时间。

- **NetFn**: 0x2E
- **CMD**: 0xB2
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Machine Type | 0x0: 通用机型; 0x1: 液冷机型 |
| 3 | Leak Detection Policy | 0x1: 仅告警; 0x2: 告警并软关机; 0x3: 告警并硬关机 |
| 4 | Alarm Persistence Duration | 漏液告警持续检测时间：1~60s |

---

### 3.46 设置液冷机型漏液检测策略（告警动作）(Set Liquid Cooling Leak Detection Policy - Action)

该命令用来设置液冷机型漏液检测策略。

- **NetFn**: 0x2E
- **CMD**: 0xB3
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Leak Detection Policy | 0x1: 仅告警; 0x2: 告警并软关机; 0x3: 告警并硬关机 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.47 设置液冷机型漏液检测策略（持续检测时间）(Set Liquid Cooling Leak Detection Duration)

该命令用来设置液冷机型漏液告警持续检测时间。

- **NetFn**: 0x2E
- **CMD**: 0xB4
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Duration | 持续检测时间：1~60（单位：秒） |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.48 获取功耗统计数据 (Get Power Consumption Statistics)

该命令用来获取功耗统计数据。

- **NetFn**: 0x2E
- **CMD**: 0x13
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2~3 | Data Length | 数据长度 |
| 4~8 | Timestamp | 时间戳 |
| 9~10 | Max Value | 最大值 |
| 11~12 | Average Value | 平均值 |
| 13~14 | Current Value | 当前值 |
| … | … | 重复的时间戳~当前值 |

---

### 3.49 清除功耗统计数据 (Clear Power Consumption Statistics)

该命令用来清除功耗统计数据。

- **NetFn**: 0x2E
- **CMD**: 0x14
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.50 设置PSU自动模式 (Set PSU Auto Mode)

该命令用来开启/关闭电源自动切换模式。

- **NetFn**: 0x2E
- **CMD**: 0x9D
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Enable | 0: disable; 1: enable |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.51 设置PSU自动模式的阈值 (Set PSU Auto Mode Threshold)

该命令用来设置PSU自动模式阈值数据。

- **NetFn**: 0x2E
- **CMD**: 0x9E
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Threshold High Byte | 阈值高位数据 |
| 2 | Threshold Low Byte | 阈值低位数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.52 获取PSU自动模式 (Get PSU Auto Mode Status)

该命令用来获取电源自动切换模式的状态。

- **NetFn**: 0x2E
- **CMD**: 0x9F
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Mode | 0: 均衡模式; 1: 主备模式 |
| 3 | AutoMode | 0: 关闭主动切换模式; 1: 开启主动切换模式 |
| 4 | Threshold High Byte | 阈值高字节数据 |
| 5 | Threshold Low Byte | 阈值低字节数据 |

---

### 3.53 设置防火墙 (Set Firewall)

该命令用来设置BMC防火墙规则。

- **NetFn**: 0x2E
- **CMD**: 0x3C
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Block enable | 0: disable; 1: enable |
| 2 | Set IP enable | 0: disable; 1: block ip |
| 3 | Set time enable | 0: disable; 1: set time |
| 4 | Set MAC enable | 0: disable; 1: block mac |
| 5 | Reserved | 保留 |
| 6~17 | Time Range | 时间范围（12字节，无秒字段）：Byte 6-7: 起始年(2字节LE); Byte 8: 起始月; Byte 9: 起始日; Byte 10: 起始时; Byte 11: 起始分; Byte 12-13: 结束年(2字节LE); Byte 14: 结束月; Byte 15: 结束日; Byte 16: 结束时; Byte 17: 结束分 |
| 18~38 | IP Address | 需要屏蔽的IP地址 |
| 39~59 | MAC Address | 需要屏蔽的MAC地址 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.54 触发bmc打包后台配置与日志 (Trigger BMC Config and Log Package)

该命令用来触发bmc打包后台配置与日志。

- **NetFn**: 0x2E
- **CMD**: 0xA4
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码（操作为异步触发，成功仅表示任务已提交） |

> **实现说明**: 该命令为异步操作，仅返回 CompletionCode 表示任务已排队。实际的打包/备份操作由后台 pend-task 完成。

---

### 3.55 锁定电源物理按键 (Lock Physical Power Button)

该命令用来将物理按键锁定。

- **NetFn**: 0x2E
- **CMD**: 0xB8
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Parameter | 0: 不锁定; 1: 锁定 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.56 DPU单独上下电 (DPU Individual Power Control)

该命令用来将DPU整卡单独上电/下电。

- **NetFn**: 0x2E
- **CMD**: 0xB9
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Parameter | 0: DPU整卡下电; 1: DPU整卡上电 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.57 DPU协同下电命令 (DPU Collaborative Power-off)

该命令用来将DPU协同系统侧下电。

- **NetFn**: 0x2E
- **CMD**: 0xBA
- **Privilege**: Admin

> CMD 值为 0xBA，源码 handler 注册确认。

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Parameter | 0: 协同下电 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.58 获取PSU最大功率 (Get PSU Maximum Power)

该命令用来获取PSU最大功率。

- **NetFn**: 0x2E
- **CMD**: 0xA8
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2:3 | PSU1 max power | PSU1最大功率 |
| 4:5 | PSU2 max power | PSU2最大功率 |

---

### 3.59 获取BBU告警开关 (Get BBU Alarm Switch)

该命令用来获取BBU告警开关。

- **NetFn**: 0x2E
- **CMD**: 0xA2
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1~4 | vendor_type | 0: controller type 0，1: controller type 1 |
| 5~8 | ctrlid | 控制器ID |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2~5 | bbu_alarm | 0: 关，1: 开 |

---

### 3.60 设置BBU告警开关 (Set BBU Alarm Switch)

该命令用来设置BBU告警开关。

- **NetFn**: 0x2E
- **CMD**: 0xA3
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1~4 | vendor_type | 0: controller type 0，1: controller type 1 |
| 5~8 | ctrlid | 控制器ID |
| 9~12 | bbu_alarm | 0: 关，1: 开 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.61 SOL切换输出串口 (SOL Output Serial Port Switch)

此命令用来选择SOL输出到系统侧串口或DPU侧串口。

- **NetFn**: 0x2E
- **CMD**: 0xAF
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Output Target | 00h = SOL输出系统侧串口; 01h = SOL输出DPU侧串口 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | C7h = Request data length invalid; C1h = Request CMD invalid |

---

### 3.62 获取inventory相关信息 (Get Inventory Info)

该命令用来获取inventory相关信息（PSGood值、硬盘在位数量、PSU在位数量、风扇在位数量、风扇总数、整机功耗）。

- **NetFn**: 0x2E
- **CMD**: 0xB0
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | PSGood | PSU供电状态 |
| 3 | DiskPresent | 硬盘在位数量 |
| 4 | PsuPresent | PSU在位数量 |
| 5 | FanPresent | 风扇在位数量 |
| 6 | FanTotal | 风扇总数 |
| 7 | PowerTotal (float byte0) | 整机功耗，IEEE 754 单精度浮点数 Byte 0（小端序） |
| 8 | PowerTotal (float byte1) | 整机功耗浮点数 Byte 1 |
| 9 | PowerTotal (float byte2) | 整机功耗浮点数 Byte 2 |
| 10 | PowerTotal (float byte3) | 整机功耗浮点数 Byte 3 |

---

### 3.63 设置板载硬盘的点灯状态 (Set Onboard Disk Locate LED)

该命令用来设置板载硬盘的点灯状态。

- **NetFn**: 0x2E
- **CMD**: 0xF6
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Slot | 槽位号 |
| 2 | Action | 0: 关闭; 1: 打开 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Islocate | 命令下发状态。若 Action=1：islocate=1 表示成功，islocate=0 表示失败；若 Action=0：islocate=0 表示成功，islocate=2 表示失败 |

---

### 3.64 获取板载硬盘的点灯状态 (Get Onboard Disk Locate LED Status)

该命令用来获取板载硬盘的点灯状态。

- **NetFn**: 0x2E
- **CMD**: 0xF7
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Slot | 槽位号 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Islocate | islocate=1: 状态灯点亮; islocate=0: 状态灯熄灭 |

---

### 3.65 删除Redis数据库里的inventory CRC数据 (Delete Inventory CRC Data in Redis)

该命令用来删除Redis数据库里的inventory CRC数据。**此为开发调试命令，请勿随意使用！**

- **NetFn**: 0x2E
- **CMD**: 0xAA
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.66 设置PSU配置 (Set PSU Configuration)

该命令用来设置PSU配置。

- **NetFn**: 0x2E
- **CMD**: 0x3A
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Mode | 0: Active; 1: Standby |
| 2 | PSU id | 0: PSU1; 1: PSU2; 2: all |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.67 获取PSU配置 (Get PSU Configuration)

该命令用来获取PSU配置。

- **NetFn**: 0x2E
- **CMD**: 0x3B
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Mode | 0: Active; 1: Standby |
| 3 | PSU id | 0: PSU1; 1: PSU2; 2: all |

---

### 3.68 设置密码安全 (Set Password Security)

该命令用来设置密码安全（登录失败锁定策略）。

- **NetFn**: 0x2E
- **CMD**: 0x11
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Failed login attempts | 允许的登录失败次数 |
| 2:3 | Failed login attempts interval time | 失败登录尝试的时间间隔 |
| 4:5 | Failed login lockout time | 锁定时间 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.69 获取密码安全 (Get Password Security)

该命令用来获取密码安全（登录失败锁定策略）。

- **NetFn**: 0x2E
- **CMD**: 0x12
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Failed login attempts | 允许的登录失败次数 |
| 3:4 | Failed login attempts interval time | 失败登录尝试的时间间隔 |
| 5:6 | Failed login lockout time | 锁定时间 |

---

### 3.70 检查密码 (Check Password)

该命令用来检查密码是否合规。

- **NetFn**: 0x2E
- **CMD**: 0xF8
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | UserID | 用户ID |
| 2 | operation | 操作类型（仅低2位有效）：0=Disable User; 1=Enable User; 2=Set Password; 3=Test Password |
| 3:22 | password | 密码（operation=2/3时必填，支持16字节或20字节两种长度） |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.71 设置SNMP trap告警等级、上报标识、trap端口号 (Set SNMP Trap Config)

该命令用来设置SNMP trap告警等级、上报标识、trap端口号。

- **NetFn**: 0x2E
- **CMD**: 0x45
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | 告警号 | 范围 1-15 |
| 2-3 | Trap端口号 | SNMP Trap 端口 |
| 4 | 告警级别 | Info: 1，Warning: 2，Critical: 4 |
| 5 | 上报标识 | 0: 主机名，1: UUID，2: 资产标签 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.72 获取SNMP trap告警等级、上报标识、trap端口号 (Get SNMP Trap Config)

该命令用来读取SNMP trap告警等级、上报标识、trap端口号。

- **NetFn**: 0x2E
- **CMD**: 0x46
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | 告警号 | 范围 1-15 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2-3 | trap端口号 | SNMP Trap 端口 |
| 4 | 告警级别 | Info: 1，Warning: 2，Critical: 4 |
| 5 | 上报标识 | 0: 主机名，1: UUID，2: 资产标签 |

---

### 3.73 设置SNMPV1\V2c版本使能状态 (Set SNMP V1/V2c Enable)

该命令用来设置SNMPV1\V2c版本使能状态。

- **NetFn**: 0x2E
- **CMD**: 0x47
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Enable state | 0: snmp V1\V2c 全部关闭; 1: snmpV1开启、V2c关闭; 2: snmpV2c开启、V1关闭; 3: snmp V1\V2c 全部开启 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.74 读取SNMPV1\V2c版本使能状态 (Get SNMP V1/V2c Enable Status)

该命令用来读取SNMPV1\V2c版本使能状态。

- **NetFn**: 0x2E
- **CMD**: 0x48
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Enable state | 0: snmp V1\V2c 全部关闭; 1: snmpV1开启、V2c关闭; 2: snmpV2c开启、V1关闭; 3: snmp V1\V2c 全部开启 |

---

### 3.75 设置SNMP团体名复杂度 (Set SNMP Community Name Complexity)

该命令用来设置SNMP团体名复杂度。

- **NetFn**: 0x2E
- **CMD**: 0xB5
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Complexity Enable | 0: 关闭团体名复杂度; 1: 开启团体名复杂度 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

### 3.76 读取SNMP团体名复杂度 (Get SNMP Community Name Complexity)

该命令用来读取SNMP团体名复杂度。

- **NetFn**: 0x2E
- **CMD**: 0xB6
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| 2 | Complexity status | 0: 团体名复杂度关闭; 1: 团体名复杂度开启 |

---

### 3.77 读取开机自检码post code (Read POST Code)

该命令用来读取开机自检码post code。

- **NetFn**: 0x2E
- **CMD**: 0xB7
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Read mode | 0: 读取当前post code; 1: 读取前一次开机的post code; 2: 读取当前post code长度; 3: 读取前一次开机post code长度 |
| 2 | Segment selector | 仅当Byte1为0或1时使用：0: 读取第1-256字节post code; 1: 读取第257-512字节post code; 2: 读取第513-768字节post code; 3: 读取第769-1024字节post code |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |
| **Request Byte1 = 2 或 3** | | |
| 2-4 | Post code length | POST code长度 |
| **Request Byte1 = 0 或 1** | | |
| 2-257 | Post code | POST code数据（最多256字节） |

---

### 3.78 BIOS升级前备份bios配置 (Backup BIOS Config Before Upgrade)

该命令用来在BIOS升级前备份bios配置。

- **NetFn**: 0x2E
- **CMD**: 0xBC
- **Privilege**: Admin

**Request:**

| Byte | Field | Description |
|------|-------|-------------|
| — | — | 无请求数据 |

**Response:**

| Byte | Field | Description |
|------|-------|-------------|
| 1 | Completion Code | 标准完成码 |

---

## 统计信息

### 总体统计

| 项目 | 数值 |
|------|------|
| OEM命令总数（详细说明） | 78 条（3.1 ~ 3.78） |
| 使用的 NetFn | 0x2E（所有命令统一） |
| CMD 最小值 | 0x03 |
| CMD 最大值 | 0xF8 |
| Admin 权限命令数 | 74 条 |
| Operator 权限命令数 | 1 条（3.4） |
| User 权限命令数 | 3 条（3.2、3.5、3.6） |
| 无请求数据命令数 | 29 条 |

### CMD 使用分布

| CMD 范围 | 已使用 CMD 值 |
|----------|--------------|
| 0x03 ~ 0x16 | 0x03, 0x04, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16 |
| 0x20 ~ 0x33 | 0x20, 0x21, 0x22, 0x2E, 0x2F, 0x30, 0x31, 0x32, 0x33 |
| 0x37 ~ 0x49 | 0x37, 0x38, 0x3A, 0x3B, 0x3C, 0x3D, 0x3F, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49 |
| 0x60 ~ 0x65 | 0x60, 0x61, 0x62, 0x63, 0x64, 0x65 |
| 0x90 ~ 0x9F | 0x90, 0x91, 0x92, 0x95, 0x97, 0x98, 0x99, 0x9A, 0x9B, 0x9D, 0x9E, 0x9F |
| 0xA0 ~ 0xAF | 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA6, 0xA7, 0xA8, 0xAA, 0xAB, 0xAC, 0xAE, 0xAF |
| 0xB0 ~ 0xBC | 0xB0, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8, 0xB9, 0xBA, 0xBC |
| 0xC1 ~ 0xC2 | 0xC1, 0xC2 |
| 0xF6 ~ 0xF8 | 0xF6, 0xF7, 0xF8 |

### 未收录详细说明的命令

以下命令在命令汇总表中列出，但详细说明章节中**未提供** Request/Response 格式说明：

| 命令名称 | NetFn | CMD | 权限 | 备注 |
|----------|-------|-----|------|------|
| 设置BIOS版本信息 | 0x2E | 0x01 | Admin | 详细说明章节无对应条目 |
| 获取BIOS版本信息 | 0x2E | 0x02 | Admin | 详细说明章节无对应条目 |
| 获取disk状态 | 0x2E | 0x34 | User | 详细说明章节无对应条目 |
| 设置PXE网络超时时间 | 0x2E | 0x35 | Admin | 详细说明章节无对应条目 |
| 获取PXE网络超时时间 | 0x2E | 0x36 | Admin | 详细说明章节无对应条目 |
| 开启socflash功能 | 0x2E | 0x96 | Admin | 详细说明章节无对应条目 |

> 上述6条命令已在汇总表中列出，但命令格式暂未提供。

---

*文档版本：2026-04-07*
