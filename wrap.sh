#!/bin/sh

. "$( dirname "$( readlink -e "$0" )" )/../ca-profile"

set -x

"$@"
