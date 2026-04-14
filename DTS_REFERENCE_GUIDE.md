# AST2600 x86 服务器板 DTS 参考指南
## 为 evb-2u-egs 创建 aspeed-bmc-evb-2u-egs.dts

---

## 📋 文件对比

| 属性 | S2600WF | Quanta S6Q | 备注 |
|------|---------|-----------|------|
| **SoC** | AST2500 (G5) | AST2600 (G6) | ⭐ S6Q 更接近 |
| **包含文件** | aspeed-g5.dtsi | aspeed-g6.dtsi | G6 是最新 |
| **行数** | ~170 行 | ~700+ 行 | S6Q 更完整 |
| **内存** | 0x20000000 (512MB) | 0x40000000 (1GB) | 根据平台调整 |

---

## 🏗️ 标准 DTS 结构（基于 Quanta S6Q）

### 1. **文件头和包含**
```dts
// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2022 <Your Company>
/dts-v1/;

#include "aspeed-g6.dtsi"
#include <dt-bindings/gpio/aspeed-gpio.h>
#include <dt-bindings/i2c/i2c.h>
```

✅ **关键点：**
- 使用 `aspeed-g6.dtsi` 作为基础（AST2600）
- 包含 GPIO 和 I2C 绑定
- SPDX 许可证是必需的

---

### 2. **根节点和基本属性**
```dts
/ {
    model = "EVB 2U EGS BMC";
    compatible = "intel,evb-2u-egs-bmc", "aspeed,ast2600";

    chosen {
        stdout-path = &uart5;
        bootargs = "console=ttyS4,115200n8 earlycon";
    };

    memory@80000000 {
        device_type = "memory";
        reg = <0x80000000 0x40000000>;  /* 1GB */
    };

    reserved-memory {
        #address-cells = <1>;
        #size-cells = <1>;
        ranges;

        vga_memory: framebuffer@9f000000 {
            no-map;
            reg = <0x9f000000 0x01000000>; /* 16MB */
        };
    };
};
```

✅ **关键点：**
- `compatible` 需要两个条目：板级 + SoC 级
- UART5 是控制台（ttyS4）
- VGA 内存保留地址计算：`RAM_BASE + RAM_SIZE - VGA_SIZE`
- 内存大小需要根据硬件调整

---

### 3. **GPIO 行名称（GPIO 线命名）**
```dts
&gpio0 {
    gpio-line-names =
    /*A0 - A7*/    "PLTRST_N", "", "PWR_DEBUG_N", "", "", "", "", "",
    /*B0 - B7*/    "", "", "", "", "", "FM_MB_RST_BTN", "", "",
    /*C0 - C7*/    "", "", "", "", "", "", "", "",
    /*D0 - D7*/    "", "", "", "", "", "", "", "",
    /*E0 - E7*/    "", "", "", "", "", "", "", "",
    /*F0 - F7*/    "PLTRST_N", "", "PWR_DEBUG_N", "", "", "", "", "",
    /* ... 完整 208 个 GPIO 行名称，每行 8 个 ... */
    /*Z0 - Z7*/    "FM_BMC_READY_N", "", "", "", "", "", "", "",
    /*AA0 - AA7*/  "", "", "", "", "", "", "", "",
    /*AB0 - AB7*/  "", "", "", "", "", "", "", "",
    /*AC0 - AC7*/  "", "", "", "", "", "", "", "";
};
```

✅ **关键点：**
- GPIO 按字母组织：A, B, C, ... Z, AA, AB, AC
- 每组 8 个（0-7）
- AST2600 有 208 个 GPIO（0 到 207）
- 空字符串表示未使用的 GPIO
- 使用有意义的名字便于后续查找

---

### 4. **SGPIO（串行 GPIO）配置**
```dts
&sgpiom0 {
    status = "okay";
    ngpios = <128>;
    bus-frequency = <48000>;
    gpio-line-names =
    /* SGPIO input lines */
    /*IOA0-IOA7*/  "", "", "SIO_POWER_GOOD", "OA1", "XDP_PRST_N", "", "", "",
    /*IOB0-IOB7*/  "FM_ADR_COMPLETE", "", "FM_PMBUS_ALERT_B_EN", "", 
                   "PSU0_PRESENT_N", "", "PSU1_PRESENT_N", "",
    /* ... 更多 SGPIO 行 ... */
    /*IOP0-IOP7*/  "IP0", "OP0", "", "", "", "", "", "", "", "", "", "", "", "", "IP7", "OP7";
};
```

✅ **关键点：**
- SGPIO 用于串行输入/输出
- `ngpios = <128>` 表示 128 个 SGPIO 线
- 命名约定：IOA, IOB, IOC ... IOP（16 组）
- 包括电源、风扇、PSU 感应等

---

