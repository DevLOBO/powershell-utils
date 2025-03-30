$defaultWorkspacePath = "C:\Workspace";

function Get-RAMUsed {
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
	param([string]$type = "Process")

	$beeps = @{
		"Process" = { [Console]::Beep(1000, 200) }
		"Fail" = { [Console]::Beep(500, 500) }
		"Success" = { [Console]::Beep(1500, 200) }
	}

	$beeps[$type].Invoke()
}

function Select-DirectoryWithWords {
    param (
        [string[]]$words
    )

    cls

    # Verifica si la ruta base existe
    if (-Not (Test-Path -Path $defaultWorkspacePath)) {
        Select-Beep Fail
        return
    }

    # Obtiene todos los directorios dentro de la ruta base
    $directories = Get-ChildItem -Path $defaultWorkspacePath -Directory

    $matchingDirectories = New-Object System.Collections.Generic.List[System.IO.DirectoryInfo]
    foreach ($directory in $directories) {
        # Convierte el nombre del directorio en minúsculas para comparar sin distinción de mayúsculas
        $dirName = $directory.Name.ToLower()

        # Verifica si todas las palabras están contenidas en el nombre del directorio
        $isMatch = $true
        foreach ($word in $words) {
            if (-Not $dirName.Contains($word.ToLower())) {
                $isMatch = $false
                break
            }
        }

        # Si encuentra un directorio que coincide con todas las palabras, cambia a ese directorio
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
    param (
        [string]$searchTerm,
        [string]$directory="src"
    )

    # Buscar los archivos que contienen el término de búsqueda
    $path = Join-Path -Path "." -ChildPath $directory
    $files = Get-ChildItem -Path $path -Recurse -File | Where-Object { $_.Name -like "*$searchTerm*" }

    # Verificar si hay archivos que coinciden
    if ($files.Count -eq 0) {
        Select-Beep Fail
    }
    elseif ($files.Count -eq 1) {
        # Si hay solo un archivo, abrirlo en el Notepad
        Select-Beep Success
        Start-Process notepad.exe $files.FullName
    }
    else {
        # Si hay varios archivos, imprimir la lista y pedir al usuario que elija uno
        Select-Beep
        $files | ForEach-Object { Write-Host "$([Array]::IndexOf($files, $_)): $_.Name" }

        # Solicitar al usuario que ingrese el índice
        $index = Read-Host "Select the index of the file: "

        # Verificar que el índice es válido
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

New-Alias -Name gtd -Value Select-DirectoryWithWords
New-Alias -Name fof -Value Open-FileByWord
New-Alias -Name ram -Value Get-RAMUsed