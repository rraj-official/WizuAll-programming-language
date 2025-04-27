#!/bin/bash

# Installation script for WizuAll

# Create installation directories
echo "Creating installation directories..."
sudo mkdir -p /usr/local/bin
sudo mkdir -p /usr/local/lib/wizuall/bin
sudo mkdir -p /usr/local/lib/wizuall/scripts
sudo mkdir -p /usr/local/lib/wizuall/examples
sudo mkdir -p /usr/local/lib/wizuall/wizz_build

# Copy files to appropriate locations
echo "Copying WizuAll files..."
sudo cp bin/wizuallc /usr/local/lib/wizuall/bin/
sudo cp scripts/preprocess.rb /usr/local/lib/wizuall/scripts/
sudo cp scripts/run.sh /usr/local/lib/wizuall/scripts/

# Create global script in PATH
cat << 'EOF' | sudo tee /usr/local/bin/wizz > /dev/null
#!/bin/bash

# Global script for WizuAll
SCRIPT_DIR="/usr/local/lib/wizuall/scripts"

# Run the actual script
"$SCRIPT_DIR/run.sh" "$@"
EOF

# Make scripts executable
sudo chmod +x /usr/local/bin/wizz
sudo chmod +x /usr/local/lib/wizuall/scripts/run.sh
sudo chmod +x /usr/local/lib/wizuall/scripts/preprocess.rb
sudo chmod +x /usr/local/lib/wizuall/bin/wizuallc

# Copy examples
echo "Installing examples..."
for dir in examples/*; do
  if [ -d "$dir" ]; then
    sudo mkdir -p "/usr/local/lib/wizuall/$dir"
    sudo cp "$dir"/* "/usr/local/lib/wizuall/$dir/" 2>/dev/null || true
  fi
done

echo "Installation complete!"
echo "Use the 'wizz' command to run WizuAll from anywhere." 