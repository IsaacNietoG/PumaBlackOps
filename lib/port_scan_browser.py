#!/usr/bin/env python3
import os
import subprocess
import re
import sys
import argparse # ✅ Importado para argumentos de consola
import time     # ✅ Importado para la pausa
from pathlib import Path

# ==============================================================================
# Definiciones de Estilo para la UI en CLI
# ==============================================================================
class Style:
    RESET = '\033[0m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[96m'
    GRAY = '\033[90m'
    BOLD = '\033[1m'
    
    HEADER_SEP = '═' * 60
    SUB_SEP = '─' * 60
    ICON_PHASE1 = '🔭'
    ICON_PHASE2 = '🔬'
    ICON_SUMMARY = '📊'
    ICON_ACTION = '✅'
    ICON_STOP = '🛑'
    ICON_PORT = '[+]'
    ICON_WAIT = '⏳'

# ==============================================================================
# CONFIGURACIÓN DE PUERTOS
# ==============================================================================
EXCLUDED_PORTS = {
    21, 22, 23, 25, 53, 110, 139, 143, 445, 993, 995,
    3306, 3389, 5432,
}

# ==============================================================================
# Funciones del Script
# ==============================================================================

def setup_environment():
    """Obtiene las variables de entorno y crea el directorio de reconocimiento."""
    target_ip = os.getenv("IP")
    target_url = os.getenv("URL")

    if not target_ip or not target_url:
        print(f"{Style.ICON_STOP} Error: Por favor, define las variables de entorno $IP y $URL.")
        sys.exit(1)

    recon_dir = Path.cwd() / "recon"
    recon_dir.mkdir(exist_ok=True)
    return target_ip, target_url, recon_dir

def run_discovery_scan(target_ip, recon_dir, max_services):
    """Fase 1: Ejecuta el descubrimiento rápido en tiempo real y retorna los puertos encontrados."""
    print(f"{Style.HEADER_SEP}")
    print(f"{Style.ICON_PHASE1} {Style.BOLD}FASE 1: DESCUBRIMIENTO SEGURO DE PUERTOS{Style.RESET}")
    print(f"{Style.HEADER_SEP}")
    
    nmap_output_file = recon_dir / f"port_scan_{target_ip}.txt"
    print(f"  {Style.BLUE}Objetivo...:{Style.RESET} {target_ip}")
    if max_services:
        print(f"  {Style.BLUE}Límite....:{Style.RESET} Detener tras encontrar {max_services} servicios")
    else:
        print(f"  {Style.BLUE}Límite....:{Style.RESET} Escanear todos los puertos")
        max_services = 999999 # Un número grande para "sin límite"
        
    print(f"  {Style.BLUE}Log.......:{Style.RESET} {recon_dir.name}/{nmap_output_file.name}")
    print(Style.SUB_SEP)

    # ✅ Comando de nmap actualizado con los parámetros seguros
    command = ["nmap", "-T3", "--max-parallelism", "50", "-p-", "-sS", "-Pn", "-n", target_ip, "-oN", str(nmap_output_file), "-vvv"]
    
    port_regex = re.compile(r"Discovered open port (\d+)/tcp")
    opened_ports = set()
    
    try:
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)

        for line in iter(process.stdout.readline, ''):
            match = port_regex.search(line)
            
            if not match:
                if "Scanning" in line or "Initiating" in line or "Completed" in line:
                     print(f"{Style.GRAY}{line.strip()}{Style.RESET}")
                continue

            port = int(match.group(1))
            if port in opened_ports:
                continue
            
            opened_ports.add(port)
            port_str = f"{port}/tcp".ljust(10)
            print(f"{Style.ICON_PORT} {Style.BOLD}Puerto Detectado:{Style.GREEN} {port_str}{Style.RESET} ({len(opened_ports)}/{max_services if max_services < 999999 else '∞'})")

            if len(opened_ports) >= max_services:
                print(f"\n{Style.ICON_STOP} Límite de {max_services} servicio(s) alcanzado. Finalizando descubrimiento...")
                process.terminate()
                break
        
        process.wait()
        return sorted(list(opened_ports))

    except FileNotFoundError:
        print(f"{Style.ICON_STOP} Error: 'nmap' no encontrado.")
        return []

