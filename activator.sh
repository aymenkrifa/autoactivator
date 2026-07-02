# Upper bound for the directory walk. Users can override before sourcing.
: "${AUTOACTIVATOR_BOUNDARY:=$HOME}"

# Per-shell memo: $PWD -> venv path. Only successful finds are cached, so a
# venv created after a directory was first visited is still picked up.
# The sentinel exists because bash expands ${_AUTOACTIVATOR_CACHE+set} as
# "is element [0] set", which is never true for an associative array used
# as a path map — testing the array directly would disable the cache.
if [[ -n "$ZSH_VERSION" ]]; then
  typeset -gA _AUTOACTIVATOR_CACHE
  _AUTOACTIVATOR_HAVE_CACHE=1
elif ((${BASH_VERSINFO[0]:-0} >= 4)); then
  declare -gA _AUTOACTIVATOR_CACHE
  _AUTOACTIVATOR_HAVE_CACHE=1
else
  _AUTOACTIVATOR_HAVE_CACHE=0
fi

_autoactivator_is_venv() {
  [[ -d "$1" && -e "$1/bin/activate" && ! -e "$1/bin/conda" ]]
}

# Result is handed back in _AUTOACTIVATOR_FOUND rather than on stdout: a
# command substitution would fork once per directory level on every cd.
_autoactivator_find_venv_in_dir() {
  local d="$1"
  local candidate name
  _AUTOACTIVATOR_FOUND=""

  # 1. Explicit override (user preference).
  if [[ -n "$AUTOACTIVATOR_VENV_NAME" ]]; then
    candidate="$d/$AUTOACTIVATOR_VENV_NAME"
    if _autoactivator_is_venv "$candidate"; then
      _AUTOACTIVATOR_FOUND="$candidate"
      return 0
    fi
  fi

  # 2. Conventional names, in priority order.
  for name in .venv venv env virtualenv; do
    candidate="$d/$name"
    if _autoactivator_is_venv "$candidate"; then
      _AUTOACTIVATOR_FOUND="$candidate"
      return 0
    fi
  done

  # 3. Fallback: first directory in the tree that looks like a venv.
  #    The activator is sourced into the user's shell, so we must NOT
  #    leak nullglob globally. Scope it: zsh has `setopt localoptions`;
  #    bash needs manual save/restore. bash < 5.2 also globs "." and ".."
  #    (no globskipdots), which would treat $d or its parent as the venv,
  #    so both loops skip them by basename.
  if [[ -n "$ZSH_VERSION" ]]; then
    setopt localoptions nullglob
    for candidate in "$d"/* "$d"/.*; do
      case "${candidate##*/}" in .|..) continue ;; esac
      if _autoactivator_is_venv "$candidate"; then
        _AUTOACTIVATOR_FOUND="$candidate"
        return 0
      fi
    done
  else
    local _had_nullglob=0
    shopt -q nullglob && _had_nullglob=1
    shopt -s nullglob
    for candidate in "$d"/* "$d"/.*; do
      case "${candidate##*/}" in .|..) continue ;; esac
      if _autoactivator_is_venv "$candidate"; then
        ((_had_nullglob)) || shopt -u nullglob
        _AUTOACTIVATOR_FOUND="$candidate"
        return 0
      fi
    done
    ((_had_nullglob)) || shopt -u nullglob
  fi
  return 1
}

_check_for_venv() {
  # A venv the user activated by hand (VIRTUAL_ENV set, but not by us) is
  # never touched; autoactivation resumes once they deactivate.
  if [[ -n "$VIRTUAL_ENV" && -z "$VENV_ORIGINAL_DIR" ]]; then
    return
  fi

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

  # Cache lookup. A stale entry (venv deleted since it was cached) is
  # dropped and falls through to the walk, so the same cd still recovers.
  if (( _AUTOACTIVATOR_HAVE_CACHE )) && [[ -n "${_AUTOACTIVATOR_CACHE[$PWD]+set}" ]]; then
    local cached="${_AUTOACTIVATOR_CACHE[$PWD]}"
    if [[ -n "$cached" && -e "$cached/bin/activate" ]]; then
      source "$cached/bin/activate"
      export VENV_ORIGINAL_DIR="$PWD"
      return
    fi
    unset "_AUTOACTIVATOR_CACHE[$PWD]"
  fi

  # Walk up, bounded.
  local dir="$PWD"
  local found=""
  while :; do
    if _autoactivator_find_venv_in_dir "$dir"; then
      found="$_AUTOACTIVATOR_FOUND"
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

  if [[ -n "$found" ]]; then
    if (( _AUTOACTIVATOR_HAVE_CACHE )); then
      _AUTOACTIVATOR_CACHE[$PWD]="$found"
    fi
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
  add-zsh-hook chpwd _check_for_venv
elif [[ -n "$BASH_VERSION" ]]; then
  if [[ "$PROMPT_COMMAND" != *"_autoactivator_bash_chpwd"* ]]; then
    PROMPT_COMMAND="_autoactivator_bash_chpwd;${PROMPT_COMMAND}"
  fi
fi
