#!/bin/bash

# Obtener la IP de la interfaz tun0
VPN_IP=$(ip addr show tun0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 2>/dev/null || echo '')

# Obtener el nombre de la VPN del proceso OpenVPN
VPN_NAME=$(ps aux | grep '[o]penvpn' | grep -o -P '(?<=--config |\/)[^\/]+\.ovpn' | xargs -r basename -s .ovpn | head -n 1 2>/dev/null || echo 'N/A')

# Si no hay IP, o si el nombre es "N/A" y la IP está vacía, la VPN no está activa.
# En este caso, simplemente imprimimos una cadena vacía o un indicador simple.
# Dracula ocultará el módulo si no hay salida (gracias a @dracula-show-empty-plugins false).
if [ -z "$VPN_IP" ] || ([ "$VPN_NAME" == "N/A" ] && [ -z "$VPN_IP" ]); then
    echo "" # Imprime una cadena vacía para que Dracula lo oculte
else
    # Si la VPN está activa, mostramos la información con un formato simple.
    # Dracula aplicará los colores definidos en tmux.conf.
    echo "🔐 ${VPN_NAME} ${VPN_IP}"
fi
