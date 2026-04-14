FILESEXTRAPATHS:prepend:evb-2u-egs := "${THISDIR}/${PN}:"
SRC_URI:append:evb-2u-egs = " \
    file://evb-2u-egs.cfg \
    file://aspeed-bmc-evb-2u-egs.dts \
    file://0001-ARM-dts-aspeed-Add-EVB-2U-EGS-board.patch \
    "

do_patch:append:evb-2u-egs() {
    cp ${UNPACKDIR}/aspeed-bmc-evb-2u-egs.dts \
        ${STAGING_KERNEL_DIR}/arch/${ARCH}/boot/dts/aspeed/
}
