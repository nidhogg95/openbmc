FILESEXTRAPATHS:prepend:evb-2u-egs := "${THISDIR}/${PN}:"

SRC_URI:append:evb-2u-egs = " file://led-group-config.json"

PACKAGECONFIG:append:evb-2u-egs = " use-lamp-test"

do_install:append:evb-2u-egs() {
        install -m 0644 ${UNPACKDIR}/led-group-config.json ${D}${datadir}/phosphor-led-manager/
}
