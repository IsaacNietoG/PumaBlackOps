# target_list.sh - Listar targets y mostrar info de un target.
# Depende: target_common.sh.

target_list() {
    local dir

    echo -e "${BLUE}Objetivos disponibles:${NC}"
    echo ""

    for dir in */; do
        if [ -d "$dir" ] && [ -f "$dir/.envrc" ]; then
            TARGET_NAME=$(basename "$dir")
            # shellcheck source=/dev/null
            source "$dir/.envrc"
            echo -e "${GREEN}• $TARGET_NAME${NC} - $IP"
        fi
    done
}

target_info() {
    if [ $# -eq 1 ]; then
        if [ -d "./$1" ] && [ -f "./$1/.envrc" ]; then
            TARGET_NAME="$1"
            WORKSPACE_DIR="./$1"
        else
            echo -e "${RED}Error: Workspace '$1' no encontrado${NC}"
            exit 1
        fi
    elif [ $# -eq 0 ]; then
        if ! target_resolve_workspace_with_optional_name; then
            echo -e "${RED}Error: Uso: target info <nombre_maquina> (o ejecuta dentro del workspace)${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Error: Uso: target info <nombre_maquina> (o ejecuta dentro del workspace)${NC}"
        exit 1
    fi

    if [ ! -d "$WORKSPACE_DIR" ]; then
        echo -e "${RED}Error: Workspace '$TARGET_NAME' no encontrado${NC}"
        exit 1
    fi

    echo -e "${BLUE}Información del objetivo: $TARGET_NAME${NC}"
    echo ""

    if [ -f "$WORKSPACE_DIR/.envrc" ]; then
        # shellcheck source=/dev/null
        source "$WORKSPACE_DIR/.envrc"
        echo -e "${GREEN}IP:${NC} $IP"
    fi
    if [ -f "$WORKSPACE_DIR/writeup.md" ]; then
        echo -e "${GREEN}Writeup:${NC} $WORKSPACE_DIR/writeup.md"
    fi
    echo -e "${GREEN}Directorios:${NC}"
    ls -la "$WORKSPACE_DIR" | grep "^d" || true
}
