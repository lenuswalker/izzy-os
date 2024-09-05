#!/usr/bin/env bash

set -ouex pipefail

# Create devbox
mkdir -p /opt/distrobox/home/devbox
distrobox create --name devbox --image ghcr.io/lenuswalker/devbox --yes --home /opt/distrobox/home/devbox