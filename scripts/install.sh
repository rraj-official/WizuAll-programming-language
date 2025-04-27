#!/bin/bash

# WizuAll Installer Script
# This script installs WizuAll system-wide

echo "Installing WizuAll system-wide..."

# Set base paths
BASE_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
BIN_DIR="$BASE_DIR/bin"
SCRIPTS_DIR="$BASE_DIR/scripts"

# Ensure the binary exists
if [ ! -f "$BIN_DIR/wizuallc" ]; then
    echo "Error: Compiler binary not found. Please build the project first."
    exit 1
fi

# Install binary to /usr/local/bin
echo "Installing WizuAll compiler to /usr/local/bin..."
cp "$BIN_DIR/wizuallc" /usr/local/bin/
chmod +x /usr/local/bin/wizuallc

# Install the main script (wizz command)
echo "Installing wizz command to /usr/local/bin..."
cp "$SCRIPTS_DIR/run.sh" /usr/local/bin/wizz
chmod +x /usr/local/bin/wizz

# Install preprocessor script
if [ -f "$SCRIPTS_DIR/preprocess.rb" ]; then
    echo "Installing preprocessor script..."
    cp "$SCRIPTS_DIR/preprocess.rb" /usr/local/bin/
    chmod +x /usr/local/bin/preprocess.rb
fi

echo "Installation completed! WizuAll is now available system-wide."
echo "You can use the 'wizz' command from anywhere to run WizuAll programs."
exit 0 