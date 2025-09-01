# AutoActivator

![Cover image representing AutoActivator, a tool for managing virtual environments](logo.png)

![Workflow](https://github.com/aymenkrifa/autoactivator/actions/workflows/ci.yml/badge.svg)
[![Supported Python version](https://img.shields.io/badge/python-3.9|3.10|3.11|3.12-blue?logo=python)](https://docs.python.org/3.10/)
[![Code style](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Autoactivator is a powerful tool designed to streamline your workflow when working with virtual environments. With Autoactivator, you can easily activate your virtual environments as soon as you enter a corresponding project directory, and stay activated for as long as you're working in that directory. Once you're done with the project and move out of the directory, Autoactivator automatically deactivates the virtual environment for you, ensuring that you don't accidentally use the wrong environment in future projects. This feature makes it easier for developers and programmers to manage multiple virtual environments without having to manually activate or deactivate them every time they switch projects.

## Dependencies

Before installing AutoActivator, please ensure that you have the following dependencies installed on your system:

- **Git**: AutoActivator relies on Git for cloning the repository and keeping it up to date with the latest changes. If you don't have Git installed, you can download it from the official website: [Git Downloads](https://git-scm.com/downloads).

- **cURL**: cURL is used to download and execute the setup script for AutoActivator. It allows for a quick and convenient installation process. If you don't have `cURL` installed, you can install it by following the instructions for your operating system.

  - For Ubuntu/Debian-based systems, run the following command:

    ```bash
    sudo apt-get install curl
    ```

  - For macOS using Homebrew, run the following command:

    ```bash
    brew install curl
    ```

These dependencies are essential for the proper installation and usage of AutoActivator. Please make sure they are installed before proceeding with the installation instructions mentioned below.

## Installation

To install AutoActivator, you can use the following `curl` command for a quick setup:

```bash
curl -sSL https://aymenkrifa.github.io/autoactivator/setup.sh | bash -s <shell1> <shell2> ...
```

Replace `shell1`, `shell2`, and so on with the shells you want to install. You can specify either `zsh`, `bash`, or both, in any order.
\
\
Here are a few examples:

- To install AutoActivator with the `zsh` shell:

  ```bash
  curl -sSL https://aymenkrifa.github.io/autoactivator/setup.sh | bash -s zsh
  ```

- To install AutoActivator with the `bash` shell:

  ```bash
  curl -sSL https://aymenkrifa.github.io/autoactivator/setup.sh | bash -s bash
  ```

- To install AutoActivator with both `zsh` and `bash`:

  ```bash
  curl -sSL https://aymenkrifa.github.io/autoactivator/setup.sh | bash -s zsh bash
  ```

<details>
<summary>Toggle to show commands in case the above installation method didn't work.</summary>

1. Clone the repository

   ```bash
   git clone https://github.com/aymenkrifa/autoactivator.git
   ```

2. Navigate into the cloned directory

   ```bash
   cd autoactivator
   ```

3. Run the installation script

   ```bash
   sudo chmod +x ./setup.sh
   ./setup.sh <shell1> <shell2> ...
   ```

</details>

\
To apply the changes, restart your terminal or source your shell configuration file:

```bash
source ~/.bashrc   # for Bash
source ~/.zshrc    # for Zsh
```

## Updating AutoActivator

To update AutoActivator to the latest version, you can use the `autoactivator update` command. Follow the steps below:

1. Open your terminal.

2. Run the following command:

   ```bash
   autoactivator update
   ```

## Removing AutoActivator

To remove AutoActivator from your system, you can delete the cloned repository and remove the configuration from your shell configuration file. Follow the steps below:

```bash
# Delete the cloned repository
rm -rf ~/.autoactivator
```

Next, remove the configuration from your shell configuration file, it would typically be in `~/.bashrc` for Bash and `~/.zshrc` for Zsh. Open the file in a text editor and delete the following lines:

```bash
############################# AutoActivator #############################
source /home/user/.autoactivator/autoactivator_config.sh
#########################################################################
```

Optionally, you can get back your original shell configuration file by restoring it from the created backup file (`~/.zshrc.pre-autoactivator` or `~/.bashrc.pre-autoactivator`). To do this, run the following command:

```bash
# For Zsh
mv ~/.zshrc.pre-autoactivator ~/.zshrc

# For Bash
mv ~/.bashrc.pre-autoactivator ~/.bashrc
```

Finally, restart your terminal or source your shell configuration file:

```bash
source ~/.bashrc   # for Bash
source ~/.zshrc    # for Zsh
```

## Contributing

Contributions are always welcome!

See `contributing.md` for ways to get started.

Please adhere to this project's `code of conduct`.
