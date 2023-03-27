import os
import sys
import pick
import subprocess

APP_NAME = "autoactivator"
PROMPT_TITLE = f"Choose which shell do you want to install {APP_NAME} for (you can choose more than one):"
SHELL_CONFIGS = {"bash": ".bashrc", "zsh": ".zshrc"}
POSSIBLE_OS = ["linux", "darwin"]

def is_shell_installed(shell_name: str) -> bool:
    try:
        # Run the shell with the "--version" option to check if it's installed
        subprocess.check_call(
            [shell_name, "--version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        return True
    except (OSError, subprocess.CalledProcessError):
        return False


def is_unixbased_system() -> bool:
    return any(os_value.lower() in sys.platform.lower() for os_value in POSSIBLE_OS)

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


install_input = pick.pick(
    options=list(SHELL_CONFIGS.keys()),
    title=PROMPT_TITLE,
    indicator="->",
    multiselect=True,
    min_selection_count=1,
)


input_shells = list(zip(*install_input))[0]

# Get the path to the activator script
autoactivator_folder_path = os.path.dirname(__file__)
activator_script_path = os.path.join(autoactivator_folder_path, "activator.sh")

for shell in input_shells:
    if is_unixbased_system():
        if is_shell_installed(shell):

            config_file = os.path.expanduser(f"~/{SHELL_CONFIGS[shell]}")
            if not os.path.exists(config_file):

                create_script_file = user_input_confirmation(
                    f"File '{config_file}' doesn't exist, it is required for the installation on '{shell}' shell. Do you want to create it?"
                )

                if create_script_file:
                    mode = "w+"
                else:
                    print(f"Skipping installation for '{shell}' shell.")
                    continue
            else:
                mode = "r+"

            # Check if the config file already sources the activator script
            with open(config_file, mode) as f:
                content = f.read()

                if f"source {activator_script_path}" in content:
                    print(f"Activator script already sourced in {config_file}")

                else:
                    # Append the source command to the end of the config file
                    f.write(f"\n# The {APP_NAME.title()} script\nsource {activator_script_path}\n""")
                    print(f"Activator script sourced in {config_file}")

            os.system(f". {config_file}")

        else:
            print(f"Sorry, '{shell}' is not installed in your system.")
    else:
        print(f"Sorry, {APP_NAME} is currently only available for Unix-based systems.")
