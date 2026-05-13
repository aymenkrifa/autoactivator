# Contributing Guidelines

Thanks for your interest in contributing to AutoActivator. This is a small project — three shell scripts and a README — so the contribution process is intentionally lightweight.

## Code of Conduct

This project follows the [Contributor Covenant](https://www.contributor-covenant.org/version/2/0/code_of_conduct.html). Please report unacceptable behavior to the maintainer.

## Getting Started

1. Fork the repository and clone your fork.
2. Create a branch with a descriptive name (e.g. `fix/zsh-hook-leak`, `feature/pyenv-support`).
3. Make your changes.
4. Push and open a pull request against `main`.

There are no project dependencies to install — the codebase is just shell scripts. To exercise your changes locally, `source ./activator.sh` in a test shell and cd around.

## Bug Reports and Feature Requests

Open a GitHub issue. Search existing issues first to avoid duplicates. Include reproduction steps for bugs and the use case for feature requests.

## Code Style

Shell scripts in this repo are linted in CI with `shellcheck` at warning severity and checked with `bash -n` for syntax. See [`.github/workflows/ci.yml`](.github/workflows/ci.yml) for the exact commands. Run them locally before opening a PR:

```bash
shellcheck --severity=warning setup.sh
shellcheck --shell=bash --severity=warning activator.sh
shellcheck --shell=bash --severity=warning autoactivator_config.sh
bash -n setup.sh activator.sh autoactivator_config.sh
```

`activator.sh` is sourced by both `bash` and `zsh`, so any zsh-specific syntax must be guarded by `[[ -n "$ZSH_VERSION" ]]` and any bash-specific syntax by `[[ -n "$BASH_VERSION" ]]`.

## Pull Requests

Keep PRs focused on a single change. Describe the motivation in the PR body. If the change affects runtime behavior (activation, deactivation, hook registration), explain how you tested it across both shells.

## Contact

For questions, email the maintainer at [aymenkrifa@gmail.com](mailto:aymenkrifa@gmail.com).
