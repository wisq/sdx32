#!/bin/sh

export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin
export MIX_ENV=dev
test -t 0 || exec > dev.log 2>&1
exec mix sdx32.dev "$@"
