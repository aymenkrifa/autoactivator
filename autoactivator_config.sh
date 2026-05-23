APP_NAME="AutoActivator"
autoactivator_folder="$HOME/.autoactivator"
activator_path="$autoactivator_folder/activator.sh"

_autoactivator_msg() {
    # $1 = stream (1=stdout, 2=stderr), rest = message
    local stream=$1; shift
    printf '\033[1m%s\033[0m: %s\n' "$APP_NAME" "$*" >&"$stream"
}

if [ -e "$activator_path" ]; then
    # shellcheck source=activator.sh disable=SC1091
    source "$activator_path"
else
    _autoactivator_msg 2 "activator script not found: $activator_path"
fi

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

# Path to the shell rc file for the current shell, or "" if unknown.
_autoactivator_rc_path() {
    if [ -n "$ZSH_VERSION" ]; then
        printf '%s' "$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        printf '%s' "$HOME/.bashrc"
    fi
}

# Number of cache entries in this shell, or "n/a" when associative arrays
# aren't available (bash < 4).
_autoactivator_cache_count() {
    if [ -n "$ZSH_VERSION" ]; then
        printf '%d' "${#_AUTOACTIVATOR_CACHE[@]}"
    elif ((${BASH_VERSINFO[0]:-0} >= 4)); then
        printf '%d' "${#_AUTOACTIVATOR_CACHE[@]}"
    else
        printf 'n/a (bash < 4)'
    fi
}

# ---------------------------------------------------------------------------
# Subcommands
#
# Each subcommand lives in its own _autoactivator_cmd_<name> function. To add
# a new one: define the function, then add a case in the dispatcher and a
# line in the help text below.
# ---------------------------------------------------------------------------

_autoactivator_cmd_help() {
    cat <<EOF
AutoActivator — auto-activate Python venvs on cd

Usage: autoactivator <command>

Commands:
  status     Show current activation state and configuration
  doctor     Diagnose installation health
  version    Show installed version
  update     Pull the latest version
  help       Show this help
EOF
}

_autoactivator_cmd_version() {
    if [ ! -d "$autoactivator_folder/.git" ]; then
        _autoactivator_msg 2 "not a git checkout at $autoactivator_folder."
        return 1
    fi

    local sha tag
    sha=$(git -C "$autoactivator_folder" rev-parse --short HEAD 2>/dev/null) || {
        _autoactivator_msg 2 "could not read git revision."
        return 1
    }
    tag=$(git -C "$autoactivator_folder" describe --tags --abbrev=0 2>/dev/null)

    if [ -n "$tag" ]; then
        _autoactivator_msg 1 "$tag ($sha)"
    else
        _autoactivator_msg 1 "$sha (no tag)"
    fi
}

_autoactivator_cmd_status() {
    _autoactivator_msg 1 "status"
    printf '\n'

    if [ -n "$VIRTUAL_ENV" ]; then
        if [ -n "$VENV_ORIGINAL_DIR" ]; then
            printf '  Active venv:    %s\n' "$VIRTUAL_ENV"
            printf '  Project root:   %s\n' "$VENV_ORIGINAL_DIR"
        else
            printf '  Active venv:    %s (not managed by AutoActivator)\n' "$VIRTUAL_ENV"
        fi
    else
        printf '  Active venv:    (none)\n'
    fi

    printf '\n'

    if [ -n "$AUTOACTIVATOR_VENV_NAME" ]; then
        printf '  Venv name:      %s (override)\n' "$AUTOACTIVATOR_VENV_NAME"
    else
        printf '  Venv name:      .venv (default)\n'
    fi
    printf '  Boundary:       %s\n' "${AUTOACTIVATOR_BOUNDARY:-$HOME}"
    printf '  Cache entries:  %s (this shell)\n' "$(_autoactivator_cache_count)"
}

# Print one doctor check line and update the caller-scoped counters
# _aa_fails / _aa_warns. Relies on dynamic scoping (works in bash and zsh).
_autoactivator_check() {
    # $1 = ok|warn|fail, $2 = message
    case "$1" in
        ok)   printf '  [ok]    %s\n' "$2" ;;
        warn) printf '  [warn]  %s\n' "$2"; _aa_warns=$((_aa_warns + 1)) ;;
        fail) printf '  [fail]  %s\n' "$2"; _aa_fails=$((_aa_fails + 1)) ;;
    esac
}

