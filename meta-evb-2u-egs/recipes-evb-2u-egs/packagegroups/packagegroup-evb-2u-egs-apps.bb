SUMMARY = "OpenBMC for evb-2u-egs - Applications"

PR = "r1"

inherit packagegroup

PROVIDES = "${PACKAGES}"
PACKAGES = " \
    ${PN}-chassis \
    ${PN}-fans \
    ${PN}-flash \
    ${PN}-system \
    "

PROVIDES += " virtual/obmc-chassis-mgmt"
PROVIDES += " virtual/obmc-fan-mgmt"
PROVIDES += " virtual/obmc-flash-mgmt"
PROVIDES += " virtual/obmc-system-mgmt"

RPROVIDES:${PN}-chassis = " virtual-obmc-chassis-mgmt"
RPROVIDES:${PN}-fans = " virtual-obmc-fan-mgmt"
RPROVIDES:${PN}-flash = " virtual-obmc-flash-mgmt"
RPROVIDES:${PN}-system = " virtual-obmc-system-mgmt"

SUMMARY:${PN}-chassis = "evb-2u-egs Chassis"
RDEPENDS:${PN}-chassis = " \
    x86-power-control \
    "

SUMMARY:${PN}-fans = "evb-2u-egs Fans"
RDEPENDS:${PN}-fans = " \
    phosphor-pid-control \
    "

SUMMARY:${PN}-flash = "evb-2u-egs Flash"
RDEPENDS:${PN}-flash = " \
    phosphor-software-manager \
    "

SUMMARY:${PN}-system = "evb-2u-egs System"
RDEPENDS:${PN}-system = " \
    phosphor-ipmi-ipmb \
    phosphor-hostlogger \
    phosphor-sel-logger \
    ipmitool \
    phosphor-post-code-manager \
    phosphor-host-postd \
    phosphor-watchdog \
    phosphor-virtual-sensor \
    "
