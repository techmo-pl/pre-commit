#!/bin/bash

# run.sh
#
# The run script for pre-commit hooks that performs pre-commit check
# in a repository within a current working path.
#
# Usage:
#   run [--config CONFIG]
#
# --config CONFIG
#   Path to a pre-commit configuration YAML file.
#   If set, the script will use it instead of the default one.

set -euo pipefail

custom_config=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --config=*)
            custom_config="${1#--config=}"
            shift
            ;;
        --config)
            if [[ $# -lt 2 ]]; then
                echo >&2 "Error: --config requires a value"
                exit 1
            fi
            custom_config="${2}"
            shift 2
            ;;
        *)
            echo >&2 "Error: unknown argument '${1}'"
            exit 1
            ;;
    esac
done

precommit_root="$(dirname "${0}")"

if [ ! -f "${precommit_root}/.pre-commit-config.path" ]; then
    echo >&2 "${0}: pre-commit not installed: run '${precommit_root}/install.sh' first"
    exit 1
fi

# Default to legacy isolated venv location for backward compatibility
# with installs that pre-date the VENV argument support.
precommit_venv="${precommit_root}/.venv"

# shellcheck disable=SC1091
source "${precommit_root}/.pre-commit-config.path"

if [ ! -d "${precommit_venv}" ]; then
    echo >&2 "${0}: pre-commit not installed: run '${precommit_root}/install.sh' first"
    exit 1
fi

# shellcheck disable=SC1091
source "${precommit_venv}/bin/activate"

pre-commit run --all-files --config="${custom_config:-${precommit_config}}"
