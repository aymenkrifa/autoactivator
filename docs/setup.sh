#!/usr/bin/env bash
set -e

APP_NAME="AutoActivator"
TARGET_DIR="$HOME/.autoactivator"
REPO_URL="${AUTOACTIVATOR_REPO_URL:-https://github.com/aymenkrifa/autoactivator}"
TARBALL_URL="${AUTOACTIVATOR_TARBALL_URL:-${REPO_URL%.git}/archive/refs/heads/main.tar.gz}"
ONELINER="curl -sSL https://autoactivator.aymenkrifa.com/setup.sh | bash"

die() { echo "Error: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

rc_for_shell() {
  case "$1" in
    bash) printf '%s/.bashrc' "$HOME" ;;
    zsh)  printf '%s/.zshrc'  "$HOME" ;;
  esac
}

# Fetch and unpack a source tarball into $TARGET_DIR when git is missing.
# Staged in a temp dir beside the target so a failed download or extract
# can never leave a half-install at $TARGET_DIR.
tarball_install() {
  if ! { have curl || have wget; } || ! have tar; then
    die "git is not installed, and the tarball fallback needs curl or wget, plus tar. Install git (recommended), or curl/wget and tar, then re-run."
  fi
  echo "git not found — downloading $APP_NAME as a tarball instead ..."
  TMP_STAGE=$(mktemp -d "$HOME/.autoactivator.new.XXXXXX")
  trap 'rm -rf "$TMP_STAGE"' EXIT
  if have curl; then
    curl -fsSL "$TARBALL_URL" -o "$TMP_STAGE/src.tar.gz"
  else
    wget -qO "$TMP_STAGE/src.tar.gz" "$TARBALL_URL"
  fi
  mkdir "$TMP_STAGE/src"
  tar -xzf "$TMP_STAGE/src.tar.gz" -C "$TMP_STAGE/src" --strip-components=1
  rm -rf "$TARGET_DIR"
  mv "$TMP_STAGE/src" "$TARGET_DIR"
}

case "$(uname -s)" in
  Linux|Darwin) ;;
  *) die "Unsupported OS: $(uname -s). Only Linux and macOS are supported." ;;
esac

shells=()
if [ $# -gt 0 ]; then
  for s in "$@"; do
    case "$s" in
      bash|zsh) shells+=("$s") ;;
      *) die "Unsupported shell '$s'. Usage: $(basename "$0") [<shell>...]  (shells: bash, zsh; no arguments = auto-detect)" ;;
    esac
  done
else
  # No arguments: detect the user's shell. $0 is useless here (piped
  # installs always run under bash), but login shells leave $SHELL behind.
  s="${SHELL##*/}"
  if { [ "$s" = bash ] || [ "$s" = zsh ]; } && have "$s"; then
    echo "No shell specified — detected $s from \$SHELL."
    shells=("$s")
  else
    # $SHELL unset or unsupported: fall back to every supported shell
    # that is installed and already has an rc file.
    for s in bash zsh; do
      if have "$s" && [ -f "$(rc_for_shell "$s")" ]; then
        shells+=("$s")
      fi
    done
    [ ${#shells[@]} -eq 0 ] || echo "No shell specified — detected: ${shells[*]}."
  fi
  [ ${#shells[@]} -gt 0 ] || die "Could not auto-detect your shell (SHELL=${SHELL:-unset}). Re-run with an explicit shell, e.g.: $ONELINER -s zsh"
fi

if [ -d "$TARGET_DIR/.git" ]; then
  have git || die "$TARGET_DIR is a git checkout but git is no longer installed. Install git, or remove the directory (rm -rf $TARGET_DIR) and re-run."
  echo "$APP_NAME is already cloned at $TARGET_DIR. Pulling latest..."
  git -C "$TARGET_DIR" pull --ff-only origin main
elif [ -e "$TARGET_DIR" ]; then
  [ -f "$TARGET_DIR/autoactivator_config.sh" ] || die "$TARGET_DIR exists but is not an $APP_NAME install. Move or remove it and re-run."
  if have git; then
    # A previous tarball install: replace it with a git checkout so
    # 'autoactivator update' works from now on.
    echo "Upgrading $TARGET_DIR to a git checkout ..."
    rm -rf "$TARGET_DIR"
    git clone "$REPO_URL" "$TARGET_DIR"
  else
    echo "Refreshing the existing install at $TARGET_DIR ..."
    tarball_install
  fi
elif have git; then
  echo "Cloning $REPO_URL to $TARGET_DIR ..."
  git clone "$REPO_URL" "$TARGET_DIR"
else
  tarball_install
fi

CONFIG_PATH="$TARGET_DIR/autoactivator_config.sh"
[ -f "$CONFIG_PATH" ] || die "Expected $CONFIG_PATH after install but it's missing."

CONSTANTS_PATH="$TARGET_DIR/_constants.sh"
[ -f "$CONSTANTS_PATH" ] || die "Expected $CONSTANTS_PATH after install but it's missing."
# shellcheck source=_constants.sh disable=SC1091
. "$CONSTANTS_PATH"

installed=()
for shell in "${shells[@]}"; do
  if ! have "$shell"; then
    echo "Skipping $shell: not installed on this system."
    continue
  fi

  rc=$(rc_for_shell "$shell")
  if [ ! -f "$rc" ]; then
    touch "$rc"
    echo "Created $rc (didn't exist)."
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
source "$CONFIG_PATH"
$AUTOACTIVATOR_BLOCK_CLOSE
EOF
    echo "$APP_NAME sourced in $rc"
  fi
  installed+=("$shell")
done

[ ${#installed[@]} -gt 0 ] || die "Could not install for any of the requested shells."

echo
echo "$APP_NAME installed for: ${installed[*]}"
echo
echo "Activate it now — run:"
for shell in "${installed[@]}"; do
  rc=$(rc_for_shell "$shell")
  printf '  %-5s source ~%s\n' "$shell:" "${rc#"$HOME"}"
done
echo "(or just open a new terminal)"
