# Plugin de Oh My Zsh para PumaBlackOps

El plugin expone PumaBlackOps a Oh My Zsh: carga los aliases del repo y añade un
indicador del target activo en el prompt.

---

## Instalación

```bash
./spells/install-omz-plugin.sh
```

El script ofrece tres opciones:

| Opción | Qué hace |
|--------|----------|
| **1) Symlink** (recomendada) | Crea `~/.oh-my-zsh/custom/plugins/pumablackops` → `<repo>/omz`. Un `git pull` en el repo actualiza el plugin automáticamente. |
| **2) Copia** | Copia el plugin. Queda congelado: hay que repetir la instalación tras cada `git pull`. |
| **3) Solo instructions** | Imprime el bloque para agregar a mano, sin tocar nada. |

Después, agrega el plugin a tu `~/.zshrc` **antes** de la línea
`source $ZSH/oh-my-zsh.sh`:

```zsh
plugins=(git pumablackops)
```

O, sin editar la lista existente:

```zsh
plugins+=(pumablackops)
```

Aplica el cambio con `exec zsh` o abriendo una terminal nueva, y comprueba que
cargó:

```zsh
alias | grep -E 'ars|nscan'
```

---

## Indicador de target en el prompt

Agrega **después** de `source $ZSH/oh-my-zsh.sh`:

```zsh
PROMPT+=' $(pbo_target_info)'
```

Dentro de un workspace de target:

```
eviltaichi@eviltaichi ~/ws/vulnbox  target:(vulnbox 10.0.0.7)
```

Fuera de un target el segmento desaparece por completo, igual que el de git
fuera de un repositorio.

### Cómo se decide el target actual

1. Si direnv está hookeado, usa `$CTF_WORKSPACE_DIR`.
2. Si no, sube desde `$PWD` buscando un `.envrc`.
3. La IP sale de `$IP` (direnv) o, si no existe, leyendo la línea `export IP=` del
   `.envrc` **sin evaluarlo** (nada de `eval`).

No lanza subshells ni procesos externos: son operaciones internas de zsh sobre un
archivo de 3 líneas. Medido en ~0.14 ms por prompt.

### Personalizar el formato

El segmento no lleva colores ni glifos hardcodeados, igual que `lib/git.zsh` en
Oh My Zsh: el formato lo pone quien lo usa. Se controla con dos variables, con
estos valores por defecto:

```zsh
ZSH_THEME_PBO_TARGET_PROMPT_PREFIX="target:("
ZSH_THEME_PBO_TARGET_PROMPT_SUFFIX=") "
```

Para que encaje con el powerline de `agnoster`:

```zsh
ZSH_THEME_PBO_TARGET_PROMPT_PREFIX='%{$fg[blue]%} '
ZSH_THEME_PBO_TARGET_PROMPT_SUFFIX='%{$reset_color%} '
```

Envuelve los colores entre `%{` y `%}`, como hace la propia agnoster, para que zsh
no los cuente como caracteres visibles al calcular el ancho del prompt.

### Desactivarlo

Comenta la línea `PROMPT+=' ...'`. El resto del plugin (los aliases) sigue
funcionando igual.

---

## Qué carga el plugin

Solo `aliases/all.sh`, mediante un symlink al repo. **El plugin no define aliases
propios**: `aliases/general.sh` es la única fuente de verdad.

Consecuencia práctica: si editas `aliases/general.sh`, el cambio se refleja al
recargar el shell, sin reinstalar nada.

Si ya sourceaste `aliases/all.sh` por otra vía, el plugin lo detecta y no lo
vuelve a cargar.

---

## Comportamiento si algo falla

El plugin nunca debe romper el arranque del shell. Si no encuentra el repo (por
ejemplo, un symlink colgante tras mover o renombrar la carpeta), omite la carga en
silencio y el shell arranca normal, solo que sin los aliases.

Si Oh My Zsh no encuentra siquiera el archivo del plugin, muestra su propio aviso
`plugin 'pumablackops' not found` y continúa.

---

## Alternativa sin Oh My Zsh

Los aliases no dependen del plugin. Si no usas OMZ (o usas bash), basta con:

```zsh
source /ruta/a/PumaBlackOps/aliases/all.sh
```

`aliases/all.sh` es compatible con bash y zsh.