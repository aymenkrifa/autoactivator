APP_NAME="AutoActivator"
autoactivator_folder="$HOME/.autoactivator"
activator_path="$autoactivator_folder/activator.sh"

if [ -e "$activator_path" ]; then
    # shellcheck source=activator.sh disable=SC1091
    source "$activator_path"
else
    echo -e "\\033[1m{$APP_NAME}\\033[0m: Activator script path not found: $activator_path"
fi

autoactivator_update() {
    if [ -d "$autoactivator_folder" ]; then
        git --git-dir="$autoactivator_folder/.git" --work-tree="$autoactivator_folder" pull origin main
        # shellcheck source=activator.sh disable=SC1091
        source "$activator_path"
    else
        echo -e "\\033[1m{$APP_NAME}\\033[0m: {$APP_NAME} directory not found."
    fi
}

autoactivator() {
    case "$1" in
    "update")
        autoactivator_update
        ;;
    *)
        echo -e "\\033[1m{$APP_NAME}\\033[0m: Invalid command. Usage: autoactivator [update]"
        ;;
    esac
}
