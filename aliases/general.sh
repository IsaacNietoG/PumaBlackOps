#!/bin/bash
# Aliases útiles para pentesting y manejo de targets
# Fuente este archivo en tu ~/.bashrc o ~/.zshrc con:
#   [ -f /ruta/a/PumaBlackOps/aliases/all.sh ] && source /ruta/a/PumaBlackOps/aliases/all.sh

## Manejo del AssaultRepository
alias ars="assaultRepository start"
alias arst="assaultRepository stop"
alias arl="assaultRepository list"

## Escaneo de puertos
# nscan <IP>        -> nmap --open -p- -v <IP>
# nsv <IP> <puertos> -> nmap -sV -p <puertos> <IP>
alias nscan="nmap --open -p- -v"
alias nsv="nmap -sV -p"

## Utilidades
alias httpserver='python3 -m http.server'
alias listen='nc -lvnp'
alias copy='xclip -se clip'
