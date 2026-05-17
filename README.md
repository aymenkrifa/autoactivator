# AutoActivator

![Cover image representing AutoActivator, a tool for managing virtual environments](logo.png)

![Workflow](https://github.com/aymenkrifa/autoactivator/actions/workflows/ci.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Automatically activate your Python virtual environment when you `cd` into a project, and deactivate it when you leave. No configuration files, no per-project setup — it just works.

## How it works

When you change directories, AutoActivator scans the current directory (and up to your home directory) for a virtual environment. If it finds one, it activates it. When you leave the project tree, it deactivates it.

Results are cached per directory, so repeated visits cost nothing. The hook fires only on actual directory changes — not on every shell prompt.

**Performance (Ubuntu 24.04):**

| Shell | v0.1.0 | v0.2.0 |
|---|---|---|
| zsh | 2.14s | 0.031s |
| bash | 1.93s | 0.002s |

## Requirements

- **bash** or **zsh**
- **git** — used for installation and updates
- Linux or macOS

No Python required.

## Installation

```bash
curl -sSL https://aymenkrifa.github.io/autoactivator/setup.sh | bash -s <shell>
```

Replace `<shell>` with `bash`, `zsh`, or both:

```bash
# zsh only
curl -sSL https://aymenkrifa.github.io/autoactivator/setup.sh | bash -s zsh

# bash only
curl -sSL https://aymenkrifa.github.io/autoactivator/setup.sh | bash -s bash

# both
curl -sSL https://aymenkrifa.github.io/autoactivator/setup.sh | bash -s zsh bash
```

<details>
<summary>Manual installation</summary>

```bash
git clone https://github.com/aymenkrifa/autoactivator.git ~/.autoactivator
chmod +x ~/.autoactivator/setup.sh
~/.autoactivator/setup.sh <shell>
```

</details>

Then restart your terminal, or source your shell config:

```bash
source ~/.bashrc   # bash
source ~/.zshrc    # zsh
```

## Updating

```bash
autoactivator update
```

This pulls the latest changes and re-sources the hook in your current shell. The update will refuse to run if you have local modifications in `~/.autoactivator`.

## What gets detected

AutoActivator looks for any directory inside your project that contains `bin/activate` and is not a conda environment. This covers venvs created by:

- `python -m venv`
- `virtualenv`
- `uv venv`
- `poetry` (when the venv is inside the project)
- `pipenv` (when `PIPENV_VENV_IN_PROJECT=1`)

It does **not** detect venvs stored outside the project tree (e.g. pyenv global envs, hatch envs in `~/.local`).

### Multiple venvs in one project

If a directory contains more than one venv, AutoActivator picks the first match in this priority order:

1. `$AUTOACTIVATOR_VENV_NAME` (if set and the directory exists)
2. `.venv`
3. `venv`
4. `env`
5. `virtualenv`
6. First directory in the tree that looks like a venv (alphabetical fallback)

### Customisation

Set `AUTOACTIVATOR_VENV_NAME` to prefer a non-standard venv name. Add the export to your shell config **before** the AutoActivator block:

```bash
export AUTOACTIVATOR_VENV_NAME=myenv
source ~/.autoactivator/autoactivator_config.sh
```

If the named directory doesn't exist in a given project, AutoActivator falls back to the standard priority list — so the override is a preference, not a hard requirement.

## Uninstalling

```bash
rm -rf ~/.autoactivator
```

Then remove the AutoActivator block from your shell config (`~/.bashrc` or `~/.zshrc`):

```bash
############################# AutoActivator #############################
source /home/user/.autoactivator/autoactivator_config.sh
#########################################################################
```

To restore your original shell config from the backup created at install time:

```bash
mv ~/.zshrc.pre-autoactivator ~/.zshrc    # zsh
mv ~/.bashrc.pre-autoactivator ~/.bashrc  # bash
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
