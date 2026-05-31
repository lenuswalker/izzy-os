#!/usr/bin/env bash
#
# Vendors the Omarchy desktop configuration into the image.
#
# Uses elpritchos/omadora -- an *actively maintained* Fedora adaptation of
# Basecamp's Omarchy whose config tracks current Hyprland (0.55.x, via the
# sdegler/hyprland COPR installed in omarchy-packages.yml). The other Fedora
# port (matoval/omadora) is abandoned (Aug 2025 / Hyprland 0.51) and its config
# throws dispatcher errors on current Hyprland.
#
# Strategy (atomic image):
#   * Vendor the omadora tree read-only into /usr/share/omadora
#   * Expose its omadora-* helper commands on PATH via /usr/bin symlinks
#   * The actual per-user config is applied at session start by
#     /usr/libexec/omarchy-session-start (so existing accounts get it too).
# A build-time smoke test runs the theme generator to fail the build early if
# the (pure bash/sed) templating ever breaks.
#
set -oue pipefail

OMADORA_REPO="${OMADORA_REPO:-https://github.com/elpritchos/omadora}"
OMADORA_REF="${OMADORA_REF:-master}"
DEST="/usr/share/omadora"

echo "Cloning omadora (${OMADORA_REF}) from ${OMADORA_REPO} into ${DEST}..."
rm -rf "${DEST}"
git clone --depth 1 --branch "${OMADORA_REF}" "${OMADORA_REPO}" "${DEST}"
rm -rf "${DEST}/.git"
chmod -R a+rX "${DEST}"

# Expose the omadora-* helper commands system-wide.
if [ -d "${DEST}/bin" ]; then
  for bin in "${DEST}/bin/"*; do
    [ -f "${bin}" ] || continue
    name="$(basename "${bin}")"
    chmod a+rx "${bin}"
    ln -sf "${DEST}/bin/${name}" "/usr/bin/${name}"
  done
fi

# ----------------------------------------------------------------------------
# Build-time smoke test: prove the theme generator works on this image, so a
# broken template never ships silently. Runs in a throwaway HOME and is deleted.
# ----------------------------------------------------------------------------
echo "Smoke-testing omadora theme generation..."
smoke="$(mktemp -d)"
(
  export HOME="${smoke}"
  export OMADORA_PATH="${DEST}"
  export PATH="${DEST}/bin:${PATH}"
  mkdir -p "${HOME}/.config/omadora/themes"
  cp -R "${DEST}/config/." "${HOME}/.config/" 2>/dev/null || true
  # restart-/gnome hooks are no-ops without a session; ignore their exit codes.
  timeout 120 omadora-theme-set "Rose Pine Darker" >/dev/null 2>&1 || true
)
if [ ! -f "${smoke}/.config/omadora/current/theme/hyprland.conf" ]; then
  echo "ERROR: omadora theme generation did not produce current/theme/hyprland.conf" >&2
  rm -rf "${smoke}"
  exit 1
fi
rm -rf "${smoke}"
echo "Theme generation OK. omadora installed at ${DEST}."
