#!/bin/bash
# Archivo: ~/.gitscripts/git-copy-commit.sh
# Script para copiar hash de commit al portapapeles

# Colores para mejor visualización
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar que estamos en un repositorio git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: No estás en un repositorio git${NC}"
    exit 1
fi

# Variables para opciones
FULL_HASH=false
COMMIT_REF=""

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--full)
            FULL_HASH=true
            shift
            ;;
        -h|--help)
            echo "Uso: git current-commit [OPCIONES] [COMMIT_REF]"
            echo ""
            echo "Copia el hash de un commit al portapapeles"
            echo ""
            echo "OPCIONES:"
            echo "  -f, --full    Copiar hash completo (por defecto: hash corto)"
            echo "  -h, --help    Mostrar esta ayuda"
            echo ""
            echo "EJEMPLOS:"
            echo "  git current-commit              # Hash corto de HEAD"
            echo "  git current-commit -f           # Hash completo de HEAD"
            echo "  git current-commit HEAD~2       # Hash corto de HEAD~2"
            echo "  git current-commit -f HEAD~2    # Hash completo de HEAD~2"
            echo "  git current-commit main         # Hash corto de la rama main"
            exit 0
            ;;
        -*)
            echo -e "${RED}Error: Opción desconocida '$1'${NC}"
            echo "Usa 'git current-commit --help' para ver las opciones disponibles"
            exit 1
            ;;
        *)
            if [ -z "$COMMIT_REF" ]; then
                COMMIT_REF="$1"
            else
                echo -e "${RED}Error: Solo se permite una referencia de commit${NC}"
                exit 1
            fi
            shift
            ;;
    esac
done

# Usar HEAD como default si no se especifica commit
COMMIT_REF="${COMMIT_REF:-HEAD}"

# Verificar que el commit existe
if ! git cat-file -e "$COMMIT_REF^{commit}" 2>/dev/null; then
    echo -e "${RED}Error: '$COMMIT_REF' no es un commit válido${NC}"
    exit 1
fi

# Obtener el hash completo del commit
COMMIT_HASH=$(git rev-parse "$COMMIT_REF" 2>/dev/null)

if [ -z "$COMMIT_HASH" ]; then
    echo -e "${RED}Error: No se pudo obtener el hash del commit '$COMMIT_REF'${NC}"
    exit 1
fi

# Obtener hash corto para mostrar
SHORT_HASH=$(git rev-parse --short "$COMMIT_REF" 2>/dev/null)

# Obtener información adicional del commit para mostrar
COMMIT_SUBJECT=$(git log -1 --pretty=format:"%s" "$COMMIT_REF" 2>/dev/null)
COMMIT_AUTHOR=$(git log -1 --pretty=format:"%an" "$COMMIT_REF" 2>/dev/null)
COMMIT_DATE=$(git log -1 --pretty=format:"%ar" "$COMMIT_REF" 2>/dev/null)

# Determinar qué hash copiar
if [ "$FULL_HASH" = true ]; then
    HASH_TO_COPY="$COMMIT_HASH"
    HASH_TYPE="completo"
else
    HASH_TO_COPY="$SHORT_HASH"
    HASH_TYPE="corto"
fi

# Mostrar información del commit
echo -e "${BLUE}=== Información del commit ===${NC}"
echo -e "${YELLOW}Referencia:${NC} $COMMIT_REF"
echo -e "${YELLOW}Hash corto:${NC} $SHORT_HASH"
echo -e "${YELLOW}Hash completo:${NC} $COMMIT_HASH"
echo -e "${YELLOW}Mensaje:${NC} $COMMIT_SUBJECT"
echo -e "${YELLOW}Autor:${NC} $COMMIT_AUTHOR"
echo -e "${YELLOW}Fecha:${NC} $COMMIT_DATE"
echo

# Intentar copiar al portapapeles
if ~/.gitscripts/copy-to-clipboard.sh "$HASH_TO_COPY"; then
    echo -e "${GREEN}✓ Hash $HASH_TYPE copiado al portapapeles${NC}"
    echo -e "${GREEN}  $HASH_TO_COPY${NC}"
else
    echo -e "${RED}⚠️  No se encontró comando de portapapeles disponible${NC}"
    echo -e "${YELLOW}Hash $HASH_TYPE: $HASH_TO_COPY${NC}"
    echo -e "${BLUE}Instala: xclip (Ubuntu/Debian) o xsel (otras distros Linux)${NC}"
    exit 1
fi