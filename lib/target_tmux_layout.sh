# target_tmux_layout.sh - Motor de layout para la sesión tmux de un target.
# Depende: target_common.sh (colores). REPO_BASE y TMUX_CONFIG deben estar definidos.

# Layout por defecto: reproduce la sesión de 3 ventanas / 4 panes que se
# creaba a mano antes de existirem este motor. Se usa si falta la config.
target_tmux_layout_default() {
    TMUX_LAYOUT=(
        "Recon|1|sudo sh -c \"echo '%IP%        %SESSION%.%SUBDOMAIN%' >> /etc/hosts\"|0|/etc/hosts::%IP%        %SESSION%.%SUBDOMAIN%"
        "Recon|2|target scan ports|0|"
        "Exploit|1|penelope -p 9000|0|"
        "Misc.|1|%REPO%/.config/tmux/plugins/tmux/scripts/ctf_timer.sh start|1|"
    )
}

# Valida que cada entrada tenga los 5 campos y que ventana/orden sean válidos.
# Retorna 0 si el layout es usable, 1 si hay una entrada inválida.
target_tmux_layout_validate() {
    local entry window order pipes

    [ "${#TMUX_LAYOUT[@]}" -gt 0 ] || return 1

    for entry in "${TMUX_LAYOUT[@]}"; do
        pipes=$(printf '%s' "$entry" | tr -cd '|' | wc -c)
        if [ "$pipes" -ne 4 ]; then
            echo -e "${RED}Layout inválido: se esperaban 5 campos separados por '|' en:${NC}"
            echo -e "${YELLOW}  $entry${NC}"
            return 1
        fi

        IFS='|' read -r window order _ _ _ <<< "$entry"

        if [ -z "$window" ]; then
            echo -e "${RED}Layout inválido: entrada con ventana vacía:${NC}"
            echo -e "${YELLOW}  $entry${NC}"
            return 1
        fi

        if ! [[ "$order" =~ ^[0-9]+$ ]] || [ "$order" -lt 1 ]; then
            echo -e "${RED}Layout inválido: orden de pane no numérico en '${window}':${NC}"
            echo -e "${YELLOW}  $entry${NC}"
            return 1
        fi
    done
    return 0
}

# Carga conf/tmux_layout.conf. Si no existe, usa el layout por defecto.
# Retorna 0 si hay un layout válido, 1 si la config existe pero es inválida.
target_tmux_layout_load() {
    local conf="$REPO_BASE/conf/tmux_layout.conf"

    if [ -f "$conf" ]; then
        # shellcheck source=/dev/null
        source "$conf"
    else
        echo -e "${YELLOW}No se encontró $conf; se usa el layout por defecto.${NC}"
        target_tmux_layout_default
    fi

    if ! target_tmux_layout_validate; then
        return 1
    fi
    return 0
}

# Expande los placeholders de un texto del layout.
target_tmux_layout_expand() {
    local text="$1"
    text="${text//%IP%/$TARGET_IP}"
    text="${text//%SESSION%/$SESSION_NAME}"
    text="${text//%SUBDOMAIN%/$SUBDOMAIN}"
    text="${text//%WORKSPACE%/$WORKSPACE_DIR}"
    text="${text//%REPO%/$REPO_BASE}"
    printf '%s' "$text"
}

