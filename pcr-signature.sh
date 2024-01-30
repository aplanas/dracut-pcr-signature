#!/bin/bash

MNT="/tmp/pcr-signature"
# Maybe a better place is loader/credentials
SYSTEMD="EFI/systemd"
VENDOR="4a67b082-0a4c-41cf-b6c7-440b29bb8c4f"
EFIVAR="/sys/firmware/efi/efivars/LoaderDevicePartUUID-$VENDOR"

cleanup()
{
    is_mount "$MNT" && umount "$MNT"
    rmdir "$MNT"
}
trap cleanup EXIT

is_mount() {
    grep -q "$1" /proc/mounts
}

mount_esp() {
    [ -e "$EFIVAR" ] || return 0
    mount "$DEV" "$MNT"
    [ -e "${MNT}/${SYSTEMD}" ] && return 0
    umount "$MNT"
}

read_efivar() {
    local var="$1"
    local val

    # Read the value of the EFI variable, that contains a header and
    # ends with '\0' and make it lowercase
    read -r val < "$var"
    val="${val:1}"
    echo "${val,,}"
}

DEV="/dev/disk/by-partuuid/$(read_efivar "$EFIVAR")"

mkdir -p "$MNT"

mount_esp

if is_mount "$MNT"; then
    if [ -e "${MNT}/${SYSTEMD}/pcrlock.json" ]; then
	mkdir -p /var/lib/systemd
	cp "${MNT}/${SYSTEMD}/pcrlock.json" /var/lib/systemd
    elif [ -e "${MNT}/${SYSTEMD}/tpm2-pcr-signature.json" ] && [ -e "${MNT}/${SYSTEMD}/tpm2-pcr-public-key.pem" ]; then
	mkdir -p /etc/systemd
	cp "${MNT}/${SYSTEMD}/tpm2-pcr-signature.json" /etc/systemd
	cp "${MNT}/${SYSTEMD}/tpm2-pcr-public-key.pem" /etc/systemd
    fi
fi

is_mount "$MNT" && umount "$MNT"
