#!/bin/bash
set -euo pipefail

# If GRUB2 is used, bli.mod needs to be loaded
EFIVAR="/sys/firmware/efi/efivars/LoaderDevicePartUUID-4a67b082-0a4c-41cf-b6c7-440b29bb8c4f"

[ -e "$EFIVAR" ] || exit 0

if [ -e "/var/lib/systemd/pcrlock.json" ] || [ -e "/etc/systemd/tpm2-pcr-signature.json" ]; then
	# Already ran?
	exit 0
fi

# Read the value of the EFI variable, that contains a header and
# ends with '\0' and make it lowercase
ESP_UUID="$(dd "if=$EFIVAR" bs=2 skip=2 conv=lcase status=none | tr -d '\0')"
DEV="/dev/disk/by-partuuid/${ESP_UUID}"
MNT="$(mktemp -d)"

cleanup()
{
	if mountpoint -q "$MNT"; then
		umount "$MNT"
	fi
	rmdir "$MNT"
}
trap cleanup EXIT

mount -o ro "$DEV" "$MNT"

for location in "${MNT}/EFI/systemd" "${MNT}/EFI/opensuse"; do
	if [ -e "${location}/pcrlock.json" ]; then
		mkdir -p /var/lib/systemd
		cp "${location}/pcrlock.json" /var/lib/systemd
		break
	elif [ -e "${location}/tpm2-pcr-signature.json" ] && [ -e "${location}/tpm2-pcr-public-key.pem" ]; then
		mkdir -p /etc/systemd
		cp "${location}/tpm2-pcr-signature.json" /etc/systemd
		cp "${location}/tpm2-pcr-public-key.pem" /etc/systemd
		break
	fi
done
