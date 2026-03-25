#!/usr/bin/env bats
# shellcheck shell=bash
#
# tests/install.bats — unit and integration tests for install.sh
#
# Unit tests source install.sh with INSTALL_SH_SOURCE_ONLY=1 so only the
# helper functions (_requirements_for_minor, _config_for_minor) are loaded
# without executing the main installation body.
#
# Integration tests invoke bash install.sh directly and rely on a stub PATH
# to exercise error-handling paths without touching real Python or pip.

SCRIPT="${BATS_TEST_DIRNAME}/../install.sh"
PRECOMMIT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"

# ---------------------------------------------------------------------------
# _source_helpers: load only the pure functions from install.sh
# ---------------------------------------------------------------------------

_source_helpers()
{
    # shellcheck disable=SC2034
    precommit_root="${PRECOMMIT_ROOT}"
    # shellcheck disable=SC1090
    INSTALL_SH_SOURCE_ONLY=1 source "${SCRIPT}"
    set +euo pipefail
}

setup()
{
    TEST_TMPDIR="$(mktemp -d)"
    export TEST_TMPDIR
}

teardown()
{
    rm -rf "${TEST_TMPDIR:-}"
}

# ===========================================================================
# _requirements_for_minor — pure function, no side effects
# ===========================================================================

@test "_requirements_for_minor: minor 7 → requirements-py38.txt" {
    _source_helpers
    result=$(_requirements_for_minor 7)
    [ "${result}" = "${PRECOMMIT_ROOT}/requirements-py38.txt" ]
}

@test "_requirements_for_minor: minor 8 → requirements-py38.txt" {
    _source_helpers
    result=$(_requirements_for_minor 8)
    [ "${result}" = "${PRECOMMIT_ROOT}/requirements-py38.txt" ]
}

@test "_requirements_for_minor: minor 9 → requirements-py39.txt" {
    _source_helpers
    result=$(_requirements_for_minor 9)
    [ "${result}" = "${PRECOMMIT_ROOT}/requirements-py39.txt" ]
}

@test "_requirements_for_minor: minor 10 → requirements.txt" {
    _source_helpers
    result=$(_requirements_for_minor 10)
    [ "${result}" = "${PRECOMMIT_ROOT}/requirements.txt" ]
}

@test "_requirements_for_minor: minor 11 → requirements.txt" {
    _source_helpers
    result=$(_requirements_for_minor 11)
    [ "${result}" = "${PRECOMMIT_ROOT}/requirements.txt" ]
}

@test "_requirements_for_minor: minor 12 → requirements.txt" {
    _source_helpers
    result=$(_requirements_for_minor 12)
    [ "${result}" = "${PRECOMMIT_ROOT}/requirements.txt" ]
}

@test "_requirements_for_minor: minor 13 → requirements.txt" {
    _source_helpers
    result=$(_requirements_for_minor 13)
    [ "${result}" = "${PRECOMMIT_ROOT}/requirements.txt" ]
}

@test "_requirements_for_minor: minor 14 → requirements.txt" {
    _source_helpers
    result=$(_requirements_for_minor 14)
    [ "${result}" = "${PRECOMMIT_ROOT}/requirements.txt" ]
}

# ===========================================================================
# _config_for_minor — depends on custom_config global
# ===========================================================================

@test "_config_for_minor: minor 8, no custom → py38 yaml" {
    _source_helpers
    custom_config=""
    result=$(_config_for_minor 8)
    [ "${result}" = "${PRECOMMIT_ROOT}/.pre-commit-config-py38.yaml" ]
}

@test "_config_for_minor: minor 9, no custom → main yaml" {
    _source_helpers
    custom_config=""
    result=$(_config_for_minor 9)
    [ "${result}" = "${PRECOMMIT_ROOT}/.pre-commit-config.yaml" ]
}

