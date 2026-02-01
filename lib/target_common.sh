# target_common.sh - Rutas, colores y helpers de resolución de workspace.
# Debe ser sourceado después de definir REPO_BASE y SCRIPT_DIR (p. ej. desde bin/target).

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Resuelve workspace desde el directorio actual: debe existir ./.envrc.
# Establece TARGET_NAME y WORKSPACE_DIR. Retorna 0 si ok, 1 si error.
target_resolve_workspace_from_cwd() {
    if [ -f ./.envrc ]; then
        TARGET_NAME=$(basename "$PWD")
        WORKSPACE_DIR="$PWD"
        return 0
    fi
    return 1
}

# Resuelve workspace con nombre opcional: si se pasa un nombre y existe ./nombre con .envrc,
# ese es el workspace; si no, si existe ./.envrc el workspace es cwd; si no, error.
# Establece TARGET_NAME y WORKSPACE_DIR. Retorna 0 si ok, 1 si error.
# Uso: target_resolve_workspace_with_optional_name [nombre_opcional]
target_resolve_workspace_with_optional_name() {
    if [ $# -ge 1 ] && [ -d "./$1" ] && [ -f "./$1/.envrc" ]; then
        TARGET_NAME="$1"
        WORKSPACE_DIR="./$1"
        return 0
    fi
    if [ -f ./.envrc ]; then
        TARGET_NAME=$(basename "$PWD")
        WORKSPACE_DIR="$PWD"
        return 0
    fi
    return 1
}

# Carga el .envrc del workspace y opcionalmente comprueba que IP esté definida.
# Uso: target_load_env [--require-ip]
target_load_env() {
    local require_ip=0
    [ "$1" = "--require-ip" ] && require_ip=1

    if [ -z "${WORKSPACE_DIR:-}" ]; then
        echo -e "${RED}Error: WORKSPACE_DIR no está definido${NC}" >&2
        return 1
    fi
    if [ ! -f "$WORKSPACE_DIR/.envrc" ]; then
        echo -e "${RED}Error: Archivo .envrc no encontrado en $WORKSPACE_DIR${NC}" >&2
        return 1
    fi
    # shellcheck source=/dev/null
    source "$WORKSPACE_DIR/.envrc"
    if [ "$require_ip" -eq 1 ] && [ -z "${IP:-}" ]; then
        echo -e "${RED}Error: Variable IP no definida en .envrc${NC}" >&2
        return 1
    fi
    return 0
}
