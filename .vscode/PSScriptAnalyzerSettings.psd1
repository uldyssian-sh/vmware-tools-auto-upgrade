@{
    # PSScriptAnalyzer settings for VMware Tools Auto-Upgrade solution
    
    # Include default rules
    IncludeDefaultRules = $true
    
    # Severity levels to include
    Severity = @('Error', 'Warning', 'Information')
    
    # Rules to exclude (if any)
    ExcludeRules = @(
        # Exclude rules that may not apply to this specific use case
        # 'PSAvoidUsingWriteHost'  # We use Write-Host for user interaction
    )
    
    # Custom rules configuration
    Rules = @{
        # Enforce consistent formatting
        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $false
        }
        
        PSPlaceCloseBrace = @{
            Enable = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $false
            NoEmptyLineBefore = $false
        }
        
        PSUseConsistentIndentation = @{
            Enable = $true
            Kind = 'space'
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
        }
        
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckSeparator = $true
        }
        
        # Security rules
        PSAvoidUsingPlainTextForPassword = @{
            Enable = $true
        }
        
        PSAvoidUsingConvertToSecureStringWithPlainText = @{
            Enable = $true
        }
        
        # Best practices
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }
        
        PSAvoidUsingPositionalParameters = @{
            Enable = $true
        }
        
        PSUseApprovedVerbs = @{
            Enable = $true
        }
        
        PSUseSingularNouns = @{
            Enable = $true
        }
        
        # Performance rules
        PSAvoidUsingInvokeExpression = @{
            Enable = $true
        }
        
        PSUseDeclaredVarsMoreThanAssignments = @{
            Enable = $true
        }
        
        # Documentation rules
        PSProvideCommentHelp = @{
            Enable = $true
            ExportedOnly = $false
            BlockComment = $true
            VSCodeSnippetCorrection = $true
            Placement = 'before'
        }
    }
}