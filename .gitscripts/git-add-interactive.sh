#!/bin/bash
# Archivo: ~/.gitscripts/git-add-interactive.sh
# Script para agregar archivos interactivamente agrupados por directorio

# Colores para mejor visualización
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables para el commit
COMMIT_MESSAGE=""
CREATE_COMMIT=false

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [-m \"mensaje del commit\"] [-h]"
    echo ""
    echo "Opciones:"
    echo "  -m <mensaje>  Crear commit con el mensaje especificado después de agregar archivos"
    echo "  -h            Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0                           # Solo agregar archivos"
    echo "  $0 -m \"Fix bug in login\"     # Agregar archivos y crear commit"
}

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -m)
            if [ -z "$2" ]; then
                echo -e "${RED}Error: La opción -m requiere un mensaje${NC}"
                show_help
                exit 1
            fi
            COMMIT_MESSAGE="$2"
            CREATE_COMMIT=true
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Opción desconocida: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Verificar que estamos en un repositorio git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: No estás en un repositorio git"
    exit 1
fi

# Obtener archivos no trackeados, modificados o agregados
# Incluye: modified (M), added (A), untracked (?), renamed (R), copied (C), deleted (D)
# Tanto en staged como unstaged
MODIFIED_FILES=$(git status --porcelain | grep -E '^.?[MADRCU?]' | sed 's/^...//')

if [ -z "$MODIFIED_FILES" ]; then
    echo -e "${GREEN}✓ No hay archivos para agregar${NC}"
    exit 0
fi

# Arrays para almacenar información
declare -a ALL_FILES=()
declare -a ALL_DIRS=()
declare -A DIR_FILES=()
declare -a DISPLAY_ORDER=()

# Procesar archivos y agrupar por directorio
while IFS= read -r file; do
    if [ -n "$file" ]; then
        ALL_FILES+=("$file")
        
        # Obtener directorio padre
        dir=$(dirname "$file")
        if [ "$dir" = "." ]; then
            dir="(raíz)"
        fi
        
        # Agregar archivo al directorio correspondiente
        if [[ -z "${DIR_FILES[$dir]}" ]]; then
            DIR_FILES["$dir"]="$file"
            ALL_DIRS+=("$dir")
        else
            DIR_FILES["$dir"]="${DIR_FILES[$dir]}|$file"
        fi
    fi
done <<< "$MODIFIED_FILES"

# Función para mostrar el menú
show_menu() {
    echo -e "${CYAN}=== Archivos para agregar ===${NC}"
    if [ "$CREATE_COMMIT" = true ]; then
        echo -e "${YELLOW}Mensaje del commit: \"$COMMIT_MESSAGE\"${NC}"
    fi
    echo
    
    local index=0
    DISPLAY_ORDER=()
    
    # Mostrar directorios y archivos
    for dir in "${ALL_DIRS[@]}"; do
        DISPLAY_ORDER+=("DIR:$dir")
        echo -e "${YELLOW}$index) $dir/${NC}"
        ((index++))
        
        # Mostrar archivos del directorio
        IFS='|' read -ra files <<< "${DIR_FILES[$dir]}"
        for file in "${files[@]}"; do
            filename=$(basename "$file")
            DISPLAY_ORDER+=("FILE:$file")
            echo -e "  ${BLUE}$index) $filename${NC}"
            ((index++))
        done
        echo
    done
}

# Función para procesar selección
process_selection() {
    local selection="$1"
    local files_to_add=()
    
    # Dividir por comas y procesar cada número
    IFS=',' read -ra NUMS <<< "$selection"
    
    for num in "${NUMS[@]}"; do
        # Limpiar espacios
        num=$(echo "$num" | xargs)
        
        # Validar que sea un número
        if ! [[ "$num" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Error: '$num' no es un número válido${NC}"
            continue
        fi
        
        # Verificar que esté en rango
        if [ "$num" -ge ${#DISPLAY_ORDER[@]} ]; then
            echo -e "${RED}Error: Número $num fuera de rango${NC}"
            continue
        fi
        
        local item="${DISPLAY_ORDER[$num]}"
        
        if [[ "$item" == DIR:* ]]; then
            # Es un directorio, agregar todos sus archivos
            local dir="${item#DIR:}"
            echo -e "${GREEN}Seleccionando directorio: $dir/${NC}"
            
            IFS='|' read -ra dir_files <<< "${DIR_FILES[$dir]}"
            for file in "${dir_files[@]}"; do
                files_to_add+=("$file")
                echo -e "  ${BLUE}+ $file${NC}"
            done
        else
            # Es un archivo individual
            local file="${item#FILE:}"
            files_to_add+=("$file")
            echo -e "${GREEN}+ $file${NC}"
        fi
    done
    
    # Eliminar duplicados manteniendo el orden
    local unique_files=()
    local seen_files=()
    
    for file in "${files_to_add[@]}"; do
        local already_seen=false
        for seen in "${seen_files[@]}"; do
            if [ "$seen" = "$file" ]; then
                already_seen=true
                break
            fi
        done
        
        if [ "$already_seen" = false ]; then
            unique_files+=("$file")
            seen_files+=("$file")
        fi
    done
    
    # Agregar archivos a git
    if [ ${#unique_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}No se seleccionaron archivos válidos${NC}"
        return 1
    fi
    
    echo
    echo -e "${CYAN}Agregando ${#unique_files[@]} archivo(s) a git...${NC}"
    
    local add_success=true
    for file in "${unique_files[@]}"; do
        if git add "$file"; then
            echo -e "${GREEN}✓ $file${NC}"
        else
            echo -e "${RED}✗ Error agregando $file${NC}"
            add_success=false
        fi
    done
    
    if [ "$add_success" = false ]; then
        echo -e "${RED}Hubo errores al agregar algunos archivos${NC}"
        return 1
    fi
    
    echo
    echo -e "${GREEN}✓ Archivos agregados correctamente${NC}"
    
    return 0
}

# Función para crear el commit al final
create_commit_if_needed() {
    if [ "$CREATE_COMMIT" = true ]; then
        echo
        echo -e "${CYAN}Creando commit...${NC}"
        if git commit -m "$COMMIT_MESSAGE"; then
            echo -e "${GREEN}✓ Commit creado exitosamente${NC}"
            return 0
        else
            echo -e "${RED}✗ Error al crear el commit${NC}"
            return 1
        fi
    fi
    return 0
}

# Función principal
main() {
    while true; do
        clear
        show_menu
        
#        echo -e "${CYAN}Instrucciones:${NC}"
#        echo "• Número individual: 1"
#        echo "• Múltiples archivos: 1,3,5"
#        echo "• Directorio completo: 0 (agrega todos los archivos del directorio)"
#        echo "• 'q' para salir"
#        echo
        
        read -p "Selecciona archivos a agregar: " selection
        
        case "$selection" in
            'q'|'Q'|'quit'|'exit')
                echo -e "${YELLOW}Saliendo...${NC}"
                exit 0
                ;;
            '')
                echo -e "${RED}Por favor, introduce una selección${NC}"
                read -p "Presiona Enter para continuar..."
                ;;
            *)
                echo
                if process_selection "$selection"; then
                    echo
                    read -p "¿Continuar agregando más archivos? (y/N): " continue_choice
                    case "$continue_choice" in
                        'y'|'Y'|'yes'|'YES')
                            continue
                            ;;
                        *)
                            # Crear commit al final si se especificó la opción -m
                            create_commit_if_needed
                            exit 0
                            ;;
                    esac
                else
                    read -p "Presiona Enter para continuar..."
                fi
                ;;
        esac
    done
}

# Ejecutar función principal
main