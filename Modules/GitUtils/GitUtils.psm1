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
		[Parameter(Mandatory=$true)][string[]]$keywords
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
	} catch {
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
New-Alias -Name gcgb     -Value Get-CurrentGitBranch     # Get Current Git Branch
New-Alias -Name gfgb     -Value Get-FilteredGitBranches  # Get Filtered Git Branches
New-Alias -Name crgr     -Value Copy-RemoteGitRepository # Copy Remote Git Repository
