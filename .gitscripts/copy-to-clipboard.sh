#!/bin/bash

# Script para copiar texto al portapapeles de forma multiplataforma
# Uso: ./copy_to_clipboard.sh "texto a copiar"

# Verificar si se proporcionó un argumento
if [ $# -eq 0 ]; then
    echo "Error: Debes proporcionar el texto a copiar como argumento"
    exit 1
fi

# El texto a copiar es todos los argumentos concatenados
TEXT="$*"

# Función para detectar el sistema operativo
detect_os() {
    case "$(uname -s)" in
        Linux*)
            if [ -n "$WSL_DISTRO_NAME" ] || [ -n "$WSL_INTEROP" ]; then
                echo "WSL"
            else
                echo "Linux"
            fi
            ;;
        Darwin*)
            echo "macOS"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "Windows"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

# Función para copiar al portapapeles según el SO
copy_to_clipboard() {
    local os=$(detect_os)
    local success=false
    
    case $os in
        "macOS")
            if command -v pbcopy >/dev/null 2>&1; then
                echo "$TEXT" | pbcopy
                success=true
            fi
            ;;
        "Linux")
            # Intentar diferentes comandos de clipboard para Linux
            if command -v xclip >/dev/null 2>&1; then
                echo "$TEXT" | xclip -selection clipboard
                success=true
            elif command -v xsel >/dev/null 2>&1; then
                echo "$TEXT" | xsel --clipboard --input
                success=true
            elif command -v wl-copy >/dev/null 2>&1; then
                # Para Wayland
                echo "$TEXT" | wl-copy
                success=true
            fi
            ;;
        "WSL")
            # Windows Subsystem for Linux
            if command -v clip.exe >/dev/null 2>&1; then
                echo "$TEXT" | clip.exe
                success=true
            elif command -v powershell.exe >/dev/null 2>&1; then
                echo "$TEXT" | powershell.exe -command "Set-Clipboard -Value ([Console]::In.ReadToEnd())"
                success=true
            fi
            ;;
        "Windows")
            # Git Bash, MSYS2, Cygwin, etc.
            if command -v clip >/dev/null 2>&1; then
                echo "$TEXT" | clip
                success=true
            elif command -v powershell >/dev/null 2>&1; then
                echo "$TEXT" | powershell -command "Set-Clipboard -Value ([Console]::In.ReadToEnd())"
                success=true
            fi
            ;;
    esac
    
    if [ "$success" = true ]; then
        echo "✅ Texto copiado al portapapeles exitosamente"
    else
        echo "❌ Error: No se pudo copiar al portapapeles"
        echo "Sistema operativo detectado: $os"
        echo ""
        echo "Instala una de estas herramientas según tu sistema:"
        case $os in
            "Linux")
                echo "  - Ubuntu/Debian: sudo apt install xclip"
                echo "  - Fedora: sudo dnf install xclip"
                echo "  - Arch: sudo pacman -S xclip"
                echo "  - Para Wayland: sudo apt install wl-clipboard"
                ;;
            "macOS")
                echo "  - pbcopy debería estar disponible por defecto"
                ;;
            "Windows")
                echo "  - clip debería estar disponible por defecto"
                echo "  - O usa PowerShell"
                ;;
        esac
        exit 1
    fi
}

# Ejecutar la función principal
copy_to_clipboard