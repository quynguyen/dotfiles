#!/bin/bash

echo "********************************************************************************"
echo "Installing Custom Packages (non-Homebrew)"
echo "********************************************************************************"

# Bun - A fast all-in-one JavaScript runtime
echo "Installing Bun JavaScript runtime..."
if ! command -v bun &> /dev/null; then
    echo "Bun not found, installing..."
    curl -fsSL https://bun.sh/install | bash
    
    # Add Bun to PATH for current session
    export PATH="$HOME/.bun/bin:$PATH"
    
    # Verify installation
    if command -v bun &> /dev/null; then
        echo "Bun installed successfully: $(bun --version)"
    else
        echo "Warning: Bun installation may have failed"
    fi
else
    echo "Bun already installed: $(bun --version)"
fi

# Ensure Bun is in PATH for future sessions
BUN_PATH_LINE='export PATH="$HOME/.bun/bin:$PATH"'
SHELL_RC_FILES=("$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile")

for rc_file in "${SHELL_RC_FILES[@]}"; do
    if [[ -f "$rc_file" ]] && ! grep -q "\.bun/bin" "$rc_file"; then
        echo "Adding Bun to PATH in $rc_file"
        echo "" >> "$rc_file"
        echo "# Bun JavaScript runtime" >> "$rc_file"
        echo "$BUN_PATH_LINE" >> "$rc_file"
    fi
done

echo "********************************************************************************"
echo "Custom packages installation complete"
echo "********************************************************************************"
echo ""
echo "Packages installed:"
echo "  - Bun (JavaScript runtime and package manager)"
echo ""
echo "Note: You may need to restart your shell or run 'source ~/.zshrc' to use Bun"