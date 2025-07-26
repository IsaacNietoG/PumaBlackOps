#!/usr/bin/env python3
import os
import subprocess
import re
import sys
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
    try:
        max_services = int(os.getenv("TOT_SERVICES", "10"))
    except ValueError:
        print(f"{Style.ICON_STOP} Error: La variable de entorno $TOT_SERVICES debe ser un número entero.")
        sys.exit(1)

    if not target_ip or not target_url:
        print(f"{Style.ICON_STOP} Error: Por favor, define las variables de entorno $IP y $URL.")
        sys.exit(1)

    recon_dir = Path.cwd() / "recon"
    recon_dir.mkdir(exist_ok=True)
    return target_ip, target_url, recon_dir, max_services

def run_discovery_scan(target_ip, recon_dir, max_services):
    """Fase 1: Ejecuta el descubrimiento rápido en tiempo real y retorna los puertos encontrados."""
    print(f"{Style.HEADER_SEP}")
    print(f"{Style.ICON_PHASE1} {Style.BOLD}FASE 1: FASTSCAN DE PUERTOS{Style.RESET}")
    print(f"{Style.HEADER_SEP}")
    
    nmap_output_file = recon_dir / f"port_scan_{target_ip}.txt"
    print(f"  {Style.BLUE}Objetivo...:{Style.RESET} {target_ip}")
    print(f"  {Style.BLUE}Límite....:{Style.RESET} {max_services} servicios")
    print(f"  {Style.BLUE}Log.......:{Style.RESET} {recon_dir.name}/{nmap_output_file.name}")
    print(Style.SUB_SEP + '\n')

    # ✅ Comando corregido para que funcione en tiempo real
    command = ["nmap", "-Pn", "-n", "-T3", "--max-parallelism", "50", target_ip, "--top-ports","1000", "-oN", str(nmap_output_file), "-sS", "-vvv", "--max-retries", "1"]
    
    port_regex = re.compile(r"Discovered open port (\d+)/tcp")
    opened_ports = set()

    try:
        # ✅ Usamos Popen para procesar la salida línea por línea
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
   
        for line in iter(process.stdout.readline, ''):
            print(f"{Style.GRAY}{line.strip()}{Style.RESET}")
            match = port_regex.search(line)
        
            if not match:
                continue

            port = int(match.group(1))
            if port in opened_ports:
                continue
            
            opened_ports.add(port)

            if len(opened_ports) >= max_services:
                print(f"\n{Style.ICON_STOP} Límite de {max_services} servicio(s) alcanzado.\n")
                process.terminate()
                break
        
        process.wait() # Espera a que el proceso de nmap termine limpiamente
        return sorted(list(opened_ports))

    except FileNotFoundError:
        print(f"{Style.ICON_STOP} Error: 'nmap' no encontrado.")
        return []

def print_summary_and_launch(ports, target_url):
    if not ports:
        return

    
    web_ports_to_open = []
    print(f"  {Style.BOLD}Puertos Descubiertos ({len(ports)} en total):{Style.RESET}\n")
    for port in ports:
        port_str = f"{port}/tcp".ljust(10)
        
        if port not in EXCLUDED_PORTS and (port >= 1024 or port in {80, 443}):
            status = f"{Style.GREEN}Posible Servicio Web Válido{Style.RESET}"
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
    
    command = ["nmap", "-Pn", "-n", "-T4", target_ip, "-sCV", "-oN", str(output_file), "-p", ports_str]
    try:
        # Usamos run porque aquí sí queremos esperar y ver la salida completa de nmap
        subprocess.run(command)
        print(f"\n{Style.ICON_ACTION} {Style.BOLD}Fase 2 (-sCV) completada.{Style.RESET}")
    except subprocess.CalledProcessError:
        print(f"\n{Style.ICON_STOP} El escaneo -sCV terminó con un error.")

# ==============================================================================
# Ejecución Principal
# ==============================================================================
if __name__ == "__main__":
    try:
        target_ip, target_url, recon_dir, max_services = setup_environment()
        
        discovered_ports = run_discovery_scan(target_ip, recon_dir, max_services)
        
        print_summary_and_launch(discovered_ports, target_url)
        
        run_version_scan(target_ip, discovered_ports, recon_dir)

    except KeyboardInterrupt:
        print(f"\n\n{Style.ICON_STOP} Script interrumpido por el usuario. ¡Adiós!{Style.RESET}")
        sys.exit(0)
