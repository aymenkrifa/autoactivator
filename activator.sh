# ANSI color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# Enable nullglob option for ZSH to support search
if [[ $(ps -p $$ -ocomm=) == *zsh* ]]; then
  setopt nullglob
fi

# Cache for virtual environment paths
declare -A VENV_CACHE

_check_for_venv() {
  if [[ "$VIRTUAL_ENV" ]]; then
    if [[ "$PWD" != "${VIRTUAL_ENV%/}"* ]]; then
      if command -v deactivate &> /dev/null; then
        deactivate
      fi
    else
      return
    fi
  fi

  dir=$PWD
  while [[ "$dir" != "/" ]]; do
    if [[ -n "${VENV_CACHE[$dir]}" ]]; then
      source "${VENV_CACHE[$dir]}/bin/activate"
      export VENV_ORIGINAL_DIR="$PWD"
      return
    fi

    if [[ $(find "$dir" -maxdepth 1 -type d | wc -l) -gt 1 ]]; then
      for venv_dir in "$dir"/* "$dir"/.*; do
        if [[ -d "$venv_dir" && -e "$venv_dir/bin/activate" && ! -e "$venv_dir/bin/conda" ]]; then
          source "$venv_dir/bin/activate"
          export VENV_ORIGINAL_DIR="$PWD"
          VENV_CACHE[$dir]="$venv_dir"
          return
        fi
      done
    fi
    dir=$(dirname "$dir")
  done
}

_chpwd() {
  _check_for_venv

  if [[ "$VIRTUAL_ENV" && "$PWD" == "${VENV_ORIGINAL_DIR%/}"* ]]; then
    if [[ ! -e "$VIRTUAL_ENV/bin/activate" ]]; then
      echo -e "${YELLOW}WARNING: Virtual environment activation failed. It appears that the virtual environment has been moved or deleted.${RESET}"
      echo -e "${YELLOW}VIRTUAL_ENV variable is pointing to a different path: '$VIRTUAL_ENV'.${RESET}"
    else
      source "$VIRTUAL_ENV/bin/activate"
    fi
  fi
}

_check_for_venv

if [[ -n "$ZSH_VERSION" ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook chpwd _chpwd
elif [[ -n "$BASH_VERSION" ]]; then
  PROMPT_COMMAND="_chpwd;$PROMPT_COMMAND"
fi
