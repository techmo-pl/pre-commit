# Changelog of pre-commit


## [3.0.0] - 2026/03/03

### Changed (breaking)

- `install.sh`: positional arguments `CONFIG` and `VENV` replaced by named flags
  `--config CONFIG` and `--venv VENV`. Callers must update accordingly:
  - `install.sh /path/to/hooks.yaml` → `install.sh --config /path/to/hooks.yaml`
  - `install.sh "" /path/to/venv` → `install.sh --venv /path/to/venv`
  - `install.sh /path/to/hooks.yaml /path/to/venv` → `install.sh --config /path/to/hooks.yaml --venv /path/to/venv`
- `run.sh`: positional argument `CONFIG` replaced by named flag `--config CONFIG`.
  Callers must update accordingly:
  - `run.sh /path/to/hooks.yaml` → `run.sh --config /path/to/hooks.yaml`

### Fixed

- `install.sh`: add `--no-input` to `pip install` calls to prevent any stdin
  interaction when running in a non-interactive environment such as a Dockerfile (#24)
- `install.sh`: pass `--clear` to `uv venv` so a second invocation does not show
  the interactive "replace existing venv?" prompt that stalls in Docker (#24)

### Added

- CI job `test_double_invocation_non_interactive` in `.gitlab-ci.yml`: runs
  `install.sh` twice in sequence with stdin closed and a timeout, exercising the
  managed-venv code path (uv) on second invocation (#24)

### Removed

- CI job `setup_uv` and the dedicated `setup` stage removed from `.gitlab-ci.yml`:
  `uv` is pre-installed on runner servers, so a serial setup step is no longer needed


## [2.2.1] - 2026/03/02

### Fixed

- Disable hadolint rule DL3005 (Do not use apt-get upgrade or dist-upgrade) (#23)


## [2.2.0] - 2026/03/02

### Added

- Documentation for sharing a single virtualenv across a project's submodule tree:
  each `setup.sh` accepts an optional venv path as `$1` and forwards it downstream,
  so only one environment is created regardless of how many submodules need hooks installed.
- Add dedicated setup for python3.8 and python3.9.
- Add tests suite for confirming that python3.8-python3.14 range is supported.


## [2.1.0] - 2026/02/27

### Added

- Optional `VENV` argument for `install.sh`: when provided, pre-commit is installed
  into that existing virtualenv instead of creating an isolated `./pre-commit/.venv`.
  After `setup.sh`, `source .venv/bin/activate` is sufficient for manual runs.
- `uv` support in `install.sh`: uses `uv venv` / `uv pip install` when `uv` is
  available in PATH, falls back to `python -m venv` / `pip` otherwise.

### Fixed

- Replaced `hadolint/hadolint` pre-commit hook (`language: system`, requires a
  system-wide `hadolint` binary) with `AleksaC/hadolint-py` (self-contained Python
  wheel — no system installation needed on a fresh machine).
- `run.sh` now reads the venv path from `.pre-commit-config.path` instead of
  hardcoding `./pre-commit/.venv`, correctly supporting both the new external-venv
  and legacy isolated-venv setups. Old `.pre-commit-config.path` files (without the
  `precommit_venv` line) continue to work via a backward-compatible default.


## [2.0.1] - 2026/02/27

### Fixed

- `clang-format` and `cppcheck` are now declared as `additional_dependencies` on
  the `pocc/pre-commit-hooks` entries, so pre-commit installs the newest available
  PyPI versions into the hook's own isolated virtualenv. This ensures the pip-installed
  binaries are used regardless of what is installed on the system and regardless of
  whether pre-commit is invoked via `run.sh` or the git commit hook.


## [2.0.0] - 2026/02/14

### Added

- ruff (replaces black, isort, and autoflake with a single, faster tool)
- `check-illegal-windows-names` hook for cross-platform filename safety
- `check-toml` hook for TOML file validation
- `no-commit-to-branch` hook to protect master from direct commits
- Python 3.9+ version check in `install.sh`
- `SKIP: no-commit-to-branch` variable in `.gitlab-ci.yml`
- gitleaks for secret detection (API keys, passwords, tokens)
- codespell for catching common misspellings
- ruff security rules (`S`/flake8-bandit), pyupgrade rules (`UP`), and bugbear rules (`B`)
- hadolint for Dockerfile linting
- clang-format and cppcheck for C/C++ linting and formatting
- ruff pycodestyle rules (`E`, `W`) for whitespace and style checks

### Changed

- pre-commit updated to 4.5.1
- pre-commit-hooks updated to v5.0.0
- mirrors-mypy updated to v1.19.1
- shellcheck-py updated to v0.11.0.1
- shfmt-py updated to v3.12.0.1

### Removed

- black (replaced by ruff-format)
- isort (replaced by ruff's isort rules)
- autoflake (replaced by ruff's pyflakes rules)

### Fixed

- duplicate `check-symlinks` entry


## [1.4.1] - 2025/03/17

### Fixed

- pre-commit should not affect `*.patch` files
- duplicate shellcheck


## [1.4.0] - 2024/03/08

### Added

- mypy


## [1.3.0] - 2023/10/31

### Added

- autoflake


## [1.2.0] - 2023/03/10

### Added

- isort


## [1.1.1] - 2022/09/08

### Changed

- shfmt and shellcheck are installed as python package
- black hook updated to 22.8.0


## [1.1.0] - 2022/05/05

### Added

- generic `setup.sh` for development

### Changed

- renamed default virtual environment to `.venv`
- renamed old `setup.sh` to `install.sh`
- pre-commit updated to 2.20.0
- pre-commit-hooks updated to 4.3.0
- black hook updated to 22.6.0


## [1.0.3] - 2022/04/08

### Changed

- black hook updated to 22.3.0


## [1.0.2] - 2022/03/18

### Changed

- pre-commit updated to 2.17.0
- pre-commit-hooks updated to 4.1.0
- black hook updated to 22.1.0
- shellcheck hook updated to 2.1.6
- shfmt hook updated to 3.4.3
- cleaned pre-commit-hooks rules


## [1.0.1] - 2021/10/8

### Added

- description in the scripts

### Changed

- described setup and usage in the readme

### Removed

- stray coverage dependencies from `requirements.txt`


## [1.0.0] - 2021/09/30

### Added

- default pre-commit configuration
- setup script
- run script
