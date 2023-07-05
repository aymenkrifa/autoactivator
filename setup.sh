#!/bin/bash

shell="$@"

TARGET_DIR="$HOME/.autoactivator"
REPO_URL="https://github.com/aymenkrifa/autoactivator"
PYTHON_EXECUTABLE="python3"

install_script_path="$TARGET_DIR/install.py"

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Please install it before launching the installation again."
    echo "You can install Git from: https://git-scm.com/"
    exit 1
fi

mkdir -p "$TARGET_DIR"
git clone "$REPO_URL" "$TARGET_DIR"

echo -e "Installing..\n"
"$PYTHON_EXECUTABLE" "$install_script_path" $shell