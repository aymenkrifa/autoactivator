#!/usr/bin/env bash
set -e

APP_NAME="AutoActivator"
TARGET_DIR="$HOME/.autoactivator"
REPO_URL="${AUTOACTIVATOR_REPO_URL:-https://github.com/aymenkrifa/autoactivator}"

die() { echo "Error: $*" >&2; exit 1; }

rc_for_shell() {
  case "$1" in
    bash) printf '%s/.bashrc' "$HOME" ;;
    zsh)  printf '%s/.zshrc'  "$HOME" ;;
  esac
}

[ $# -gt 0 ] || die "Usage: $(basename "$0") <shell> [<shell>...]  (shells: bash, zsh)"

for s in "$@"; do
  case "$s" in
    bash|zsh) ;;
    *) die "Unsupported shell '$s'. Must be 'bash' or 'zsh'." ;;
  esac
done

case "$(uname -s)" in
  Linux|Darwin) ;;
  *) die "Unsupported OS: $(uname -s). Only Linux and macOS are supported." ;;
esac

command -v git >/dev/null 2>&1 || die "git is not installed. https://git-scm.com/"

if [ -d "$TARGET_DIR/.git" ]; then
  echo "$APP_NAME is already cloned at $TARGET_DIR. Pulling latest..."
  git -C "$TARGET_DIR" pull --ff-only origin main
elif [ -e "$TARGET_DIR" ]; then
  die "$TARGET_DIR exists but is not a git checkout. Move or remove it and re-run."
else
  echo "Cloning $REPO_URL to $TARGET_DIR ..."
  git clone "$REPO_URL" "$TARGET_DIR"
fi

CONFIG_PATH="$TARGET_DIR/autoactivator_config.sh"
[ -f "$CONFIG_PATH" ] || die "Expected $CONFIG_PATH after clone but it's missing."

CONSTANTS_PATH="$TARGET_DIR/_constants.sh"
[ -f "$CONSTANTS_PATH" ] || die "Expected $CONSTANTS_PATH after clone but it's missing."
# shellcheck source=_constants.sh disable=SC1091
. "$CONSTANTS_PATH"

installed=()
for shell in "$@"; do
  if ! command -v "$shell" >/dev/null 2>&1; then
    echo "Skipping $shell: not installed on this system."
    continue
  fi

  rc=$(rc_for_shell "$shell")
  if [ ! -f "$rc" ]; then
    echo "Skipping $shell: $rc does not exist. Run 'touch $rc' and re-run."
    continue
  fi

  backup="$rc.pre-autoactivator"
  if [ ! -e "$backup" ]; then
    cp -p "$rc" "$backup"
    echo "Created backup: $backup"
  fi

  if grep -qF "$AUTOACTIVATOR_BLOCK_OPEN" "$rc"; then
    echo "$APP_NAME already sourced in $rc"
  else
    cat >> "$rc" <<EOF

$AUTOACTIVATOR_BLOCK_OPEN
source $CONFIG_PATH
$AUTOACTIVATOR_BLOCK_CLOSE
EOF
    echo "$APP_NAME sourced in $rc"
  fi
  installed+=("$shell")
done

[ ${#installed[@]} -gt 0 ] || die "Could not install for any of the requested shells."

echo
echo "$APP_NAME installed for: ${installed[*]}"
echo "Restart your terminal for the changes to take effect."
