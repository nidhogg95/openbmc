#!/bin/bash
# OpenBMC QEMU 启动脚本 - EVB-2U-EGS 平台
# 支持 SSH、BMCWeb WebUI、IPMI 端口转发
#
# 技术说明:
#   EVB-2U-EGS DTS 启用的是 mac2(1e670000) 和 mac3(1e690000)
#   QEMU ast2600-evb 内置 4 个 NIC (mac0-mac3)
#   -net nic -net nic 分别占位 mac0/mac1，第三个 -net nic,netdev=usernet 连接到 mac2
#   这样用户网络(SLIRP)才能正确桥接到 Linux 看到的 eth0

set -e

MACHINE="evb-2u-egs"
BUILD_DIR="/home/dev/openbmc-workspace/openbmc/build/${MACHINE}"
QEMU="${BUILD_DIR}/tmp/work/x86_64-linux/qemu-helper-native/1.0/recipe-sysroot-native/usr/bin/qemu-system-arm"
MTD="${BUILD_DIR}/tmp/deploy/images/${MACHINE}/obmc-phosphor-image-${MACHINE}.static.mtd"

if [ ! -f "$QEMU" ]; then
    echo "错误: QEMU 未找到: $QEMU"
    echo "请先编译: bitbake obmc-phosphor-image"
    exit 1
fi

if [ ! -f "$MTD" ]; then
    echo "错误: 固件镜像未找到: $MTD"
    echo "请先编译: bitbake obmc-phosphor-image"
    exit 1
fi

echo "============================================"
echo "  OpenBMC QEMU - ${MACHINE}"
echo "============================================"
echo ""
echo "  WebUI:  https://localhost:2443"
echo "  SSH:    ssh -p 2222 root@localhost"
echo "  IPMI:   ipmitool -I lanplus -H localhost -p 2623 -U root -P 0penBmc chassis status"
echo "  密码:   0penBmc"
echo ""
echo "  启动后约 60 秒系统就绪"
echo "  按 Ctrl-A 然后按 X 退出 QEMU"
echo "============================================"
echo ""

exec $QEMU \
    -machine ast2600-evb,execute-in-place=true,fmc-model=w25q512jv \
    -m 1G \
    -drive file=$MTD,if=mtd,format=raw \
    -netdev user,id=usernet,hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:2443-:443,hostfwd=udp:127.0.0.1:2623-:623 \
    -net nic -net nic -net nic,netdev=usernet \
    -serial mon:stdio -serial null \
    -nographic
