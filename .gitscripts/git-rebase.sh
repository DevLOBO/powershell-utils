#!/bin/bash

# Script para hacer rebase con manejo automático de stash
# Uso: ./git_rebase.sh [rama]
# Si no se proporciona rama, usa origin/develop por defecto

# Configurar rama por defecto
DEFAULT_BRANCH="origin/develop"
TARGET_BRANCH="${1:-$DEFAULT_BRANCH}"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para mostrar mensajes con colores
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que estamos en un repositorio git
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    print_error "No estás en un repositorio Git"
    exit 1
fi

print_info "Iniciando proceso de rebase hacia: $TARGET_BRANCH"

# Variable para trackear si hicimos stash
STASH_CREATED=false

# Verificar si hay archivos modificados en el árbol de trabajo
if ! git diff-index --quiet HEAD --; then
    print_warning "Se detectaron archivos modificados en el árbol de trabajo"
    print_info "Ejecutando git stash para guardar cambios temporalmente..."
    
    # Hacer stash de los cambios
    if git stash push -m "Auto-stash before rebase to $TARGET_BRANCH"; then
        print_info "Cambios guardados en stash exitosamente"
        STASH_CREATED=true
    else
        print_error "Error al hacer stash de los cambios"
        exit 1
    fi
else
    print_info "No hay archivos modificados en el árbol de trabajo"
fi

# Ejecutar el rebase
print_info "Ejecutando git fetch origin && git rebase $TARGET_BRANCH..."
if git fetch origin && git rebase "$TARGET_BRANCH"; then
    print_info "Rebase completado exitosamente"
    
    # Si hicimos stash, hacer pop
    if [ "$STASH_CREATED" = true ]; then
        print_info "Restaurando cambios desde stash..."
        if git stash pop; then
            print_info "Cambios restaurados exitosamente"
        else
            print_error "Error al restaurar cambios desde stash"
            print_warning "Los cambios siguen en el stash. Usa 'git stash pop' manualmente"
            exit 1
        fi
    fi
    
    print_info "Proceso completado exitosamente"
else
    print_error "Error durante el rebase"
    
    # Si hicimos stash y el rebase falló, informar al usuario
    if [ "$STASH_CREATED" = true ]; then
        print_warning "Los cambios están guardados en stash"
        print_warning "Resuelve los conflictos del rebase y luego usa 'git stash pop' para restaurar tus cambios"
    fi
    
    print_info "Para continuar el rebase después de resolver conflictos: git rebase --continue"
    print_info "Para abortar el rebase: git rebase --abort"
    exit 1
fi