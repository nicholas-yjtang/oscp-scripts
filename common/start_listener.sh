#!/bin/bash
SCRIPTDIR=$(dirname "${BASH_SOURCE[0]}")
project=$1
host_port=$2
interactive=$3
if [[ ! -z "$interactive" ]]; then
    echo "Starting listener in interactive mode..."
    interactive_shell=true
fi
# shellcheck source=~/oscp/scripts/common/project.sh
source $SCRIPTDIR/project.sh
# shellcheck source=~/oscp/scripts/common/network.sh
source $SCRIPTDIR/network.sh
# shellcheck source=~/oscp/scripts/common/reverse_shell.sh
source $SCRIPTDIR/reverse_shell.sh
# shellcheck source=~/oscp/scripts/common/general.sh
source $SCRIPTDIR/general.sh
start_listener
