#!/bin/bash
set -euo pipefail

if [ -e "/run/systemd/pcrlock.json" ]; then
    echo "pcr-signature: signature file already present"
    exit 0
fi

# Link to /usr/lib/initrd-release
# shellcheck disable=SC1091
. /etc/os-release
# shellcheck disable=SC2153
name="${NAME% *}"
name="${name,,}"

for location in "/sysefi/EFI/systemd" "/sysefi/EFI/$name"; do
    if [ -e "${location}/pcrlock.json" ]; then
	mkdir -p /run/systemd
	cp "${location}/pcrlock.json" /run/systemd
	break
    fi
done

for location in "/sysefi/EFI/systemd" "/sysefi/EFI/$name"; do
    if [ -e "${location}/measure-pcr-prediction" ]; then
	# This directory should be already present, and contains the
	# public key
	mkdir -p /var/lib/sdbootutil
	cp "${location}/measure-pcr-prediction" /var/lib/sdbootutil
	[ -e "${location}/measure-pcr-prediction.sha256" ] && cp "${location}/measure-pcr-prediction.sha256" /var/lib/sdbootutil
    fi
done
