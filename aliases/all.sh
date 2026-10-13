#!/bin/bash
# Sourcea todos los archivos .sh de este directorio excepto a sí mismo.
# Compatible con bash y zsh.

# Ruta de este script. $BASH_SOURCE no existe en zsh, por lo que usarlo dejaba
# el directorio vacío y el glob terminaba sobre el cwd del usuario.
if [ -n "${BASH_VERSION:-}" ]; then
    _all_self="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
    _all_self="${(%):-%x}"
else
    _all_self="$0"
fi

# Ruta absoluta de este script, para poder compararla con la de los candidatos.
_all_self_abs="$(cd "$(dirname "$_all_self")" 2>/dev/null && pwd)/$(basename "$_all_self")"
_all_dir="$(dirname "$_all_self_abs")"

for f in "$_all_dir"/*.sh; do
    [ -f "$f" ] || continue
    [ "$f" = "$_all_self_abs" ] && continue
    source "$f"
done

unset _all_self _all_self_abs _all_dir