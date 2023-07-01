#!/bin/bash

TARGET_DIR="$HOME/.autoactivator"
REPO_URL="https://github.com/aymenkrifa/autoactivator"
BRANCH="feature/host_setup_shell_script"

# Create the target directory
mkdir -p "$TARGET_DIR"

# Clone the repository into the target directory
git clone "$REPO_URL" "$TARGET_DIR"

# Change to the cloned directory
cd "$TARGET_DIR"

# Checkout the desired branch
git checkout "$BRANCH"

# Run the install.py script
python3 install.py bash
