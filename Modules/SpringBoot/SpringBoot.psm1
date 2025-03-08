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