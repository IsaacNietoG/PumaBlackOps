# Autocompletado Bash para la Herramienta Target

Este directorio contiene scripts de autocompletado bash para la herramienta `target`.

## Instalación

### Instalación Automática
Ejecuta el script de instalación desde la raíz del proyecto:
```bash
./spells/install-completion.sh
```

### Instalación Manual
1. Incluye el archivo de autocompletado en tu configuración de shell:
   ```bash
   # Agrega esta línea a tu ~/.bashrc o ~/.zshrc
   source "/ruta/a/PumaBlackOps/completions/target.bash"
   ```

2. Recarga tu configuración de shell:
   ```bash
   source ~/.bashrc  # o ~/.zshrc para zsh
   ```

## Uso

Una vez instalado, puedes usar el autocompletado con tab para el comando `target`:

### Comandos Básicos
```bash
target <TAB>                    # Muestra todos los comandos disponibles
target add <TAB>                # Completa nombres de targets
target scan <TAB>               # Muestra subcomandos de escaneo
target info <TAB>               # Muestra targets existentes
```

### Comandos de Escaneo
```bash
target scan ports <TAB>         # Muestra opciones de escaneo de puertos
target scan ports --top-ports <TAB>  # Sugiere números de puerto comunes
target scan all --all-ports     # Completa opciones de escaneo
```

### Comandos Específicos de Target
```bash
target info <TAB>               # Lista targets existentes
target note <TAB>               # Lista targets existentes
target dirsearch <TAB>          # Lista targets existentes
target dirsearch target1 <TAB>  # Sugiere puertos comunes
target venv <TAB>               # Lista targets existentes
```

## Características

- **Autocompletado dinámico de targets**: Detecta automáticamente targets existentes buscando directorios con archivos `.envrc`
- **Autocompletado contextual**: Diferentes sugerencias basadas en el comando actual y posición
- **Sugerencias de puertos**: Números de puerto comunes para escaneo y búsqueda de directorios
- **Sugerencias de patrones IP**: Patrones de dirección IP comunes para nuevos targets

## Solución de Problemas

Si el autocompletado no funciona:

1. Verifica que el archivo de autocompletado esté incluido en tu configuración de shell
2. Reinicia tu terminal o ejecuta `source ~/.bashrc`
3. Verifica que la función de autocompletado esté cargada: `type _target_completion`

## Personalización

Puedes modificar el script de autocompletado (`target.bash`) para:
- Agregar más números de puerto comunes
- Incluir patrones de IP adicionales
- Agregar sugerencias personalizadas de nombres de targets
- Extender el autocompletado para nuevos comandos 