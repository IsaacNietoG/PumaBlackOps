#!/bin/bash
# Sourcea todos los archivos .sh en este directorio excepto a sí mismo

for f in "$(dirname "$BASH_SOURCE")"/*.sh; do
    [ "$f" = "$BASH_SOURCE" ] && continue
    [ -f "$f" ] && source "$f"
done 