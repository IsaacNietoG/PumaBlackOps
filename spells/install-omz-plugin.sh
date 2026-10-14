#!/bin/bash

# Spell: install-omz-plugin.sh
# Instala el plugin de PumaBlackOps para Oh My Zsh enlazándolo dentro de
# $ZSH_CUSTOM/plugins/pumablackops (o en el path que indique ZSH_CUSTOM).

set -e

REPO_BASE="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_SRC="$REPO_BASE/omz"
PLUGIN_NAME="pumablackops"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
PLUGIN_DEST="$ZSH_CUSTOM/plugins/$PLUGIN_NAME"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[CHOICE]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ ! -d "$ZSH_CUSTOM" ]; then
    print_error "No se encontró $ZSH_CUSTOM"
    echo "  Instala Oh My Zsh primero: https://ohmyz.sh"
    echo "  Si usas otra ruta, expónla: export ZSH_CUSTOM=/ruta/custom"
    exit 1
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    print_warning "No se detectó ~/.oh-my-zsh. Se continuará usando ZSH_CUSTOM=$ZSH_CUSTOM"
    echo ""
fi

print_status "¿Cómo quieres instalar el plugin $PLUGIN_NAME?"
echo ""
print_warning "1) Symlink (recomendado) - el plugin sigue al repo, un git pull lo actualiza"
echo "   $PLUGIN_DEST -> $PLUGIN_SRC"
print_warning "2) Copia - independiente del repo, hay que actualizarla a mano"
echo "   $PLUGIN_DEST"
print_warning "3) Solo imprimir el bloque para agregar a tu .zshrc a mano"
echo ""
read -p "Elige una opción [1-3]: " choice

case "$choice" in
    1|2)
        mkdir -p "$ZSH_CUSTOM/plugins"

        # No pisar una instalación previa sin avisar.
        if [ -e "$PLUGIN_DEST" ] || [ -L "$PLUGIN_DEST" ]; then
            print_warning "Ya existe $PLUGIN_DEST"
            if [ -L "$PLUGIN_DEST" ] && [ "$(readlink -f "$PLUGIN_DEST")" = "$(readlink -f "$PLUGIN_SRC")" ]; then
                print_status "El enlace ya apunta a este repo. No hay nada que hacer."
                break
            fi
            read -p "¿Reemplazarlo? [s/N]: " ok
            if [[ ! "$ok" =~ ^[sSyY]$ ]]; then
                print_status "Cancelado."
                exit 0
            fi
            rm -rf "$PLUGIN_DEST"
        fi

        if [ "$choice" = "1" ]; then
            ln -s "$PLUGIN_SRC" "$PLUGIN_DEST"
            print_status "Symlink creado en $PLUGIN_DEST"
        else
            cp -r "$PLUGIN_SRC" "$PLUGIN_DEST"
            print_status "Plugin copiado en $PLUGIN_DEST"
        fi
        ;;
    3)
        print_status "Agrega esto a tu .zshrc, ANTES de 'source \$ZSH/oh-my-zsh.sh':"
        echo ""
        echo "  plugins+=($PLUGIN_NAME)"
        echo ""
        ;;
    *)
        print_error "Opción inválida. Saliendo."
        exit 1
        ;;
esac

echo ""
print_status "Agrega el plugin a tu .zshrc (antes de 'source \$ZSH/oh-my-zsh.sh'):"
echo ""
echo "  plugins+=($PLUGIN_NAME)"
echo ""
print_warning "Después: exec zsh   (o abre una terminal nueva)"
print_warning "Verifica que cargó con: alias | grep -E 'ars|nscan'"