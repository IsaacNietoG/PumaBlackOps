# PumaBlackOps

**PumaBlackOps** es un conjunto de herramientas y scripts Bash para facilitar la gestión de objetivos, automatización de tareas y utilidades comunes en pentesting y CTFs, ahora con integración avanzada de tmux y flujos automáticos para CTF.

## Estructura del repositorio

```
.
├── aliases/
│   └── general.sh
├── bin/
│   ├── target
│   ├── ctflinpeas
│   └── penelope
├── lib/
│   └── tmux_helpers.sh
├── spells/
│   ├── add-bin-to-path.sh
│   ├── peass-ng.sh
│   └── penelope.sh
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
- **ctflinpeas**: Binario generado por el script `spells/peass-ng.sh`, versión personalizada de linPEAS para enumeración de privilegios en Linux.
- **penelope**: Script Python descargado por `spells/penelope.sh`, herramienta para automatizar tareas de post-explotación y manejo de shells.

### `lib/`
Scripts de ayuda:

- **tmux_helpers.sh**: Funciones Bash para manipular títulos de paneles/ventanas y obtener información de tmux, usadas por el script `target` para integración avanzada.

### `spells/`
Scripts Bash para instalar, configurar o facilitar el uso de herramientas, nacen por la necesidad de automatizar varias tareas y además tener acceso a las ultimas versiones de las herramientas:

- **add-bin-to-path.sh**: Script interactivo para agregar el directorio `bin/` al PATH del usuario de varias formas (temporal, permanente, subshell, symlinks).
- **peass-ng.sh**: Descarga, compila y coloca una versión personalizada de linPEAS en `bin/ctflinpeas`.
- **penelope.sh**: Descarga y coloca la herramienta penelope en `bin/penelope`.

### `aliases/`
Alias útiles para pentesting y manejo de shells:

- **general.sh**: Define alias como `httpserver` (servidor HTTP rápido con Python) y `listen` (listener con netcat). Se recomienda añadirlo al `.bashrc` o `.zshrc`.

### `.config/tmux/`
Configuración avanzada de tmux para flujos de CTF:

- **tmux.conf**: Configuración personalizada de tmux con integración de mouse, atajos para selección de paneles, y plugins para mejorar la experiencia (TPM, tmux-sensible, tmux-resurrect, tmux-yank, dracula theme, etc). Incluye keybindings y macros para extracción de flags y manejo de timers CTF.
- **plugins/**: Plugins de tmux gestionados como submódulos git, necesarios para la funcionalidad extendida (ver sección de instalación).

### `src/`
Directorio reservado para código fuente adicional o scripts personalizados.

---

## Uso rápido de la herramienta principal: `target`

El script `bin/target` permite gestionar workspaces de pentesting de forma sencilla y ahora automatiza la creación de entornos tmux listos para CTF. Sus subcomandos principales son:

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

---

## Integración avanzada con tmux y plugins

- Al crear un objetivo con `target add`, se lanza automáticamente una sesión tmux con:
  - Paneles y ventanas preconfigurados para Recon, Exploit y Misc.
  - Comandos útiles precargados (ej: penelope, macros para flags, etc).
  - Integración con plugins: tmux-resurrect (persistencia), tmux-yank (copiado), tmux-sensible, y el theme Dracula.
  - Timer CTF visual y macros para extracción de flags con atajos de teclado.
  - Automatización de la entrada en `/etc/hosts` para el target.
- El script `target` usa funciones de `lib/tmux_helpers.sh` para cambiar dinámicamente los títulos de paneles/ventanas según el estado de los escaneos.
- El archivo `.config/tmux/tmux.conf` define atajos y macros útiles para CTF, como extracción de flags, búsqueda de archivos, y control del timer.

---

## Instalación y configuración

1. Clona el repositorio y entra en la carpeta:
   ```bash
   git clone <repo_url>
   cd PumaBlackOps
   ```

2. Inicializa los submódulos de plugins de tmux:
   ```bash
   git submodule update --init --recursive
   ```

3. (Opcional) Ejecuta el script para agregar los binarios al PATH:
   ```bash
   ./spells/add-bin-to-path.sh
   ```

4. (Opcional) Fuentea los alias en tu shell:
   ```bash
   echo 'source /ruta/a/PumaBlackOps/aliases/general.sh' >> ~/.bashrc
   source ~/.bashrc
   ```

5. Instala direnv para manejo automático de variables de entorno por workspace.

6. Usa los scripts desde cualquier lugar si tienes el PATH configurado.

7. Para aprovechar la integración tmux, asegúrate de tener tmux instalado y copia o enlaza `.config/tmux/tmux.conf` a tu `~/.config/tmux/tmux.conf`.

---

## Requisitos

- Bash
- tmux (>=3.0) y los siguientes plugins (se instalan como submódulos):
  - tpm
  - tmux-sensible
  - tmux-resurrect
  - tmux-yank
  - dracula/tmux
- Python 3 (para penelope y httpserver)
- ffuf (para dirsearch)
- nmap (para escaneo)
- git, wget (para spells)
- SecLists en `/usr/share/seclists` (para dirsearch)
- xclip (para integración de clipboard en tmux)
- direnv (para manejo automático de variables de entorno por workspace)

## Recomendado

- Personalizar los atajos de tmux en `.config/tmux/tmux.conf` según tus preferencias.
- Usar una terminal compatible con mouse y UTF-8 para aprovechar todos los features visuales.

---

## Créditos y licencias

- linPEAS/PEASS-ng: https://github.com/carlospolop/PEASS-ng
- penelope: https://github.com/brightio/penelope
- SecLists: https://github.com/danielmiessler/SecLists
- tmux-plugins/tpm: https://github.com/tmux-plugins/tpm
- tmux-plugins/tmux-sensible: https://github.com/tmux-plugins/tmux-sensible
- tmux-plugins/tmux-resurrect: https://github.com/tmux-plugins/tmux-resurrect
- tmux-plugins/tmux-yank: https://github.com/tmux-plugins/tmux-yank
- dracula/tmux: https://github.com/dracula/tmux