### 5. **ADC 配置（模拟数字转换）**
```dts
&adc0 {
    vref = <2500>;  /* 2.5V 参考 */
    status = "okay";
    pinctrl-names = "default";
    pinctrl-0 = <&pinctrl_adc0_default &pinctrl_adc1_default
        &pinctrl_adc2_default &pinctrl_adc3_default
        &pinctrl_adc4_default &pinctrl_adc5_default
        &pinctrl_adc6_default &pinctrl_adc7_default>;
};

&adc1 {
    vref = <2500>;
    status = "okay";
    pinctrl-names = "default";
    pinctrl-0 = <&pinctrl_adc8_default &pinctrl_adc9_default
        &pinctrl_adc10_default &pinctrl_adc11_default
        &pinctrl_adc12_default &pinctrl_adc13_default
        &pinctrl_adc14_default &pinctrl_adc15_default>;
};

iio-hwmon {
    compatible = "iio-hwmon";
    io-channels = <&adc0 0>, <&adc0 1>, <&adc0 2>, <&adc0 3>,
        <&adc0 4>, <&adc0 5>, <&adc0 6>, <&adc0 7>,
        <&adc1 0>, <&adc1 1>, <&adc1 2>, <&adc1 3>,
        <&adc1 4>, <&adc1 5>, <&adc1 6>, <&adc1 7>;
};
```

✅ **关键点：**
- AST2600 有 2 个 ADC 控制器（adc0, adc1），每个 8 通道
- `vref = <2500>` 通常是标准参考电压（2.5V）
- pinctrl 绑定到相应的 GPIO 引脚
- `iio-hwmon` 向应用暴露这些通道

---

### 6. **Flash/SPI 配置**
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
};

&spi2 {
    pinctrl-names = "default";
    pinctrl-0 = <&pinctrl_spi2_default &pinctrl_spi2cs1_default
        &pinctrl_spi2cs2_default>;
    status = "okay";

    flash@0 {
        status = "okay";
        m25p,fast-read;
        label = "spi2:0";
        spi-max-frequency = <50000000>;
    };
};
```

✅ **关键点：**
- `fmc` = Flash Memory Controller（主 Flash）
- 可以有多个 SPI 控制器（spi1, spi2, spi2）
- `m25p,fast-read` 启用快速读取模式
- `openbmc-flash-layout-64.dtsi` 包含分区定义
- `spi-max-frequency = <50000000>` = 50 MHz

---

### 7. **I2C 总线配置**
```dts
&i2c0 {
    status = "okay";
    
    U34_PWR_ADC@48 {
        compatible = "ti,ads7830";
        reg = <0x48>;
    };

    i2c-mux@70 {
        compatible = "nxp,pca9546";
        reg = <0x70>;
        #address-cells = <1>;
        #size-cells = <0>;
        i2c-mux-idle-disconnect;

        SMB_HOST_DB2000_3V3AUX_SCL: i2c@0 {
            #address-cells = <1>;
            #size-cells = <0>;
            reg = <0>;
        };

        SMB_HOST_DB800_B_SCL: i2c@1 {
            #address-cells = <1>;
            #size-cells = <0>;
            reg = <1>;
        };
    };
};

&i2c1 {
    status = "okay";

    i2c-mux@59 {
        compatible = "nxp,pca9848";
        reg = <0x59>;
        #address-cells = <1>;
        #size-cells = <0>;
        i2c-mux-idle-disconnect;

        SMB_TEMP_3V3AUX_SCL: i2c@3 {
            #address-cells = <1>;
            #size-cells = <0>;
            reg = <3>;

            U163_tmp75@48 {
                compatible = "ti,tmp75";
                reg = <0x48>;
            };
        };
    };
};
```

✅ **关键点：**
- AST2600 有 16 个 I2C 总线（i2c0-i2c15）
- I2C mux（复用器）用来扩展总线数量
- 标签（e.g., `SMB_TEMP_3V3AUX_SCL:`）便于引用
- 设备地址在 `reg` 属性中（例如 `<0x48>` = 0x48）
- `i2c-mux-idle-disconnect` 提高隔离性

---

### 8. **网络接口（MAC）**
```dts
&mdio2 {
    status = "okay";

    ethphy2: ethernet-phy@0 {
        compatible = "ethernet-phy-ieee802.3-c22";
        reg = <0>;
    };
};

&mac2 {
    status = "okay";
    phy-mode = "rgmii";
    phy-handle = <&ethphy2>;

    pinctrl-names = "default";
    pinctrl-0 = <&pinctrl_rgmii3_default>;
};

