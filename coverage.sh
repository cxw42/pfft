#!/bin/bash
set -x
set -eEuo pipefail
./bootstrap
./configure --enable-code-coverage USER_VALAFLAGS='-g' CFLAGS='-g -O0' "$@"
make -j4 check-code-coverage
