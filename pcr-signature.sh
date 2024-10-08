#!/bin/bash
set -euo pipefail

# If GRUB2 is used, bli.mod needs to be loaded
EFIVAR="/sys/firmware/efi/efivars/LoaderDevicePartUUID-4a67b082-0a4c-41cf-b6c7-440b29bb8c4f"

[ -e "$EFIVAR" ] || exit 0

# Avoid race condition when multiple disks are encrypted
if [ -e "/run/systemd/pcrlock.json" ] || [ -e "/run/systemd/tpm2-pcr-signature.json" ]; then
    echo "pcr-signature: signature file already present"
    exit 0
fi

# Read the value of the EFI variable, that contains a header and ends
# with '\0' and make it lowercase
ESP_UUID="$(dd "if=$EFIVAR" bs=2 skip=2 conv=lcase status=none | tr -d '\0')"
DEV="/dev/disk/by-partuuid/${ESP_UUID}"
MNT="$(mktemp -d)"

cleanup()
{
    if mountpoint -q "$MNT"; then
	umount "$MNT" || {
	    echo "pcr-signature: unable to umount ESP"
	    exit 0
	}
    fi
    rmdir "$MNT"
}
trap cleanup EXIT

mount -o ro "$DEV" "$MNT" || {
    echo "pcr-signature: unable to mount ESP"
    exit 0
}

for location in "${MNT}/EFI/systemd" "${MNT}/EFI/opensuse"; do
    if [ -e "${location}/pcrlock.json" ]; then
	mkdir -p /run/systemd
	cp "${location}/pcrlock.json" /run/systemd
	break
    elif [ -e "${location}/tpm2-pcr-signature.json" ] && [ -e "${location}/tpm2-pcr-public-key.pem" ]; then
	mkdir -p /run/systemd
	cp "${location}/tpm2-pcr-signature.json" /run/systemd
	cp "${location}/tpm2-pcr-public-key.pem" /run/systemd
	break
    fi
done
