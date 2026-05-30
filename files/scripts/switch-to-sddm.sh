#!/usr/bin/env bash
#
# Switch the display manager from GDM (the Silverblue default) to SDDM, which
# launches the uwsm-managed Hyprland session.
#
# Done in a script rather than the bluebuild `systemd` module so the order is
# deterministic: GDM must be disabled (which removes the display-manager.service
# alias) *before* SDDM is enabled, otherwise `systemctl enable sddm.service`
# fails with "File exists" on the alias and breaks the build.
#
set -oue pipefail

# Drop GDM. Disabling removes its unit symlinks, including the
# display-manager.service alias; remove it explicitly too, just in case.
systemctl disable gdm.service 2>/dev/null || true
rm -f /etc/systemd/system/display-manager.service

# Enable SDDM (recreates display-manager.service -> sddm.service) and ensure the
# greeter user exists before SDDM starts.
systemctl enable sddm.service
systemctl enable omarchy-sddm-useradd.service
