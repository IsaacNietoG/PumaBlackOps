# Análisis para refactorización de `bin/target`

Documento de análisis **función por función** y **feature por feature** del script `bin/target`, con propuesta de componentes y destino de cada función.

---

## 1. Estructura actual del script (por bloques)

| Líneas   | Bloque              | Descripción |
|----------|---------------------|-------------|
| 1-15     | **Bootstrap**      | Shebang, `SCRIPT_DIR`, `REPO_BASE`, `source tmux_helpers.sh`, colores |
| 17-50    | **show_help**       | Ayuda y ejemplos del CLI |
| 52-216   | **target_add**      | Crear workspace + sesión tmux (lógica grande) |
| 218-281  | **target_scan_ports** | Escaneo de puertos (nmap o port_scan_browser.py) |
| 283-301  | **target_scan_services** | Escaneo -sCV sobre puertos ya detectados |
| 303-308  | **target_scan_all** | Orquestador: ports + services |
| 310-356  | **main_target_scan** | Dispatcher de `scan` + resolución de workspace |
| 358-370  | **target_list**     | Listar targets (dirs con .envrc) |
| 372-404  | **target_info**     | Mostrar IP, writeup, directorios de un target |
| 406-424  | **target_note**     | Añadir nota al writeup.md |
| 427-456  | **target_dirsearch** | Ffuf recursivo contra URL del target |
| 458-528  | **target_venv**     | Crear venv y enganchar a .envrc |
| 430-613  | **Main**            | Comprobación de args y `case` de subcomandos |

*(Rangos aproximados; en el archivo real dirsearch ~427-456, venv ~458-528.)*

---

## 2. Inventario función por función

### 2.1. show_help (L17-50)

- **Qué hace:** Imprime uso, subcomandos, subcomandos de `scan` y ejemplos.
- **Dependencias:** Solo variables de color (`BLUE`, `GREEN`, etc.).
- **Destino propuesto:** **lib/target_help.sh** (o mantener en el binario como única función de “CLI”) o **lib/target_common.sh** si queremos todo lo “global” del target en un solo sitio.

---

### 2.2. target_add (L52-216)

- **Qué hace:**
  1. Valida 2 args: `nombre_maquina`, `IP`.
  2. Crea `WORKSPACE_DIR="$(pwd)/$TARGET_NAME"` y `mkdir -p`.
  3. Escribe `.envrc` (IP, URL, CTF_WORKSPACE_DIR).
  4. `direnv allow`.
  5. Crea `writeup.md` con plantilla.
  6. Crea subdirs: `recon`, `exploits`, `loot`, `research`.
  7. Copia `ctflinpeas` desde `bin/` al workspace si existe.
  8. **Bloque Tmux (L114-215):**
     - Determina `SERVER_NAME` (default vs PumaBlackOps) según sesiones existentes.
     - Genera config tmux (`generate-tmux-config.sh`).
     - Si ya existe sesión con nombre del target → attach.
     - Si no: crea sesión, ventanas (Recon con 2 paneles, Exploit, Misc.), envía keys (hosts, `target scan ports -s`, penelope, ctf_timer), selecciona ventana/pane y attach.
- **Dependencias:** `REPO_BASE`, `SCRIPT_DIR`, colores, `tmux`, `direnv`, `set_tmux_status_name` (no se usa aquí; se usa en scan).
- **Destino propuesto:**
  - Creación de estructura: **lib/target_workspace.sh** → función `target_create_workspace_structure()` (pasos 2-7).
  - Lógica tmux: **lib/target_tmux.sh** → `target_tmux_get_server_name()`, `target_tmux_ensure_config()`, `target_tmux_attach_or_create_session()`.
  - `target_add` puede quedar en **lib/target_workspace.sh** (o en un orquestador) y hacer: `target_create_workspace_structure` + `target_tmux_attach_or_create_session`.

---

### 2.3. target_scan_ports (L218-281)

- **Qué hace:**
  1. Parsea opciones: `--top-ports N`, `--all-ports`, `-s|--services`.
  2. Si `-s|--services`: llama a `port_scan_browser.py -s N` y retorna.
  3. Si no: opcionalmente actualiza título del pane tmux (`set_tmux_status_name`), ejecuta `nmap ... -oN ... port_scan.txt`, restaura título.
