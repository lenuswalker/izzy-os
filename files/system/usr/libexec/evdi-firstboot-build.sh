#!/usr/bin/env bash
set -euo pipefail

STAMP="/var/lib/evdi-firstboot-build.done"
KERNEL="$(uname -r)"

mkdir -p /var/lib

if [[ -f "$STAMP" ]]; then
  exit 0
fi

echo "Building evdi for kernel ${KERNEL}..."
akmods --force --kernels "${KERNEL}" --akmod evdi

echo "Loading evdi module..."
modprobe evdi || true

echo "Restarting DisplayLink service..."
systemctl restart displaylink.service || true

touch "$STAMP"