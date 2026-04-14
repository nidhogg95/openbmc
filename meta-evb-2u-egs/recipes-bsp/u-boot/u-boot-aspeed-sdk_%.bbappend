FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://0001-Fix-missing-timestamp.h-include-for-U_BOOT_DMI_DATE.patch \
    file://evb-2u-egs.cfg \
    "
