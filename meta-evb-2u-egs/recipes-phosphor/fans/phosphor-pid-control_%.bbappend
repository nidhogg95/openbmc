FILESEXTRAPATHS:prepend:evb-2u-egs := "${THISDIR}/${PN}:"
SRC_URI:append:evb-2u-egs = " file://config.json"

do_install:append:evb-2u-egs() {
    install -m 0755 -d ${D}${datadir}/swampd
    install -m 0644 ${UNPACKDIR}/config.json ${D}${datadir}/swampd/
}

FILES:${PN}:append:evb-2u-egs = " ${datadir}/swampd/config.json"
