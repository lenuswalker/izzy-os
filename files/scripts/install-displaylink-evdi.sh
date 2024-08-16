#!/bin/bash

set -ouex pipefail

/tmp/files/scripts/github-release-install.sh displaylink-rpm/displaylink-rpm x86_64 fedora-$(rpm -E %fedora)

rpm-ostree uninstall make gcc glibc-devel openssl-devel zlib-ng-compat-devel libxcrypt-devel libzstd-devel perl-base