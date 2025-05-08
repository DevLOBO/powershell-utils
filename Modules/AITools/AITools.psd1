@{
    # Nombre del módulo
    RootModule         = 'AITools.psm1'

    # Versión del módulo
    ModuleVersion      = '1.0.0'

    # Descripción
    Description        = 'Funciones útiles para ejecutar modelos LLM.'

    # Autor
    Author             = 'Franco Hernández'

    # Funciones públicas expuestas por el módulo
    FunctionsToExport  = @('Invoke-AIModelRequest')

    # Cmdlets públicos exportados (ninguno)
    CmdletsToExport    = @()

    # Variables públicas exportadas
    VariablesToExport  = @()

    # Alias públicos exportados
    AliasesToExport    = @('aiq')

    # Requiere PowerShell versión mínima
    PowerShellVersion  = '5.1'

    # Archivos requeridos
    RequiredModules    = @()
    RequiredAssemblies = @()

    # Copyright
    Copyright          = '(c) 2025 TuNombre. Todos los derechos reservados.'

    # Privado o visible en PSGet
    PrivateData        = @{}
}
