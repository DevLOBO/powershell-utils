function Invoke-AIModelRequest {
	<#
    .SYNOPSIS
        Envía una solicitud POST a una API para ejecutar un modelo de lenguaje IA usando la función personalizada Invoke-CustomWebRequest.

    .DESCRIPTION
        Esta función permite personalizar el endpoint, los encabezados, y el cuerpo de la solicitud para consumir una API de IA.
        Guarda la respuesta por defecto en 'res.json'.

    .PARAMETER ApiKey
        Nombre de la variable de entorno dónde está la ApiKey a usar

    .PARAMETER ContextFiles
        Archivos de contexto para enviar junto con el Prompt

    .PARAMETER Instructions
        Contenido para agregar instrucciones al modelo en el rol de "system"

    .PARAMETER Prompt
        Contenido del mensaje del usuario (rol "user") para el modelo.

    .PARAMETER AdditionalBody
        Parámetros adicionales que quieras incluir en el cuerpo, como temperature, max_tokens, etc. (hashtable).

    .PARAMETER OutputFile
        Ruta del archivo dónde se guardará la respuesta
    #>
	param(
		[Parameter(Mandatory = $true)][string]$Prompt,
		[Alias("k")][string]$ApiKey = "GENAI_API_KEY",
		[Alias("i")][string]$Instructions = "",
		[Alias("cf")][string[]]$ContextFiles = @(),
		[Alias("eb")][hashtable]$AdditionalBody = @{},
		[Alias("o")][string]$OutputFile
	)

	$Model = Get-ConfigProp aiModel
	$Endpoint = Get-ConfigProp aiEndpoint

	# Construir el prompt
	$AIPrompt = if ($ContextFiles.Count -eq 0) { $Prompt } else {
		$Prompt + "`n---`n" + ($ContextFiles | ForEach-Object { "`n$([System.IO.Path]::GetFileName($_)):`n" + (Get-Content $_ -Raw) }) -join "`n`n"
	}

	# Construir el cuerpo base
	$body = @{
		model = $Model
		stream = $false
		messages = @(
			@{
				role = "system"
				content = "Eres un asistente que responde directamente, sin texto introductorio/explicativo o elogios innecesarios. Analiza el idioma del prompt del usuario, y responde siempre en el mismo idioma del usuario, a menos que te solicite explicítamente que respondas en un idioma distinto. No actives el modo de razonamiento /nothinking. $Instructions".Trim()
			}
			@{
				role = "user"
				content = $AIPrompt.Trim()
			}
		)
	}

	# Fusionar cualquier parámetro adicional al cuerpo
	foreach ($key in $AdditionalBody.Keys) {
		$body[$key] = $AdditionalBody[$key]
	}

	# Convertir a JSON (hasta 10 niveles por seguridad)
	$jsonBody = $body | ConvertTo-Json -Depth 10

	# Construir encabezados personalizados
	$ApiKey = (Get-Item -Path "Env:$ApiKey").Value
	$headers = @("Authorization: Bearer $ApiKey")

	# Ejecutar solicitud
	Invoke-CustomWebRequest -uri $Endpoint -method "POST" -data $jsonBody -headers $headers -outputFile $OutputFile -silent

	Clear-Host
	$responseObj = Get-Content -Path $OutputFile -Raw | ConvertFrom-Json

	if (-not $responseObj.choices) {
		Select-Beep Fail
		Write-Host "The response from API was failed"
		return
	}

	$content = $responseObj.choices[0].message.content

	if ($OutputFile -ne "") {
		Set-Content $content -Path $OutputFile
	}

	Write-Host "Prompt Tokens: $($responseObj.usage.prompt_tokens)"
	Write-Host "Output Tokens: $($responseObj.usage.completion_tokens)"
	Write-Host "Total Tokens: $($responseObj.usage.total_tokens)"
	Write-Host "`n---`n"
	Write-Host $content
	Select-Beep Success
}

New-Alias -Value Invoke-AIModelRequest -Name aiq
