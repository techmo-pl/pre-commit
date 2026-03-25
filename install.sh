#!/bin/bash

# install.sh
#
# The installation script for pre-commit hooks that installs them
# in a repository within a current working path.
#
# Usage:
#   install [--config CONFIG] [--venv VENV]
#
# --config CONFIG
#   Path to a pre-commit configuration YAML file.
#   If set, the run script will use it as the default config.
#
# --venv VENV
#   Path to an existing Python virtualenv to install pre-commit into.
#   When provided, no isolated ./pre-commit/.venv is created and the
#   Python version check is skipped (the venv is assumed to satisfy the
#   pre-commit requirement for its Python version).
#   If omitted, a new isolated venv is created at ./pre-commit/.venv.
#
# Python version support:
#   Python 3.10+ → pre-commit 4.x  (requirements.txt)
#   Python 3.9   → pre-commit 3.x  (requirements-py39.txt)
#   Python 3.8   → pre-commit 2.x  (requirements-py38.txt,
#                                    .pre-commit-config-py38.yaml)

set -euo pipefail

custom_config=""
external_venv=""
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
        --venv=*)
            external_venv="${1#--venv=}"
            shift
            ;;
        --venv)
            if [[ $# -lt 2 ]]; then
                echo >&2 "Error: --venv requires a value"
                exit 1
            fi
            external_venv="${2}"
            shift 2
            ;;
        *)
            echo >&2 "Error: unknown argument '${1}'"
            exit 1
            ;;
    esac
done

precommit_root="$(cd "$(dirname "${0}")" && pwd)"

# Select the requirements file appropriate for the given Python minor version.
_requirements_for_minor()
{
    local minor="$1"
    if [ "${minor}" -ge 10 ]; then
        echo "${precommit_root}/requirements.txt"
    elif [ "${minor}" -eq 9 ]; then
        echo "${precommit_root}/requirements-py39.txt"
    else
        echo "${precommit_root}/requirements-py38.txt"
    fi
}

# Select the default pre-commit config for the given Python minor version.
# Python 3.8 uses a dedicated variant (older mypy, ruff py38 target).
# An explicit --config flag always takes precedence.
_config_for_minor()
{
    local minor="$1"
    if [ -n "${custom_config}" ]; then
        echo "${custom_config}"
    elif [ "${minor}" -le 8 ]; then
        echo "${precommit_root}/.pre-commit-config-py38.yaml"
    else
        echo "${precommit_root}/.pre-commit-config.yaml"
    fi
}

# Allow tests to source this file for function access only (no main body executed).
[[ ${INSTALL_SH_SOURCE_ONLY:-} == "1" ]] && return 0

if [ -n "${external_venv}" ]; then
    if [ ! -d "${external_venv}" ]; then
        echo >&2 "Error: provided venv '${external_venv}' does not exist"
        exit 1
    fi
    venv_path="$(cd "${external_venv}" && pwd)"
    venv_is_managed=false

    # Detect the Python version inside the external venv to pick the right
    # requirements file and default config.
    venv_python="${venv_path}/bin/python"
    [ -x "${venv_python}" ] || venv_python="${venv_path}/bin/python3"
    python_minor=$("${venv_python}" -c 'import sys; print(sys.version_info.minor)')
    requirements_file="$(_requirements_for_minor "${python_minor}")"
    precommit_config="$(_config_for_minor "${python_minor}")"
else
    # Search for the highest available Python version (3.8+).
    # pre-commit 4.x requires 3.10+, 3.x requires 3.9+, 2.x requires 3.7+.
    python_cmd=""
    for candidate in python3.14 python3.13 python3.12 python3.11 python3.10 python3.9 python3.8 python3; do
        if command -v "${candidate}" &> /dev/null; then
            if "${candidate}" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' 2> /dev/null; then
                python_cmd="${candidate}"
                break
            fi
        fi
    done

    if [ -z "${python_cmd}" ]; then
        echo >&2 "Error: Python 3.8+ is required but not found"
        exit 1
    fi

    echo "Using ${python_cmd} ($(${python_cmd} -c 'import sys; print(".".join(map(str, sys.version_info[:3])))'))"

    python_minor=$("${python_cmd}" -c 'import sys; print(sys.version_info.minor)')
    requirements_file="$(_requirements_for_minor "${python_minor}")"
    precommit_config="$(_config_for_minor "${python_minor}")"
    python_bin="$(command -v "${python_cmd}")"
    venv_path="${precommit_root}/.venv"
    venv_is_managed=true
fi

_cleanup_on_err()
{
    if [ "${venv_is_managed}" = "true" ]; then
        rm -fr "${venv_path}" "${precommit_root}/.pre-commit-config.path"
    fi
}
trap _cleanup_on_err ERR

echo "precommit_config=\"${precommit_config}\"" > "${precommit_root}/.pre-commit-config.path"
echo "precommit_venv=\"${venv_path}\"" >> "${precommit_root}/.pre-commit-config.path"

echo "pre-commit will be using ${precommit_config}"

if [ "${venv_is_managed}" = "true" ]; then
    if command -v uv &> /dev/null; then
        # Pass the full path so uv uses the exact verified interpreter, not its own discovery
        uv venv --clear --python "${python_bin}" "${venv_path}"
    else
        "${python_cmd}" -m venv "${venv_path}"
    fi
fi

# shellcheck disable=SC1091
source "${venv_path}/bin/activate"

if command -v uv &> /dev/null; then
    uv pip install --quiet -r "${requirements_file}"
else
    pip install --quiet --no-input --upgrade pip
    pip install --quiet --no-input -r "${requirements_file}"
fi

pre-commit install --config="${precommit_config}"
