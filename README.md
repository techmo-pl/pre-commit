# pre-commit

[![Tests](https://github.com/techmo-pl/pre-commit/actions/workflows/test.yml/badge.svg)](https://github.com/techmo-pl/pre-commit/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

pre-commit hooks for Techmo's projects.

## Requirements

- Python 3.8+

## Setup

To install pre-commit within a target repository link this project as a submodule first then run the installation script once or better still integrate it with a setup script of the repository.

Example (isolated venv created at `./submodules/pre-commit/.venv`):
```bash
./submodules/pre-commit/install.sh
```

Example (install into an existing project virtualenv so no separate activation is needed):
```bash
./submodules/pre-commit/install.sh --venv ".venv"
```

### Sharing one environment across a submodule tree

Create the virtualenv once at the top level and pass its path down the tree — each
`setup.sh` accepts an optional venv path, creates one if absent, then forwards
it to `install.sh --venv` and to any child submodules.

**Root `setup.sh`**
```bash
#!/bin/bash
set -euo pipefail

venv_arg="${1:-}"
if [ -z "${venv_arg}" ]; then
    uv venv .venv
    venv_arg="$(pwd)/.venv"
fi

source "${venv_arg}/bin/activate"
uv pip install -e ".[test]"

./submodules/pre-commit/install.sh --venv "${venv_arg}"

# Propagate the shared venv to submodules.
./submodule-a/setup.sh "${venv_arg}"
./submodule-b/setup.sh "${venv_arg}"
```

Submodule `setup.sh` scripts follow the same pattern without the propagation block.

Each `install.sh` registers git hooks for its own repository. Scripts work correctly both
standalone (create their own venv) and as child calls (reuse the shared one).

## Usage

### Shell

To perform a single check on demand run `run.sh` script.

Example:
```
./submodules/pre-commit/run.sh
```

### git commit

When installed the hooks are called automatically on `git commit`. The commit operation is aborted if check fails.

The `no-commit-to-branch` hook prevents direct commits to master. To bypass it when necessary:
```bash
SKIP=no-commit-to-branch git commit -m "message"
```

### CI

To call pre-commit hooks within a CI pipeline of the target repository add a relevant job.
The `SKIP` variable must be set to disable `no-commit-to-branch` in CI, since pipelines run on all branches.

Example (GitHub Actions):
```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive
      - name: Run pre-commit hooks
        run: |
          ./setup.sh
          SKIP=no-commit-to-branch ./submodules/pre-commit/run.sh
```

This example assumes `setup.sh` exists in the target repository and installs pre-commit hooks for it.

### Custom configuration

The default pre-commit configuration is listed in `.pre-commit-config.yaml`. If needed, a custom pre-commit config may be specified via `--config`.

Examples:
```bash
./submodules/pre-commit/install.sh --config path/to/custom/config
```
```bash
./submodules/pre-commit/run.sh --config path/to/custom/config
```

## Python linting

As of v2.0.0, Python linting and formatting is handled by [ruff](https://docs.astral.sh/ruff/), replacing the previous black + isort + autoflake setup. Ruff is configured via inline args in `.pre-commit-config.yaml` and provides:

- **`ruff check --fix`** - linting with auto-fix (pyflakes, isort, bandit security, pyupgrade, bugbear rules)
- **`ruff format`** - code formatting (Black-compatible, 160 char line length)

The following security rules are ignored by default to reduce false positives: `S101` (assert), `S603`/`S607` (subprocess with list args). To suppress additional rules per project, add `--extend-ignore=SXXX` to the hook's `args` in your project's pre-commit config override, or configure exclusions via a project-level `ruff.toml`.

## C/C++ linting

[clang-format](https://clang.llvm.org/docs/ClangFormat.html) formats C/C++ source files. By default it uses `--style=file`, which looks for a `.clang-format` configuration in the project root. If none is found, files are left unchanged (`--fallback-style=none`).

[cppcheck](http://cppcheck.net/) performs static analysis on C/C++ code, catching bugs, undefined behavior, and style issues. The default standard is C++17.

Both hooks are provided via [pocc/pre-commit-hooks](https://github.com/pocc/pre-commit-hooks) and declared with `additional_dependencies`, so pre-commit installs the PyPI-bundled binaries into the hook's own isolated environment automatically — no system-wide installation needed.

## Secret detection

[Gitleaks](https://github.com/gitleaks/gitleaks) scans staged changes for secrets such as API keys, passwords, and tokens. It is more comprehensive than the built-in `detect-private-key` hook which only catches SSH private keys.

## Dockerfile linting

[Hadolint](https://github.com/hadolint/hadolint) lints Dockerfiles for best practices and uses ShellCheck under the hood to validate `RUN` instructions. The hook uses [hadolint-py](https://github.com/AleksaC/hadolint-py), which ships pre-compiled hadolint binaries as Python wheels — no system-wide `hadolint` installation is needed.

## Spell checking

[Codespell](https://github.com/codespell-project/codespell) checks for common misspellings in code, comments, and documentation. To ignore specific words, add a `[codespell]` section to `setup.cfg` (e.g. `ignore-words-list = foo,bar`) or pass `--ignore-words-list` args in a project-level pre-commit config override.

## References

[pre-commit](https://pre-commit.com/)
[ruff](https://docs.astral.sh/ruff/)

## License

The scripts and configuration files in this repository (`install.sh`, `run.sh`,
`.pre-commit-config.yaml`, etc.) are released under the [MIT License](LICENSE).

### Third-party tools

The default configuration references several external tools that are downloaded
and run by pre-commit in **isolated environments on the user's machine**. They
are not bundled or redistributed here. Their licenses are listed for reference:

| Tool | License |
|------|---------|
| [pre-commit](https://github.com/pre-commit/pre-commit) | MIT |
| [pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks) | MIT |
| [ruff](https://github.com/astral-sh/ruff) | MIT |
| [mypy](https://github.com/python/mypy) | MIT |
| [gitleaks](https://github.com/gitleaks/gitleaks) | MIT |
| [codespell](https://github.com/codespell-project/codespell) | GPL-2.0 |
| [ShellCheck](https://github.com/koalaman/shellcheck) | GPL-3.0 |
| [shfmt](https://github.com/mvdan/sh) | BSD-3-Clause |
| [hadolint](https://github.com/hadolint/hadolint) | GPL-3.0 |
| [clang-format](https://clang.llvm.org/docs/ClangFormat.html) | Apache-2.0 |
| [cppcheck](https://cppcheck.sourceforge.io/) | GPL-3.0 |

Using a GPL-licensed tool as an external process does not affect the license of
code that invokes it. The GPL copyleft applies to distribution of derivative
works, not to runtime invocation. See the
[GNU FAQ](https://www.gnu.org/licenses/gpl-faq.html#MereAggregation) for details.
