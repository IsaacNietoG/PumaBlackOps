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

# ============================================================================
# Indicador de target
#
# Sigue el patrón de lib/git.zsh de Oh My Zsh:
#   * vacío cuando no aplica (fuera de un workspace, como git fuera de un repo)
#   * sin colores hardcodeados: el formato lo pone el tema
#   * el nombre se escapa con %% para no romper el prompt
# ============================================================================

# IP del target. Se usa $IP si viene de direnv; si no, se lee la línea
# 'export IP=' del .envrc sin evaluarlo (nada de eval). Es un archivo de 3
# líneas, así que el costo por prompt es despreciable.
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

# Resuelve el target activo. Deja el resultado en _PBO_LABEL.
# Retorna 1 si no hay target.
function _pbo_resolve() {
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
    [[ -n "$ws" ]] || return 1

    local ip=""
    _pbo_target_ip "$ws" && ip="$REPLY"

    # El prompt ya muestra la ruta (y con ella el nombre del target), así que el
    # segmento muestra la IP: es el dato que no aparece en ninguna otra parte.
    # Si no hay IP en el .envrc, cae al nombre del directorio.
    _PBO_LABEL="${ip:-${ws:t}}"
    return 0
}

# Función pública: texto plano, sin depender del tema.
function pbo_target_info() {
    _pbo_resolve || return 0
    echo "${ZSH_THEME_PBO_TARGET_PROMPT_PREFIX}${_PBO_LABEL//\%/%%}${ZSH_THEME_PBO_TARGET_PROMPT_SUFFIX}"
}

# Segmento con el estilo del tema, al estilo de prompt_virtualenv de agnoster.
# Reutiliza el prompt_segment del tema para que la cadena de colores cierre bien.
function _pbo_prompt_segment() {
    (( $+functions[prompt_segment] )) || return 0
    _pbo_resolve || return 0
    prompt_segment "${PBO_TARGET_BG:-cyan}" "${PBO_TARGET_FG:-$CURRENT_FG}" \
        "${_PBO_LABEL//\%/%%}"
}

# --- Integración con el tema ---------------------------------------------------
# Oh My Zsh carga el tema DESPUÉS de los plugins, así que aquí no existe todavía.
# Se espera al primer prompt (precmd), cuando el tema ya está cargado.
#
# Con tema powerline (agnoster y derivados): se envuelve prompt_end para que
# el segmento sea el último bloque con color y prompt_end lo cierre. Es el mismo
# punto donde agnoster mete sus segmentos, así que la cadena no se rompe.
# Sin prompt_segment: se cae a un PROMPT plano.
function _pbo_install_segment() {
    # PBO_TARGET_DISABLE=1 apaga solo el indicador; los aliases no se ven afectados.
    if [[ -n "${PBO_TARGET_DISABLE:-}" ]]; then
        return 0
    fi

    if (( $+functions[prompt_segment] )) && (( $+functions[prompt_end] )); then
        functions[_pbo_orig_prompt_end]=$functions[prompt_end]
        function prompt_end() {
            _pbo_prompt_segment
            _pbo_orig_prompt_end
        }
    else
        PROMPT+=' $(pbo_target_info)'
    fi
    add-zsh-hook -d precmd _pbo_install_segment
}

if (( $+functions[add-zsh-hook] )); then
    add-zsh-hook precmd _pbo_install_segment
else
    _pbo_install_segment
fi

# Colores del segmento powerline (usados solo si el tema define prompt_segment).
: ${PBO_TARGET_BG:=cyan}
: ${PBO_TARGET_FG:=white}

unset _PBO_REPO