#!/bin/sh

#exec > /tmp/wisq/sdx32.log
#exec 2>&1
. ~/.path
exec mix sdx32.dev "$@"
