# PumaBlackOps

**PumaBlackOps** es un conjunto de herramientas y scripts Bash para facilitar la gestión de objetivos, automatización de tareas y utilidades comunes en pentesting y CTFs.

## Estructura del repositorio

```
.
├── aliases/
│   └── general.sh
├── bin/
│   ├── target
│   ├── ctflinpeas
│   └── penelope
├── spells/
│   ├── add-bin-to-path.sh
│   ├── peass-ng.sh
│   └── penelope.sh
├── src/
└── README.md
```

---

## Descripción de carpetas y archivos principales

### `bin/`
Contiene herramientas principales y utilidades ejecutables:

- **target**: Script Bash principal para la gestión de workspaces de pentesting. Permite crear, listar, escanear y documentar objetivos, así como realizar búsquedas de directorios con ffuf.
- **ctflinpeas**: Binario generado por el script `spells/peass-ng.sh`, versión personalizada de linPEAS para enumeración de privilegios en Linux.
- **penelope**: Script Python descargado por `spells/penelope.sh`, herramienta para automatizar tareas de post-explotación y manejo de shells.

### `spells/`
Scripts Bash para instalar, configurar o facilitar el uso de herramientas, nacen por la necesidad de automatizar varias tareas y además tener acceso a las ultimas versiones de las herramientas:

- **add-bin-to-path.sh**: Script interactivo para agregar el directorio `bin/` al PATH del usuario de varias formas (temporal, permanente, subshell, symlinks).
- **peass-ng.sh**: Descarga, compila y coloca una versión personalizada de linPEAS en `bin/ctflinpeas`.
- **penelope.sh**: Descarga y coloca la herramienta penelope en `bin/penelope`.

### `aliases/`
Alias útiles para pentesting y manejo de shells:

- **general.sh**: Define alias como `httpserver` (servidor HTTP rápido con Python) y `listen` (listener con netcat). Se recomienda añadirlo al `.bashrc` o `.zshrc`.

### `src/`
Directorio reservado para código fuente adicional o scripts personalizados.

---

## Uso rápido de la herramienta principal: `target`

El script `bin/target` permite gestionar workspaces de pentesting de forma sencilla. Sus subcomandos principales son:

- `add <nombre_maquina> <IP>`: Crea un nuevo workspace para un objetivo; carga una copia de ctfpeas en la raiz del proyecto para un rápido despliegue en el foothold.
- `scan <nombre_maquina>`: Ejecuta un escaneo Nmap completo y guarda los resultados.
- `list`: Lista todos los objetivos/workspaces creados.
- `info <nombre_maquina>`: Muestra información y estructura del objetivo.
- `note [nombre_maquina] <nota>`: Agrega una nota rápida al writeup del objetivo.
- `dirsearch [nombre_maquina] [puerto]`: Realiza una búsqueda recursiva de directorios con ffuf usando SecLists.
- `help`: Muestra la ayuda y ejemplos de uso.
- `venv [nombre_maquina]`: Crea y configura un entorno virtual Python en el workspace del target, agregando la activación automática a .envrc (ideal para usar con direnv).

**Ejemplo de flujo de trabajo:**
```bash
# Crear un nuevo objetivo
target add vulnbox 192.168.1.100

# Cambiar al directorio del objetivo
cd vulnbox

# Escanear con Nmap
target scan

# Buscar directorios web en el puerto 8080
target dirsearch 8080

# Crear y activar entorno virtual Python para el target
target venv

# Agregar una nota rápida
target note "Encontrado panel de admin en /admin"
```

---

## Instalación y configuración

1. Clona el repositorio y entra en la carpeta:
   ```bash
   git clone <repo_url>
   cd PumaBlackOps
   ```

2. (Opcional) Ejecuta el script para agregar los binarios al PATH:
   ```bash
   ./spells/add-bin-to-path.sh
   ```

3. (Opcional) Fuentea los alias en tu shell:
   ```bash
   echo 'source /ruta/a/PumaBlackOps/aliases/general.sh' >> ~/.bashrc
   source ~/.bashrc
   ```

4. Usa los scripts desde cualquier lugar si tienes el PATH configurado.

---

## Requisitos

- Bash
- Python 3 (para penelope y httpserver)
- ffuf (para dirsearch)
- nmap (para escaneo)
- git, wget (para spells)
- SecLists en `/usr/share/seclists` (para dirsearch)

## Recomendado

- Si descargas direnv, las variables de entorno dependientes al folder creadas por target se manejan automáticamente, así como el entorno virtual de Python (si aplica).

---

## Créditos y licencias

- linPEAS/PEASS-ng: https://github.com/carlospolop/PEASS-ng
- penelope: https://github.com/brightio/penelope
- SecLists: https://github.com/danielmiessler/SecLists