# Crea la sesión con el layout cargado.
# Argumentos: $1=SESSION_NAME, $2=WORKSPACE_DIR, $3=TARGET_IP
# Devuelve:  0 = sesión creada | 1 = error de layout (no se creó sesión)
target_tmux_layout_render() {
    local SESSION_NAME="$1"
    local WORKSPACE_DIR="$2"
    local TARGET_IP="$3"
    local SUBDOMAIN="${TARGET_SUBDOMAIN:-echocity-f.com}"

    if ! target_tmux_layout_load; then
        return 1
    fi

    local -a windows=()
    local -A pane_total=()
    local entry window order

    # --- Pasada 1: descubrir ventanas (en orden de aparición) y cuántos panes
    # --- tiene cada una.
    for entry in "${TMUX_LAYOUT[@]}"; do
        IFS='|' read -r window order _ _ _ <<< "$entry"
        if [ -z "${pane_total[$window]:-}" ]; then
            pane_total[$window]=0
            windows+=("$window")
        fi
        pane_total[$window]=$(( ${pane_total[$window]} + 1 ))
    done

    # --- Pasada 2: crear ventanas y panes con índices deterministas.
    local -A win_index=()
    local i n real_index
    for (( i=0; i<${#windows[@]}; i++ )); do
        window="${windows[$i]}"
        n="${pane_total[$window]}"

        if [ "$i" -eq 0 ]; then
            tmux -L "$SERVER_NAME" -f "$TMUX_CONFIG" new-session -d \
                -s "$SESSION_NAME" -n "$window" -c "$WORKSPACE_DIR" || return 1
        else
            tmux -L "$SERVER_NAME" new-window -t "$SESSION_NAME:" \
                -n "$window" -c "$WORKSPACE_DIR" || return 1
        fi

        # El pane 1 lo crea la ventana; los siguientes, split-window.
        local s
        for (( s=1; s<n; s++ )); do
            tmux -L "$SERVER_NAME" split-window -v \
                -t "$SESSION_NAME:$window" -c "$WORKSPACE_DIR" || return 1
        done

        # Usar el índice real que asignó tmux. Los nombres no sirven como target
        # de pane si contienen '.' (p. ej. "Misc." -> "sesion:Misc..1" es
        # ambiguo), y así el layout no depende de base-index del tmux.conf.
        real_index=$(tmux -L "$SERVER_NAME" display-message -p \
            -t "$SESSION_NAME:$window" '#{window_index}') || return 1
        win_index[$window]="$real_index"
    done

    # --- Pasada 3: enviar el comando de cada pane respetando el campo 'orden'
    # --- dentro de su ventana (no el orden de declaración en el archivo).
    # --- Los índices de pane se leen de tmux para no depender de pane-base-index.
    local pane_list pane_target
    for entry in "${TMUX_LAYOUT[@]}"; do
        IFS='|' read -r window order command submit guard <<< "$entry"

        pane_list=$(tmux -L "$SERVER_NAME" list-panes -t "$SESSION_NAME:$window" \
            -F '#{pane_index}') || return 1
        pane_target=$(printf '%s\n' "$pane_list" | sed -n "${order}p")
        if [ -z "$pane_target" ]; then
            echo -e "${RED}Layout inválido: la ventana '$window' no tiene el pane $order.${NC}"
            return 1
        fi

        target_tmux_layout_send_pane "$SESSION_NAME:${win_index[$window]}.$pane_target" \
            "$command" "$submit" "$guard"
    done

    # Enfocar la primera ventana y su primer pane (equivale al select-window 1
    # + select-pane -U del código original).
    tmux -L "$SERVER_NAME" select-window -t "$SESSION_NAME:${win_index[${windows[0]}]}"
    tmux -L "$SERVER_NAME" select-pane -t "$SESSION_NAME:${win_index[${windows[0]}]}.1"
    return 0
}

# Envía el comando de un pane ya existente, respetando submit y guard.
target_tmux_layout_send_pane() {
    local pane="$1"
    local command="$2"
    local submit="$3"
    local guard="$4"
    local expanded guard_file guard_text

    # clear en todos los panes, igual que antes
    tmux -L "$SERVER_NAME" send-keys -t "$pane" "clear" C-m

    # Sin comando: el pane se queda en el prompt.
    [ -z "$command" ] && return 0

    # Guarda: no enviar si el texto ya está en el archivo.
    if [ -n "$guard" ]; then
        guard_file="${guard%%::*}"
        guard_text="${guard#*::}"
        guard_text=$(target_tmux_layout_expand "$guard_text")
        if [ -f "$guard_file" ] && grep -qF -- "$guard_text" "$guard_file" 2>/dev/null; then
            tmux -L "$SERVER_NAME" display-message -t "$pane" \
                "${YELLOW}La entrada '$guard_text' ya existe en $guard_file. Saltando.${NC}"
            return 0
        fi
    fi

    expanded=$(target_tmux_layout_expand "$command")
    if [ "$submit" = "1" ]; then
        tmux -L "$SERVER_NAME" send-keys -t "$pane" "$expanded" C-m
    else
        tmux -L "$SERVER_NAME" send-keys -t "$pane" "$expanded"
    fi
}