#!/bin/bash
# Wrapper script to call the modularized wizz.sh with all arguments
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")/scripts"

# Ensure bin directory exists
mkdir -p "$(dirname "$(readlink -f "$0")")/bin"

# Run the actual script
"$SCRIPT_DIR/run.sh" "$@"
