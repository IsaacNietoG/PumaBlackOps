# target_note.sh - Agregar nota al writeup.
# Depende: target_common.sh.

target_note() {
    local NOTE_TEXT NOTE_DATE WRITEUP_FILE

    # $1 solo se consume como nombre de target si es un workspace válido.
    # Si no lo es, NO se hace shift: el resto de los argumentos es el texto de
    # la nota. Antes, un nombre mal escrito se colaba dentro de la nota y, si no
    # estabas en un workspace, se escribía un writeup.md espurio en el cwd.
    if [ $# -ge 1 ] && [ -d "./$1" ] && [ -f "./$1/.envrc" ]; then
        TARGET_NAME="$1"
        WORKSPACE_DIR="./$1"
        shift
    elif target_resolve_workspace_from_cwd; then
        :
    else
        echo -e "${RED}Error: Workspace '$1' no encontrado y no estás dentro de un workspace.${NC}"
        echo "Uso: target note [nombre_maquina] <texto de la nota>"
        exit 1
    fi

    if [ $# -eq 0 ]; then
        echo -e "${RED}Error: Debes ingresar el texto de la nota${NC}"
        exit 1
    fi

    NOTE_TEXT="$*"
    NOTE_DATE=$(date '+%Y-%m-%d %H:%M')
    WRITEUP_FILE="$WORKSPACE_DIR/writeup.md"
    if [ ! -f "$WRITEUP_FILE" ]; then
        echo -e "${RED}Error: No se encontró $WRITEUP_FILE${NC}"
        echo -e "${YELLOW}La nota no se agregó para no crear un writeup espurio en un directorio equivocado.${NC}"
        exit 1
    fi
    echo -e "\n---\n**Nota rápida [$NOTE_DATE]:** $NOTE_TEXT" >> "$WRITEUP_FILE"
    echo -e "${GREEN}Nota agregada a $WRITEUP_FILE${NC}"
}