@test "_config_for_minor: minor 10, no custom → main yaml" {
    _source_helpers
    custom_config=""
    result=$(_config_for_minor 10)
    [ "${result}" = "${PRECOMMIT_ROOT}/.pre-commit-config.yaml" ]
}

@test "_config_for_minor: custom_config overrides minor 8" {
    _source_helpers
    # shellcheck disable=SC2034
    custom_config="/custom/hooks.yaml"
    result=$(_config_for_minor 8)
    [ "${result}" = "/custom/hooks.yaml" ]
}

@test "_config_for_minor: minor 14, no custom → main yaml" {
    _source_helpers
    custom_config=""
    result=$(_config_for_minor 14)
    [ "${result}" = "${PRECOMMIT_ROOT}/.pre-commit-config.yaml" ]
}

@test "_config_for_minor: custom_config overrides minor 10" {
    _source_helpers
    # shellcheck disable=SC2034
    custom_config="/custom/hooks.yaml"
    result=$(_config_for_minor 10)
    [ "${result}" = "/custom/hooks.yaml" ]
}

@test "_config_for_minor: custom_config overrides minor 14" {
    _source_helpers
    # shellcheck disable=SC2034
    custom_config="/custom/hooks.yaml"
    result=$(_config_for_minor 14)
    [ "${result}" = "/custom/hooks.yaml" ]
}

# ===========================================================================
# install.sh integration — external venv validation
# ===========================================================================

@test "install.sh: missing external venv dir exits 1 with error message" {
    run bash "${SCRIPT}" --venv "/nonexistent/venv/path/$$"
    [ "${status}" -eq 1 ]
    [[ "${output}" =~ "does not exist" ]]
}

# ===========================================================================
# install.sh integration — managed venv / python discovery
# ===========================================================================

@test "install.sh: no python executables in PATH exits 1 with error message" {
    local stub_dir="${TEST_TMPDIR}/stubs_nopy"
    mkdir -p "${stub_dir}"
    # Provide dirname so precommit_root resolution works, but no Python.
    cat > "${stub_dir}/dirname" << 'STUB'
#!/bin/bash
# Minimal dirname: strip last path component.
p="${1}"
[ -z "${p}" ] && printf '.\n' && exit 0
r="${p%/*}"
[ "${r}" = "${p}" ] && r="."
printf '%s\n' "${r}"
STUB
    chmod +x "${stub_dir}/dirname"
    # Use /bin/bash explicitly so env doesn't search for bash in the stub PATH.
    # PATH contains only our stub dir — no Python candidates are discoverable.
    run env PATH="${stub_dir}" /bin/bash "${SCRIPT}"
    [ "${status}" -eq 1 ]
    local pattern="Python 3.8[+] is required"
    [[ "${output}" =~ ${pattern} ]]
}

@test "install.sh: all python versions fail version check exits 1" {
    local stub_dir="${TEST_TMPDIR}/stubs_badpy"
    mkdir -p "${stub_dir}"
    # Shadow every Python candidate with a stub that always fails the version check.
    for py in python3.7 python3.8 python3.9 python3.10 python3.11 python3.12 python3.13 python3.14 python3; do
        cat > "${stub_dir}/${py}" << 'STUB'
#!/bin/bash
exit 1
STUB
        chmod +x "${stub_dir}/${py}"
    done
    # Prepend stub dir so our stubs shadow any system Python while system
    # utilities (dirname, etc.) remain reachable via the rest of PATH.
    run env PATH="${stub_dir}:/usr/local/bin:/usr/bin:/bin" bash "${SCRIPT}"
    [ "${status}" -eq 1 ]
    local pattern="Python 3.8[+] is required"
    [[ "${output}" =~ ${pattern} ]]
}

@test "install.sh: uv venv called with --clear when venv already exists" {
    local stub_dir="${TEST_TMPDIR}/stubs_exist"
    mkdir -p "${stub_dir}"
    local venv_args_file="${TEST_TMPDIR}/uv_venv_args"

    # Stub python3.12 to simulate a discoverable Python 3.12.
    cat > "${stub_dir}/python3.12" << 'STUB'
#!/bin/bash
case "$*" in
    *"version_info >="*) exit 0 ;;
    *"version_info.minor"*) echo "12" ;;
    *) echo "3.12.0" ;;
