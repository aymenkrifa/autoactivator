import os
import sys
import shutil
import argparse
import subprocess
from typing import List
from pathlib import Path


APP_NAME = "AutoActivator"
HOME_FOLDER = str(Path.home())
TARGET_FOLDER = os.path.join(HOME_FOLDER, ".autoactivator")
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

def backup_shell_config(shell_name: str):
    """
    Create a backup of the shell configuration file.

    Parameters
    ----------
    shell_name : str
        Chosen shell name
    """
    config_file = os.path.join(HOME_FOLDER, SHELL_CONFIGS[shell_name])
    if os.path.exists(config_file):
        backup_file = os.path.join(HOME_FOLDER, f"{SHELL_CONFIGS[shell_name]}.pre-{APP_NAME.lower()}")
        shutil.copyfile(config_file, backup_file)
        print(f"Created a backup of {SHELL_CONFIGS[shell_name]} at {backup_file}")


parser = argparse.ArgumentParser(
    prog=APP_NAME,
    description=f"{APP_NAME} - Automatically activate Python virtual environments based on project directories.",
    epilog="Please restart the terminal after installation for the changes to take effect.",
)

parser.add_argument(
    "shells",
    choices=list(SHELL_CONFIGS.keys()),
    nargs="+",
    type=str.lower,
    help=f"The shell to install {APP_NAME} for.",
)
args = parser.parse_args()

chosen_shells = args.shells
not_installed_shells = 0
installed_shells = []

for chosen_shell in chosen_shells:
    print()
    if not is_shell_installed(chosen_shell):
        print(f"Error: '{chosen_shell}' is not installed on your system.")
        sys.exit(1)

    if not is_system_compatible(POSSIBLE_OS):
        print(f"Error: {APP_NAME} is currently not supported on your system.")
        sys.exit(1)

    backup_shell_config(chosen_shell)
    
    # Get the path to the activator script and the config file
    dotactivator_script_path = os.path.join(TARGET_FOLDER, "activator.sh")

    config_file = os.path.join(HOME_FOLDER, SHELL_CONFIGS[chosen_shell])

    if not os.path.exists(config_file):
        print(
            f"File '{config_file}' doesn't exist, it is required for the installation on '{chosen_shell}' shell. You can create it using 'touch ~/{chosen_shell}' and then re-run the script"
        )

        print(f"Skipping installation for '{chosen_shell}' shell.")
        not_installed_shells += 1
        continue

    with open(config_file, "r+") as f:
        content = f.read()

        if 'source "$activator_path"' in content:
            print(f"Activator script is already sourced in {config_file}")
        else:
            f.write(
                f"""\n
############################# {APP_NAME} #############################
autoactivator_folder="{TARGET_FOLDER}"
activator_path="{dotactivator_script_path}"

if [ -e "$activator_path" ]; then
source "$activator_path"
else
echo -e "\\033[1m{APP_NAME}\\033[0m: Activator script path not found: $activator_path"
fi

autoactivator_update() {{
    if [ -d "$autoactivator_folder" ]; then
        git --git-dir="$autoactivator_folder/.git" --work-tree="$autoactivator_folder" pull origin main
        source "$activator_path"
    else
        echo -e "\\033[1m{APP_NAME}\\033[0m: {APP_NAME} directory not found."
    fi
}}

autoactivator() {{
    case "$1" in
        "update")
            autoactivator_update
            ;;
        *)
            echo -e "\\033[1m{APP_NAME}\\033[0m: Invalid command. Usage: autoactivator [update]"
            ;;
    esac
}}
#########################################################################
"""
            )
            print(f"Activator script sourced in {config_file}")

    # Source the config file in the current shell
    os.system(f". {config_file}")
    installed_shells.append(chosen_shell)

if not_installed_shells == len(chosen_shells):
    print("ERROR: An error occured while setting-up all the chosen shell")
    print("Please check the GitHub page for the issue encountered.")
else:
    print(
        f"\nThe {APP_NAME} is installed for {installed_shells}. Please restart the terminal for the changes to take effect."
    )
