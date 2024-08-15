#!/bin/bash

set -ouex pipefail

./kernel-modules build
./kernel-modules load