# target_scan.sh - Escaneos nmap: ports, services, all.
# Depende: target_common.sh, tmux_helpers.sh (set_tmux_status_name). REPO_BASE.

target_scan_ports() {
    local PORT_OPTION="-p 21,22,80,1337,3000,5000,5005,5050,5173,6022,6667,8000,8013,8080,8081,8800,9999,10720,10750"
    local SCAN_SERVICES=""
    local current_pane_id
    local PYTHON_SCRIPT OUTPUT_FILE

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --top-ports)
                shift
                PORT_OPTION="--top-ports $1"
                shift
                ;;
            --all-ports)
                PORT_OPTION="-p-"
                shift
                ;;
            -s|--services)
                shift
                SCAN_SERVICES=$1
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    if [ -n "$SCAN_SERVICES" ]; then
        PYTHON_SCRIPT="$REPO_BASE/lib/port_scan_browser.py"
        echo -e "${BLUE}Iniciando escaneo rápido con script externo para encontrar $SCAN_SERVICES servicios...${NC}"
        if [ -f "$PYTHON_SCRIPT" ]; then
            python3 "$PYTHON_SCRIPT" -s "$SCAN_SERVICES"
        else
            echo -e "${RED}Error: No se encontró el script en $PYTHON_SCRIPT${NC}"
        fi
        return 0
    fi

    if [ -n "${TMUX:-}" ]; then
        current_pane_id=$(tmux display-message -p '#{pane_id}')
        [ -n "$current_pane_id" ] && set_tmux_status_name "$current_pane_id" "󰇑 Nmap Pts:$TARGET_NAME" "original_pane_title"
    fi

    OUTPUT_FILE="$WORKSPACE_DIR/recon/port_scan.txt"
    echo -e "${BLUE}Iniciando escaneo de puertos para $TARGET_NAME ($IP)${NC}"
    echo -e "${YELLOW}Comando: nmap -Pn -n -T4 $IP --open $PORT_OPTION -oN $OUTPUT_FILE -sS${NC}"
    nmap -Pn -n -T4 "$IP" --open $PORT_OPTION -oN "$OUTPUT_FILE" -sS
    echo -e "${GREEN}Escaneo de puertos completado. Resultados en: $OUTPUT_FILE${NC}"

    if [ -n "${current_pane_id:-}" ]; then
        set_tmux_status_name "$current_pane_id" "" "original_pane_title"
    fi
}

target_scan_services() {
    local PORTS_FILE="$WORKSPACE_DIR/recon/port_scan.txt"
    local OUTPUT_FILE="$WORKSPACE_DIR/recon/versions_scan.txt"
    local OPEN_PORTS

    if [ ! -f "$PORTS_FILE" ]; then
        echo -e "${RED}Error: No se encontró $PORTS_FILE. Ejecuta primero 'target scan ports' o 'target scan all'.${NC}"
        exit 1
    fi
    OPEN_PORTS=$(grep -oP '^[0-9]+/tcp\s+open' "$PORTS_FILE" | cut -d'/' -f1 | paste -sd, -)
    if [ -z "$OPEN_PORTS" ]; then
        echo -e "${YELLOW}No se detectaron puertos abiertos en $PORTS_FILE. No se realizará escaneo de servicios.${NC}"
        exit 0
    fi
    echo -e "${BLUE}Iniciando escaneo de servicios/versión para $TARGET_NAME ($IP) en puertos: $OPEN_PORTS${NC}"
    echo -e "${YELLOW}Comando: nmap -Pn -n -T4 $IP -sCV -oN $OUTPUT_FILE -p $OPEN_PORTS${NC}"
    nmap -Pn -n -T4 "$IP" -sCV -oN "$OUTPUT_FILE" -p "$OPEN_PORTS"
    echo -e "${GREEN}Escaneo de servicios completado. Resultados en: $OUTPUT_FILE${NC}"
}

target_scan_all() {
    target_scan_ports "$@"
    target_scan_services
}

main_target_scan() {
    local MODE

    if [ $# -eq 0 ]; then
        echo -e "${BLUE}Uso de target scan:${NC}"
        echo "  target scan ports [--top-ports N | --all-ports]   # Escaneo de puertos TCP (por defecto top 1000)"
        echo "  target scan services                             # Escaneo de servicios/versión sobre puertos detectados"
        echo "  target scan all [--top-ports N | --all-ports]    # Hace ambos pasos en orden"
        exit 1
    fi
    MODE=$1
    shift

    if ! target_resolve_workspace_from_cwd; then
        echo -e "${RED}Error: Ejecuta este comando dentro del workspace del target (donde está .envrc)${NC}"
        exit 1
    fi
    if ! target_load_env --require-ip; then
        exit 1
    fi

    case "$MODE" in
        ports)
            target_scan_ports "$@"
            ;;
        services)
            target_scan_services
            ;;
        all)
            target_scan_all "$@"
            ;;
        *)
            echo -e "${RED}Error: Modo de escaneo '$MODE' no reconocido${NC}"
            echo "Modos válidos: ports, services, all"
            exit 1
            ;;
    esac
}
