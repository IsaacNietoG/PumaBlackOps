#!/bin/bash

# Spell: source-aliases.sh
# Ofrece opciones para sourcear aliases/all.sh de distintas formas

set -e

ALIASES_DIR="$(cd "$(dirname "$0")" && pwd)/../aliases"
ALL_SCRIPT="$ALIASES_DIR/all.sh"

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

print_status "¿Cómo quieres sourcear los aliases del proyecto?"
echo ""
print_warning "1) Temporal (solo en esta sesión)"
echo "   source \"$ALL_SCRIPT\""
print_warning "2) Imprimir el comando a copiar-pegar para hacerlo manualmente"
print_warning "3) Agregar a tu perfil de terminal (e.g., .zshrc, .bashrc) (recomendado)"
print_warning "4) Lanzar consola nueva con aliases cargados (subshell)"
echo ""
read -p "Elige una opción [1-4]: " choice

case $choice in
    1)
        source "$ALL_SCRIPT"
        print_status "Aliases cargados para esta sesión."
        ;;
    2)
        echo -e "\nCopia y pega esto en tu shell para cargar los aliases en esta sesión:"
        echo "source \"$ALL_SCRIPT\""
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
        echo "source \"$ALL_SCRIPT\"" >> "$SHELL_PROFILE"
        print_status "Agregado a $SHELL_PROFILE. Reinicia tu terminal o ejecuta: source $SHELL_PROFILE"
        ;;
    4)
        print_status "Lanzando un nuevo shell con los aliases cargados..."
        source "$ALL_SCRIPT"
        exec "$SHELL"
        ;;
    *)
        echo "Opción inválida. Saliendo."
        exit 1
        ;;
esac 