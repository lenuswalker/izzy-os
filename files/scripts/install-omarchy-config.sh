#!/usr/bin/env bash
#
# Installs the Omarchy desktop configuration into the image.
#
# Omarchy (https://github.com/basecamp/omarchy) is DHH's opinionated Arch/Hyprland
# setup. "omadora" (https://github.com/matoval/omadora) is a faithful Fedora
# adaptation of it. We vendor omadora's config tree because it already maps the
# Omarchy look-and-feel (Hyprland config, Waybar, themes, keybindings and the
# omarchy-* helper commands / menu) onto Fedora.
#
# Strategy for an atomic/immutable image:
#   * Vendor the omadora tree read-only into /usr/share/omadora
#   * Expose its `omarchy-*` helper commands on PATH via /usr/bin symlinks
#   * Seed /etc/skel so every newly created user inherits the Omarchy desktop
#
# Exit on any error so a broken build never ships a half-configured image.
set -oue pipefail

OMADORA_REPO="${OMADORA_REPO:-https://github.com/matoval/omadora}"
OMADORA_REF="${OMADORA_REF:-master}"
DEST="/usr/share/omadora"
SKEL="/etc/skel"
DEFAULT_THEME="tokyo-night"

echo "Cloning omadora (${OMADORA_REF}) from ${OMADORA_REPO} into ${DEST}..."
rm -rf "${DEST}"
git clone --depth 1 --branch "${OMADORA_REF}" "${OMADORA_REPO}" "${DEST}"
rm -rf "${DEST}/.git"

# Make the vendored tree world-readable/traversable.
chmod -R a+rX "${DEST}"

# ----------------------------------------------------------------------------
# Expose the omarchy-* helper commands system-wide.
# ----------------------------------------------------------------------------
if [ -d "${DEST}/bin" ]; then
  for bin in "${DEST}/bin/"*; do
    [ -f "${bin}" ] || continue
    name="$(basename "${bin}")"
    chmod a+rx "${bin}"
    ln -sf "${DEST}/bin/${name}" "/usr/bin/${name}"
  done
fi

# ----------------------------------------------------------------------------
# Seed /etc/skel with the Omarchy configuration for every new user.
#
# All symlinks point at the read-only /usr/share/omadora tree (absolute paths),
# so they resolve correctly in any user's home directory.
# ----------------------------------------------------------------------------
mkdir -p "${SKEL}/.local/share" "${SKEL}/.config"

# Configs + the omarchy-* commands source from ~/.local/share/omadora.
ln -sfn "${DEST}" "${SKEL}/.local/share/omadora"

# User-editable config from the omadora `config/` tree.
cp -R "${DEST}/config/." "${SKEL}/.config/"

# Default shell rc.
if [ -f "${DEST}/default/bashrc" ]; then
  cp "${DEST}/default/bashrc" "${SKEL}/.bashrc"
fi

# Theme links. These mirror what omadora's installer sets up at first run.
# omarchy-theme-* relinks them when the user switches themes.
mkdir -p "${SKEL}/.config/omadora/themes" "${SKEL}/.config/omadora/current"
for theme in "${DEST}/themes/"*/; do
  [ -d "${theme}" ] || continue
  tname="$(basename "${theme}")"
  ln -sfn "${DEST}/themes/${tname}" "${SKEL}/.config/omadora/themes/${tname}"
done
ln -sfn "${DEST}/themes/${DEFAULT_THEME}" "${SKEL}/.config/omadora/current/theme"

# First wallpaper shipped with the default theme.
bg="$(find "${DEST}/themes/${DEFAULT_THEME}/backgrounds" -type f \
  \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null | sort | head -n1 || true)"
if [ -n "${bg}" ]; then
  ln -sfn "${bg}" "${SKEL}/.config/omadora/current/background"
fi

# Per-app theme links used by omadora.
if [ -d "${SKEL}/.config/nvim/lua/plugins" ]; then
  ln -sfn "${DEST}/themes/${DEFAULT_THEME}/neovim.lua" "${SKEL}/.config/nvim/lua/plugins/theme.lua"
fi
mkdir -p "${SKEL}/.config/btop/themes"
ln -sfn "${DEST}/themes/${DEFAULT_THEME}/btop.theme" "${SKEL}/.config/btop/themes/current.theme"
mkdir -p "${SKEL}/.config/mako"
ln -sfn "${DEST}/themes/${DEFAULT_THEME}/mako.ini" "${SKEL}/.config/mako/config"

echo "Omarchy (omadora) configuration installed into ${DEST} and seeded to ${SKEL}."
