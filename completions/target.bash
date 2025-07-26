#!/bin/bash

# Bash completion script for the 'target' tool
# Usage: source this file or place it in /etc/bash_completion.d/

_target_completion() {
    local cur prev opts cmds
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main commands
    cmds="add scan list info note dirsearch venv help"
    
    # If we're completing the first argument (command)
    if [[ $COMP_CWORD -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "${cmds}" -- "${cur}") )
        return 0
    fi
    
    # Handle completion for specific commands
    case "${prev}" in
        add)
            # For 'add', we need <nombre_maquina> <IP>
            if [[ $COMP_CWORD -eq 2 ]]; then
                # Could suggest common target names, but for now just complete filenames
                COMPREPLY=( $(compgen -f -- "${cur}") )
            elif [[ $COMP_CWORD -eq 3 ]]; then
                # For IP, we could suggest common IP patterns
                COMPREPLY=( $(compgen -W "192.168.1. 10.0.0. 172.16.0." -- "${cur}") )
            fi
            ;;
        scan)
            # For 'scan', we need subcommands
            if [[ $COMP_CWORD -eq 2 ]]; then
                COMPREPLY=( $(compgen -W "ports services all" -- "${cur}") )
            elif [[ $COMP_CWORD -eq 3 ]]; then
                case "${COMP_WORDS[2]}" in
                    ports)
                        COMPREPLY=( $(compgen -W "--top-ports --all-ports" -- "${cur}") )
                        ;;
                    all)
                        COMPREPLY=( $(compgen -W "--top-ports --all-ports" -- "${cur}") )
                        ;;
                esac
            elif [[ $COMP_CWORD -eq 4 ]] && [[ "${COMP_WORDS[3]}" == "--top-ports" ]]; then
                # Suggest common port numbers
                COMPREPLY=( $(compgen -W "100 500 1000 2000 5000 10000" -- "${cur}") )
            fi
            ;;
        info|note|dirsearch|venv)
            # These commands can take a target name as first argument
            if [[ $COMP_CWORD -eq 2 ]]; then
                # Get list of existing targets (directories with .envrc files)
                local targets
                targets=$(find . -maxdepth 1 -type d -name "*" -exec test -f "{}/.envrc" \; -print | sed 's|^\./||' | tr '\n' ' ')
                COMPREPLY=( $(compgen -W "${targets}" -- "${cur}") )
            elif [[ $COMP_CWORD -eq 3 ]] && [[ "${prev}" == "dirsearch" ]]; then
                # For dirsearch, second argument is port
                COMPREPLY=( $(compgen -W "80 443 8080 8443 3000 5000 8000" -- "${cur}") )
            fi
            ;;
        list|help)
            # These commands don't take additional arguments
            COMPREPLY=()
            ;;
        --top-ports)
            # Complete port numbers
            COMPREPLY=( $(compgen -W "100 500 1000 2000 5000 10000" -- "${cur}") )
            ;;
        --all-ports)
            # This flag doesn't take arguments
            COMPREPLY=()
            ;;
        *)
            # Default completion
            COMPREPLY=( $(compgen -f -- "${cur}") )
            ;;
    esac
    
    return 0
}

# Register the completion function
complete -F _target_completion target

# Also provide completion for the script if it's called directly
complete -F _target_completion ./bin/target
complete -F _target_completion "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../bin/target" 