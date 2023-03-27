import sys
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