- **Dependencias:** `REPO_BASE`, `WORKSPACE_DIR`, `TARGET_NAME`, `IP` (espera que estén definidos por quien llama), colores, `set_tmux_status_name` (tmux_helpers.sh).
- **Destino propuesto:** **lib/target_scan.sh**. La resolución de workspace y carga de `.envrc` la hace `main_target_scan`, no esta función.

---

### 2.4. target_scan_services (L283-301)

- **Qué hace:** Lee `WORKSPACE_DIR/recon/port_scan.txt`, extrae puertos abiertos, ejecuta `nmap -sCV` y escribe `versions_scan.txt`.
- **Dependencias:** `WORKSPACE_DIR`, `TARGET_NAME`, `IP`, colores.
- **Destino propuesto:** **lib/target_scan.sh**.

---

### 2.5. target_scan_all (L303-308)

- **Qué hace:** Llama a `target_scan_ports "$@"` y luego `target_scan_services`.
- **Destino propuesto:** **lib/target_scan.sh**.

---

### 2.6. main_target_scan (L310-356)

- **Qué hace:**
  1. Si no hay argumentos, imprime uso de `scan` y sale.
  2. Toma primer arg como modo: `ports` | `services` | `all`.
  3. **Resuelve workspace:** si existe `./.envrc` → workspace = cwd y `TARGET_NAME=basename $PWD`; si no, error.
  4. Hace `source "$WORKSPACE_DIR/.envrc"` y comprueba que `IP` esté definida.
  5. Según modo, llama a `target_scan_ports`, `target_scan_services` o `target_scan_all`.
- **Dependencias:** Colores, funciones de scan.
- **Destino propuesto:** **lib/target_scan.sh**. La “resolución de workspace desde cwd” se puede extraer a **lib/target_common.sh** como `target_resolve_workspace_from_cwd` (retorna/establece TARGET_NAME y WORKSPACE_DIR) para reutilizarla en otros subcomandos.

---

### 2.7. target_list (L358-370)

- **Qué hace:** Itera sobre `*/` en cwd; si el dir tiene `.envrc`, hace `source` y muestra nombre e IP.
- **Dependencias:** Colores.
- **Destino propuesto:** **lib/target_list.sh** (o **lib/target_query.sh** si agrupamos list + info). No necesita resolución de un único target.

---

### 2.8. target_info (L372-404)

- **Qué hace:**
  1. **Resuelve target:** si hay 1 arg y existe `./$1` con `.envrc` → ese target; si hay 0 args y existe `./.envrc` → cwd; si no, error.
  2. Comprueba que `WORKSPACE_DIR` exista.
  3. Muestra IP (vía .envrc), ruta del writeup, y lista de directorios.
- **Dependencias:** Colores.
- **Destino propuesto:** **lib/target_list.sh** (o **target_query.sh**). Usa un helper de “resolver target por nombre opcional o cwd” → **lib/target_common.sh**.

---

### 2.9. target_note (L406-424)

- **Qué hace:**
  1. **Resuelve target:** igual que en dirsearch/venv: si hay al menos un arg y `./$1` es un workspace (dir con .envrc), entonces primer arg es target y el resto es la nota; si no, asume cwd como workspace y todos los args son la nota.
  2. Comprueba que haya texto de nota.
  3. Añade línea al writeup con fecha y texto.
- **Dependencias:** Colores.
- **Destino propuesto:** **lib/target_note.sh** (o **target_writeup.sh**). La resolución “primer arg puede ser target o parte del contenido” debe estar en **lib/target_common.sh** como helper reutilizable.

---

### 2.10. target_dirsearch (L427-456)

- **Qué hace:**
  1. **Resuelve target y puerto:** mismo patrón que note: primer arg puede ser nombre de target o, si estamos en workspace, puerto; segundo arg puede ser puerto.
  2. Carga `.envrc` y comprueba `IP`.
  3. Construye URL (http/https, puerto 80/443 u otro).
  4. Crea `recon` si no existe, define nombre de fichero con timestamp, ejecuta ffuf recursivo, escribe resultado.
