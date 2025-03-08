function Get-CurrentGitBranch {
	$branch = git branch --show-current 2>$null
	Set-Clipboard $branch
	Select-Beep Success
	return $branch
}

function Get-FilteredGitBranches {
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
		select-Beep Success
	} catch {
		Select-Beep Fail
	}
}

function Copy-RemoteGitRepository {
	$repositoryUrl = git remote get-url origin 2>$null

	if (-not $repositoryUrl) {
		Select-Beep Fail
		return
	}

	Set-Clipboard $repositoryUrl
	Select-Beep Success
}

Set-Alias -Name gcgb -Value Get-CurrentGitBranch
Set-Alias -Name gfgb -Value Get-FilteredGitBranches
Set-Alias -Name crgr -Value Copy-RemoteGitRepository