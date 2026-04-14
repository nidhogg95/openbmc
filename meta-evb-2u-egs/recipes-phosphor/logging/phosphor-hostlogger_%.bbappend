# Fix: template unit hostlogger@.service cannot be 'systemctl enable'd
# during rootfs postinst (systemd rejects enable on template units).
# Override SYSTEMD_SERVICE to list only the concrete instance so the
# enable succeeds.  The template .service file is still installed by
# upstream do_install; we ship it via FILES so the installed-vs-shipped
# QA check passes.
SYSTEMD_SERVICE:${PN} = "hostlogger@ttyVUART0.service"
FILES:${PN} += "${systemd_system_unitdir}/hostlogger@.service"
