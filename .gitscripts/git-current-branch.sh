#!/bin/bash
# Archivo: ~/.gitscripts/git-copy-branch.sh
# Script para copiar la rama actual al portapapeles

# Verificar que estamos en un repositorio git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: No estás en un repositorio git"
    exit 1
fi

# Obtener la rama actual
BRANCH=$(git branch --show-current 2>/dev/null)

if [ -z "$BRANCH" ]; then
    echo "Error: No estás en una rama válida o no hay commits"
    exit 1
fi

# Ejecutar el script para copiar el texto al portapapeles
~/.gitscripts/copy-to-clipboard.sh "$BRANCH"
