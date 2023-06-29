import os
import curses
import helpers

APP_NAME = "AutoActivator"
PROMPT_TITLE = f"Choose which shell do you want to install {APP_NAME} for (you can choose more than one), press 'q' to quit."
SHELL_CONFIGS = {"bash": ".bashrc", "zsh": ".zshrc"}
POSSIBLE_OS = ["linux", "darwin"]

input_shells = curses.wrapper(
    helpers.pick_shell, 
    options=list(SHELL_CONFIGS.keys()), 
    title=PROMPT_TITLE
)

if input_shells:
    # Get the path to the activator script
    autoactivator_folder_path = os.path.dirname(__file__)
    activator_script_path = os.path.join(autoactivator_folder_path, "activator.sh")

    for shell in input_shells:
        if helpers.is_system_compatible(POSSIBLE_OS):
            if helpers.is_shell_installed(shell):

                config_file = os.path.expanduser(f"~/{SHELL_CONFIGS[shell]}")
                if not os.path.exists(config_file):

                    create_script_file = helpers.user_input_confirmation(
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
                        f.write(f"\n# The {APP_NAME.title()} script\nsource {activator_script_path}\n")
                        print(f"Activator script sourced in {config_file}")

                os.system(f". {config_file}")

            else:
                print(f"Sorry, '{shell}' is not installed in your system.")
        else:
            print(f"Sorry, {APP_NAME} is currently not supported by your system.")

    print(f"The {APP_NAME} is installed in your system. Please restart the terminal in order for the full effect.")
else:
    print("Abort: User quit.")