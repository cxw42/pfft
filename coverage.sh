#!/bin/bash
set -x
set -eEuo pipefail

# Reconfigure if necessary so that coverage is enabled
if [[ ! -x ./config.status ]] || \
        ! ./config.status --config | grep -- '--enable-code-coverage'
then
    ./bootstrap
    ./configure --enable-code-coverage USER_VALAFLAGS='-g' CFLAGS='-g -O0' "$@"
fi

# Clean up from old runs, e.g., test runs of ./src/pfft compiled with
# coverage turned on.
make -j4 remove-code-coverage-data

# Check it
make -j4 check-code-coverage
