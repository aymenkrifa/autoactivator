#!/bin/bash

TARGET_DIR="$HOME/.autoactivator"
REPO_URL="https://github.com/aymenkrifa/autoactivator"
BRANCH="feature/host_setup_shell_script"
PYTHON_EXECUTABLE="python3"
SHELLS=""

echo "Installing..."

# Parse command line arguments
while getopts ":s:" opt; do
  case $opt in
    s)
      SHELLS="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

# Create the target directory
mkdir -p "$TARGET_DIR"

# Clone the repository into the target directory
git clone "$REPO_URL" "$TARGET_DIR"

# Change to the cloned directory
cd "$TARGET_DIR"

# Checkout the desired branch
git checkout "$BRANCH"

# Modify the shebang line of activator.sh to use bash
sed -i 's/#!\/bin\/sh/#!\/bin\/bash/' activator.sh

# Run the install.py script with the chosen Python executable and shells
"$PYTHON_EXECUTABLE" install.py $SHELLS
