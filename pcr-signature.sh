#!/bin/bash
set -euo pipefail

if [ -e "/run/systemd/pcrlock.json" ] || [ -e "/run/systemd/tpm2-pcr-signature.json" ]; then
    echo "pcr-signature: signature file already present"
    exit 0
fi

for location in "/boot/efi/EFI/systemd" "/boot/efi/EFI/opensuse"; do
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
