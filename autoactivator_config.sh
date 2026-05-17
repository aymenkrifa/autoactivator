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

autoactivator_update() {
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

autoactivator() {
    case "$1" in
        update)
            autoactivator_update
            ;;
        *)
            _autoactivator_msg 2 "Usage: autoactivator update"
            return 1
            ;;
    esac
}
