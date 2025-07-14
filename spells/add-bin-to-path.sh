#!/bin/bash

# Spell: add-bin-to-path.sh
# Forma interactiva de ofrecer al usuario agregar los binarios del proyecto de distintas formas

set -e

BIN_DIR="$(cd "$(dirname "$0")" && pwd)/../bin"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[CHOICE]${NC} $1"
}

# Present options
print_status "Como quisieras agregar las herramientas a tu PATH?"
echo ""
print_warning "1) Temporal (solo en esta sesión)"
echo "   export PATH=\"$BIN_DIR:\$PATH\""
print_warning "2) Imprimir el comando a copiar-pegar para hacerlo manualmente"
print_warning "3) Agregar a tu perfil de terminal(e.g., .zshrc, .bashrc) (recomendado)"
print_warning "4) Lanzar consola nueva con herramientas en el PATH (subshell)"
print_warning "5) Enlaces simbólicos en ~/bin (te toca verificar si está en tu PATH)"
echo ""
read -p "Enter your choice [1-5]: " choice

case $choice in
    1)
        export PATH="$BIN_DIR:$PATH"
        print_status "Added $BIN_DIR to PATH for this shell session."
        ;;
    2)
        echo "\nCopy and paste this in your shell to add bin to PATH for this session:"
        echo "export PATH=\"$BIN_DIR:\$PATH\""
        ;;
    3)
        SHELL_PROFILE=""
        if [ -n "$ZSH_VERSION" ]; then
            SHELL_PROFILE="$HOME/.zshrc"
        elif [ -n "$BASH_VERSION" ]; then
            SHELL_PROFILE="$HOME/.bashrc"
        else
            SHELL_PROFILE="$HOME/.profile"
        fi
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_PROFILE"
        print_status "Added to $SHELL_PROFILE. Restart your terminal or run: source $SHELL_PROFILE"
        ;;
    4)
        print_status "Launching a new shell with bin in PATH..."
        export PATH="$BIN_DIR:$PATH"
        exec "$SHELL"
        ;;
    5)
        mkdir -p "$HOME/bin"
        for f in "$BIN_DIR"/*; do
            ln -sf "$f" "$HOME/bin/$(basename "$f")"
        done
        print_status "Symlinked all tools from $BIN_DIR to $HOME/bin. Make sure $HOME/bin is in your PATH."
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac 