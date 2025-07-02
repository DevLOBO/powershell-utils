class ProgressBar {
    [int]$Total
    [int]$BarLength = 40
    [datetime]$LastUpdate
    [double]$IntervalSeconds

    ProgressBar([int]$total, [double]$intervalSeconds = 2) {
        $this.Total = $total
        $this.IntervalSeconds = $intervalSeconds
        $this.LastUpdate = [datetime]::MinValue
    }

    [void] Update([int]$current) {
        $now = Get-Date
        $elapsed = ($now - $this.LastUpdate).TotalSeconds

        if ($elapsed -ge $this.IntervalSeconds -or $current -eq $this.Total) {
            $this.LastUpdate = $now
            $percent = [math]::Round(($current / $this.Total) * 100)
            $filledLength = [math]::Round(($this.BarLength * $current) / $this.Total)
            $bar = ('#' * $filledLength).PadRight($this.BarLength)

            Write-Host -NoNewline "`r[$bar] $percent% ($current / $($this.Total))"
        }
    }
}

function Remove-FilteredItems {
    <#
    .SYNOPSIS
    Busca y elimina recursivamente elementos que coincidan con un filtro específico.
    
    .DESCRIPTION
    Esta función busca recursivamente todos los elementos que coincidan con un parámetro de filtro
    utilizando las reglas de -Filter de Get-ChildItem, y luego los elimina con confirmación del usuario.
    
    .PARAMETER Path
    Ruta donde iniciar la búsqueda. Por defecto es el directorio actual.
    
    .PARAMETER Filter
    Filtro para buscar elementos (utiliza las reglas de -Filter de Get-ChildItem).
    
    .PARAMETER f
    Switch para filtrar únicamente archivos.
    
    .PARAMETER d
    Switch para filtrar únicamente directorios.
    
    .PARAMETER p
    Switch para imprimir la ruta de todos los elementos encontrados.
    
    .EXAMPLE
    Remove-FilteredItems -Filter "*.tmp" -f
    Busca y elimina todos los archivos .tmp recursivamente.
    
    .EXAMPLE
    Remove-FilteredItems -Filter "*cache*" -d -p
    Busca directorios que contengan "cache" en el nombre, muestra las rutas y los elimina.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Filter,
        
        [Parameter(Mandatory = $false)]
        [string]$Path = ".",
        
        [Parameter(Mandatory = $false)]
        [switch]$f,  # Solo archivos
        
        [Parameter(Mandatory = $false)]
        [switch]$d,  # Solo directorios
        
        [Parameter(Mandatory = $false)]
        [switch]$p   # Imprimir rutas
    )
    
    # Validar que no se usen ambos switches -f y -d
    if ($f -and $d) {
        Write-Error "No se pueden usar los parámetros -f y -d simultáneamente."
        return
    }
    
    Write-Host "Buscando elementos..." -ForegroundColor Yellow
    
    try {
        # Construir parámetros para Get-ChildItem
        $getChildItemParams = @{
            Path = $Path
            Filter = $Filter
            Recurse = $true
            ErrorAction = 'SilentlyContinue'
        }
        
        # Aplicar filtros según los switches
        if ($f) {
            $getChildItemParams.File = $true
            $itemType = "archivos"
        }
        elseif ($d) {
            $getChildItemParams.Directory = $true
            $itemType = "directorios"
        }
        else {
            $itemType = "elementos"
        }
        
        # Obtener elementos que coincidan con el filtro
        $allItems = Get-ChildItem @getChildItemParams
        
        # Si estamos buscando directorios, filtrar solo los directorios padre
        # usando un método más eficiente: contar coincidencias del nombre en la ruta
        if ($d -and $allItems.Count -gt 0) {
            $items = @()
            
            foreach ($item in $allItems) {
                # Dividir la ruta en segmentos y contar coincidencias con el filtro
                $pathSegments = $item.FullName.Split([System.IO.Path]::DirectorySeparatorChar, [System.StringSplitOptions]::RemoveEmptyEntries)
                $matchCount = 0
                
                foreach ($segment in $pathSegments) {
                    if ($segment -like $Filter) {
                        $matchCount++
                    }
                }
                
                # Solo incluir si hay exactamente una coincidencia (directorio padre)
                if ($matchCount -eq 1) {
                    $items += $item
                }
            }
        }
        else {
            $items = $allItems
        }
        
        if ($items.Count -eq 0) {
            Write-Host "No se encontraron $itemType que coincidan con el filtro '$Filter'." -ForegroundColor Green
            return
        }
        
        # Mostrar información adicional si se filtraron directorios anidados
        if ($d -and $allItems.Count -gt $items.Count) {
            Write-Host "Se encontraron $($allItems.Count) $itemType en total, pero se procesarán solo $($items.Count) directorios padre" -ForegroundColor Cyan
            Write-Host "(Los directorios anidados se excluyen para evitar conflictos al eliminar recursivamente)" -ForegroundColor Gray
        }
        else {
            Write-Host "Se encontraron $($items.Count) $itemType que coinciden con el filtro '$Filter'." -ForegroundColor Cyan
        }
        
        # Mostrar rutas si se especifica el parámetro -p
        if ($p) {
            Write-Host "`nRutas encontradas:" -ForegroundColor Magenta
            foreach ($item in $items) {
                Write-Host "  $($item.FullName)" -ForegroundColor Gray
            }
            Write-Host ""
        }
        
        # Pedir confirmación
        $confirmation = Read-Host "¿Estás seguro de que quieres eliminar estos $($items.Count) $itemType? (s/N)"
        
        if ($confirmation -notmatch '^[sS]$') {
            Write-Host "Operación cancelada." -ForegroundColor Yellow
            return
        }
        
        # Inicializar barra de progreso
        $progress = [ProgressBar]::new($items.Count, 2)
        $deletedCount = 0
        $errorCount = 0
        
        Write-Host "`nEliminando $itemType..." -ForegroundColor Red
        
        # Eliminar elementos con barra de progreso
        for ($i = 0; $i -lt $items.Count; $i++) {
            $item = $items[$i]
            
            try {
                if ($item.PSIsContainer) {
                    # Es un directorio
                    Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
                }
                else {
                    # Es un archivo
                    Remove-Item -Path $item.FullName -Force -ErrorAction Stop
                }
                $deletedCount++
            }
            catch {
                Write-Warning "Error al eliminar: $($item.FullName) - $($_.Exception.Message)"
                $errorCount++
            }
            
            # Actualizar barra de progreso
            $progress.Update($i + 1)
        }
        
        # Mostrar resumen final
        Write-Host "`n" -NoNewline
        Write-Host "Operación completada:" -ForegroundColor Green
        Write-Host "  - Eliminados exitosamente: $deletedCount $itemType" -ForegroundColor Green
        
        if ($errorCount -gt 0) {
            Write-Host "  - Errores: $errorCount $itemType" -ForegroundColor Red
        }
    }
    catch {
        Write-Error "Error durante la operación: $($_.Exception.Message)"
    }
}

function Invoke-IfSuccess {
	param(
		[Parameter(ValueFromRemainingArguments=$true)][string[]]$Commands
	)

	Clear-Host
	foreach($command in $Commands) {
		try {
			Invoke-Expression $command
		} catch {
			Select-Beep Fail
			return
		}

		if ($LASTEXITCODE -ne 0) {
			Select-Beep Fail
			return
		}
	}

	Select-Beep Success
}

function Find-TextInFiles {
	<#
.SYNOPSIS
Busca una cadena de texto en todos los archivos dentro de un directorio especifico y muestra las coincidencias encontradas.

.DESCRIPTION
La función Find-TextInFiles recorre recursivamente los archivos dentro de un directorio dado, buscando una cadena de texto especifica.
Imprime los nombres de los archivos que contienen coincidencias y las lineas donde se encuentran. Si se especifica el parametro -DoOpen,
permite abrir el archivo correspondiente en el Bloc de notas.

.PARAMETER Query
La cadena de texto a buscar dentro de los archivos. Este parametro es obligatorio.

.PARAMETER Directory
Ruta del directorio donde se realizara la busqueda. Por defecto es "src". Se puede abreviar con -d.

.PARAMETER ExcludeDirectories
Lista de directorios que serán excluidos durante la búsqueda

.PARAMETER ExcludeFiles
Lista de archivos que serán excluidos de la búsqueda

.PARAMETER DoOpen
Si se especifica, permite abrir en el Bloc de notas el archivo encontrado. Se puede abreviar con -o.

.EXAMPLE
Find-TextInFiles -Query "password"

Busca la cadena "password" dentro del directorio "src" y muestra los archivos y lineas donde se encuentra.

.EXAMPLE
Find-TextInFiles -Query "TODO" -Directory "C:\Projects" -DoOpen

Busca "TODO" en el directorio "C:\Projects" y permite abrir el archivo con coincidencias en el Bloc de notas.
#>

	param(
		[Parameter(Mandatory = $true)]
		[string]$Query,

		[Alias("d")]
		[string]$Directory = ".",

		[Alias("xd")]
		[string[]]$ExcludeDirectories = @(),

		[Alias("xf")]
		[string[]]$ExcludeFiles = @(),

		[Alias("f")]
		[string]$Filter = "*",

		[Alias("o")]
		[switch]$DoOpen
	)

	$fileCounter = 0
	$filesEncountered = @()

	$files = Get-ChildItem -Path $Directory -Recurse -File -Filter $Filter

	if ($ExcludeDirectories.Count -gt 0) {
		$files = $files | Where-Object {
			$driveName = $_.PSDrive
			$dirPath = $_.DirectoryName
			$dirs = ($dirPath -split '\\') | Where-Object { $_ -and ($_ -ne "$($driveName):") }
			$flag = $true

			foreach ($dir in $ExcludeDirectories) {
				if ($dirs -contains $dir) {
					$flag = $false
					break
				}
			}

			$flag
		}
	}

	if ($ExcludeFiles.Count -gt 0) {
		$files = $files | Where-Object {
			$flag = $true

			foreach ($file in $ExcludeFiles) {
				if ($_.Name -like $file) {
					$flag = $false
					break
				}
			}

			$flag
		}
	}

	$progress = [ProgressBar]::new($files.Count, 2)
	$itemProgress = 0
	$textToShow = ""

	$files | ForEach-Object {
		$itemProgress++
		$progress.Update($itemProgress)

		$filePath = $_.FullName -replace '\[', '`[' -replace '\]', '`]'
		$fileName = $_.Name
		$fileContent = Get-Content -Path $filePath
		if ($fileContent -like "*$Query*") {
			$filesEncountered += $filePath
			$textToShow += "$($fileCounter)`) $fileName`n"
			$lineNumber = 0
			$fileContent | ForEach-Object {
				$lineNumber++
				if ($_ -like "*$Query*") {
					$textToShow += "$($lineNumber): $($_.Trim())`n"
				}
			}
			$fileCounter++
	$textToShow += "`n"
		}
	}

	if ($filesEncountered.Count -eq 0) {
		return
	}

	Clear-Host
	Write-Host $textToShow

	if (-not $DoOpen) {
		return
	}

	if ($filesEncountered.Count -eq 1) {
		notepad $filesEncountered[0]
		Select-Beep Success
		return
	}

	$index = Read-Host "Type the file index: "
	if ([int]::TryParse($index, [ref]$null) -and $index -ge 0 -and $index -lt $filesEncountered.Count) {
		notepad $filesEncountered[$index]
		Select-Beep Success
	}
	else {
		Select-Beep Fail
	}
}

function Get-RAMUsed {
	<#
.SYNOPSIS
Muestra los procesos cuyo nombre coincide con el parametro dado y calcula la RAM usada en MB.

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
		[Parameter(Mandatory = $true)][Alias("p")][string]$processName
	)

	$processes = Get-Process | Where-Object { $_.ProcessName -like "$processName" } | Select-Object ProcessName, Id, @{Name = "RAM_MB"; Expression = { [math]::Round($_.WS / 1MB, 2) } }
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
Produce un beep con frecuencia y duración distintas segun el tipo para indicar estado de procesos, errores o exito.

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
Recorre los subdirectorios en la ruta de trabajo predeterminada, y si encuentra coincidencias con todas las palabras, permite al usuario seleccionar uno y navega hacia el.

.EXAMPLE
Select-DirectoryWithWords -words "api", "test"

.NOTES
Alias: gtd
#>
	param (
		[string[]]$words
	)

	cls
	$defaultWorkspacePath = Get-ConfigProp workspacePath

	if (-not (Test-Path -Path $defaultWorkspacePath)) {
		Select-Beep Fail
		return
	}

	if ($words.Count -eq 0) {
		Set-Location -Path $defaultWorkspacePath
		Select-Beep Success
		return
	}

	$directories = Get-ChildItem -Path $defaultWorkspacePath -Directory

	$matchingDirectories = New-Object System.Collections.Generic.List[System.IO.DirectoryInfo]
	foreach ($directory in $directories) {
		$dirName = $directory.Name.ToLower()

		$isMatch = $true
		foreach ($word in $words) {
			if (-not $dirName.Contains($word.ToLower())) {
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
Termino que debe estar presente en el nombre del archivo.

.PARAMETER directory
Directorio base de busqueda. Por defecto es "src".

.DESCRIPTION
Busca archivos recursivamente en un directorio, permite seleccionar uno si hay multiples coincidencias y lo abre con Notepad.

.EXAMPLE
Open-FileByWord -searchTerm "config" -directory "src"

.NOTES
Alias: fof
#>
	param (
		[Parameter(Mandatory=$true)][string[]]$searchTerm,
		[Alias("d")][string]$directory = ""
	)

	$path = Join-Path -Path "." -ChildPath $directory
	$pattern = ($searchTerm | ForEach-Object { "(?=.*$_)" }) -join ''
	$files = Get-ChildItem -Path $path -Recurse -File | Where-Object { $_.Name -match $pattern }

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
Get-ConfigProp -prop "token"
#>
	param(
		[Parameter(Mandatory = $true)][string]$prop
	)

	$userPath = $env:PSModulePath -split ';' | Where-Object { $_ -match 'Users' } | Select-Object -First 1 | Split-Path -Parent
	$configPath = Join-Path $userPath 'config.json'

	if (-not (Test-Path $configPath)) {
		notepad $configPath
		Write-Host "Please setup the configuration file"
		Select-Beep Fail
		return
	}

	$configProps = Get-Content -Raw -Path $configPath | ConvertFrom-Json

	if (-not $configProps.PSObject.Properties.Name -contains $prop) {
		Write-Host The property does not exist in the config file
		Select-Beep Fail
		return
	}

	return $configProps.$($prop)
}

function Get-ExportedFunctionsAndAliasesFromModule {
	param(
		[Parameter(Mandatory = $true)][string]$moduleName
	)

	Write-Host "Functions:"
	(Get-Module $moduleName).ExportedFunctions.Keys
	Write-Host "---"
	Write-Host "Aliases:"
	(Get-Module $moduleName).ExportedAliases.Keys
}

New-Alias -Name gtd -Value Select-DirectoryWithWords
New-Alias -Name fof -Value Open-FileByWord
New-Alias -Name ram -Value Get-RAMUsed
New-Alias -Name modexports -Value Get-ExportedFunctionsAndAliasesFromModule
New-Alias -Name ftf -Value Find-TextInFiles
New-Alias -Name and -Value Invoke-IfSuccess
New-Alias -Value Remove-FilteredItems -Name rmr