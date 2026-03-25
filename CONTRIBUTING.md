# Contributing to pre-commit

Thank you for your interest in contributing!

## Running the tests locally

Tests are written with [bats-core](https://github.com/bats-core/bats-core).

Install bats:
```bash
# Debian / Ubuntu
sudo apt-get install bats

# macOS
brew install bats-core
```

Run all tests:
```bash
bats tests/install.bats
bats tests/run.bats
```

## Coding conventions

- Shell scripts must pass ShellCheck (`shellcheck <script>`)
- Keep `install.sh` and `run.sh` POSIX-compatible where possible; bash-specific
  features are acceptable but must be declared with `#!/bin/bash` and `set -euo pipefail`
- New hooks added to `.pre-commit-config.yaml` should have a corresponding test
  in `tests/`

## Pull request process

1. Fork the repository and create a branch from `master`
2. Add or update tests to cover your change
3. Ensure `bats tests/*.bats` passes locally
4. Open a pull request — CI will run the full test suite automatically
5. A maintainer will review and merge once CI is green

## Reporting issues

Open a [GitHub Issue](https://github.com/techmo-pl/pre-commit/issues) with a
clear description of the problem and steps to reproduce.
