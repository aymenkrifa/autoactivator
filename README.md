<div align="center">
  <img src="docs/logo/assets/autoactivator-banner-animated.svg" alt="AutoActivator" width="640">
  <p><em>A shell hook that activates your Python venv the moment you <code>cd</code> in — and deactivates it when you leave.</em></p>
  <p><a href="https://autoactivator.aymenkrifa.com"><b>autoactivator.aymenkrifa.com</b></a></p>
</div>

# AutoActivator

![Workflow](https://github.com/aymenkrifa/autoactivator/actions/workflows/ci.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Automatically activate your Python virtual environment when you `cd` into a project, and deactivate it when you leave. No configuration files, no per-project setup — it just works.

## How it works

When you change directories, AutoActivator scans the current directory (and up to your home directory) for a virtual environment. If it finds one, it activates it. When you leave the project tree, it deactivates it.

Found venvs are cached per directory, so repeated visits cost nothing. Directories without a venv are re-checked on each visit, so a venv you create later is picked up immediately. The hook fires only on actual directory changes — not on every shell prompt.

If you activate a venv by hand, AutoActivator leaves it alone — no automatic switching happens until you `deactivate`.

**Performance (Ubuntu 24.04):**

| Shell | v0.1.0 | v0.2.0 | v0.3.0 |
|---|---|---|---|
| zsh | 2.14s | 0.004s | 0.0002s |
| bash | 1.93s | 0.004s | 0.0002s |
| *speedup vs previous* | — | *~500×* | *~20×* |

*Measured as wall-clock time for the hook to fire on a single `cd` into a project with a `.venv`, cold cache, in an `ubuntu:24.04` container. Reproduce with [`bench/bench.sh`](bench/bench.sh).*

## Requirements

- **bash** or **zsh**
- **git** — recommended for installation and updates; without it, the installer falls back to a tarball download (needs **curl** or **wget**, plus **tar**)
- Linux or macOS (both covered by CI, including macOS's stock bash 3.2)

No Python required.

## Installation

```bash
curl -sSL https://autoactivator.aymenkrifa.com/setup.sh | bash
```

No arguments needed — the installer detects your shell from `$SHELL` and wires up the matching rc file (creating it if it doesn't exist). Want a specific shell (or both)? Pass it explicitly:

```bash
# zsh only
curl -sSL https://autoactivator.aymenkrifa.com/setup.sh | bash -s zsh

# bash only
curl -sSL https://autoactivator.aymenkrifa.com/setup.sh | bash -s bash

# both
curl -sSL https://autoactivator.aymenkrifa.com/setup.sh | bash -s zsh bash
```

<details>
<summary>Manual installation</summary>

```bash
git clone https://github.com/aymenkrifa/autoactivator.git ~/.autoactivator
chmod +x ~/.autoactivator/setup.sh
~/.autoactivator/setup.sh   # optionally pass a shell: ~/.autoactivator/setup.sh zsh
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

Installed without git? `autoactivator update` will point you back to the install one-liner — re-running it refreshes the install in place (and upgrades it to a git checkout once git is available).

## Tool support

AutoActivator finds venvs that live **inside the project tree**. Here's how that maps to the common Python tools:

| Tool | Default layout | Supported |
|---|---|:---:|
| `python -m venv` | `.venv` / `venv` / `env` in project | ✅ |
| `virtualenv` | `env` in project | ✅ |
| `uv venv` | `.venv` in project | ✅ |
| `pyenv` + `python -m venv` | venv in project | ✅ |
| `poetry` (with `virtualenvs.in-project = true`) | `.venv` in project | ✅ |
| `pipenv` (with `PIPENV_VENV_IN_PROJECT=1`) | `.venv` in project | ✅ |
| Custom-named directory in project | any name (set `$AUTOACTIVATOR_VENV_NAME`) | ✅ |
| `poetry` (default) | `~/.cache/pypoetry/virtualenvs/…` | ❌ |
| `pipenv` (default) | `~/.local/share/virtualenvs/…` | ❌ |
| `pyenv-virtualenv` plugin | `~/.pyenv/versions/…` | ❌ |
| `hatch` | `~/.local/share/hatch/…` | ❌ |
| Conda / Anaconda / Miniconda | `$CONDA_PREFIX/envs/…` | ❌ (use `conda activate`) |

The rule of thumb: **if the venv directory lives anywhere inside your project, AutoActivator will find it.** External venv layouts (poetry default, pyenv-virtualenv, hatch) are out of scope for now.

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
autoactivator uninstall
```

This removes the `############################# AutoActivator #############################` block (and the matching close marker) from `~/.bashrc` and `~/.zshrc`. Everything else in those files is left alone, and a fresh timestamped backup is written beside each rc (`~/.bashrc.pre-uninstall.<timestamp>`) before any change. Open a new shell to fully unload the hook.

The repo at `~/.autoactivator` is **not** deleted by default — the command prints the `rm -rf` line for you to run. To wipe everything in one go:

```bash
autoactivator uninstall --purge
```

<details>
<summary>About the <code>~/.zshrc.pre-autoactivator</code> backup</summary>

The installer creates `~/.zshrc.pre-autoactivator` (or `.bashrc.pre-autoactivator`) the first time it runs. That file is a **snapshot from install time**, not a diff. Restoring it (`mv ~/.zshrc.pre-autoactivator ~/.zshrc`) will erase anything else you've added to your shell config since installing AutoActivator — aliases, other tools' init blocks, `PATH` edits, all of it. Only use it as a fallback if you're sure nothing else has changed.

`autoactivator uninstall` avoids this entirely by deleting just the AutoActivator block in place.

</details>

<details>
<summary>Manual removal</summary>

If for some reason you can't run the command, delete this block from `~/.bashrc` / `~/.zshrc`:

```bash
############################# AutoActivator #############################
source "/home/<you>/.autoactivator/autoactivator_config.sh"
#########################################################################
```

Then `rm -rf ~/.autoactivator` if you want the repo gone too.

</details>

## Security note

Activating a venv means `source`-ing its `bin/activate` — so cd-ing into an untrusted checkout executes whatever shell code its venv-shaped directories contain. If you routinely clone code you don't trust, inspect it before cd-ing in. (Tools like direnv address this with a per-directory allow-list; AutoActivator deliberately stays zero-config.)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
