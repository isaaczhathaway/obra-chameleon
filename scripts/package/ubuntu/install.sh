#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
export OBRA_PLATFORM_NAME="Ubuntu Linux"
# shellcheck source=../common/install-linux-common.sh
# Resolved relative to this wrapper at runtime.
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/install-linux-common.sh"

install_for_linux "$@"
