# Ruta de la carpeta de origen (modifícala según sea necesario)
$sourcePath = ".\Modules"

# Obtener la primera ruta en $env:PSModulePath (la ruta por defecto de módulos)
$destinationPath = $env:PSModulePath -split ";" | Select-Object -First 1

# Verificar si la ruta de origen existe
if (Test-Path $sourcePath) {
    # Crear la carpeta de destino si no existe
    if (!(Test-Path $destinationPath)) {
        New-Item -ItemType Directory -Path $destinationPath -Force
    }
    
    # Copiar los archivos y carpetas
    Copy-Item -Path "$sourcePath\*" -Destination $destinationPath -Recurse -Force
    
    Write-Host "Archivos copiados exitosamente a $destinationPath"

    # Obtener los nombres de las carpetas en sourcePath
    $moduleDirs = Get-ChildItem -Path $sourcePath -Directory | Select-Object -ExpandProperty Name
    
    # Leer el contenido actual del perfil de PowerShell
    if (Test-Path $PROFILE) {
        $profileContent = Get-Content -Path $PROFILE
    } else {
        $profileContent = @()
    }
    
    # Agregar Import-Module al perfil de PowerShell solo si no existe
    foreach ($dirName in $moduleDirs) {
        $importLine = "Import-Module `"$dirName`""
        if ($profileContent -notcontains $importLine) {
            $importLine | Add-Content -Path $PROFILE
        }
    }
} else {
    Write-Host "La ruta de origen no existe: $sourcePath"
}

# Agregar el conteniido para el archivo config.json
$configContent = @{}
$configKeys = @("aiModel", "aiEndpoint", "scriptsPath", "workspacePath")
foreach ($key in $configKeys) {
	$configContent[$key] = ""
}

#Buscar la ruta para guardar config.json
	$userPath = $env:PSModulePath -split ';' | Where-Object { $_ -match 'Users' } | Select-Object -First 1 | Split-Path -Parent
	$configPath = Join-Path $userPath 'config.json'

	if (-not (Test-Path $configPath)) {
	$configJson = $configContent | ConvertTo-Json -Depth 10
	Set-Content $configJson -Path $configPath
	Write-Host "Se creó el archivo config.json correctamente"
}