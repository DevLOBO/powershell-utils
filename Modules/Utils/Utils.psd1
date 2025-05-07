@{
    # Módulo raíz
    RootModule = 'Utils.psm1'

    # Información de versión
    ModuleVersion = '1.0.0'

    # GUID único (puedes generar uno nuevo si lo deseas con [guid]::NewGuid())
    GUID = 'e6a91a4f-52e0-4c5d-bd3a-5fefb5193a77'

    # Información del autor y descripción
    Author = 'Franco Hernández'
    Description = 'Funciones utilitarias para gestión de procesos, archivos y configuración en PowerShell.'

    # Versión mínima requerida de PowerShell
    PowerShellVersion = '5.1'

    # Exportaciones
    FunctionsToExport = @(
        'Get-RAMUsed',
        'Select-Beep',
        'Select-DirectoryWithWords',
        'Open-FileByWord',
        'Get-ConfigProp'
    )

    AliasesToExport = @(
        'ram',
        'gtd',
        'fof'
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
            Tags = @('PowerShell', 'Utilities', 'Productivity')
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = 'https://github.com/tuusuario/tu-repo'
            ReleaseNotes = 'Versión inicial con utilidades personalizadas.'
        }
    }
}
