#!/bin/bash

# Script para filtrar ramas de git por palabras clave
# Uso: git filter-branch palabra1 palabra2 ... [-p]

# Función para mostrar ayuda
show_help() {
    echo "Uso: git filter-branch <palabra1> [palabra2] ... [-p]"
    echo ""
    echo "Opciones:"
    echo "  -p    Solo imprimir las ramas encontradas (sin selección interactiva)"
    echo "  -h    Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  git filter-branch feature fix 123"
    echo "  git filter-branch hotfix -p"
}

# Verificar si estamos en un repositorio git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: No estás en un repositorio git"
    exit 1
fi

# Procesar argumentos
print_only=false
keywords=()

for arg in "$@"; do
    case $arg in
        -p)
            print_only=true
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            keywords+=("$arg")
            ;;
    esac
done

# Verificar que se proporcionaron palabras clave
if [ ${#keywords[@]} -eq 0 ]; then
    echo "Error: Debes proporcionar al menos una palabra clave"
    show_help
    exit 1
fi

# Obtener todas las ramas (locales y remotas, sin duplicados)
all_branches=$(git branch -a | sed 's/^[* ] //' | sed 's|remotes/origin/||' | grep -v '^HEAD' | sort -u)

# Filtrar ramas que contengan todas las palabras clave
filtered_branches=()
while IFS= read -r branch; do
    # Verificar si la rama contiene todas las palabras clave
    contains_all=true
    for keyword in "${keywords[@]}"; do
        if [[ ! "$branch" == *"$keyword"* ]]; then
            contains_all=false
            break
        fi
    done
    
    if [ "$contains_all" = true ]; then
        filtered_branches+=("$branch")
    fi
done <<< "$all_branches"

# Verificar si se encontraron ramas
if [ ${#filtered_branches[@]} -eq 0 ]; then
    echo "No se encontraron ramas que contengan todas las palabras clave: ${keywords[*]}"
    exit 1
fi

# Si el flag -p está presente, solo imprimir las ramas
if [ "$print_only" = true ]; then
    printf '%s\n' "${filtered_branches[@]}"
    exit 0
fi

# Si solo hay una rama, seleccionarla automáticamente
if [ ${#filtered_branches[@]} -eq 1 ]; then
    selected_branch="${filtered_branches[0]}"
    echo "Única rama encontrada: $selected_branch"
else
    # Mostrar ramas encontradas y permitir selección
    echo "Ramas encontradas que contienen: ${keywords[*]}"
    echo ""

    for i in "${!filtered_branches[@]}"; do
        echo "$((i+1)). ${filtered_branches[i]}"
    done

    echo ""
    read -p "Selecciona una rama (1-${#filtered_branches[@]}): " selection

    # Validar la selección
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#filtered_branches[@]} ]; then
        echo "Error: Selección inválida"
        exit 1
    fi

    # Obtener la rama seleccionada
    selected_branch="${filtered_branches[$((selection-1))]}"
    echo "Rama seleccionada: $selected_branch"
fi

# Copiar al portapapeles usando el script existente
~/.gitscripts/copy-to-clipboard.sh "$selected_branch"