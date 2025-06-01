@{
    IncludeRules = @(
        'PSUseConsistentIndentation',
        'PSPlaceOpenBrace',
        'PSPlaceCloseBrace',
        'PSUseConsistentWhitespace'
    )

    Rules = @{
        PSUseConsistentIndentation = @{
            Enable            = $true
            Kind              = 'tab'  # Usa 'tab' en lugar de 'space'
            IndentationSize   = 1      # Número de tabulaciones por nivel de indentación
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
        }

        PSPlaceOpenBrace = @{
            Enable      = $true
            OnSameLine  = $true
            NewLineAfter = $true
        }

        PSPlaceCloseBrace = @{
            Enable      = $true
            NewLineAfter = $true
            NoEmptyLineBefore = $false
        }

        PSUseConsistentWhitespace = @{
            Enable             = $true
            CheckOpenBrace     = $true
            CheckOpenParen     = $true
            CheckOperator      = $true
            CheckSeparator     = $true
        }
    }
}