def print_summary_and_launch(ports, target_url):
    """Fase 1.5: Imprime el resumen y lanza los navegadores."""
    if not ports:
        return

    
    web_ports_to_open = []
    print(f"  \n{Style.BOLD}Puertos Descubiertos:{Style.RESET}\n")
    for port in ports:
        port_str = f"{port}/tcp".ljust(10)
        
        if port not in EXCLUDED_PORTS and (port >= 1024 or port in {80, 443}):
            status = f"{Style.GREEN}Servicio Web Válido{Style.RESET}"
            web_ports_to_open.append(port)
        elif port in EXCLUDED_PORTS:
            status = f"{Style.GRAY}Excluido (ej. DB, SSH){Style.RESET}"
        else:
            status = f"{Style.GRAY}Reservado (no web){Style.RESET}"
            
        print(f"    {Style.GREEN}[+]{Style.RESET} {port_str} └──> {status}")

    if web_ports_to_open:
        print(f"\n  {Style.YELLOW}Lanzando {len(web_ports_to_open)} pestaña(s) en Firefox...{Style.RESET}")
        for port in web_ports_to_open:
            protocol = "https" if port == 443 else "http"
            full_url = f"{protocol}://{target_url}" if port in {80, 443} else f"{protocol}://{target_url}:{port}"
            try:
                subprocess.Popen(["firefox", "--new-tab", full_url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except FileNotFoundError:
                print(f"    {Style.GRAY}AVISO: Comando 'firefox' no encontrado.{Style.RESET}")
                break
    else:
        print(f"\n  {Style.BLUE}No se encontraron servicios web para abrir en el navegador.{Style.RESET}")

def run_version_scan(target_ip, ports, recon_dir):
    """Fase 2: Ejecuta un escaneo -sCV en los puertos descubiertos."""
    if not ports:
        return

    print(f"\n{Style.HEADER_SEP}")
    print(f"{Style.ICON_PHASE2} {Style.BOLD}FASE 2: ENUMERACIÓN DETALLADA (-sCV){Style.RESET}")
    print(f"{Style.HEADER_SEP}")
    
    ports_str = ",".join(map(str, ports))
    output_file = recon_dir / f"version_scan_{target_ip}.txt"
    
    print(f"  {Style.BLUE}Objetivo...:{Style.RESET} {target_ip}")
    print(f"  {Style.BLUE}Puertos...:{Style.RESET} {Style.GREEN}{ports_str}{Style.RESET}")
    print(f"  {Style.BLUE}Log.......:{Style.RESET} {recon_dir.name}/{output_file.name}\n")
    
    command = ["nmap", "-Pn", "-n", "-T3", target_ip, "-sCV", "-oN", str(output_file), "-p", ports_str]
    try:
        subprocess.run(command)
        print(f"\n{Style.ICON_ACTION} {Style.BOLD}Fase 2 (-sCV) completada.{Style.RESET}")
    except subprocess.CalledProcessError:
        print(f"\n{Style.ICON_STOP} El escaneo -sCV terminó con un error.")

# ==============================================================================
# Ejecución Principal
# ==============================================================================
if __name__ == "__main__":
    # ✅ Configuración de argumentos de consola
    parser = argparse.ArgumentParser(description="Escáner de puertos en 2 fases con lanzamiento en navegador.")
    parser.add_argument("-s", "--services", type=int, help="Número total de servicios a encontrar antes de detener la Fase 1. Escanea todos los puertos si no se especifica.")
    args = parser.parse_args()
    
    try:
        target_ip, target_url, recon_dir = setup_environment()
        
        # Fase 1
        discovered_ports = run_discovery_scan(target_ip, recon_dir, args.services)
        
        print_summary_and_launch(discovered_ports, target_url)
        
        # ✅ Pausa de 15 segundos
        if discovered_ports: # Solo pausar si hay algo que hacer en la Fase 2
            print(f"\n{Style.ICON_WAIT} {Style.YELLOW}Iniciando Fase 2 en 5 segundos (cooldown)... (Presiona Ctrl+C para cancelar){Style.RESET}")
            time.sleep(5)

        # Fase 2
        run_version_scan(target_ip, discovered_ports, recon_dir)

    except KeyboardInterrupt:
        print(f"\n\n{Style.ICON_STOP} Script interrumpido por el usuario. ¡Adiós!{Style.RESET}")
        sys.exit(0)
