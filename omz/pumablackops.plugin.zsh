# pumablackops.plugin.zsh - Plugin de Oh My Zsh para PumaBlackOps.
#
# Se instala enlazando este directorio dentro de $ZSH_CUSTOM/plugins (ver
# spells/install-omz-plugin.sh). Este plugin NO duplica los aliases: los carga
# desde aliases/all.sh, que sigue siendo la única fuente de verdad. Así el repo
# continúa funcionando igual para quien no use Oh My Zsh, o use bash.
#
# Documentación: docs/OMZ_PLUGIN.md

# --- Localizar la raíz del repo ------------------------------------------------
# Oh My Zsh sourcea los plugins con ruta absoluta ($ZSH_CUSTOM/<plugin>), y
# ${0:A} resuelve symlinks, que es justo lo que hace falta porque el plugin se
# instala por symlink al repo.
typeset -g _PBO_REPO="${0:A:h:h}"

if [[ ! -f "$_PBO_REPO/aliases/all.sh" ]]; then
    # No se encontró el repo: se omite en silencio para no romper el shell.
    unset _PBO_REPO
    return 0 2>/dev/null || true
fi

# --- Cargar los aliases --------------------------------------------------------
# aliases/all.sh ya es compatible con bash y zsh. Si el usuario ya lo sourceó por
# otra vía, no se vuelve a cargar.
if ! alias ars >/dev/null 2>&1; then
    source "$_PBO_REPO/aliases/all.sh"
fi

# --- Indicador de target en el prompt -------------------------------------------
# Sigue el mismo patrón que lib/git.zsh de Oh My Zsh:
#   * vacío cuando no aplica (fuera de un workspace, como git fuera de un repo)
#   * sin colores hardcodeados: el formato lo pone el tema
#   * el nombre se escapa con %% para no romper el prompt

# IP del target. Se usa $IP si viene de direnv; si no, se lee la línea
# 'export IP=' del .envrc sin evaluarlo (nada de eval, y se escapa % al
# imprimir). Es un archivo de 3 líneas, así que el costo por prompt es nulo.
function _pbo_target_ip() {
    [[ -n "${IP:-}" ]] && { REPLY="$IP"; return 0; }
    [[ -f "$1/.envrc" ]] || return 1
    local line
    while IFS= read -r line; do
        case "$line" in
            "export IP="*)
                REPLY="${line#export IP=}"
                REPLY="${REPLY%\"}"; REPLY="${REPLY#\"}"
                REPLY="${REPLY%\'}"; REPLY="${REPLY#\'}"
                [[ -n "$REPLY" ]] && return 0
                ;;
        esac
    done < "$1/.envrc"
    return 1
}

# Nombre + IP del target activo, o vacío si no hay ninguno.
function pbo_target_info() {
    local ws="" d

    # 1) direnv ya exportó CTF_WORKSPACE_DIR al entrar al workspace.
    if [[ -n "${CTF_WORKSPACE_DIR:-}" && -f "$CTF_WORKSPACE_DIR/.envrc" ]]; then
        ws="$CTF_WORKSPACE_DIR"
    else
        # 2) fallback sin direnv: subir desde $PWD buscando un .envrc.
        #    Se calcula en cada llamada, no al cargar el plugin, porque el
        #    prompt se reevalúa tras cada cd.
        d="$PWD"
        while [[ -n "$d" && "$d" != "/" ]]; do
            if [[ -f "$d/.envrc" ]]; then
                ws="$d"
                break
            fi
            d="${d:h}"
        done
    fi

    # Sin workspace: vacío, igual que git fuera de un repositorio.
    [[ -n "$ws" ]] || return 0

    local ip=""
    _pbo_target_ip "$ws" && ip=" $REPLY"

    # Escapar % para que el prompt no lo interprete (igual que hace
    # _omz_git_prompt_info con el nombre de la rama).
    local name="${ws:t}"
    echo "${ZSH_THEME_PBO_TARGET_PROMPT_PREFIX}${name//\%/%%}${ip//\%/%%}${ZSH_THEME_PBO_TARGET_PROMPT_SUFFIX}"
}

# Variables de tema. OMZ no define defaults para las suyas: si el tema no las
# pone, el segmento sale vacío. Se hace igual aquí, pero se ofrece un default
# legible desde el prompt si el usuario no define nada.
: ${ZSH_THEME_PBO_TARGET_PROMPT_PREFIX:="target:("}
: ${ZSH_THEME_PBO_TARGET_PROMPT_SUFFIX:=") "}

unset _PBO_REPO