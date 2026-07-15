#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
export OBRA_PLATFORM_NAME="Bazzite Linux"
# shellcheck source=../common/install-linux-common.sh
# shellcheck source-path=SCRIPTDIR
source "$SCRIPT_DIR/../common/install-linux-common.sh"

install_for_linux "$@"