- **Dependencias:** Colores, `ffuf`, wordlist por defecto.
- **Destino propuesto:** **lib/target_dirsearch.sh** (o **target_web.sh**). Resolución target/args en **lib/target_common.sh**.

---

### 2.11. target_venv (L458-528)

- **Qué hace:**
  1. **Resuelve workspace:** 1 arg y existe `./$1` con .envrc → ese workspace; 0 args y ./.envrc → cwd; si no, error.
  2. Crea `venv` si no existe, añade `source ./venv/bin/activate` a `.envrc` si no está, opcionalmente instala `requirements.txt`.
- **Dependencias:** Colores.
- **Destino propuesto:** **lib/target_venv.sh**. Resolución en **lib/target_common.sh**.

---

### 2.12. Main (L430-613)

- **Qué hace:** Si `$# -eq 0` → show_help y exit; si no, `case $1` en add, scan, list, info, note, dirsearch, venv, help y delega en las funciones anteriores.
- **Destino propuesto:** Queda en **bin/target**, que solo hace `source` de los módulos y este dispatch.

---

## 3. Patrones repetidos (lógica a extraer)

### 3.1. Resolución de workspace / target

Aparece de forma similar en:

- **main_target_scan:** solo “desde cwd” (hay .envrc en cwd → workspace = cwd).
- **target_info:** “1 arg = nombre de target” o “0 args = cwd”.
- **target_note:** “1 arg = puede ser target o primer palabra de la nota” (si ./$1 es workspace → target; si no → cwd y todo es nota).
- **target_dirsearch:** mismo patrón que note: primer arg = target o puerto según contexto.
- **target_venv:** “1 arg = nombre de target” o “0 args = cwd”.

Funciones propuestas en **lib/target_common.sh**:

- **target_resolve_workspace_from_cwd**  
  Comprueba que `./.envrc` exista, asigna `TARGET_NAME=$(basename "$PWD")`, `WORKSPACE_DIR="$PWD"`. Retorna 0/1.

- **target_resolve_workspace_with_optional_name** `[nombre_opcional]`  
  Si se pasa un nombre y existe `./nombre_opcional` con `.envrc` → ese es el workspace; si no, si existe `./.envrc` → cwd; si no, error. Establece `TARGET_NAME` y `WORKSPACE_DIR`.

- **target_load_env**  
  Recibe `WORKSPACE_DIR`, hace `source "$WORKSPACE_DIR/.envrc"` y opcionalmente comprueba que `IP` esté definida.

Así, cada subcomando que necesite “un target” usará uno de estos helpers y, si hace falta, interpretará el resto de args (nota, puerto, etc.) después.

---

### 3.2. Colores y constantes globales

- Todas las funciones usan `RED`, `GREEN`, `YELLOW`, `BLUE`, `NC`.
- **Destino:** **lib/target_common.sh** (o **lib/colors.sh** si se quiere un módulo solo de presentación).  
- `REPO_BASE` y `SCRIPT_DIR` también pueden definirse una sola vez en **target_common.sh** (o en un pequeño **lib/bootstrap.sh** que solo ponga rutas y cargue colors y common).

---

## 4. Features y agrupación en componentes

| Feature        | Funciones / responsabilidad                    | Archivo propuesto     |
|----------------|------------------------------------------------|------------------------|
| Bootstrap      | Rutas, colores, helpers de resolución y env     | lib/target_common.sh   |
| Ayuda          | show_help                                      | lib/target_help.sh     |
| Workspace      | target_add, creación de estructura y .envrc    | lib/target_workspace.sh|
| Tmux           | Servidor, config, crear/adjuntar sesión        | lib/target_tmux.sh     |
| Scan           | main_target_scan, ports, services, all        | lib/target_scan.sh     |
| Listado/consulta| target_list, target_info                       | lib/target_list.sh     |
| Notas/writeup  | target_note                                   | lib/target_note.sh     |
| Dirsearch      | target_dirsearch                               | lib/target_dirsearch.sh|
| Venv           | target_venv                                    | lib/target_venv.sh     |
| CLI            | Validación de args y case de subcomandos       | bin/target             |

---

## 5. Mapeo función → archivo

