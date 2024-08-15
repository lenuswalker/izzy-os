#!/bin/bash

set -ouex pipefail

/tmp/files/scripts/kernel-modules build
/tmp/files/scripts/kernel-modules load