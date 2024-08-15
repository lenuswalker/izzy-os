#!/bin/bash

set -ouex pipefail

/tmp/files/scripts/kernel-modules.sh build
/tmp/files/scripts/kernel-modules.sh load