&mac3 {
    status = "okay";
    phy-mode = "rmii";
    use-ncsi;

    pinctrl-names = "default";
    pinctrl-0 = <&pinctrl_rmii4_default>;
};
```

✅ **关键点：**
- AST2600 有 4 个 MAC（mac0, mac1, mac2, mac3）
- `phy-mode` 可以是 `rgmii`, `rmii`, `gmii` 等
- `use-ncsi` 用于 NC-SI（网络控制器 Sideband Interface）
- `phy-handle` 引用相应的 PHY 设备
- mdio = Management Data Input/Output

---

### 9. **PECI 总线**
```dts
&peci0 {
    status = "okay";
    aspeed,external-mux = <&gpio0 ASPEED_GPIO(H, 4) GPIO_ACTIVE_LOW>;
};
```

⚠️ **AST2600 PECI 注意事项：**
- `peci0` 在基础 dtsi 中定义为 `1e78b000`
- PECI 用于 CPU 温度、功率监测
- 可选：如果需要 PECI 多路，添加 `aspeed,external-mux`

---

### 10. **UART 配置**
```dts
&uart1 {
    status = "okay";
};

&uart2 {
    status = "okay";
};

&uart4 {
    status = "okay";
};

&uart5 {
    status = "okay";
};

&uart_routing {
    status = "okay";
};
```

✅ **关键点：**
- uart5 通常是控制台（ttyS4）
- `uart_routing` 管理 UART 多路选择
- 其他 UART 可用于 SOL、串行接口等

---

### 11. **LED 配置**
```dts
leds {
    compatible = "gpio-leds";

    BMC_HEARTBEAT_N {
        label = "BMC_HEARTBEAT_N";
        gpios = <&gpio0 ASPEED_GPIO(P, 7) GPIO_ACTIVE_LOW>;
        linux,default-trigger = "heartbeat";
    };

    BMC_LED_STATUS_AMBER_N {
        label = "BMC_LED_STATUS_AMBER_N";
        gpios = <&gpio0 ASPEED_GPIO(S, 6) GPIO_ACTIVE_LOW>;
        default-state = "off";
    };

    FM_ID_LED_N {
        label = "FM_ID_LED_N";
        gpios = <&gpio0 ASPEED_GPIO(B, 5) GPIO_ACTIVE_LOW>;
        default-state = "off";
    };
};
```

✅ **关键点：**
- `ASPEED_GPIO(PORT, PIN)` 宏用于引用 GPIO
- `GPIO_ACTIVE_LOW` 表示低电平激活
- `linux,default-trigger` 控制 LED 行为
- 标签应该是有意义的名称

---

### 12. **IPMI/KCS 配置**
```dts
&kcs1 {
    status = "okay";
    aspeed,lpc-io-reg = <0xCA0>;
};

&kcs2 {
    status = "okay";
    aspeed,lpc-io-reg = <0xCA8>;
};

&kcs3 {
    status = "okay";
    aspeed,lpc-io-reg = <0xCA2>;
};

&lpc_snoop {
    status = "okay";
    snoop-ports = <0x80>;
};

&ibt {
    status = "okay";
};
```

✅ **关键点：**
- KCS = Keyboard Controller Style（IPMI 接口）
- `aspeed,lpc-io-reg` 指定 LPC 口地址
- `lpc_snoop` 用于窃听 LPC 端口
- IBT = In-Band Telemetry

---

### 13. **EMMC 配置**
```dts
&emmc_controller {
    status = "okay";
};

&emmc {
    non-removable;
    bus-width = <4>;
    max-frequency = <100000000>;
};
```

✅ **关键点：**
- AST2600 支持嵌入式 MMC
- 可选功能，许多平台不需要

---

## 📐 GPIO 编号方案

AST2600 GPIO 按字母分组：
- A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z (26 组)
- AA, AB, AC (3 组，因为 208 = 26×8 + 3×4)

**计算 GPIO 编号：** `GPIO_NUMBER = GROUP_INDEX * 8 + PIN_NUMBER`

例如：
- `GPIO(A, 0)` = 0
- `GPIO(B, 5)` = 13
- `GPIO(P, 7)` = 135
- `GPIO(Z, 0)` = 208

---

## 🎯 为 evb-2u-egs 创建 DTS 的步骤

### 1️⃣ **开始模板**
```bash
# 位置：openbmc/arch/arm/boot/dts/aspeed-bmc-intel-evb-2u-egs.dts
# （或在 meta-evb-2u-egs 内部，取决于项目结构）
```

### 2️⃣ **复制 Quanta S6Q 框架**
- 使用 Quanta S6Q 作为起点（最接近的 AST2600 参考）
- 更新 `model`, `compatible` 属性

### 3️⃣ **自定义 GPIO 行名**
- 参考硬件定义文档（47 个命名 GPIO）
- 填充 gpio0 的 `gpio-line-names`
- 填充 sgpiom0 的 SGPIO 输入/输出线

### 4️⃣ **配置 I2C 总线**
- 参考硬件定义文档（26+ I2C 设备）
- 为每个 I2C 总线设置正确的频率
- 为 mux 和设备定义标签（便于 `.bbappend` 引用）

### 5️⃣ **配置网络**
- 参考硬件定义：mac1 (RGMII-RXID), mac2 (RGMII)
- 设置 PHY 模式和 pinctrl

### 6️⃣ **配置 PECI**
- 如果需要，启用 `&peci0` 并指定外部 mux GPIO

### 7️⃣ **配置 Flash**
- 根据硬件：2× SPI w25q512 (64MB each)
- 设置频率为 50 MHz
- 包含 flash 分区文件（openbmc-flash-layout-128.dtsi）

### 8️⃣ **添加特定于平台的设备**
- 温度传感器、风扇、PSU 监测
- FRU EEPROM
- LED 指示灯

### 9️⃣ **测试和验证**
```bash
# 编译 DTS
dtc -I dts -O dtb aspeed-bmc-intel-evb-2u-egs.dts

