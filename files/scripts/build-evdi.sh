#!/bin/bash

set -ouex pipefail

/files/scripts/kernel-modules build
/files/scripts/kernel-modules load