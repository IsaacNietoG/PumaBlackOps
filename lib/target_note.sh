# target_note.sh - Agregar nota al writeup.
# Depende: target_common.sh.

target_note() {
    local NOTE_TEXT NOTE_DATE WRITEUP_FILE

    if [ $# -ge 1 ]; then
        if [ -d "./$1" ] && [ -f "./$1/.envrc" ]; then
            TARGET_NAME="$1"
            WORKSPACE_DIR="./$1"
            shift
        else
            TARGET_NAME=$(basename "$PWD")
            WORKSPACE_DIR="$PWD"
        fi
    elif target_resolve_workspace_from_cwd; then
        :
    else
        echo -e "${RED}Error: Uso: target note [nombre_maquina] <texto de la nota> (o ejecuta dentro del workspace)${NC}"
        exit 1
    fi

    if [ ! -d "$WORKSPACE_DIR" ]; then
        echo -e "${RED}Error: Workspace '$TARGET_NAME' no encontrado${NC}"
        exit 1
    fi
    if [ $# -eq 0 ]; then
        echo -e "${RED}Error: Debes ingresar el texto de la nota${NC}"
        exit 1
    fi

    NOTE_TEXT="$*"
    NOTE_DATE=$(date '+%Y-%m-%d %H:%M')
    WRITEUP_FILE="$WORKSPACE_DIR/writeup.md"
    echo -e "\n---\n**Nota rápida [$NOTE_DATE]:** $NOTE_TEXT" >> "$WRITEUP_FILE"
    echo -e "${GREEN}Nota agregada a $WRITEUP_FILE${NC}"
}
