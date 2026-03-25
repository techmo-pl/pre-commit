#!/usr/bin/env bats
# shellcheck shell=bash
#
# tests/run.bats — unit and integration tests for run.sh
#
# Tests exercise the guard conditions (missing config.path, missing venv) and
# the happy path where a stub pre-commit binary is on PATH.

SCRIPT="${BATS_TEST_DIRNAME}/../run.sh"
PRECOMMIT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

setup()
{
    TEST_TMPDIR="$(mktemp -d)"
    export TEST_TMPDIR

    REAL_PATH_FILE="${PRECOMMIT_ROOT}/.pre-commit-config.path"
    if [ -f "${REAL_PATH_FILE}" ]; then
        cp "${REAL_PATH_FILE}" "${TEST_TMPDIR}/.pre-commit-config.path.bak"
        rm -f "${REAL_PATH_FILE}"
    fi
}

teardown()
{
    REAL_PATH_FILE="${PRECOMMIT_ROOT}/.pre-commit-config.path"
    rm -f "${REAL_PATH_FILE}"
    if [ -f "${TEST_TMPDIR}/.pre-commit-config.path.bak" ]; then
        cp "${TEST_TMPDIR}/.pre-commit-config.path.bak" "${REAL_PATH_FILE}"
    fi
    rm -rf "${TEST_TMPDIR:-}"
}

# ===========================================================================
# Argument validation
# ===========================================================================

@test "run.sh: unknown argument exits 1 with error message" {
    run bash "${SCRIPT}" --unknown-flag
    [ "${status}" -eq 1 ]
    [[ "${output}" =~ "unknown argument" ]]
}

@test "run.sh: --config without value exits 1 with error message" {
    run bash "${SCRIPT}" --config
    [ "${status}" -eq 1 ]
    [[ "${output}" =~ "requires a value" ]]
}

# ===========================================================================
# Guard: missing .pre-commit-config.path
# ===========================================================================

@test "run.sh: missing .pre-commit-config.path exits 1 with install hint" {
    rm -f "${PRECOMMIT_ROOT}/.pre-commit-config.path"
    run bash "${SCRIPT}"
    [ "${status}" -eq 1 ]
    [[ "${output}" =~ install.sh ]]
}

# ===========================================================================
# Guard: missing venv directory
# ===========================================================================

@test "run.sh: missing venv exits 1 with install hint" {
    local venv_dir="${TEST_TMPDIR}/nonexistent_venv"
    local fake_config="${TEST_TMPDIR}/hooks.yaml"

    printf 'precommit_config="%s"\nprecommit_venv="%s"\n' \
        "${fake_config}" "${venv_dir}" > "${PRECOMMIT_ROOT}/.pre-commit-config.path"

    run bash "${SCRIPT}"
    [ "${status}" -eq 1 ]
    [[ "${output}" =~ install.sh ]]
}

# ===========================================================================
# Happy path: config.path and venv present, stub pre-commit succeeds
# ===========================================================================

@test "run.sh: valid setup runs pre-commit and exits 0" {
    local venv_dir="${TEST_TMPDIR}/fakevenv"
    local stub_dir="${TEST_TMPDIR}/stubs"
    local fake_config="${TEST_TMPDIR}/.pre-commit-config.yaml"
    mkdir -p "${venv_dir}/bin" "${stub_dir}"

    printf '#!/bin/bash\n' > "${venv_dir}/bin/activate"

    cat > "${stub_dir}/pre-commit" << 'STUB'
#!/bin/bash
exit 0
STUB
    chmod +x "${stub_dir}/pre-commit"

    printf 'fail_fast: false\nrepos: []\n' > "${fake_config}"

    printf 'precommit_config="%s"\nprecommit_venv="%s"\n' \
        "${fake_config}" "${venv_dir}" > "${PRECOMMIT_ROOT}/.pre-commit-config.path"

    run env PATH="${stub_dir}:/usr/local/bin:/usr/bin:/bin" bash "${SCRIPT}"
    [ "${status}" -eq 0 ]
}

@test "run.sh: custom CONFIG arg is forwarded to pre-commit" {
    local venv_dir="${TEST_TMPDIR}/fakevenv2"
    local stub_dir="${TEST_TMPDIR}/stubs2"
    local default_config="${TEST_TMPDIR}/default.yaml"
    local custom_config="${TEST_TMPDIR}/custom.yaml"
    mkdir -p "${venv_dir}/bin" "${stub_dir}"

    printf '#!/bin/bash\n' > "${venv_dir}/bin/activate"

    # Record the --config argument that pre-commit receives.
    cat > "${stub_dir}/pre-commit" << 'STUB'
#!/bin/bash
echo "called with: $*"
exit 0
STUB
    chmod +x "${stub_dir}/pre-commit"

    printf 'fail_fast: false\nrepos: []\n' > "${default_config}"
    printf 'fail_fast: false\nrepos: []\n' > "${custom_config}"

    printf 'precommit_config="%s"\nprecommit_venv="%s"\n' \
        "${default_config}" "${venv_dir}" > "${PRECOMMIT_ROOT}/.pre-commit-config.path"

    run env PATH="${stub_dir}:/usr/local/bin:/usr/bin:/bin" bash "${SCRIPT}" --config "${custom_config}"
    [ "${status}" -eq 0 ]
    [[ "${output}" =~ ${custom_config} ]]
}