# 检查语法错误
dtc -I dts -O dtb -o /dev/null aspeed-bmc-intel-evb-2u-egs.dts -v
```

---

## 🔗 参考 GitHub 链接

- **Quanta S6Q DTS** (完整参考)：
  https://github.com/torvalds/linux/blob/master/arch/arm/boot/dts/aspeed/aspeed-bmc-quanta-s6q.dts

- **AST2600 基础 dtsi**：
  https://github.com/torvalds/linux/blob/master/arch/arm/boot/dts/aspeed/aspeed-g6.dtsi

- **S2600WF DTS** (AST2500 参考 - 较旧但简单)：
  https://github.com/torvalds/linux/blob/master/arch/arm/boot/dts/aspeed/aspeed-bmc-intel-s2600wf.dts

---

## ⚠️ 常见错误

❌ **错误1：** 在 S2600WF DTS 中使用 `aspeed-g5.dtsi` 基础
- ✅ 解决：使用 `aspeed-g6.dtsi` 作为 AST2600 的基础

❌ **错误2：** 计算 VGA 内存地址错误
- 计算：`0x80000000 + 0x40000000 - 0x01000000 = 0xBF000000`
- ✅ 或直接使用：`0x9f000000` (0x80000000 + 0x20000000 - 0x01000000)

❌ **错误3：** 忘记包含 GPIO 和 I2C 绑定
- ✅ 必须包含：`#include <dt-bindings/gpio/aspeed-gpio.h>`

❌ **错误4：** I2C 设备地址冲突
- ✅ 验证硬件文档中没有重复的 I2C 地址

❌ **错误5：** GPIO 编号超出范围（AST2600 = 0-207）
- ✅ 检查 GPIO 编号 < 208

---

## 📝 最小可行 DTS 模板

```dts
// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright 2024 Intel
/dts-v1/;

#include "aspeed-g6.dtsi"
#include <dt-bindings/gpio/aspeed-gpio.h>
#include <dt-bindings/i2c/i2c.h>

/ {
    model = "EVB 2U EGS BMC";
    compatible = "intel,evb-2u-egs-bmc", "aspeed,ast2600";

    chosen {
        stdout-path = &uart5;
        bootargs = "console=ttyS4,115200n8 earlycon";
    };

    memory@80000000 {
        device_type = "memory";
        reg = <0x80000000 0x40000000>;
    };

    reserved-memory {
        #address-cells = <1>;
        #size-cells = <1>;
        ranges;

        vga_memory: framebuffer@9f000000 {
            no-map;
            reg = <0x9f000000 0x01000000>;
        };
    };

    leds {
        compatible = "gpio-leds";
        BMC_HEARTBEAT_N {
            label = "BMC_HEARTBEAT_N";
            gpios = <&gpio0 ASPEED_GPIO(P, 7) GPIO_ACTIVE_LOW>;
            linux,default-trigger = "heartbeat";
        };
    };
};

&fmc {
    status = "okay";
    flash@0 {
        status = "okay";
        m25p,fast-read;
        label = "bmc";
#include "openbmc-flash-layout-64.dtsi"
    };
};

&uart5 {
    status = "okay";
};

&i2c0 {
    status = "okay";
};

&mac0 {
    status = "okay";
    use-ncsi;
};

&mac1 {
    status = "okay";
};
```

---

## 🚀 下一步

1. ✅ 获取 evb-2u-egs 硬件定义文档（GPIO 映射、I2C 设备）
2. ✅ 基于 Quanta S6Q 创建 DTS 文件
3. ✅ 在 meta-evb-2u-egs 机器层中注册（layer.conf 中）
4. ✅ 在 conf/machine/evb-2u-egs.conf 中添加 `KERNEL_DEVICETREE`
5. ✅ 编译并测试 DTS
6. ✅ 迭代添加特定平台设备（温度传感器、风扇等）

---

**最后更新：** 2024-04
**参考：** Linux kernel AST2600/AST2500 DTS 文件

