@{
    # Módulo raíz
    RootModule = 'InvokeCustomWebRequests.psm1'

    # Versión del módulo
    ModuleVersion = '1.0.0'

    # Identificador único
    GUID = 'c3de4f5f-8f6b-45d7-88fd-ef2b81c7385e'

    # Autor y descripción
    Author = 'Franco Hernández'
    Description = 'Módulo personalizado para realizar peticiones HTTP enriquecidas desde PowerShell.'

    # Versión mínima de PowerShell
    PowerShellVersion = '5.1'

    # Exportaciones
    FunctionsToExport = @('Invoke-CustomWebRequest')
    AliasesToExport   = @('req')

    CmdletsToExport   = @()
    VariablesToExport = @()

    # Dependencias (ninguna requerida directamente)
    RequiredModules = @()
    RequiredAssemblies = @()

    PrivateData = @{
        PSData = @{
            Tags = @('PowerShell', 'HTTP', 'WebRequest', 'Utilities')
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = 'https://github.com/tuusuario/tu-repo'
            ReleaseNotes = 'Versión inicial del módulo con funcionalidad HTTP personalizada.'
        }
    }
}
