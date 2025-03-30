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

New-Alias -Name srun -Value Use-SpringDev
New-Alias -Name srundebug -Value Use-SpringDevDebug
New-Alias -Name bimgnat -Value New-NativeImage
New-Alias -Name spmm -Value Monitor-SpringBootActuatorMetrics