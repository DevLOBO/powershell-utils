# Script de instalación mejorado para módulos de PowerShell, aliases de Git y scripts
param(
    [string]$SourcePath = ".\Modules",
    [string]$GitScriptsYml = ".\gitscripts.yml",
    [string]$GitScriptsFolder = ".\.gitscripts"
)

function Install-PowerShellModules {
    param([string]$SourcePath)
    
    Write-Host "=== Instalando Modulos de PowerShell ===" -ForegroundColor Cyan
    
    # Obtener la primera ruta en $env:PSModulePath (la ruta por defecto de módulos)
    $destinationPath = $env:PSModulePath -split ";" | Select-Object -First 1
    
    # Verificar si la ruta de origen existe
    if (-not (Test-Path $SourcePath)) {
        Write-Host "ERROR: La ruta de origen no existe: $SourcePath" -ForegroundColor Red
        return $false
    }
    
    try {
        # Crear la carpeta de destino si no existe
        if (!(Test-Path $destinationPath)) {
            New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
            Write-Host "Carpeta de destino creada: $destinationPath" -ForegroundColor Green
        }
        
        # Copiar los archivos y carpetas
        Copy-Item -Path "$SourcePath\*" -Destination $destinationPath -Recurse -Force
        Write-Host "Modulos copiados exitosamente a $destinationPath" -ForegroundColor Green
        
        # Obtener los nombres de las carpetas en sourcePath
        $moduleDirs = Get-ChildItem -Path $SourcePath -Directory | Select-Object -ExpandProperty Name
        
        if ($moduleDirs.Count -eq 0) {
            Write-Host "No se encontraron modulos para importar" -ForegroundColor Yellow
            return $true
        }
        
        # Crear el archivo de perfil si no existe
        if (!(Test-Path $PROFILE)) {
            New-Item -ItemType File -Path $PROFILE -Force | Out-Null
            Write-Host "Archivo de perfil de PowerShell creado: $PROFILE" -ForegroundColor Green
        }
        
        # Leer el contenido actual del perfil de PowerShell
        $profileContent = Get-Content -Path $PROFILE -ErrorAction SilentlyContinue
        if ($null -eq $profileContent) { $profileContent = @() }
        
        # Agregar Import-Module al perfil de PowerShell solo si no existe
        $addedModules = @()
        foreach ($dirName in $moduleDirs) {
            $importLine = "Import-Module `"$dirName`""
            if ($profileContent -notcontains $importLine) {
                $importLine | Add-Content -Path $PROFILE
                $addedModules += $dirName
            }
        }
        
        if ($addedModules.Count -gt 0) {
            Write-Host "Modulos agregados al perfil: $($addedModules -join ', ')" -ForegroundColor Green
        } else {
            Write-Host "Todos los modulos ya estaban en el perfil" -ForegroundColor Yellow
        }
        
        return $true
    }
    catch {
        Write-Host "ERROR al instalar modulos: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Install-GitAliases {
    param([string]$GitScriptsYml)
    
    Write-Host "=== Configurando Aliases de Git ===" -ForegroundColor Cyan
    
    if (-not (Test-Path $GitScriptsYml)) {
        Write-Host "Archivo gitscripts.yml no encontrado: $GitScriptsYml" -ForegroundColor Yellow
        return $true
    }
    
    try {
        # Verificar que git esté instalado
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Host "ERROR: Git no esta instalado o no esta en el PATH" -ForegroundColor Red
            return $false
        }
        
        # Verificar que el módulo powershell-yaml esté disponible
        if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
            Write-Host "ERROR: El modulo powershell-yaml no esta instalado. Ejecuta: Install-Module powershell-yaml" -ForegroundColor Red
            return $false
        }
        
        # Importar el módulo powershell-yaml si no está cargado
        if (-not (Get-Module -Name powershell-yaml)) {
            Import-Module powershell-yaml -Force
        }
        
        # Leer y parsear el archivo YAML usando powershell-yaml
        $yamlContent = Get-Content -Path $GitScriptsYml -Raw
        $yamlData = ConvertFrom-Yaml $yamlContent
        
        # Extraer aliases del YAML parseado
        $newAliases = @{}
        
        # Buscar la sección de aliases (puede ser 'alias' o 'aliases')
        $aliasSection = $null
        if ($yamlData.ContainsKey('alias')) {
            $aliasSection = $yamlData.alias
        } elseif ($yamlData.ContainsKey('aliases')) {
            $aliasSection = $yamlData.aliases
        }
        
        if ($null -eq $aliasSection) {
            Write-Host "No se encontro seccion 'alias' o 'aliases' en el archivo YAML" -ForegroundColor Yellow
            return $true
        }
        
        # Convertir los aliases del YAML a hashtable
        if ($aliasSection -is [System.Collections.IDictionary]) {
            foreach ($alias in $aliasSection.GetEnumerator()) {
                $newAliases[$alias.Key] = $alias.Value.ToString()
            }
        } else {
            Write-Host "ERROR: La seccion de aliases no tiene el formato correcto" -ForegroundColor Red
            return $false
        }
        
        if ($newAliases.Count -eq 0) {
            Write-Host "No se encontraron aliases en el archivo YAML" -ForegroundColor Yellow
            return $true
        }
        
        Write-Host "Aliases encontrados en YAML: $($newAliases.Count)" -ForegroundColor Green
        
        # Obtener la ubicación del archivo .gitconfig
        $gitConfigPath = "$env:USERPROFILE\.gitconfig"
        
        # Crear .gitconfig si no existe
        if (-not (Test-Path $gitConfigPath)) {
            New-Item -ItemType File -Path $gitConfigPath -Force | Out-Null
            "[user]`n[core]`n[alias]" | Set-Content -Path $gitConfigPath
            Write-Host ".gitconfig creado en: $gitConfigPath" -ForegroundColor Green
        }
        
        # Leer el contenido actual del .gitconfig
        $gitConfigContent = Get-Content -Path $gitConfigPath
        
        # Encontrar la sección [alias] o crearla
        $aliasStartIndex = -1
        $aliasEndIndex = -1
        
        for ($i = 0; $i -lt $gitConfigContent.Count; $i++) {
            if ($gitConfigContent[$i] -match '^\[alias\]') {
                $aliasStartIndex = $i
            } elseif ($aliasStartIndex -ge 0 -and $gitConfigContent[$i] -match '^\[.*\]' -and $i -ne $aliasStartIndex) {
                $aliasEndIndex = $i - 1
                break
            }
        }
        
        # Si no se encontró el final de la sección alias, va hasta el final del archivo
        if ($aliasStartIndex -ge 0 -and $aliasEndIndex -eq -1) {
            $aliasEndIndex = $gitConfigContent.Count - 1
        }
        
        # Extraer aliases actuales
        $currentAliases = @{}
        if ($aliasStartIndex -ge 0) {
            for ($i = $aliasStartIndex + 1; $i -le $aliasEndIndex; $i++) {
                if ($gitConfigContent[$i] -match '^\s*([^=]+)\s*=\s*(.+)$') {
                    $currentAliases[$matches[1].Trim()] = $matches[2].Trim()
                }
            }
        }
        
        # Combinar aliases (los nuevos sobrescriben los existentes si tienen el mismo nombre)
        $combinedAliases = $currentAliases.Clone()
        $addedCount = 0
        $updatedCount = 0
        
        foreach ($alias in $newAliases.GetEnumerator()) {
            if ($combinedAliases.ContainsKey($alias.Key)) {
                if ($combinedAliases[$alias.Key] -ne $alias.Value) {
                    $combinedAliases[$alias.Key] = $alias.Value
                    $updatedCount++
                }
            } else {
                $combinedAliases[$alias.Key] = $alias.Value
                $addedCount++
            }
        }
        
        # Reconstruir el archivo .gitconfig
        $newGitConfig = @()
        $aliasSection = @("[alias]")
        
        foreach ($alias in $combinedAliases.GetEnumerator() | Sort-Object Key) {
            $aliasSection += "    $($alias.Key) = $($alias.Value)"
        }
        
        # Copiar contenido antes de [alias]
        if ($aliasStartIndex -gt 0) {
            $newGitConfig += $gitConfigContent[0..($aliasStartIndex - 1)]
        } elseif ($aliasStartIndex -eq -1) {
            $newGitConfig += $gitConfigContent
        }
        
        # Agregar sección de aliases
        $newGitConfig += $aliasSection
        
        # Copiar contenido después de [alias] si existe
        if ($aliasEndIndex -ge 0 -and $aliasEndIndex + 1 -lt $gitConfigContent.Count) {
            $newGitConfig += $gitConfigContent[($aliasEndIndex + 1)..($gitConfigContent.Count - 1)]
        }
        
        # Escribir el nuevo .gitconfig
        $newGitConfig | Set-Content -Path $gitConfigPath -Encoding UTF8
        
        Write-Host "Aliases de Git configurados: $addedCount nuevos, $updatedCount actualizados" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "ERROR al configurar aliases de Git: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Install-GitScripts {
    param([string]$GitScriptsFolder)
    
    Write-Host "=== Instalando Scripts de Git ===" -ForegroundColor Cyan
    
    if (-not (Test-Path $GitScriptsFolder)) {
        Write-Host "Carpeta de scripts no encontrada: $GitScriptsFolder" -ForegroundColor Yellow
        return $true
    }
    
    try {
        $userPath = $env:USERPROFILE
        $scriptFiles = Get-ChildItem -Path $GitScriptsFolder -File -Recurse
        
        if ($scriptFiles.Count -eq 0) {
            Write-Host "No se encontraron scripts para copiar" -ForegroundColor Yellow
            return $true
        }
        
        $copiedCount = 0
        foreach ($file in $scriptFiles) {
            $destinationPath = Join-Path $userPath $file.Name
            Copy-Item -Path $file.FullName -Destination $destinationPath -Force
            $copiedCount++
        }
        
        Write-Host "Scripts copiados exitosamente: $copiedCount archivos a $userPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "ERROR al copiar scripts: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Create-ConfigFile {
    Write-Host "=== Creando Archivo de Configuracion ===" -ForegroundColor Cyan
    
    try {
        # Crear el contenido para el archivo config.json
        $configContent = @{
            aiModel = ""
            aiEndpoint = ""
            scriptsPath = ""
            workspacePath = ""
        }
        
        # Buscar la ruta para guardar config.json
        $userModulePath = $env:PSModulePath -split ';' | Where-Object { $_ -match 'Users' } | Select-Object -First 1
        if ($userModulePath) {
            $userPath = Split-Path -Parent $userModulePath
        } else {
            $userPath = $env:USERPROFILE
        }
        
        $configPath = Join-Path $userPath 'config.json'
        
        if (-not (Test-Path $configPath)) {
            $configJson = $configContent | ConvertTo-Json -Depth 10
            Set-Content -Value $configJson -Path $configPath -Encoding UTF8
            Write-Host "Archivo config.json creado en: $configPath" -ForegroundColor Green
        } else {
            Write-Host "El archivo config.json ya existe en: $configPath" -ForegroundColor Yellow
        }
        
        return $true
    }
    catch {
        Write-Host "ERROR al crear config.json: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Función principal
function Main {
    Write-Host "=== INICIANDO INSTALACION ===" -ForegroundColor Magenta
    
    $success = $true
    
    # Instalar módulos de PowerShell
    if (-not (Install-PowerShellModules -SourcePath $SourcePath)) {
        $success = $false
    }
    
    # Configurar aliases de Git
    if (-not (Install-GitAliases -GitScriptsYml $GitScriptsYml)) {
        $success = $false
    }
    
    # Instalar scripts de Git
    if (-not (Install-GitScripts -GitScriptsFolder $GitScriptsFolder)) {
        $success = $false
    }
    
    # Crear archivo de configuración
    if (-not (Create-ConfigFile)) {
        $success = $false
    }
    
    Write-Host "=== INSTALACION COMPLETADA ===" -ForegroundColor Magenta
    
    if ($success) {
        Write-Host "Instalacion exitosa! Reinicia PowerShell para aplicar los cambios." -ForegroundColor Green
    } else {
        Write-Host "La instalacion se completo con algunos errores. Revisa los mensajes anteriores." -ForegroundColor Yellow
    }
    
    # Pausa para ver los resultados
    Write-Host "`nPresiona cualquier tecla para continuar..." -NoNewline -ForegroundColor White
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Ejecutar función principal
Main