FILESEXTRAPATHS:prepend:evb-2u-egs := "${THISDIR}/${PN}:"
SRC_URI:append:evb-2u-egs = " file://evb-2u-egs-baseboard.json"

do_install:append:evb-2u-egs() {
    install -m 0644 ${UNPACKDIR}/evb-2u-egs-baseboard.json ${D}${datadir}/entity-manager/configurations/
}