| Función                  | Archivo destino        | Notas |
|--------------------------|------------------------|--------|
| (colores, REPO_BASE, SCRIPT_DIR) | lib/target_common.sh   | Constantes y bootstrap |
| target_resolve_workspace_from_cwd | lib/target_common.sh   | Nueva, extraída de main_target_scan y otros |
| target_resolve_workspace_with_optional_name | lib/target_common.sh | Nueva, unifica lógica de info/note/dirsearch/venv |
| target_load_env          | lib/target_common.sh   | Nueva, extraída de varios |
| show_help                | lib/target_help.sh     | Mueve desde bin/target |
| target_create_workspace_structure | lib/target_workspace.sh | Nueva, extraída de target_add (pasos 2-7) |
| target_add               | lib/target_workspace.sh | Llama a create + tmux |
| target_tmux_get_server_name | lib/target_tmux.sh   | Nueva, extraída de target_add |
| target_tmux_ensure_config | lib/target_tmux.sh    | Nueva, extraída de target_add |
| target_tmux_attach_or_create_session | lib/target_tmux.sh | Nueva, extraída de target_add |
| main_target_scan         | lib/target_scan.sh     | Usa target_resolve_workspace_from_cwd y target_load_env |
| target_scan_ports        | lib/target_scan.sh     | |
| target_scan_services     | lib/target_scan.sh     | |
| target_scan_all          | lib/target_scan.sh     | |
| target_list              | lib/target_list.sh     | |
| target_info              | lib/target_list.sh     | Usa target_resolve_workspace_with_optional_name |
| target_note              | lib/target_note.sh     | Usa target_resolve_workspace_with_optional_name (y parsing de “resto = nota”) |
| target_dirsearch         | lib/target_dirsearch.sh | Usa target_resolve_workspace_with_optional_name y target_load_env |
| target_venv              | lib/target_venv.sh     | Usa target_resolve_workspace_with_optional_name |
| (main: case y llamadas)  | bin/target             | Solo sources y dispatch |

---

## 6. Orden de carga de módulos en `bin/target`

El binario debería hacer algo como:

```bash
#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f -- "$0")")"
REPO_BASE="$(dirname "$SCRIPT_DIR")"

# 1) Helpers ya existentes
source "$REPO_BASE/lib/tmux_helpers.sh"

# 2) Common: rutas, colores, resolución de workspace y carga de env
source "$REPO_BASE/lib/target_common.sh"

# 3) Ayuda
source "$REPO_BASE/lib/target_help.sh"

# 4) Módulos por feature (el orden puede importar si hay dependencias entre ellos)
source "$REPO_BASE/lib/target_workspace.sh"   # puede depender de target_tmux
source "$REPO_BASE/lib/target_tmux.sh"
source "$REPO_BASE/lib/target_scan.sh"
source "$REPO_BASE/lib/target_list.sh"
source "$REPO_BASE/lib/target_note.sh"
source "$REPO_BASE/lib/target_dirsearch.sh"
source "$REPO_BASE/lib/target_venv.sh"

# 5) Main: si no hay args → show_help; else case $1 in add|scan|list|...)
```

Si `target_workspace.sh` llama a funciones de `target_tmux.sh`, entonces `target_tmux.sh` debe cargarse antes que `target_workspace.sh`.

---

## 7. Resumen de nuevos archivos

| Archivo                  | Contenido principal |
|--------------------------|---------------------|
| lib/target_common.sh     | REPO_BASE, SCRIPT_DIR, colores; target_resolve_workspace_from_cwd; target_resolve_workspace_with_optional_name; target_load_env |
| lib/target_help.sh      | show_help |
| lib/target_workspace.sh  | target_create_workspace_structure; target_add (orquestación con tmux) |
| lib/target_tmux.sh      | target_tmux_get_server_name; target_tmux_ensure_config; target_tmux_attach_or_create_session |
| lib/target_scan.sh      | main_target_scan; target_scan_ports; target_scan_services; target_scan_all |
| lib/target_list.sh      | target_list; target_info |
| lib/target_note.sh      | target_note |
| lib/target_dirsearch.sh | target_dirsearch |
| lib/target_venv.sh      | target_venv |
| bin/target              | Solo shebang, rutas base, source de los lib y case de subcomandos |

Con este mapa se puede llevar a cabo la refactorización de forma ordenada y que cada función tenga un único destino claro.
