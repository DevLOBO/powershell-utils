function Invoke-GitAutoSquash {
    param (
        [Parameter(Mandatory = $true)]
        [int]$Count
    )

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "Git no está instalado o no está en el PATH."
        Select-Beep Fail
        return
    }

    # Verificar si hay suficientes commits
	$Count++
    $commitCount = git rev-list --count HEAD
    if ($commitCount -lt ($Count + 1)) {
        Write-Error "No hay suficientes commits para hacer squash de $Count. Actualmente hay $commitCount commits."
        Select-Beep Fail
        return
    }

    # Obtener el hash del commit base
    $hash = git rev-parse "HEAD~$Count" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "No se pudo obtener el hash. Asegúrate de tener al menos $Count commits."
        Select-Beep Fail
        return
    }

    Write-Host "Preparando rebase interactivo desde $hash..."

    # Script para GIT_SEQUENCE_EDITOR: convierte todos los "pick" menos el primero en "squash"
    $sequenceEditorScript = [IO.Path]::GetTempFileName() + ".ps1"
    Set-Content $sequenceEditorScript @'
$path = $args[0]
$lines = Get-Content $path
for ($i = 1; $i -lt $lines.Count; $i++) {
    $lines[$i] = $lines[$i] -replace '^pick', 'squash'
}
$lines | Set-Content $path
'@

    # Script para GIT_EDITOR: comenta todos los mensajes menos el primero
    $editorScript = [IO.Path]::GetTempFileName() + ".ps1"
    Set-Content $editorScript @'
$path = $args[0]
$lines = Get-Content $path
$output = @()
$hasKeptMessage = $false

foreach ($line in $lines) {
    if (-not $hasKeptMessage -and $line -notmatch '^#' -and $line.Trim() -ne '') {
        $output += $line
        $hasKeptMessage = $true
    } elseif ($line.Trim() -ne '') {
        $output += "# $line"
    } else {
        $output += ""
    }
}
$output | Set-Content $path
'@

    # Ejecutar el rebase
    $env:GIT_SEQUENCE_EDITOR = "powershell -ExecutionPolicy Bypass -File `"$sequenceEditorScript`""
    $env:GIT_EDITOR = "powershell -ExecutionPolicy Bypass -File `"$editorScript`""
    
    git rebase -i $hash

    if ($LASTEXITCODE -eq 0) {
        Select-Beep
    } else {
        Select-Beep Fail
    }

    # Limpiar scripts temporales
    Remove-Item $sequenceEditorScript, $editorScript -Force
}

function New-CommitAndPush {
	<#
    .SYNOPSIS
        Aplica git add, git commit y git push consecutivamente para guardar los cambios en el repositorio remoto
    .PARAMETER message
        El mensaje obligatorio para crear el commit en la rama
    .PARAMETER files
        Los archivos que se agregan al commit, si no se define ninguno por defecto es "."
    .NOTES
        Guarda todos los cambios, aplica el commit y envía los cambios al repositorio remoto
        Requiere que Git esté instalado y disponible en la terminal.
    #>
	param(
		[Parameter(Mandatory = $true)][string]$message,
		[Alias("a")][string[]]$files = @()
	)

	$addFiles = if ($files.Count -gt 0) { $files -join " " } else { "." }
	git add $addFiles
	git commit -m $message
	git push
}

function Get-CurrentGitBranch {
	<#
    .SYNOPSIS
        Obtiene la rama actual del repositorio Git y la copia al portapapeles.
    .NOTES
        Utiliza 'git branch --show-current' para identificar la rama actual.
        Requiere que Git esté instalado y disponible en la terminal.
    #>
	$branch = git branch --show-current 2>$null
	Set-Clipboard $branch
	Select-Beep Success
	return $branch
}

function Get-FilteredGitBranches {
	<#
    .SYNOPSIS
        Filtra y muestra ramas Git que contengan todas las palabras clave especificadas.
    .PARAMETER keywords
        Lista de palabras clave que deben estar presentes en el nombre de la rama.
    .NOTES
        Ignora prefijos como 'remotes/origin/' y puede usarse con múltiples palabras clave.
        Útil para buscar ramas específicas de forma rápida.
    #>
	param(
		[Parameter(Mandatory = $true)][string[]]$keywords
	)

	try {
		$branches = git branch -a 2>$null
		$branches = $branches | % { $_.ToLower() -replace '^\*?\s*', '' -replace '^remotes\/origin\/', '' } | Sort-Object -Unique

		$filteredBranches = $branches | Where-Object {
			$branch = $_

			foreach ($keyword in $keywords) {
				if ($branch -notmatch [regex]::Escape($keyword)) { return $false }
			}

			return $true
		}

		if ($filteredBranches.Count -eq 0) {
			Select-Beep Fail
			return
		}

		$filteredBranches | % { Write-Host $_ }
		Select-Beep Success
	}
	catch {
		Select-Beep Fail
	}
}

function Copy-RemoteGitRepository {
	<#
    .SYNOPSIS
        Copia la URL del repositorio Git remoto 'origin' al portapapeles.
    .NOTES
        Utiliza 'git remote get-url origin' para obtener la URL.
        Requiere que el repositorio tenga configurado un remoto llamado 'origin'.
    #>
	$repositoryUrl = git remote get-url origin 2>$null

	if (-not $repositoryUrl) {
		Select-Beep Fail
		return
	}

	Set-Clipboard $repositoryUrl
	Select-Beep Success
}

# Alias sugeridos
New-Alias -Name curbran     -Value Get-CurrentGitBranch     # Get Current Git Branch
New-Alias -Name filbran     -Value Get-FilteredGitBranches  # Get Filtered Git Branches
New-Alias -Name remrepo     -Value Copy-RemoteGitRepository # Copy Remote Git Repository
New-Alias -Name pushit -Value New-CommitAndPush
New-Alias -Name gitsquash -Value Invoke-GitAutoSquash
