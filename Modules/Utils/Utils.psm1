$defaultWorkspacePath = "C:\Workspace";

function Get-RAMUsed {
<#
.SYNOPSIS
Muestra los procesos cuyo nombre coincide con el parámetro dado y calcula la RAM usada en MB.

.PARAMETER processName
Nombre del proceso a buscar. Puede ser parcial.

.DESCRIPTION
Filtra los procesos que coinciden con el nombre proporcionado, muestra su uso de RAM en MB y cuenta total de procesos.

.EXAMPLE
Get-RAMUsed -processName "chrome"

.NOTES
Alias: ram
#>
	param(
		[Parameter(Mandatory=$true)][Alias("p")][string]$processName
	)

	$processes = Get-Process | Where-Object {$_.ProcessName -like "$processName"} | Select-Object ProcessName, Id, @{Name="RAM_MB"; Expression={[math]::Round($_.WS / 1MB, 2)}}
	$ramTotal = ($processes | Measure-Object RAM_MB -Sum).Sum
	$processesCount = $processes.Count

	$processes | Format-Table -AutoSize
	Write-Host "Open Processes: $processesCount"
	Write-Host "RAM Total: $ramTotal"
}

function Select-Beep {
<#
.SYNOPSIS
Ejecuta un sonido de beep dependiendo del tipo especificado.

.PARAMETER type
Tipo de beep. Puede ser "Process", "Fail" o "Success". Por defecto es "Process".

.DESCRIPTION
Produce un beep con frecuencia y duración distintas según el tipo para indicar estado de procesos, errores o éxito.

.EXAMPLE
Select-Beep -type "Fail"
#>
	param([string]$type = "Process")

	$beeps = @{
		"Process" = { [Console]::Beep(1000, 200) }
		"Fail" = { [Console]::Beep(500, 500) }
		"Success" = { [Console]::Beep(1500, 200) }
	}

	$beeps[$type].Invoke()
}

function Select-DirectoryWithWords {
<#
.SYNOPSIS
Busca y navega a un directorio cuyo nombre contenga ciertas palabras clave.

.PARAMETER words
Arreglo de palabras que deben estar presentes en el nombre del directorio.

.DESCRIPTION
Recorre los subdirectorios en la ruta de trabajo predeterminada, y si encuentra coincidencias con todas las palabras, permite al usuario seleccionar uno y navega hacia él.

.EXAMPLE
Select-DirectoryWithWords -words "api", "test"

.NOTES
Alias: gtd
#>
    param (
        [Alias("d")][string[]]$words
    )

    cls

    if (-Not (Test-Path -Path $defaultWorkspacePath)) {
        Select-Beep Fail
        return
    }

    $directories = Get-ChildItem -Path $defaultWorkspacePath -Directory

    $matchingDirectories = New-Object System.Collections.Generic.List[System.IO.DirectoryInfo]
    foreach ($directory in $directories) {
        $dirName = $directory.Name.ToLower()

        $isMatch = $true
        foreach ($word in $words) {
            if (-Not $dirName.Contains($word.ToLower())) {
                $isMatch = $false
                break
            }
        }

        if ($isMatch) {
            $matchingDirectories.Add($directory)
        }
    }

    if ($matchingDirectories.Count -eq 0) {
        Select-Beep Fail
        return
    }

    $index = 0
    if ($matchingDirectories.Count -gt 1) {
        $matchingDirectories | ForEach-Object { Write-Host "$([Array]::IndexOf($matchingDirectories, $_)): $_" }
        $index = Read-Host "Select the index of the directory: "
    }
    $selectedDirectory = $matchingDirectories[$index]
    Set-Location -Path $selectedDirectory.FullName
    Select-Beep Success
}

function Open-FileByWord {
<#
.SYNOPSIS
Busca archivos por palabra clave y permite abrir uno con Notepad.

.PARAMETER searchTerm
Término que debe estar presente en el nombre del archivo.

.PARAMETER directory
Directorio base de búsqueda. Por defecto es "src".

.DESCRIPTION
Busca archivos recursivamente en un directorio, permite seleccionar uno si hay múltiples coincidencias y lo abre con Notepad.

.EXAMPLE
Open-FileByWord -searchTerm "config" -directory "src"

.NOTES
Alias: fof
#>
    param (
        [string]$searchTerm,
        [Alias("d")][string]$directory="src"
    )

    $path = Join-Path -Path "." -ChildPath $directory
    $files = Get-ChildItem -Path $path -Recurse -File | Where-Object { $_.Name -like "*$searchTerm*" }

    if ($files.Count -eq 0) {
        Select-Beep Fail
    }
    elseif ($files.Count -eq 1) {
        Select-Beep Success
        Start-Process notepad.exe $files.FullName
    }
    else {
        Select-Beep
        $files | ForEach-Object { Write-Host "$([Array]::IndexOf($files, $_)): $_" }

        $index = Read-Host "Select the index of the file: "

        if ($index -ge 0 -and $index -lt $files.Count) {
            $selectedFile = $files[$index]
            Select-Beep Success
            Start-Process notepad.exe $selectedFile.FullName
        }
        else {
            Select-Beep Fail
        }
    }
}

function Get-ConfigProp {
<#
.SYNOPSIS
Obtiene el valor de una propiedad desde un archivo de configuración JSON del usuario.

.PARAMETER prop
Nombre de la propiedad a recuperar.

.DESCRIPTION
Busca el archivo config.json en la ruta del perfil del usuario y devuelve el valor de la propiedad especificada si existe.

.EXAMPLE
Get-ConfigProp -prop "Token"
#>
	param(
		[Parameter(Mandatory = $true)][string]$prop
	)

	$userPath = $env:PSModulePath -split ';' | Where-Object { $_ -match 'Users' } | Select-Object -First 1 | Split-Path -Parent
	$configPath = Join-Path $userPath 'config.json'

	if (-not (Test-Path $configPath)) {
		The config file was not found
		Select-Beep Fail
		return
	}

	$configProps = Get-Content -Raw -Path $configPath | ConvertFrom-Json

	if (-not $configProps.ContainsKey($prop)) {
		Write-Host The property does not exist in the config file
		Select-Beep Fail
		return
	}

	return $configProps[$prop]
}

function Get-ExportedFunctionsAndAliasesFromModule {
	param(
		[Alias("m")][Paramter(Mandatory=$true)][string]$moduleName
	)

	(Get-Module $moduleName).ExportedFunctions.Keys
	(Get-Module $moduleName).ExportedAliases.Keys
}

New-Alias -Name gtd -Value Select-DirectoryWithWords
New-Alias -Name fof -Value Open-FileByWord
New-Alias -Name ram -Value Get-RAMUsed
New-Alias -Name modexports -Value Get-ExportedFunctionsAndAliasesFromModule
