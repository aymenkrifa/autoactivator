# ANSI color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'


_check_for_venv() {
  # Check if there's an active virtualenv and exit if found
  if [[ "$VIRTUAL_ENV" ]]; then
    # If we're changing out of the main directory, deactivate the virtualenv
    if [[ "$PWD" != "${VIRTUAL_ENV%/}"* ]]; then
      deactivate
    else
      return
    fi
  fi

  # Traverse up the directory tree until a virtualenv is found, or until we reach the root directory
  dir=$PWD
  while [[ "$dir" != "/" ]]; do
    # Check if there are any virtual environment directories present
    if [[ $(find "$dir" -maxdepth 1 -type d -name "*" | wc -l) -gt 1 ]]; then
      for venv_dir in "$dir"/*; do
        if [[ -d "$venv_dir" && -e "$venv_dir/bin/activate" && ! -e "$venv_dir/bin/conda" ]]; then
          # Virtualenv found, activate it and record the original directory
          source "$venv_dir/bin/activate"
          export VENV_ORIGINAL_DIR="$PWD"
          return
        fi
      done
    fi
    dir=$(dirname "$dir")
  done
}



# Define a function to be called whenever the current directory changes
_chpwd() {
  _check_for_venv

  # If we're changing back to the original directory, reactivate the virtualenv
  if [[ "$VIRTUAL_ENV" && "$PWD" == "${VENV_ORIGINAL_DIR%/}"* ]]; then
    if [[ ! -e "$VIRTUAL_ENV/bin/activate" ]]; then
      echo -e "${YELLOW}WARNING: Virtual environment activation failed. It appears that the virtual environment has been moved or deleted.${RESET}"
      echo -e "${YELLOW}VIRTUAL_ENV variable is pointing to a different path: '$VIRTUAL_ENV'.${RESET}"
    else
      source "$VIRTUAL_ENV/bin/activate"
    fi
  fi
}

# Call the function once at startup to ensure the correct virtualenv is active
_check_for_venv

# Set the chpwd hook to call _chpwd whenever the current directory changes
if [[ -n "$ZSH_VERSION" ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook chpwd _chpwd
elif [[ -n "$BASH_VERSION" ]]; then
  PROMPT_COMMAND="_chpwd;$PROMPT_COMMAND"
fi
