FILESEXTRAPATHS:prepend:evb-2u-egs := "${THISDIR}/${PN}:"
SRC_URI:append:evb-2u-egs = " file://power-config-host0.json"

do_install:append:evb-2u-egs() {
    install -m 0755 -d ${D}/${datadir}/${BPN}
    install -m 0644 ${UNPACKDIR}/power-config-host0.json ${D}${datadir}/${BPN}
}
