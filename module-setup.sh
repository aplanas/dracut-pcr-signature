#!/bin/bash

# Prerequisite check(s) for module.
check() {
    # Return 255 to only include the module, if another module requires it.
    if [ -n "$hostonly" ]; then
        if ! [ -d /sys/class/tpmrm ] || [ -z "$(ls -A /sys/class/tpmrm)" ]; then
            return 255
        fi

        # Only a BLS boot loader (systemd-boot or grub2-bls) drops the
        # pcrlock.json in the ESP, so the module is useless when the
        # system boots with a different one, like the classic grub2-efi.
        # The package can still be installed there, as sdbootutil
        # requires it, but the module is not added to the initrd.
        if [ -e /etc/sysconfig/bootloader ]; then
            local loader_type
            # shellcheck disable=SC1091
            loader_type="$(. /etc/sysconfig/bootloader &> /dev/null; echo "$LOADER_TYPE")"
            case "$loader_type" in
                systemd-boot | grub2-bls | "") ;;
                *) return 255 ;;
            esac
        fi
    fi

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
    inst_script "$moddir/sysefi-generator.sh" /usr/lib/systemd/system-generators/sysefi-generator
    inst_simple "$moddir/pcr-signature.service" "$systemdsystemunitdir/pcr-signature.service"
    $SYSTEMCTL -q --root "$initdir" enable pcr-signature.service
}
