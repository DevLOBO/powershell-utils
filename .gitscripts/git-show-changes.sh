#!/bin/bash

commit_ref="$1"

# Usa --no-pager para evitar que se abra 'less'
git_diff() {
    if [ -n "$commit_ref" ]; then
        git --no-pager diff "$commit_ref"^! -- "$1"
    else
        git --no-pager diff -- "$1"
    fi
}

# Obtener lista de archivos modificados
if [ -n "$commit_ref" ]; then
    files=($(git --no-pager diff "$commit_ref"^! --name-only))
else
    files=($(git --no-pager diff --name-only))
fi

if [ ${#files[@]} -eq 0 ]; then
    echo "No hay cambios."
    exit 0
fi

current_index=0
current_hunk_index=0

clear
current_file="${files[$current_index]}"
git_diff "$current_file"

mostrar_cambio() {
    current_file="${files[$current_index]}"
    hunks=($(git_diff "$current_file" | grep -n '^@@' | cut -d: -f1))

    if [ ${#hunks[@]} -eq 0 ]; then
        clear
        echo "Archivo: $current_file (sin cambios en formato diff)"
        git_diff "$current_file"
        return
    fi

    start=${hunks[$current_hunk_index]}
    end_index=$((current_hunk_index + 1))

    if [ $end_index -lt ${#hunks[@]} ]; then
        end=$((hunks[$end_index] - 1))
    else
        end='$'
    fi

    clear
    echo "Archivo: $current_file ($((current_index+1))/${#files[@]}), cambio $((current_hunk_index+1))/${#hunks[@]}"
    git_diff "$current_file" | sed -n "${start},${end}p"
}

while true; do
    IFS= read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
        read -rsn2 -t 0.01 rest
        key+="$rest"
    fi

    case "$key" in
        $'\e[B')  # Flecha Abajo
            if [ $current_index -lt $((${#files[@]} - 1)) ]; then
                current_index=$((current_index + 1))
                current_hunk_index=0
                mostrar_cambio
            fi
            ;;
        $'\e[A')  # Flecha Arriba
            if [ $current_index -gt 0 ]; then
                current_index=$((current_index - 1))
                current_hunk_index=0
                mostrar_cambio
            fi
            ;;
        $'\e[C')  # Flecha Derecha
            current_file="${files[$current_index]}"
            hunks=($(git_diff "$current_file" | grep -n '^@@' | cut -d: -f1))
            if [ $current_hunk_index -lt $((${#hunks[@]} - 1)) ]; then
                current_hunk_index=$((current_hunk_index + 1))
                mostrar_cambio
            fi
            ;;
        $'\e[D')  # Flecha Izquierda
            if [ $current_hunk_index -gt 0 ]; then
                current_hunk_index=$((current_hunk_index - 1))
                mostrar_cambio
            fi
            ;;
        q)
            echo "Saliendo..."
            exit 0
            ;;
        *)
            # Ignorar otras teclas
            ;;
    esac
done
