#!/bin/bash
# t/071-core-writer-emit.sh - test My.Writer.emit("-", "...")

set -eEuo pipefail

here="$(cd "$(dirname "$0")" &>/dev/null ; pwd)"
retval=

echo '1..1'

if "$here/071-core-writer-emit-t" 'emit' | grep -q -E '^magicmessage$' ; then
    echo 'ok 1'
    retval=0
else
    echo 'not ok 1'
    retval=1
fi

exit "$retval"
