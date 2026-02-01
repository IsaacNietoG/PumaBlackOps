# target_tmux.sh - Integración tmux: servidor, config, crear/adjuntar sesión.
# Depende: target_common.sh (colores, REPO_BASE). tmux_helpers.sh (set_tmux_status_name no usado aquí).

# Determina SERVER_NAME (default vs PumaBlackOps) según sesiones tmux existentes.
# Asume que el cwd es el directorio que contiene los subdirs de targets (p. ej. padre del workspace).
# Establece SERVER_NAME.
target_tmux_get_server_name() {
    local EXISTING_SESSIONS TARGET_SESSIONS_ONLY session target_dir target_name SESSION_EXISTS_IN_TARGET

    EXISTING_SESSIONS=$(tmux list-sessions 2>/dev/null | cut -d: -f1 || echo "")
    TARGET_SESSIONS_ONLY=true

    if [ -n "$EXISTING_SESSIONS" ]; then
        while IFS= read -r session; do
            if [ -n "$session" ]; then
                SESSION_EXISTS_IN_TARGET=false
                for target_dir in */; do
                    if [ -d "$target_dir" ] && [ -f "$target_dir/.envrc" ]; then
                        target_name=$(basename "$target_dir")
                        if [ "$session" = "$target_name" ]; then
                            SESSION_EXISTS_IN_TARGET=true
                            break
                        fi
                    fi
                done
                if [ "$SESSION_EXISTS_IN_TARGET" = false ]; then
                    TARGET_SESSIONS_ONLY=false
                    break
                fi
            fi
        done <<< "$EXISTING_SESSIONS"
    fi

    if [ "$TARGET_SESSIONS_ONLY" = true ] && [ -n "$EXISTING_SESSIONS" ]; then
        SERVER_NAME="default"
        echo -e "${BLUE}Todas las sesiones existentes son targets creados por esta herramienta. Usando socket: $SERVER_NAME${NC}"
    elif [ -n "$EXISTING_SESSIONS" ]; then
        SERVER_NAME="PumaBlackOps"
        echo -e "${BLUE}Se han encontrado sesiones de Tmux que, o no son relacionadas con targets, o la lógica de esta herramienta no está diseñada para manejarlas. Para evitar conflictos se ha establecido el nombre del socket en $SERVER_NAME${NC}"
        echo -e "${YELLOW}Nota: Puedes buscar esta sesión usando: tmux -L $SERVER_NAME list-sessions${NC}"
    else
        SERVER_NAME="default"
        echo -e "${BLUE}No se han encontrado otras sesiones de Tmux, se ha establecido el nombre del socket en $SERVER_NAME${NC}"
    fi
}

# Genera la config de tmux y establece TMUX_CONFIG.
target_tmux_ensure_config() {
    echo -e "${BLUE}Generating tmux configuration...${NC}"
    if [ -f "$REPO_BASE/lib/generate-tmux-config.sh" ]; then
        bash "$REPO_BASE/lib/generate-tmux-config.sh"
        TMUX_CONFIG="$REPO_BASE/.config/tmux/tmux.conf"
        echo -e "${GREEN}Tmux configuration generated successfully!${NC}"
    else
        echo -e "${YELLOW}Warning: tmux config generator not found at $REPO_BASE/lib/generate-tmux-config.sh${NC}"
        TMUX_CONFIG="$REPO_BASE/.config/tmux/tmux.conf"
    fi
}

# Crea o adjunta la sesión tmux para el target.
# Argumentos: $1=SESSION_NAME, $2=WORKSPACE_DIR, $3=TARGET_IP
# Debe estar definido: SERVER_NAME, TMUX_CONFIG, REPO_BASE.
target_tmux_attach_or_create_session() {
    local SESSION_NAME="$1"
    local WORKSPACE_DIR="$2"
    local TARGET_IP="$3"
    local HOSTS_ENTRY

    if tmux -L "$SERVER_NAME" has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${YELLOW}Sesión de Tmux '$SESSION_NAME' ya existe. Adjuntando...${NC}"
        tmux -L "$SERVER_NAME" attach-session -t "$SESSION_NAME"
    else
        echo -e "${BLUE}Creando y adjuntando nueva sesión de Tmux '$SESSION_NAME' ...${NC}"

        tmux -L "$SERVER_NAME" -f "$TMUX_CONFIG" new-session -d -s "$SESSION_NAME" -n "Recon" -c "$WORKSPACE_DIR"
        tmux -L "$SERVER_NAME" set-environment -t "$SESSION_NAME" CTF_WORKSPACE_DIR_TMUX "$WORKSPACE_DIR"
        tmux -L "$SERVER_NAME" set-environment -t "$SESSION_NAME" TMUX_CONF "$TMUX_CONFIG"

        # Ventana 1: Recon (dos paneles)
        tmux -L "$SERVER_NAME" split-window -v -t "$SESSION_NAME:1" -c "$WORKSPACE_DIR"
        tmux -L "$SERVER_NAME" send-keys -t "$SESSION_NAME:1.1" "clear" C-m
        tmux -L "$SERVER_NAME" send-keys -t "$SESSION_NAME:1.2" "clear" C-m

        HOSTS_ENTRY="$TARGET_IP        $SESSION_NAME.echocity-f.com"
        if ! grep -q "$HOSTS_ENTRY" /etc/hosts 2>/dev/null; then
            tmux -L "$SERVER_NAME" send-keys -t "$SESSION_NAME:1.1" "sudo sh -c \"echo '$HOSTS_ENTRY' >> /etc/hosts\""
        else
            tmux -L "$SERVER_NAME" display-message -t "$SESSION_NAME:1.1" -F "${YELLOW}La entrada '$HOSTS_ENTRY' ya existe en /etc/hosts. Saltando.${NC}"
        fi
        tmux -L "$SERVER_NAME" send-keys -t "$SESSION_NAME:1.2" "target scan ports -s "

        # Ventana 2: Exploit
        tmux -L "$SERVER_NAME" new-window -t "$SESSION_NAME:2" -n "Exploit" -c "$WORKSPACE_DIR"
        tmux -L "$SERVER_NAME" send-keys -t "$SESSION_NAME:2" "clear" C-m
        tmux -L "$SERVER_NAME" send-keys -t "$SESSION_NAME:2" "penelope -p 9000"

        # Ventana 3: Misc
        tmux -L "$SERVER_NAME" new-window -t "$SESSION_NAME:3" -n "Misc." -c "$WORKSPACE_DIR"
        tmux -L "$SERVER_NAME" send-keys -t "$SESSION_NAME:3" "clear" C-m
        (tmux -L "$SERVER_NAME" send-keys -t "$SESSION_NAME:3.1" "$REPO_BASE/.config/tmux/plugins/tmux/scripts/ctf_timer.sh start" C-m) &

        tmux -L "$SERVER_NAME" select-window -t "$SESSION_NAME:1"
        tmux -L "$SERVER_NAME" select-pane -U
        tmux -L "$SERVER_NAME" attach-session -t "$SESSION_NAME"
    fi
}
