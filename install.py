import os
import sys
import argparse
import subprocess
from typing import List
from pathlib import Path


APP_NAME = "AutoActivator"
TARGET_FOLDER = os.path.join(str(Path.home()), ".autoactivator")
PROMPT_TITLE = f"Choose which shell do you want to install {APP_NAME} for (you can choose more than one), press 'q' to quit."
SHELL_CONFIGS = {"bash": ".bashrc", "zsh": ".zshrc"}
POSSIBLE_OS = ["linux", "darwin"]


def is_shell_installed(shell_name: str) -> bool:
    """
    Check if the user's system has the compatible
    chosen shell.

    Parameters
    ----------
    shell_name : str
        Chosen shell name

    Returns
    -------
    bool
        Whether the chosen shell is installed on
        the user's machine
    """
    try:
        # Run the shell with the "--version" option to check if it's installed
        subprocess.check_call(
            [shell_name, "--version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        return True
    except (OSError, subprocess.CalledProcessError):
        return False


def is_system_compatible(possible_os_list: List[str]) -> bool:
    """
    Check if the user's operating system is compatible with the
    covered OS list for the project.

    Parameters
    ----------
    possible_os_list : List[str]
        List of convered operating systems

    Returns
    -------
    bool
        Whether the system is compatible or not
    """
    return any(
        os_value.lower() in sys.platform.lower() for os_value in possible_os_list
    )


def user_input_confirmation(question: str, default: str = "yes") -> bool:
    """
    Ask a yes/no question via input() and return the answer as a boolean value.

    Parameters
    ----------
    question : str
        Question presented to the user in the prompt
    default : str, optional
        The presumed answer if the user just hits <Enter>, by default "yes"

        The 'default' argument must be:
            - "yes": <Enter> is interpreted as a yes,
            - "no" or None: meaning an answer is required of the user

    Returns
    -------
    bool
        return True for "yes"
        return False for "no"

    Raises
    ------
    ValueError
        If the default parameter is neither a 'yes', 'no' or None, raise a ValueError.
    """

    # Initilize a yes/no value mapper
    valid = {"yes": True, "y": True, "ye": True, "no": False, "n": False}

    if default is None:
        prompt = " [y/n] "
    elif default == "yes":
        prompt = " [Y/n] "
    elif default == "no":
        prompt = " [y/N] "
    else:
        raise ValueError("invalid default answer: '%s'" % default)

    while True:
        sys.stdout.write(question + prompt)
        choice = input().lower()
        if default is not None and choice == "":
            return valid[default]
        elif choice in valid:
            return valid[choice]
        else:
            sys.stdout.write("Please respond with 'yes' or 'no' " "(or 'y' or 'n').\n")


parser = argparse.ArgumentParser(
    prog=APP_NAME,
    description=f"{APP_NAME} - Automatically activate Python virtual environments based on project directories.",
    epilog="Please restart the terminal after installation for the changes to take effect.",
)

parser.add_argument(
    "shells",
    choices=list(SHELL_CONFIGS.keys()),
    nargs="+",
    help=f"The shell to install {APP_NAME} for.",
)
args = parser.parse_args()

# Get the chosen shells from the arguments
chosen_shells = args.shells

for chosen_shell in chosen_shells:
    # Check if the chosen shell is installed
    if not is_shell_installed(chosen_shell):
        print(f"Error: '{chosen_shell}' is not installed on your system.")
        sys.exit(1)

    # Check if the system is compatible
    if not is_system_compatible(POSSIBLE_OS):
        print(f"Error: {APP_NAME} is currently not supported on your system.")
        sys.exit(1)

    # Get the path to the activator script
    dotactivator_script_path = os.path.join(TARGET_FOLDER, "activator.sh")

    # Get the config file for the chosen shell
    config_file = os.path.expanduser(f"~/{SHELL_CONFIGS[chosen_shell]}")

    # Check if the config file exists
    if not os.path.exists(config_file):
        create_script_file = user_input_confirmation(
            f"File '{config_file}' doesn't exist, it is required for the installation on '{chosen_shell}' shell. Do you want to create it?"
        )

        if not create_script_file:
            print(f"Skipping installation for '{chosen_shell}' shell.")
            continue

    # Check if the config file already sources the activator script
    with open(config_file, "r+") as f:
        content = f.read()

        if 'source "$activator_path"' in content:
            print(f"Activator script is already sourced in {config_file}")
        else:
            # Append the source command to the end of the config file
            f.write(
                f"""\n
############################# {APP_NAME} #############################
activator_path="{dotactivator_script_path}"

if [ -e "$activator_path" ]; then
source "$activator_path"
else
echo -e "\\033[1m{APP_NAME}\\033[0m: Activator script path not found: $activator_path"
fi
#########################################################################
"""
            )
            print(f"Activator script sourced in {config_file}")

    # Source the config file in the current shell
    os.system(f". {config_file}")

print(f"The {APP_NAME} is installed for the chosen shells. Please restart the terminal for the changes to take effect.")