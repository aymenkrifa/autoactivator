# Upper bound for the directory walk. Users can override before sourcing.
: "${AUTOACTIVATOR_BOUNDARY:=$HOME}"

# Make empty globs vanish (both shells)
if [[ -n "$ZSH_VERSION" ]]; then
  setopt nullglob
elif [[ -n "$BASH_VERSION" ]]; then
  shopt -s nullglob
fi

# Per-shell memo: $PWD -> venv path (empty string = "walked, no venv").
# Missing key = "not yet walked".
if [[ -n "$ZSH_VERSION" ]]; then
  typeset -gA _AUTOACTIVATOR_CACHE
elif ((${BASH_VERSINFO[0]:-0} >= 4)); then
  declare -gA _AUTOACTIVATOR_CACHE
fi

_autoactivator_find_venv_in_dir() {
  local d="$1"
  local candidate
  for candidate in "$d"/* "$d"/.*; do
    if [[ -d "$candidate" && -e "$candidate/bin/activate" && ! -e "$candidate/bin/conda" ]]; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  return 1
}

_check_for_venv() {
  # If autoactivator has an active venv, decide whether we left its project tree.
  if [[ -n "$VIRTUAL_ENV" && -n "$VENV_ORIGINAL_DIR" ]]; then
    if [[ "$PWD" == "$VENV_ORIGINAL_DIR" || "$PWD" == "${VENV_ORIGINAL_DIR%/}"/* ]]; then
      return
    fi
    if command -v deactivate &>/dev/null; then
      deactivate
    fi
    unset VENV_ORIGINAL_DIR
  fi

  # Cache lookup
  if [[ -n "${_AUTOACTIVATOR_CACHE+set}" && -n "${_AUTOACTIVATOR_CACHE[$PWD]+set}" ]]; then
    local cached="${_AUTOACTIVATOR_CACHE[$PWD]}"
    if [[ -n "$cached" ]]; then
      if [[ -e "$cached/bin/activate" ]]; then
        source "$cached/bin/activate"
        export VENV_ORIGINAL_DIR="$PWD"
      else
        unset "_AUTOACTIVATOR_CACHE[$PWD]"
      fi
    fi
    return
  fi

  # Walk up, bounded.
  local dir="$PWD"
  local found=""
  while :; do
    if found=$(_autoactivator_find_venv_in_dir "$dir"); then
      break
    fi
    if [[ "$dir" == "$AUTOACTIVATOR_BOUNDARY" || "$dir" == "/" ]]; then
      break
    fi
    local parent="${dir%/*}"
    [[ -z "$parent" ]] && parent="/"
    [[ "$parent" == "$dir" ]] && break
    dir="$parent"
  done

  if [[ -n "${_AUTOACTIVATOR_CACHE+set}" ]]; then
    _AUTOACTIVATOR_CACHE[$PWD]="$found"
  fi

  if [[ -n "$found" ]]; then
    source "$found/bin/activate"
    export VENV_ORIGINAL_DIR="$PWD"
  fi
}

# bash fires PROMPT_COMMAND on every prompt; gate on PWD change so the
# real work only runs on cd.
_autoactivator_bash_chpwd() {
  if [[ "$PWD" != "$_AUTOACTIVATOR_LAST_PWD" ]]; then
    _AUTOACTIVATOR_LAST_PWD="$PWD"
    _check_for_venv
  fi
}

# Initial check so a shell that starts inside a project is already active.
_check_for_venv

# Register the cd hook idempotently.
if [[ -n "$ZSH_VERSION" ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook -d chpwd _chpwd 2>/dev/null
  add-zsh-hook chpwd _check_for_venv
elif [[ -n "$BASH_VERSION" ]]; then
  if [[ "$PROMPT_COMMAND" != *"_autoactivator_bash_chpwd"* ]]; then
    PROMPT_COMMAND="_autoactivator_bash_chpwd;${PROMPT_COMMAND}"
  fi
fi
