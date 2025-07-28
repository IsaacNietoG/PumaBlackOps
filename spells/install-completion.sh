#!/bin/bash

# Script to install bash completion for the target tool

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Installing bash completion for target tool...${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$(dirname "$(readlink -f -- "$0")")"
REPO_BASE="$(dirname "$SCRIPT_DIR")"
COMPLETION_FILE="$REPO_BASE/completions/target.bash"

# Check if completion file exists
if [ ! -f "$COMPLETION_FILE" ]; then
    echo -e "${YELLOW}Error: Completion file not found at $COMPLETION_FILE${NC}"
    exit 1
fi

# Make completion file executable
chmod +x "$COMPLETION_FILE"

# Function to detect shell
detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

# Function to get shell config file
get_shell_config() {
    local shell_type="$1"
    case "$shell_type" in
        bash)
            if [ -f "$HOME/.bashrc" ]; then
                echo "$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        zsh)
            if [ -f "$HOME/.zshrc" ]; then
                echo "$HOME/.zshrc"
            else
                echo "$HOME/.zshrc"
            fi
            ;;
        *)
            echo ""
            ;;
    esac
}

# Install completion
install_completion() {
    local shell_type="$1"
    local config_file="$2"
    
    echo -e "${BLUE}Detected shell: $shell_type${NC}"
    echo -e "${BLUE}Config file: $config_file${NC}"
    
    # Check if completion is already installed
    if grep -q "source.*target.bash" "$config_file" 2>/dev/null; then
        echo -e "${YELLOW}Completion already installed in $config_file${NC}"
        return 0
    fi
    
    # Add source line to shell config
    echo "" >> "$config_file"
    echo "# Target tool completion" >> "$config_file"
    echo "source \"$COMPLETION_FILE\"" >> "$config_file"
    
    echo -e "${GREEN}Completion installed successfully!${NC}"
    echo -e "${YELLOW}Please restart your shell or run: source $config_file${NC}"
}

# Main installation
SHELL_TYPE=$(detect_shell)
CONFIG_FILE=$(get_shell_config "$SHELL_TYPE")

if [ -z "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}Could not detect shell configuration file.${NC}"
    echo -e "${BLUE}Please manually add this line to your shell config:${NC}"
    echo -e "${GREEN}source \"$COMPLETION_FILE\"${NC}"
    exit 1
fi

install_completion "$SHELL_TYPE" "$CONFIG_FILE"

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${BLUE}Usage examples:${NC}"
echo -e "  target <TAB>                    # Show all commands"
echo -e "  target add <TAB>                # Complete target names"
echo -e "  target scan <TAB>               # Show scan subcommands"
echo -e "  target info <TAB>               # Show existing targets" 