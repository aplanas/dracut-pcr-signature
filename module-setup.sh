#!/bin/bash

# Prerequisite check(s) for module.
check() {
    # Return 255 to only include the module, if another module requires it.
    return 0
}

installkernel() {
    # Filesystem (vfat) and codepages required to mount the ESP
    hostonly="" instmods vfat nls_cp437 nls_iso8859-1 nls_utf8
}

install() {
    inst_multiple mountpoint rmdir dd tr mktemp
    inst_script "$moddir/pcr-signature.sh" /usr/bin/pcr-signature.sh
    # There is a cryptsetup-pre.target that can be used, but is not
    # easy execute the service when the ESP device is ready and the
    # systemd-cryptsetup service was still not executed
    # (cryptsetup.target).  The solution is to use a generator, that
    # will after/requires from dev-disk-by-partuuid-XXX, where XXX
    # comes from LoaderDevicePartUUID efivar.
    inst_script "$moddir/boot-efi-generator.sh" /usr/lib/systemd/system-generators/boot-efi-generator
    inst_simple "$moddir/pcr-signature.service" "$systemdsystemunitdir/pcr-signature.service"
    $SYSTEMCTL -q --root "$initdir" enable pcr-signature.service
}
