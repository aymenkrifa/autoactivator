import sys
import curses
import subprocess
from typing import List


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
            [shell_name, "--version"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
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
        os_value.lower() in sys.platform.lower()
        for os_value in possible_os_list
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
        If the default parameter is neither a 'yes', 'no' or None,
        raise a ValueError.
    """

    # Initilize a yes/no value mapper
    valid = {"yes": True, "y": True, "ye": True, "no": False, "n": False}

    if default == "yes":
        prompt = " [Y/n] "
    elif default == "no":
        prompt = " [y/N] "
    else:
        raise ValueError("invalid default answer: '%s'" % default)

    while True:
        choice = input(question + prompt).strip().lower()
        if default is not None and choice == "":
            return valid[default]
        elif choice in valid:
            return valid[choice]
        else:
            print("Please respond with 'yes' or 'no' (or 'y' or 'n').")


def pick_shell(stdscr, options: list, title: str):
    # Clear the screen
    stdscr.clear()

    # Initialize the curses settings
    curses.curs_set(0)
    stdscr.nodelay(1)
    stdscr.keypad(1)
    stdscr.timeout(100)

    # Initialize the selected options list
    selected_options = []

    # Initialize the current position of the selection
    current_position = 0

    while True:
        # Clear the screen
        stdscr.clear()

        # Print the title
        stdscr.addstr(0, 0, title, curses.A_BOLD)

        # Print the menu options
        for i, option in enumerate(options):
            if option in selected_options:
                stdscr.addstr(i + 2, 4, "[x] " + option, curses.A_REVERSE)
            else:
                stdscr.addstr(i + 2, 4, "[ ] " + option)

            # Display arrow indicator on the current selection
            if i == current_position:
                stdscr.addstr(i + 2, 0, "->", curses.A_REVERSE)

        # Refresh the screen to display changes
        stdscr.refresh()

        # Wait for user input
        key = stdscr.getch()

        # Handle user input
        if key == ord("q"):
            return None

        elif key == curses.KEY_UP:
            # Move the selection up
            current_position -= 1
            if current_position < 0:
                current_position = len(options) - 1

        elif key == curses.KEY_DOWN:
            # Move the selection down
            current_position += 1
            if current_position >= len(options):
                current_position = 0

        elif key == ord(" "):
            # Toggle the selection of the current option
            current_option = options[current_position]
            if current_option in selected_options:
                selected_options.remove(current_option)
            else:
                selected_options.append(current_option)

        elif key == curses.KEY_ENTER or key == 10 or key == 13:
            # Process ENTER key to finish selection
            if len(selected_options) > 0:
                break

    return selected_options