esac
STUB
    chmod +x "${stub_dir}/python3.12"

    # Stub uv; record args when subcommand is "venv".
    cat > "${stub_dir}/uv" << STUB
#!/bin/bash
if [ "\${1}" = "venv" ]; then
    printf '%s\n' "\$@" > "${venv_args_file}"
fi
exit 0
STUB
    chmod +x "${stub_dir}/uv"

    # Stub pre-commit.
    cat > "${stub_dir}/pre-commit" << 'STUB'
#!/bin/bash
exit 0
STUB
    chmod +x "${stub_dir}/pre-commit"

    local venv_path="${PRECOMMIT_ROOT}/.venv"
    local path_file="${PRECOMMIT_ROOT}/.pre-commit-config.path"

    # Pre-create the venv directory to simulate a second invocation.
    mkdir -p "${venv_path}/bin"
    printf '#!/bin/bash\n' > "${venv_path}/bin/activate"

    run env PATH="${stub_dir}:/usr/local/bin:/usr/bin:/bin" bash "${SCRIPT}"
    local exit_status="${status}"

    # Cleanup side-effect files written by install.sh.
    rm -rf "${venv_path}"
    rm -f "${path_file}"

    [ "${exit_status}" -eq 0 ]
    [ -f "${venv_args_file}" ]
    grep -q -- "--clear" "${venv_args_file}"
}

@test "install.sh: valid external venv writes config.path" {
    local venv_dir="${TEST_TMPDIR}/myvenv"
    local stub_dir="${TEST_TMPDIR}/stubs"
    mkdir -p "${venv_dir}/bin" "${stub_dir}"

    # Stub python3 inside the fake venv reporting minor version 10.
    cat > "${venv_dir}/bin/python3" << 'STUB'
#!/bin/bash
case "$*" in
    *"version_info.minor"*) echo "10" ;;
    *) echo "3.10.0" ;;
esac
STUB
    chmod +x "${venv_dir}/bin/python3"

    # No-op activate script.
    printf '#!/bin/bash\n' > "${venv_dir}/bin/activate"

    # Stub uv (uv pip install).
    cat > "${stub_dir}/uv" << 'STUB'
#!/bin/bash
exit 0
STUB
    chmod +x "${stub_dir}/uv"

    # Stub pre-commit.
    cat > "${stub_dir}/pre-commit" << 'STUB'
#!/bin/bash
exit 0
STUB
    chmod +x "${stub_dir}/pre-commit"

    local path_file="${PRECOMMIT_ROOT}/.pre-commit-config.path"
    run env PATH="${stub_dir}:/usr/local/bin:/usr/bin:/bin" bash "${SCRIPT}" --venv "${venv_dir}"
    [ "${status}" -eq 0 ]
    [ -f "${path_file}" ]
    # shellcheck disable=SC2002
    [[ "$(cat "${path_file}")" =~ "precommit_config=" ]]

    # Cleanup the side-effect file written by install.sh.
    rm -f "${path_file}"
}

# ===========================================================================
# install.sh integration — argument validation
# ===========================================================================

@test "install.sh: unknown argument exits 1 with error message" {
    run bash "${SCRIPT}" --unknown-flag
    [ "${status}" -eq 1 ]
    [[ "${output}" =~ "unknown argument" ]]
}

@test "install.sh: --config without value exits 1 with error message" {
    run bash "${SCRIPT}" --config
    [ "${status}" -eq 1 ]
    [[ "${output}" =~ "requires a value" ]]
}

@test "install.sh: --venv without value exits 1 with error message" {
    run bash "${SCRIPT}" --venv
    [ "${status}" -eq 1 ]
    [[ "${output}" =~ "requires a value" ]]
}
