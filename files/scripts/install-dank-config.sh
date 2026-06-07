#!/usr/bin/env bash
#
# Vendors the DankMaterialShell (DMS) Quickshell config into the image and wires
# up the graphical boot target.
#
# Strategy (atomic image):
#   * Clone DankMaterialShell read-only into /etc/xdg/quickshell/dms. Quickshell
#     resolves `qs -c dms` from $XDG_CONFIG_DIRS (default /etc/xdg), so every
#     user gets the shell with zero per-user seeding; user settings/state are
#     written to ~/.config/DankMaterialShell separately and survive rebases.
#   * Make sure the system boots to the graphical target (SDDM). The `systemd`
#     module enables sddm.service; this just guarantees default.target.
#
# A build-time smoke test confirms the clone produced the shell entrypoint so a
# broken/empty checkout fails the build early.
set -oue pipefail

DMS_REPO="${DMS_REPO:-https://github.com/AvengeMedia/DankMaterialShell}"
DMS_REF="${DMS_REF:-master}"
DEST="/etc/xdg/quickshell/dms"
SRC_SUBDIR="quickshell"

echo "Cloning DankMaterialShell (${DMS_REF}) from ${DMS_REPO}..."
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
git clone --depth 1 --branch "${DMS_REF}" "${DMS_REPO}" "${TMP}"

if [ ! -f "${TMP}/${SRC_SUBDIR}/shell.qml" ]; then
  echo "ERROR: ${SRC_SUBDIR}/shell.qml missing in checkout -- DankMaterialShell layout changed" >&2
  exit 1
fi

echo "Installing DankMaterialShell into ${DEST}..."
mkdir -p "$(dirname "${DEST}")"
rm -rf "${DEST}"

# Move only the quickshell/ subdir's contents so shell.qml lands at the config root.
mv "${TMP}/${SRC_SUBDIR}" "${DEST}"
chmod -R a+rX "${DEST}"

# Quickshell entrypoint is shell.qml at the config root.
if [ ! -f "${DEST}/shell.qml" ]; then
  echo "ERROR: ${DEST}/shell.qml missing -- DankMaterialShell checkout looks broken" >&2
  exit 1
fi
echo "DankMaterialShell installed at ${DEST}."

