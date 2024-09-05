#!/usr/bin/env bash

set -ouex pipefail

/tmp/files/scripts/github-release-install.sh displaylink-rpm/displaylink-rpm x86_64 fedora-$(rpm -E %fedora)