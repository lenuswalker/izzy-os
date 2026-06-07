# izzy-os &nbsp; [![bluebuild build badge](https://github.com/lenuswalker/izzy-os/actions/workflows/build.yml/badge.svg)](https://github.com/lenuswalker/izzy-os/actions/workflows/build.yml)

See the [BlueBuild docs](https://blue-build.org/how-to/setup/) for quick setup instructions for setting up your own repository based on this template.

After setup, it is recommended you update this README to describe your custom image.

## Images

This repo builds several images. Notably:

- **`izzy-os-omarchy`** — an atomic Fedora image for the Dell XPS 13 that mimics
  [Omarchy](https://github.com/basecamp/omarchy) (DHH's opinionated Arch/Hyprland
  setup). It builds on `ghcr.io/ublue-os/silverblue-main`, layers the Hyprland
  0.55 ecosystem from the `sdegler/hyprland` COPR, keeps GDM as the (Wayland)
  display manager listing a uwsm-managed Hyprland session, and vendors the
  [omadora](https://github.com/elpritchos/omadora) configuration (an actively
  maintained Fedora adaptation of Omarchy) into `/usr/share/omadora`. The
  config + theme are applied into each user's home at first Hyprland login (so
  existing/rebased accounts get it too), along with the `omadora-*` helper
  commands. Defined in [`recipes/recipe-omarchy.yml`](recipes/recipe-omarchy.yml).

- **`izzy-os-dank`** — a light, **GNOME-free** atomic Fedora image for the Dell
  XPS running [Hyprland](https://hypr.land) with the
  [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (DMS)
  Quickshell desktop. It builds on the minimal `ghcr.io/ublue-os/base-main`
  (no desktop environment), layers the full Hyprland 0.55 stack from the
  `lionheartp/Hyprland` COPR, and pulls DMS and its dependencies (quickshell,
  matugen, dgop, danksearch, cliphist, material-symbols-fonts, ghostty) from the
  `avengemedia/danklinux` COPR. [SDDM](https://github.com/sddm/sddm) is the
  display manager. DMS is vendored system-wide into `/etc/xdg/quickshell/dms`
  (so `qs -c dms` / `dms run` works for every user with no per-user setup), and
  a default Hyprland config is seeded into each user's home at first login.
  Defined in [`recipes/recipe-dank.yml`](recipes/recipe-dank.yml).

## Installation

> **Warning**  
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.

To rebase an existing atomic Fedora installation to the latest build:

- First rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/lenuswalker/izzy-os:latest
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/lenuswalker/izzy-os:latest
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```

The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

## ISO

If build on Fedora Atomic, you can generate an offline ISO with the instructions available [here](https://blue-build.org/learn/universal-blue/#fresh-install-from-an-iso). These ISOs cannot unfortunately be distributed on GitHub for free due to large sizes, so for public projects something else has to be used for hosting.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/lenuswalker/izzy-os
```
