#!/bin/bash

# Set the desired shell based on the command-line argument
shell="$1"

TARGET_DIR="$HOME/.autoactivator"
REPO_URL="https://github.com/aymenkrifa/autoactivator"

install_script_path="$TARGET_DIR/install.py"

# Create the target directory
mkdir -p "$TARGET_DIR"
git clone "$REPO_URL" "$TARGET_DIR"

# Change to the project directory
cd $TARGET_DIR

# Execute the install.py script with the chosen shell flag
python3 "$install_script_path" "$shell"
