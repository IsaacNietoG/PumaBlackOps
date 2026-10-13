# target_venv.sh - Crear y configurar venv Python en el workspace.
# Depende: target_common.sh.

target_venv() {
    local RESP

    local SUBDOMAIN="${TARGET_SUBDOMAIN:-echocity-f.com}"

    if [ $# -ge 1 ]; then
        if [ -d "./$1" ] && [ -f "./$1/.envrc" ]; then
            TARGET_NAME="$1"
            WORKSPACE_DIR="./$1"
        else
            echo -e "${RED}Error: Workspace '$1' no encontrado${NC}"
            exit 1
        fi
    elif ! target_resolve_workspace_from_cwd; then
        echo -e "${RED}Error: Uso: target venv [nombre_maquina] (o ejecuta dentro del workspace)${NC}"
        exit 1
    fi

    cd "$WORKSPACE_DIR" || exit 1

    if [ ! -d "venv" ]; then
        echo -e "${BLUE}Creando entorno virtual Python en $WORKSPACE_DIR/venv ...${NC}"
        if ! python3 -m venv venv; then
            echo -e "${RED}Error: no se pudo crear el entorno virtual.${NC}"
            echo -e "${YELLOW}En Debian/Ubuntu suele faltar el paquete: sudo apt install python3-venv${NC}"
            cd - > /dev/null || true
            return 1
        fi
        echo -e "${GREEN}Entorno virtual creado.${NC}"
    else
        echo -e "${YELLOW}El entorno virtual ya existe en $WORKSPACE_DIR/venv${NC}"
    fi

    if ! grep -q 'source ./venv/bin/activate' .envrc; then
        echo 'source ./venv/bin/activate' >> .envrc
        echo -e "${GREEN}Línea de activación agregada a .envrc${NC}"
    else
        echo -e "${YELLOW}La activación automática ya está presente en .envrc${NC}"
    fi

    # Editar .envrc invalida el sello de confianza de direnv: si no se vuelve a
    # autorizar, direnv bloquea el archivo y el venv deja de activarse al entrar.
    # Se hace siempre, no solo cuando se modificó, para poder reparar un .envrc
    # que ya quedó bloqueado en una ejecución anterior.
    if command -v direnv > /dev/null 2>&1; then
        direnv allow . && echo -e "${GREEN}.envrc autorizado por direnv.${NC}"
    else
        echo -e "${YELLOW}direnv no está instalado: ejecuta 'direnv allow' manualmente en el workspace.${NC}"
    fi

    echo -e "${BLUE}Si tienes direnv instalado, el entorno virtual se activará automáticamente al entrar a este directorio.${NC}"
    echo -e "${YELLOW}Si no usas direnv, puedes activar el entorno manualmente con: source venv/bin/activate${NC}"

    if [ -f "requirements.txt" ]; then
        echo -e "${BLUE}Se detectó requirements.txt. ¿Deseas instalar dependencias ahora? (s/n)${NC}"
        read -r RESP
        if [[ "$RESP" =~ ^[sS]$ ]]; then
            ./venv/bin/pip install -r requirements.txt
        fi
    fi

    cd - > /dev/null || true
}
