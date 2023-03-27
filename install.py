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

            # Check if the config file already sources the activator script
            with open(config_file, "r+") as f:
                content = f.read()

                if f"source {activator_script_path}" in content:
                    print(f"Activator script already sourced in {config_file}")

                else:
                    # Append the source command to the end of the config file
                    f.write(f"""\nsource {activator_script_path}\n""")
                    print(f"Activator script sourced in {config_file}")

            os.system(f". {config_file}")
        else:
            print(f"Sorry, '{shell}' is not installed in your system.")
    else:
        print(f"Sorry, {APP_NAME} is currently only available for Unix-based systems.")
