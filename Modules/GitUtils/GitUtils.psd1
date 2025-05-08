@{
    # Módulo raíz
    RootModule = 'GitUtils.psm1'

    # Versión del módulo
    ModuleVersion = '1.0.0'

    # Identificador único
    GUID = 'f8124b30-63dc-4a8d-97a0-9b62cb1b9307'

    # Autor e información descriptiva
    Author = 'Franco Hernández'
    Description = 'Utilidades para trabajar con ramas y repositorios Git desde PowerShell.'

    # Requiere al menos PowerShell 5.1
    PowerShellVersion = '5.1'

    # Exportaciones
    FunctionsToExport = @(
        'Get-CurrentGitBranch',
        'Get-FilteredGitBranches',
        'Copy-RemoteGitRepository',
        'New-CommitAndPush'
    )

    AliasesToExport = @(
        'gcgb',
        'gfgb',
        'crgr',
        'ngcp'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()

    RequiredModules   = @()
    RequiredAssemblies = @()

    PrivateData = @{
        PSData = @{
            Tags = @('Git', 'PowerShell', 'Utilities', 'Development')
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = 'https://github.com/tuusuario/git-utils'
            ReleaseNotes = 'Versión inicial del módulo GitUtils con funciones de consulta de ramas y URL remota.'
        }
    }
}