_autoactivator_cmd_doctor() {
    _autoactivator_msg 1 "doctor"
    printf '\n'

    local _aa_fails=0 _aa_warns=0
    local rc branch
    rc=$(_autoactivator_rc_path)

    # 1. Repo present.
    if [ -d "$autoactivator_folder/.git" ]; then
        _autoactivator_check ok "repo present at $autoactivator_folder"

        # 2. Branch + cleanliness (only meaningful when repo exists).
        branch=$(git -C "$autoactivator_folder" rev-parse --abbrev-ref HEAD 2>/dev/null)
        if git -C "$autoactivator_folder" diff --quiet HEAD 2>/dev/null; then
            _autoactivator_check ok "on branch ${branch:-?}, clean working tree"
        else
            _autoactivator_check warn "local modifications in $autoactivator_folder — \`update\` will refuse to run"
        fi
    else
        _autoactivator_check fail "repo NOT found at $autoactivator_folder"
    fi

    # 3. Activator block referenced from the shell rc.
    if [ -n "$rc" ] && [ -f "$rc" ] && grep -q "autoactivator_config.sh" "$rc" 2>/dev/null; then
        _autoactivator_check ok "activator block found in $rc"
    elif [ -n "$rc" ]; then
        _autoactivator_check fail "activator block NOT found in $rc"
    else
        _autoactivator_check warn "unknown shell — could not locate rc file"
    fi

    # 4. Activator sourced into current shell.
    if command -v _check_for_venv >/dev/null 2>&1; then
        _autoactivator_check ok "activator sourced in current shell"
    else
        _autoactivator_check fail "activator NOT sourced in current shell — restart your terminal or \`source ${rc:-your shell rc}\`"
    fi

    # 5. cd hook registered.
    if [ -n "$ZSH_VERSION" ]; then
        if (( ${chpwd_functions[(I)_check_for_venv]:-0} )); then
            _autoactivator_check ok "chpwd hook registered (zsh)"
        else
            _autoactivator_check fail "chpwd hook NOT registered"
        fi
    elif [ -n "$BASH_VERSION" ]; then
        if [[ "$PROMPT_COMMAND" == *"_autoactivator_bash_chpwd"* ]]; then
            _autoactivator_check ok "PROMPT_COMMAND hook registered (bash)"
        else
            _autoactivator_check fail "PROMPT_COMMAND hook NOT registered"
        fi
    fi

    printf '\n'
    local total=$((_aa_fails + _aa_warns))
    if (( total == 0 )); then
        printf 'All checks passed.\n'
        return 0
    elif (( _aa_fails == 0 )); then
        printf '%d warning(s).\n' "$total"
        return 0
    else
        printf '%d issue(s) found.\n' "$total"
        return 1
    fi
}

_autoactivator_cmd_update() {
    if [ ! -d "$autoactivator_folder/.git" ]; then
        _autoactivator_msg 2 "not a git checkout at $autoactivator_folder — cannot update."
        return 1
    fi

    # Refuse to clobber local edits silently.
    if ! git -C "$autoactivator_folder" diff --quiet HEAD 2>/dev/null; then
        _autoactivator_msg 2 "local modifications detected in $autoactivator_folder — refusing to update."
        _autoactivator_msg 2 "stash or reset them, then retry."
        return 1
    fi

    local before after
    before=$(git -C "$autoactivator_folder" rev-parse HEAD 2>/dev/null) || {
        _autoactivator_msg 2 "could not read current HEAD."
        return 1
    }

    if ! git -C "$autoactivator_folder" pull --ff-only --quiet origin main; then
        _autoactivator_msg 2 "update failed (pull was not a fast-forward, or network is down)."
        return 1
    fi

    after=$(git -C "$autoactivator_folder" rev-parse HEAD)

    if [ "$before" = "$after" ]; then
        _autoactivator_msg 1 "already up to date."
        return 0
    fi

    _autoactivator_msg 1 "updated to the latest version."

    # shellcheck source=activator.sh disable=SC1091
    source "$activator_path"
    _autoactivator_msg 1 "activator reloaded. Restart your terminal if shell config changed."
}

# ---------------------------------------------------------------------------
# Dispatcher
# ---------------------------------------------------------------------------

autoactivator() {
    case "$1" in
        ""|help|-h|--help)  _autoactivator_cmd_help ;;
        status)             _autoactivator_cmd_status ;;
        doctor)             _autoactivator_cmd_doctor ;;
        version|--version)  _autoactivator_cmd_version ;;
        update)             _autoactivator_cmd_update ;;
        *)
            _autoactivator_msg 2 "unknown command: $1"
            _autoactivator_msg 2 "run \`autoactivator help\` for usage."
            return 1
            ;;
    esac
}
