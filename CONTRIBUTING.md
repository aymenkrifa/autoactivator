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

Shell scripts in this repo — including the tests and the benchmark — are linted in CI with `shellcheck` at warning severity and syntax-checked with `bash -n` and `zsh -n`. See [`.github/workflows/ci.yml`](.github/workflows/ci.yml) for the exact commands. Run them locally before opening a PR:

```bash
shellcheck --severity=warning setup.sh bench/bench.sh
shellcheck --shell=bash --severity=warning activator.sh autoactivator_config.sh _constants.sh tests/*.sh
bash -n setup.sh activator.sh autoactivator_config.sh _constants.sh tests/*.sh bench/bench.sh
zsh -n activator.sh autoactivator_config.sh _constants.sh tests/test_activator.sh tests/test_subcommands.sh bench/bench.sh
```

(`setup.sh` and `tests/test_setup.sh` are bash-only — piped installs always run under bash — so they are excluded from the `zsh -n` check.)

`activator.sh` is sourced by both `bash` and `zsh`, so any zsh-specific syntax must be guarded by `[[ -n "$ZSH_VERSION" ]]` and any bash-specific syntax by `[[ -n "$BASH_VERSION" ]]`.

## Tests

The repo has three black-box test suites, none of which needs Python or an external test framework:

- [`tests/test_activator.sh`](tests/test_activator.sh) builds a fake project tree in a temp directory, sources `activator.sh`, and asserts behavior by invoking `_check_for_venv` directly.
- [`tests/test_subcommands.sh`](tests/test_subcommands.sh) sources the full config under a throwaway `$HOME` and exercises the `autoactivator` subcommands.
- [`tests/test_setup.sh`](tests/test_setup.sh) runs the installer end-to-end against a local fixture repo and tarball under throwaway `$HOME`s — no network. It is bash-only, like the installer itself.

Run them before opening a PR (the first two under both shells):

```bash
bash tests/test_activator.sh   && zsh tests/test_activator.sh
bash tests/test_subcommands.sh && zsh tests/test_subcommands.sh
bash tests/test_setup.sh
```

CI runs all of these on every push and pull request, on Linux and on macOS (where the system bash 3.2 exercises the cacheless code path).

## Pull Requests

Keep PRs focused on a single change. Describe the motivation in the PR body. If the change affects runtime behavior (activation, deactivation, hook registration), explain how you tested it across both shells.

## Contact

For questions, email the maintainer at [aymenkrifa@gmail.com](mailto:aymenkrifa@gmail.com).
