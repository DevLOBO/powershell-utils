@{
    # Módulo raíz
    RootModule = 'SpringBoot.psm1'

    # Información de versión
    ModuleVersion = '1.0.0'

    # GUID único (puedes generar uno nuevo si lo deseas con [guid]::NewGuid())
    GUID = 'e6a91a4f-52e0-4c5d-bd3a-5fefb5193a77'

    # Información del autor y descripción
    Author = 'Franco Hernández'
    Description = 'Funciones utilitarias para trabajar con aplicaciones Spring Boot y Maven.'

    # Versión mínima requerida de PowerShell
    PowerShellVersion = '5.1'

    # Exportaciones
    FunctionsToExport = @(
        'Watch-SpringBootActuatorMetrics',
        'New-NativeImage',
        'Start-SpringDev',
        'Start-SpringDevDebug',
        'Analyze-SurefireReports'
    )

    AliasesToExport = @(
        'spmon',
        'natimg',
        'spdev',
        'spdbg',
        'sfrep'
    )

    # No se exportan cmdlets ni variables
    CmdletsToExport = @()
    VariablesToExport = @()

    # Archivos requeridos (ninguno en este caso)
    RequiredModules = @()
    RequiredAssemblies = @()

    # Datos opcionales
    PrivateData = @{
        PSData = @{
            Tags = @('PowerShell', 'Spring Boot', 'Maven', 'Tests')
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = 'https://github.com/tuusuario/tu-repo'
            ReleaseNotes = 'Versión inicial con funciones para Spring Boot y Maven.'
        }
    }
}
