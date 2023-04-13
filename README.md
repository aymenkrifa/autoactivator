
# AutoActivator

Autoactivator is a powerful tool designed to streamline your workflow when working with virtual environments. With Autoactivator, you can easily activate your virtual environments as soon as you enter a corresponding project directory, and stay activated for as long as you're working in that directory. Once you're done with the project and move out of the directory, Autoactivator automatically deactivates the virtual environment for you, ensuring that you don't accidentally use the wrong environment in future projects. This feature makes it easier for developers and programmers to manage multiple virtual environments without having to manually activate or deactivate them every time they switch projects.

## Installation

Clone the repository

```bash
git clone https://github.com/aymenkrifa/autoactivator.git
```

Navigate into the cloned directory

```bash
cd autoactivator
```

Install the 'pick' package using pip and run the installation script

```bash
pip install pick
python3 install.py
```

Follow the on-screen prompts to select which shells you want to install the activator script for.

Restart your terminal or source your shell configuration file to activate the changes:

```bash
source ~/.bashrc   # for Bash
source ~/.zshrc    # for Zsh
```

## Contributing

Contributions are always welcome!

See `contributing.md` for ways to get started.

Please adhere to this project's `code of conduct`.
