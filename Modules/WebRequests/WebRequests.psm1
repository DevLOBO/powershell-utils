function req {
    param(
        [Parameter(Mandatory = $true)][string]$uri,
        [Alias("X")][string]$method = "GET",
        [Alias("d")][string]$data = "{}",
        [Alias("H")][string[]]$headers = @(),
        [Alias("f")][string]$file = ""
    )

    # Diccionario de headers por defecto
    $headersDict = @{
        "Content-Type"    = "application/json; charset=utf-8"
        "Accept-Language" = "es"
    }

    # Procesar encabezados adicionales
    foreach ($header in $headers) {
        if ($header -match "^\s*(.+?):\s*(.+)$") {
            $headersDict[$matches[1]] = $matches[2]
        } else {
            Write-Host "Header inválido: '$header' (Debe ser 'Clave: Valor')" -ForegroundColor Red
            return
        }
    }

    # Leer datos desde archivo si se proporciona `-f`
    if ($file -ne "") {
        if (Test-Path $file) {
            $fileContent = Get-Content -Raw -Path $file -ErrorAction Stop
            $data = if ([System.IO.Path]::GetExtension($file).ToLower() -in ".yml", ".yaml") { ConvertFrom-Yaml -Yaml $fileContent | ConvertTo-Json } else { $fileContent }
        } else {
            Write-Host "Archivo no encontrado: $file" -ForegroundColor Red
            return
        }
    }

    # Convertir método HTTP a mayúsculas
    $method = $method.ToUpper()

    # Limpiar pantalla y mostrar información de la petición
    cls
    Write-Host "$method $uri" -ForegroundColor Yellow

    try {
        # Realizar la petición HTTP
        $response = if ($method -in "GET", "DELETE") {
            Invoke-WebRequest -Uri $uri -Method $method -Headers $headersDict -ErrorAction Stop
        } else {
            Invoke-WebRequest -Uri $uri -Method $method -Headers $headersDict -Body $data -ErrorAction Stop
        }
        $content = $response.Content

        Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
        
        # Mostrar el contenido formateado con jq si está instalado
        if (Get-Command jq -ErrorAction SilentlyContinue) {
            $content | jq
        } else {
            $content | Write-Host -ForegroundColor Cyan
        }
    }
    catch {
        $errorResponse = $_.Exception.Response
        if ($errorResponse) {
            $statusCode = $errorResponse.StatusCode
            Write-Host "Error Status Code: $statusCode" -ForegroundColor Red
            
            $errorContent = $errorResponse.GetResponseStream()
            $errorReader = New-Object System.IO.StreamReader($errorContent)
            $content = $errorReader.ReadToEnd()
            $errorReader.Close()
            $errorContent.Close()
            
            if (Get-Command jq -ErrorAction SilentlyContinue) {
                $content | jq
            } else {
                Write-Host $content -ForegroundColor Cyan
            }
        } else {
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    $content | Out-File -Encoding UTF8 "./res.json"
}
