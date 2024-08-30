#!/bin/bash

set -ouex pipefail

wget "https://vault.bitwarden.com/download/?app=cli&platform=linux" -O /tmp/bitwarden.zip

unzip /tmp/bitwarden.zip -d /tmp

chmod u+x /tmp/bw

mv /tmp/bw /usr/local/bw