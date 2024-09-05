#!/usr/bin/env bash

set -ouex pipefail

wget "https://vault.bitwarden.com/download/?app=cli&platform=linux" -O /tmp/bitwarden.zip
unzip /tmp/bitwarden.zip -d /tmp
chmod u+x /tmp/bw
if [ ! -d /usr/local/bin ]; then
    mkdir -p /usr/local/bin
fi
mv /tmp/bw /usr/local/bin/bw