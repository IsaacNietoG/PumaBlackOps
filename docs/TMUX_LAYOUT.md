# Layout de tmux por target (`conf/tmux_layout.conf`)

Cuando ejecutas `target add <nombre> <IP>`, además de crear el workspace en disco se
crea una sesión de tmux con un layout que tú decides. Ese layout vive en
**`conf/tmux_layout.conf`** y se aplica a **todos** los targets que crees a partir
de ahora en adelante.

Si el archivo no existe, se usa un layout por defecto idéntico al que se creaba
antes de que existiera esta configuración (3 ventanas, 4 panes).

---

## 1. Formato del archivo

El archivo es un array de bash llamado `TMUX_LAYOUT`. **Cada línea describe un
pane**:

```bash
TMUX_LAYOUT=(
"<ventana>|<orden>|<comando>|<submit>|<guard>"
)
```

### Los 5 campos

| Campo      | Qué es                                                                 |
|------------|------------------------------------------------------------------------|
| `ventana`  | Nombre de la ventana. La **primera ventana citada crea la sesión**; las siguientes se crean como ventanas nuevas. |
| `orden`    | Posición del pane dentro de esa ventana (1, 2, 3…). El pane 1 es el que tmux crea junto con la ventana; los siguientes se generan con `split-window -v`. |
| `comando`  | Texto que se envía al pane. Si va **vacío**, el pane se queda solo en el prompt. Admite placeholders (ver §2). |
| `submit`   | `1` = se añade `C-m` y **el comando se ejecuta**. `0` = el comando **queda escrito**, esperando a que tú pulses Enter. |
| `guard`    | `archivo::texto` = solo se envía el comando si `texto` **no** aparece ya dentro de `archivo`. Vacío = sin guarda. |

> **Cuidado con `|`.** Es el separador de campos, así que un comando que lo contenga
> rompe la línea. Usa otro separador o envuélvelo de otra forma.

> **Cuidado con el quoting.** Si tu comando lleva comillas dobles, escríbelas
> como `\"` dentro de la línea del array (ver el ejemplo de `/etc/hosts`).

---

## 2. Placeholders

En `comando` y en el `texto` del `guard` puedes usar estos marcadores. Se
sustituyen por su valor real al momento de crear la sesión:

| Placeholder   | Se reemplaza por                                   | Ejemplo                                  |
|---------------|----------------------------------------------------|------------------------------------------|
| `%IP%`        | IP del target                                      | `10.10.10.10`                            |
| `%SESSION%`   | Nombre del target / de la sesión                   | `vulnbox`                                |
| `%SUBDOMAIN%` | Subdominio, tomado de `TARGET_SUBDOMAIN`           | `echocity-f.com`                         |
| `%WORKSPACE%` | Ruta absoluta del workspace del target             | `/home/tu/PumaBlackOps/vulnbox`          |
| `%REPO%`      | Ruta absoluta de este repositorio (PumaBlackOps)   | `/home/tu/PumaBlackOps`                  |

Ejemplo: `%SESSION%.%SUBDOMAIN%` produce `vulnbox.echocity-f.com`.

---

## 3. `submit`: ejecutar o solo escribir

Es la diferencia entre un pane que **arranca solo** y uno que te espera a ti.

- `submit=1` → `tmux send-keys "lo que sea" C-m` → **se ejecuta**.
  Útil para comandos que ya sabes que quieres launched, como arrancar el temporizador.
- `submit=0` → `tmux send-keys "lo que sea"` → **queda en la línea**, sin ejecutar.
  Útil cuando el comando necesita que tú completes un argumento.

```bash
"Recon|2|target scan ports|0|"            # escribe "target scan ports" y tú decides cuándo lanzarlo
"Misc.|1|%REPO%/.config/tmux/plugins/tmux/scripts/ctf_timer.sh start|1|"   # arranca solo
```

Un comando con `submit=0` también puede quedar a la espera de que le escribas un
argumento: basta con dejar el texto sin terminar.

```bash
"Recon|2|nmap -p |0|"     # escribe "nmap -p " y tú tecleas los puertos
```

Al escribirlo en el array, respeta las comillas: un espacio final es un espacio
real, no un error de formato.

---

## 4. `guard`: no repetir un comando si ya está hecho

Some panes ejecutan algo que no tiene sentido repetir (por ejemplo, añadir una línea
a `/etc/hosts` que tal vez ya existe). La guarda evita eso.

Formato: `ruta_del_archivo::texto_a_buscar`

Antes de enviar el comando, el motor comprueba si `texto` (con los placeholders ya
expandidos) ya está en el archivo:

- **No está** → envía el comando normalmente.
- **Ya está** → **no envía nada** y muestra un aviso en el pane.

```bash
"Recon|1|sudo sh -c \"echo '%IP%        %SESSION%.%SUBDOMAIN%' >> /etc/hosts\"|0|/etc/hosts::%IP%        %SESSION%.%SUBDOMAIN%"
```

Este es el caso real de la línea del `/etc/hosts`: si `10.10.10.10  vulnbox.echocity-f.com`
ya está en el archivo, el motor **no** vuelve a escribir el comando, y avisa en el pane.

La búsqueda es literal (no regex), así que los `.` de las IPs y los subdominios se
tratan como caracteres normales.

---

## 5. Cómo se construye la sesión

El motor (`lib/target_tmux_layout.sh`) procesa tu configuración en este orden:

