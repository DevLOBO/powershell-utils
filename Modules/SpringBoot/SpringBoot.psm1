function Watch-SpringBootActuatorMetrics {
    <#
    .SYNOPSIS
        Monitorea el uso de CPU y memoria de una aplicación Spring Boot mediante el endpoint Actuator.
    .PARAMETER actuatorUrl
        URL base del endpoint Actuator (por defecto: http://localhost:8080/actuator/metrics).
    .PARAMETER timeSleep
        Tiempo de espera entre cada muestreo, en segundos (por defecto: 4).
    .NOTES
        Muestra el uso de recursos en la consola en tiempo real.
    #>
    param(
        [string]$actuatorUrl="http://localhost:8080/actuator/metrics",
        [int]$timeSleep=4
    )

    while ($true) {
        $memoryResponse = Invoke-RestMethod -Uri "$actuatorUrl/jvm.memory.used"
        $cpuResponse = Invoke-RestMethod -Uri "$actuatorUrl/system.cpu.usage"

        $memoryUsed = $memoryResponse.measurements[0].value / 1048576
        $cpuUsage = $cpuResponse.measurements[0].value * 100

        $cpuUsage = "{0:N2}" -f $cpuUsage
        $memoryUsed = "{0:N2}" -f $memoryUsed

        Write-Host "Uso de CPU: $cpuUsage%"
        Write-Host "Memoria RAM usada: $($memoryUsed)MB"

        Start-Sleep -Seconds $sleepTime
        Clear-Host
    }
}

function New-NativeImage {
    <#
    .SYNOPSIS
        Construye una imagen nativa de una aplicación Spring Boot usando el perfil 'native'.
    .NOTES
        Ejecuta el comando Maven para generar la imagen.
    #>
	cls
	mvn spring-boot:build-image -DskipTests -Pnative
}

function Start-SpringDev {
    <#
    .SYNOPSIS
        Inicia una aplicación Spring Boot en modo desarrollo sin ejecutar tests.
    .NOTES
        Utiliza Maven con la opción -DskipTests.
    #>
	cls
	mvn spring-boot:run -DskipTests
}

function Start-SpringDevDebug {
    <#
    .SYNOPSIS
        Inicia una aplicación Spring Boot en modo debug.
    .NOTES
        Usa la opción -Ddebug de Maven.
    #>
	cls
	mvn spring-boot:run -Ddebug
}

function Analyze-SurefireReports {
    <#
    .SYNOPSIS
        Ejecuta los tests y analiza los reportes Surefire de Maven para mostrar resultados detallados.
    .NOTES
        Muestra por consola los tests exitosos y fallidos, junto con sus mensajes y tipo de error.
    #>
    mvn test > $null

    $reportPath = "target/surefire-reports"
    $reportFiles = Get-ChildItem -Path $reportPath -Filter "*.xml"

    if ($reportFiles.Count -eq 0) {
        Write-Warning "No se encontraron archivos de reporte Surefire en '$reportPath'."
        return
    }

    $failedTests = 0
    foreach ($reportFile in $reportFiles) {
        Write-Host "`n--- Reporte: $($reportFile.Name) ---"

        [xml]$xmlReport = Get-Content -Path $reportFile.FullName

        foreach ($testcase in $xmlReport.testsuite.testcase) {
            $testName = $testcase.name
            $executionTime = $testcase.time

            if ($testcase.failure) {
                $failedTests += 1
                Write-Host "[FAILED] $($testName) - $($executionTime)s"
                Write-Host "   Mensaje de Fallo: $($testcase.failure.message)"
                if ($testcase.failure.type) {
                    Write-Host "   Tipo de Fallo: $($testcase.failure.type)"
                }
            } else {
                Write-Host "[SUCCESS] $($testName) - $($executionTime)s"
            }
        }
    }

    if ($failedTests -gt 0) {
        Select-Beep Fail
    } else {
        Select-Beep Success
    }
}

New-Alias -Name spmon -Value Watch-SpringBootActuatorMetrics
New-Alias -Name natimg -Value New-NativeImage
New-Alias -Name spdev -Value Start-SpringDev
New-Alias -Name spdbg -Value Start-SpringDevDebug
New-Alias -Name sfrep -Value Analyze-SurefireReports
