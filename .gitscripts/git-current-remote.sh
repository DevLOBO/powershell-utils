#!/bin/bash

# Script para copiar la URL del repositorio remoto de Git al portapapeles
# Uso: ./git_copy_remote.sh [nombre_remoto]
# Si no se especifica remoto, usa 'origin' por defecto

# Configuración
DEFAULT_REMOTE="origin"
REMOTE_NAME="${1:-$DEFAULT_REMOTE}"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes con color
print_error() {
    echo -e "${RED}❌ Error: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Verificar si estamos en un repositorio Git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "No estás en un repositorio Git"
    exit 1
fi

# Obtener la URL del remoto
REMOTE_URL=$(git remote get-url "$REMOTE_NAME" 2>/dev/null)

if [ -z "$REMOTE_URL" ]; then
    print_error "No se encontró el remoto '$REMOTE_NAME'"
    print_info "Remotos disponibles:"
    git remote -v | sed 's/^/  /'
    exit 1
fi

# Convertir SSH a HTTPS si es necesario
convert_to_https() {
    local url="$1"
    
    # Si ya es HTTPS, devolverlo tal como está
    if [[ "$url" == https://* ]]; then
        echo "$url"
        return
    fi
    
    # Convertir SSH a HTTPS
    if [[ "$url" == git@* ]]; then
        # Formato: git@hostname:usuario/repo.git
        local hostname=$(echo "$url" | sed 's/git@\([^:]*\):.*/\1/')
        local path=$(echo "$url" | sed 's/git@[^:]*:\(.*\)/\1/')
        
        # Remover .git del final si existe
        path=$(echo "$path" | sed 's/\.git$//')
        
        echo "https://$hostname/$path"
        return
    fi
    
    # Si no es ninguno de los formatos conocidos, devolver tal como está
    echo "$url"
}

# Convertir a HTTPS para mejor compatibilidad
HTTPS_URL=$(convert_to_https "$REMOTE_URL")

# Mostrar información del repositorio
print_info "Repositorio: $(basename "$(git rev-parse --show-toplevel)")"
print_info "Rama actual: $(git branch --show-current 2>/dev/null || echo 'HEAD detached')"

# Copiar la URL al portapapeles
~/.gitscripts/copy-to-clipboard.sh "$HTTPS_URL"
