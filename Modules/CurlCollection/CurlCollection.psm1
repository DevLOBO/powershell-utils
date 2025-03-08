$scriptsPath = "C:\scripts"

function Invoke-CurlCommand {
	param(
		[Alias("a")][int]$app = 0,
		[Alias("c")][int]$command = 0,
		[Alias("va")][switch]$viewApps = $false,
		[Alias("vc")][switch]$viewCommands = $false,
		[Alias("p")][string[]]$params = @(),
		[Alias("ic")][string]$inputStringCommand = "",
		[Alias("pr")][string[]]$paramRoutes = @()
	)

	$apps = Get-ChildItem -Path $scriptsPath -Directory | Sort-Object Name
	if ($viewApps) {
		$apps | ForEach-Object { Write-Host $([array]::IndexOf($apps, $_)): $_.Name }
		return
	}

	$commandsPath = Join-Path $apps[$app].FullName "commands.yaml"
	$commandsValues = Get-Content -Path $commandsPath -Raw | ConvertFrom-Yaml
	$commands = $commandsValues["commands"]
	if ($viewCommands) {
		Write-Host Commands for $apps[$app].Name
		$commands | ForEach-Object { Write-Host $([array]::IndexOf($commands, $_)): $_["description"] }
		return
	}

	$commandInfo = $commands[$command]
	$baseUrl = $commandsValues["baseUrl"]
	$fullUri = "$($baseUrl)$($commandInfo['url'])"
	$method = if ($commandInfo.ContainsKey("method")) { $commandInfo["method"] } else { "GET" }
	$headers = if ($commandInfo.ContainsKey("headers")) { $commandInfo["headers"] } else { @() }
	$hasBody = -not ($method -in @("GET", "OPTIONS", "HEAD", "DELETE")) -and ($commandInfo.ContainsKey("body") -or $commandInfo.ContainsKey("bodyFile"))

	if ($hasBody) {
		$body = if ($commandInfo.ContainsKey("body")) {
			$commandInfo["body"]
		} else {
			$bodyFilePath = Join-Path $apps[$app].FullName $commandInfo["bodyFile"]
			Get-Content -Raw -Path $bodyFilePath | ConvertFrom-Json
		}

		if ($params) {
			foreach ($param in $params) {
				$parts = $param.Split("=")
				$props = $parts[0].Split(".")
				$value = ConvertTo-TypedValue $($parts[1])

				$body = Set-NestedProp $body $props $value
			}
		}

		req $fullUri -X $method -d $($body | ConvertTo-Json -Compress) -H $headers

		$curlCommand = 'req "{0}" -X {1} -d ''{2}''' -f $fullUri, $method, $bodyString
	} else {
		req $fullUri -X $method -H $headers

		$curlCommand = 'req "{0}" -X {1}' -f $fullUri, $method
	}

	$bodyString = if ($hasBody) { $body | ConvertTo-Json -Compress } else { $null }
	$curlCommand = Get-CurlCommandString -url $fullUri -method $method -body $bodyString -headers $headers
	Set-Clipboard $curlCommand
	Select-Beep Success
}

function Set-NestedProp {
	param(
		[Parameter(Mandatory=$true)][hashtable]$hashtable,
		[Parameter(Mandatory=$true)][string[]]$props,
		[Parameter(Mandatory=$true)][object]$value
	)

	$currentHashtable = $hashtable

	for ($i = 0; $i -lt $props.Count - 1; $i++) {
		if (-not $currentHashtable.ContainsKey($props[$i])) { $currentHashtable[$props[$i]] = @{} }

		$currentHashtable = $currentHashtable[$props[$i]]
	}

	$currentHashtable[$props[-1]] = $value

	return $hashtable
}

function ConvertTo-TypedValue {
	param(
		[Parameter(Mandatory=$true)][string]$inputString
	)

	if ($inputString -eq "" -or $inputString -eq "null" -or $inputString.Length -lt 2) {
		return $null
	}

	$suffix = $inputString.Substring($inputString.Length - 1).ToLower()
	$val = $inputString.Substring(0, $inputString.Length - 1)

	switch ($suffix) {
		"s" { return $val }
		"i" { return [int]$val }
		"d" {return [double]$val }
		"b" {return [bool]$val }
	}

}

function Get-CurlCommandString {
	param(
		[Parameter(Mandatory=$true)][string]$url,
		[Parameter(Mandatory=$true)][string]$method,
		[string]$body,
		[string[]]$headers,
		[switch]$curl
	)

	$curlCommand = if ($curl) { 'curl "{0}" -X {1}' } else { 'req "{0}" -X {1}' }
	$curlCommand = $curlCommand -f $url, $method

	if ($headers.Count -gt 0) {
		$headersString = $headers | % { "`"$_`"" }
		$headersString = $headersString -join ','
		$headersString = ' -H {0}' -f $headersString

		$curlCommand += $headersString
	}

	if ($body) {
		$curlCommand += ' -d ''{0}''' -f $body
	}

	return $curlCommand
}

Set-Alias icc Invoke-CurlCommand