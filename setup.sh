#!/bin/bash

shell="$@"

TARGET_DIR="$HOME/.autoactivator"
REPO_URL="https://github.com/aymenkrifa/autoactivator"
BRANCH="feature/host_setup_shell_script"
PYTHON_EXECUTABLE="python"

install_script_path="$TARGET_DIR/install.py"

mkdir -p "$TARGET_DIR"
git clone "$REPO_URL" "$TARGET_DIR"

cd $TARGET_DIR
git checkout "$BRANCH"

"$PYTHON_EXECUTABLE" "$install_script_path" $shell