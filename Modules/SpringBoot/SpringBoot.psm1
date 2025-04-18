function Watch-SpringBootActuatorMetrics {
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
	cls
	mvn spring-boot:build-image -DskipTests -Pnative
}

function Use-SpringDev {
	cls
	mvn spring-boot:run -DskipTests
}

function Use-SpringDevDebug {
	cls
	mvn spring-boot:run -Ddebug
}

function Analyze-SurefireReports {
    mvn test > $null

    # Define la ruta a la carpeta de reportes de Surefire
    $reportPath = "target/surefire-reports"

    # Busca todos los archivos XML en la carpeta de reportes
    $reportFiles = Get-ChildItem -Path $reportPath -Filter "*.xml"

    if ($reportFiles.Count -eq 0) {
        Write-Warning "No se encontraron archivos de reporte Surefire en '$reportPath'."
        return
    }

    $failedTests = 0
    foreach ($reportFile in $reportFiles) {
        Write-Host "`n--- Reporte: $($reportFile.Name) ---"

        # Lee el contenido del archivo XML
        [xml]$xmlReport = Get-Content -Path $reportFile.FullName

        # Itera sobre cada etiqueta <testcase>
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

New-Alias -Name srun -Value Use-SpringDev
New-Alias -Name srundebug -Value Use-SpringDevDebug
New-Alias -Name bimgnat -Value New-NativeImage
New-Alias -Name spmm -Value Monitor-SpringBootActuatorMetrics
New-Alias -Name spt -Value Analyze-SurefireReports