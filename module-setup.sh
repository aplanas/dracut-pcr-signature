#!/bin/bash

# Prerequisite check(s) for module.
check() {
    # Return 255 to only include the module, if another module requires it.
    return 0
}

depends() {
    return 0
}

installkernel() {
    inst_multiple mountpoint rmdir dd tr mktemp
    # Filesystem (vfat) and codepages required to mount the ESP
    hostonly="" instmods vfat nls_cp437 nls_iso8859-1 nls_utf8
}

install() {
    inst_script "${moddir}/pcr-signature.sh" /usr/bin/pcr-signature.sh
    # There is a cryptsetup-pre.target that can be used, but is not
    # easy execute the service when the ESP device is ready and the
    # systemd-cryptsetup service was still not executed
    # (cryptsetup.target).  One solution is to use a generator, that
    # will after/requires from dev-disk-by-partuuid-XXX, where XXX
    # comes from LoaderDevicePartUUID efivar.  The other option is an
    # override (this one).
    inst_simple "${moddir}/pcr-signature.conf" "/etc/systemd/system/systemd-cryptsetup@.service.d/pcr-signature.conf"
}