1. **Carga** `conf/tmux_layout.conf`. Si no existe, usa el layout por defecto.
2. **Valida** que cada línea tenga los 5 campos, que la ventana no esté vacía y
   que el `orden` sea un número. Si algo está mal, **aborta sin crear nada** y te
   dice qué línea falló.
3. **Crea** las ventanas en el orden en que aparecen por primera vez en el archivo.
   La primera crea la sesión; el resto se añaden con `new-window`. Cada ventana nace
   con 1 pane, y se hacen los `split-window -v` necesarios para llegar al número de
   panes que pediste en las líneas de esa ventana.
4. **Envía** el comando de cada pane, respetando el campo `orden` de cada línea
   (no el orden en que las escribiste en el archivo).
5. **Enfoca** la primera ventana, en su primer pane, y se adjunta a la sesión.

Todos los panes arrancan en la carpeta del workspace, así que `direnv` carga el
`.envrc` y `$IP` / `$URL` quedan disponibles en todos ellos.

---

## 6. Ejemplos

### Layout por defecto (el que trae el repo)

```bash
TMUX_LAYOUT=(
"Recon|1|sudo sh -c \"echo '%IP%        %SESSION%.%SUBDOMAIN%' >> /etc/hosts\"|0|/etc/hosts::%IP%        %SESSION%.%SUBDOMAIN%"
"Recon|2|target scan ports|0|"
"Exploit|1|penelope -p 9000|0|"
"Misc.|1|%REPO%/.config/tmux/plugins/tmux/scripts/ctf_timer.sh start|1|"
)
```

Produce:

```
┌ Recon ────────────┐  ┌ Exploit ──┐  ┌ Misc. ──┐
│ 1.1  /etc/hosts   │  │ 2.1       │  │ 3.1     │
│     (sin ejecutar)│  │  penelope │  │  timer  │
│ 1.2  target scan  │  │  (sin    │  │  (auto) │
│     ports -s      │  │  ejecutar)│  │         │
└───────────────────┘  └───────────┘  └─────────┘
```

### Solo una ventana, un pane, un comando

```bash
TMUX_LAYOUT=(
"Shell|1|penelope -p 9000|0|"
)
```

### Más panes, mixture de submit y placeholders

```bash
TMUX_LAYOUT=(
"Recon|1|echo target=%SESSION% ip=%IP%|1|"
"Recon|2|target scan all --top-ports 1000|1|"
"Recon|3|target dirsearch %SESSION% 8080|0|"
"Shells|1|penelope -p 9000|0|"
"Shells|2|nc -lvnp 4444|0|"
"Shells|3|curl http://%SESSION%.%SUBDOMAIN%|0|"
"Notes|1||0|"
)
```

Esto crea 3 ventanas: `Recon` (3 panes), `Shells` (3 panes) y `Notes` (1 pane, solo
prompt porque el `comando` va vacío).

### El orden de las líneas no importa

El campo `orden` es el que decide en qué pane va cada comando, **no** el orden en que
las escribas en el archivo. Estas dos configuraciones producen exactamente la misma
sesión:

```bash
TMUX_LAYOUT=(
"Recon|1|primer|0|"
"Recon|2|segundo|0|"
"Recon|3|tercer|0|"
)
```

```bash
TMUX_LAYOUT=(
"Recon|3|tercer|0|"
"Recon|2|segundo|0|"
"Recon|1|primer|0|"
)
```

En ambos casos el pane `.1` recibe `primer`, el `.2` recibe `segundo` y el `.3`
recibe `tercer`.

---

## 7. Errores frecuentes

**"Layout inválido: se esperaban 5 campos separados por '|'"**
A tu línea le faltan o sobran campos. Cuenta los `|`: deben ser **4**.

**"Layout inválido: orden de pane no numérico"**
El segundo campo (el `orden`) tiene que ser un número entero (`1`, `2`, …).

**"Layout inválido: entrada con ventana vacía"**
La línea empieza por `|` — falta el nombre de la ventana.

**El layout por defecto aparece en vez del tuyo**
Comprueba que el archivo se llame exactamente `conf/tmux_layout.conf` y que el
array se llame `TMUX_LAYOUT=( ... )`. Si el archivo existe pero está mal formado,
el motor **aborta** en vez de usar el default (para no crear sesiones con un layout
que no esperabas).

**Mi comando no aparece en el pane**
Revisa el `submit`. Con `0` el comando se escribe pero no se ejecuta, que es lo
esperado. Además, si la `guard` se activó, el comando no se envía y en su lugar
verás un aviso.

---

## 8. Referencia rápida

| Quiero…                                        | Cómo lo escribo                                             |
|------------------------------------------------|-------------------------------------------------------------|
| Que el comando se ejecute solo                  | `submit` = `1`                                               |
| Que quede escrito para completarlo yo           | `submit` = `0`                                               |
| Un pane solo con prompt                         | `comando` vacío: `"Win|1||0|"`                               |
| No repetir si ya está en un archivo             | `guard` = `archivo::texto`                                   |
| La IP, el nombre o el subdominio del target      | `%IP%` `%SESSION%` `%SUBDOMAIN%`                            |
| La ruta del workspace                           | `%WORKSPACE%`                                                |
| La ruta de este repo (p. ej., para un plugin)   | `%REPO%`                                                     |
| Añadir otro pane a una ventana                  | Otra línea con el mismo nombre de `ventana` y un `orden` nuevo |