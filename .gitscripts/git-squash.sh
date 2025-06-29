#!/bin/bash
# Archivo: ~/.gitscripts/git-squash.sh
# Script para automatizar squash de commits

# Validar argumentos
if [ -z "$1" ]; then
    echo "Error: Debes proporcionar el número de commits (ej: git-squash.sh 3)"
    exit 1
fi

# Verificar que el argumento sea un número válido
if ! [[ "$1" =~ ^[0-9]+$ ]] || [ "$1" -lt 2 ]; then
    echo "Error: El argumento debe ser un número mayor o igual a 2"
    exit 1
fi

# Verificar que estamos en un repositorio git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: No estás en un repositorio git"
    exit 1
fi

# Verificar que tenemos suficientes commits
COMMIT_COUNT=$(git rev-list --count HEAD)
if [ "$COMMIT_COUNT" -lt "$1" ]; then
    echo "Error: Solo hay $COMMIT_COUNT commits en la rama actual"
    exit 1
fi

echo "Preparando squash de los últimos $1 commits..."



# Crear script temporal para el editor combinado
COMBINED_EDITOR_SCRIPT=$(mktemp)
cat > "$COMBINED_EDITOR_SCRIPT" << 'EOF'
#!/bin/bash
# Editor script para manejar tanto rebase como mensajes
FILE="$1"

# Si es el archivo de rebase interactivo (contiene pick/squash)
if grep -q "^pick\|^squash" "$FILE" 2>/dev/null; then
    # Cambiar todos los 'pick' excepto el primero a 'squash'
    sed -i.bak '2,$ s/^pick/squash/' "$FILE"
    rm -f "$FILE.bak"
    
# Si es el archivo de mensajes de commit (contiene "This is a combination of")
elif grep -q "^# This is a combination of" "$FILE" 2>/dev/null; then
    # Extraer solo el mensaje del primer commit
    awk '
        BEGIN { 
            in_first_commit = 0
            collecting_first = 0
            first_message = ""
        }
        /^# This is the 1st commit message:/ { 
            in_first_commit = 1
            collecting_first = 1
            next 
        }
        /^# This is the commit message #[2-9]:/ || /^# This is the commit message #[0-9][0-9]:/ { 
            in_first_commit = 0
            collecting_first = 0
        }
        collecting_first == 1 && /^[^#]/ && !/^$/ { 
            if (first_message == "") {
                first_message = $0
            } else {
                first_message = first_message "\n" $0
            }
        }
        /^# Please enter the commit message/ {
            print first_message
            print ""
            print $0
            next
        }
        /^# Lines starting with/ { print; next }
        /^# Changes to be committed:/ { print; next }
        /^#/ && !/^# This is/ { print; next }
        END {
            if (first_message == "") {
                # Si no encontramos mensaje del primer commit, usar el primero disponible
                print "Squashed commits"
            }
        }
    ' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
fi
EOF

# Hacer el script ejecutable
chmod +x "$COMBINED_EDITOR_SCRIPT"

# Función para limpiar archivos temporales
cleanup() {
    rm -f "$COMBINED_EDITOR_SCRIPT"
}

# Configurar trap para limpiar en caso de interrupción
trap cleanup EXIT

echo "Iniciando rebase interactivo..."

# Ejecutar el rebase interactivo con nuestro editor combinado
if EDITOR="$COMBINED_EDITOR_SCRIPT" git rebase -i HEAD~$1; then
    echo "✓ Squash completado exitosamente"
    echo "Los últimos $1 commits han sido combinados manteniendo el mensaje del primer commit"
else
    echo "✗ Error durante el rebase"
    echo "Puedes resolver conflictos manualmente y continuar con: git rebase --continue"
    echo "O cancelar el rebase con: git rebase --abort"
    exit 1
fi