# target_dirsearch.sh - Búsqueda de directorios con ffuf.
# Depende: target_common.sh.

target_dirsearch() {
    local PORT=80
    local WORDLIST="/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt"
    local OUTPUT_DIR OUTPUT_FILE TIMESTAMP

    if [ $# -ge 1 ]; then
        if [ -d "./$1" ] && [ -f "./$1/.envrc" ]; then
            TARGET_NAME="$1"
            WORKSPACE_DIR="./$1"
            shift
        else
            TARGET_NAME=$(basename "$PWD")
            WORKSPACE_DIR="$PWD"
        fi
    elif ! target_resolve_workspace_from_cwd; then
        echo -e "${RED}Error: Uso: target dirsearch [nombre_maquina] [puerto] (o ejecuta dentro del workspace)${NC}"
        exit 1
    fi

    if [ ! -d "$WORKSPACE_DIR" ]; then
        echo -e "${RED}Error: Workspace '$TARGET_NAME' no encontrado${NC}"
        exit 1
    fi
    if ! target_load_env --require-ip; then
        exit 1
    fi

    [ $# -ge 1 ] && PORT=$1

    if [ "$PORT" = "80" ]; then
        URL="http://$IP/"
    elif [ "$PORT" = "443" ]; then
        URL="https://$IP/"
    else
        URL="http://$IP:$PORT/"
    fi

    OUTPUT_DIR="$WORKSPACE_DIR/recon"
    mkdir -p "$OUTPUT_DIR"
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    OUTPUT_FILE="$OUTPUT_DIR/ffuf_dirsearch_${PORT}_${TIMESTAMP}.txt"

    echo -e "${BLUE}Iniciando búsqueda de directorios con ffuf para $TARGET_NAME ($URL)${NC}"
    echo -e "${YELLOW}Comando: ffuf -u ${URL}FUZZ -w $WORDLIST -recursion -o $OUTPUT_FILE${NC}"
    echo ""
    ffuf -u "${URL}FUZZ" -w "$WORDLIST" -recursion -o "$OUTPUT_FILE" -of md
    echo ""
    echo -e "${GREEN}Búsqueda completada. Resultados guardados en: $OUTPUT_FILE${NC}"
}
