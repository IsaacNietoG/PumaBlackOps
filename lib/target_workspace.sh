# target_workspace.sh - Creación de workspace y comando add.
# Depende: target_common.sh, target_tmux.sh. REPO_BASE debe estar definido.

# Crea la estructura del workspace: dir, .envrc, writeup.md, subdirs, ctflinpeas.
# Argumentos: $1=TARGET_NAME, $2=TARGET_IP
# Establece WORKSPACE_DIR. Debe ejecutarse con cwd = directorio donde crear el target (p. ej. repo root).
target_create_workspace_structure() {
    local TARGET_NAME="$1"
    local TARGET_IP="$2"
    local BIN_DIR CTFLINPEAS_SRC CTFLINPEAS_DST
    local SUBDOMAIN="${TARGET_SUBDOMAIN:-echocity-f.com}"

    WORKSPACE_DIR="$(pwd)/$TARGET_NAME"
    mkdir -p "$WORKSPACE_DIR"

    echo "export IP=$TARGET_IP" > "$WORKSPACE_DIR/.envrc"
    echo "export URL=$TARGET_NAME.$SUBDOMAIN" >> "$WORKSPACE_DIR/.envrc"
    echo "export CTF_WORKSPACE_DIR=$WORKSPACE_DIR" >> "$WORKSPACE_DIR/.envrc"

    direnv allow "$WORKSPACE_DIR"

    cat <<EOL > "$WORKSPACE_DIR/writeup.md"
# $TARGET_NAME

- **IP**: $TARGET_IP
- **Creado el**: $(date)
- **Notas**: Escribe cualquier detalle relevante aquí.

## Notas Iniciales

## Reconocimiento

## Explotación

## Post-Explotación

## Notas Finales
EOL

    mkdir -p "$WORKSPACE_DIR/recon" "$WORKSPACE_DIR/exploits" "$WORKSPACE_DIR/loot" "$WORKSPACE_DIR/research"

    BIN_DIR="$REPO_BASE/bin"
    CTFLINPEAS_SRC="$BIN_DIR/ctflinpeas"
    CTFLINPEAS_DST="$WORKSPACE_DIR/ctflinpeas"
    if [ -f "$CTFLINPEAS_SRC" ]; then
        cp "$CTFLINPEAS_SRC" "$CTFLINPEAS_DST"
        chmod +x "$CTFLINPEAS_DST"
        echo -e "${GREEN}ctflinpeas copiado a $CTFLINPEAS_DST${NC}"
    else
        echo -e "${YELLOW}Advertencia: ctflinpeas no encontrado en $CTFLINPEAS_SRC. No se copió.${NC}"
    fi

    echo -e "${GREEN}Workspace para $TARGET_NAME creada en $WORKSPACE_DIR${NC}"
}

# Comando: target add <nombre_maquina> <IP>
target_add() {
    if [ $# -ne 2 ]; then
        echo -e "${RED}Error: Uso: target add <nombre_maquina> <IP>${NC}"
        exit 1
    fi

    TARGET_NAME="$1"
    TARGET_IP="$2"

    target_create_workspace_structure "$TARGET_NAME" "$TARGET_IP"

    # Tmux: ejecutar desde el padre del workspace
    cd "$WORKSPACE_DIR/.." || exit 1
    target_tmux_get_server_name
    target_tmux_ensure_config
    target_tmux_attach_or_create_session "$TARGET_NAME" "$WORKSPACE_DIR" "$TARGET_IP"
}
