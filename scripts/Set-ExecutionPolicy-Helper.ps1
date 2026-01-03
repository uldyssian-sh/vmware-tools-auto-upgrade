<#
.SYNOPSIS
    Helper script to configure PowerShell execution policy for VMware Tools Auto-Upgrade solution

.DESCRIPTION
    This helper script configures the appropriate PowerShell execution policy
    to allow the VMware Tools auto-upgrade script to run while maintaining
    security best practices for enterprise environments.

.PARAMETER Scope
    The scope for the execution policy (CurrentUser, LocalMachine, Process)

.PARAMETER Policy
    The execution policy to set (RemoteSigned, Unrestricted, Bypass)

.PARAMETER Temporary
    Set execution policy for current process only (temporary)

.EXAMPLE
    .\Set-ExecutionPolicy-Helper.ps1
    Interactive mode with recommendations

.EXAMPLE
    .\Set-ExecutionPolicy-Helper.ps1 -Scope CurrentUser -Policy RemoteSigned
    Set RemoteSigned policy for current user

.EXAMPLE
    .\Set-ExecutionPolicy-Helper.ps1 -Temporary
    Set bypass policy for current process only

.NOTES
    Author: uldyssian-sh
    Version: 1.0
    Requires: PowerShell 5.1 or later
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('CurrentUser', 'LocalMachine', 'Process')]
    [string]$Scope = 'CurrentUser',
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('RemoteSigned', 'Unrestricted', 'Bypass')]
    [string]$Policy = 'RemoteSigned',
    
    [Parameter(Mandatory = $false)]
    [switch]$Temporary
)

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-CurrentExecutionPolicy {
    Write-ColorOutput "=== Current PowerShell Execution Policy ===" "Cyan"
    Write-ColorOutput ""
    
    $policies = @('Process', 'CurrentUser', 'LocalMachine', 'UserPolicy', 'MachinePolicy')
    
    foreach ($scope in $policies) {
        try {
            $policy = Get-ExecutionPolicy -Scope $scope -ErrorAction SilentlyContinue
            if ($policy) {
                $color = switch ($policy) {
                    'Restricted' { 'Red' }
                    'AllSigned' { 'Yellow' }
                    'RemoteSigned' { 'Green' }
                    'Unrestricted' { 'Yellow' }
                    'Bypass' { 'Magenta' }
                    default { 'White' }
                }
                Write-ColorOutput "  $scope : $policy" $color
            }
        } catch {
            Write-ColorOutput "  $scope : Unable to determine" "Gray"
        }
    }
    
    Write-ColorOutput ""
    $effectivePolicy = Get-ExecutionPolicy
    Write-ColorOutput "Effective Policy: $effectivePolicy" "White"
    Write-ColorOutput ""
}

function Set-RecommendedPolicy {
    param(
        [string]$TargetScope,
        [string]$TargetPolicy
    )
    
    Write-ColorOutput "Setting execution policy..." "Yellow"
    Write-ColorOutput "  Scope: $TargetScope" "White"
    Write-ColorOutput "  Policy: $TargetPolicy" "White"
    Write-ColorOutput ""
    
    try {
        if ($TargetScope -eq 'LocalMachine' -and -not (Test-AdminPrivileges)) {
            Write-ColorOutput "ERROR: LocalMachine scope requires administrator privileges" "Red"
            Write-ColorOutput "Please run PowerShell as Administrator or use CurrentUser scope" "Yellow"
            return $false
        }
        
        Set-ExecutionPolicy -ExecutionPolicy $TargetPolicy -Scope $TargetScope -Force
        Write-ColorOutput "✓ Execution policy set successfully" "Green"
        return $true
        
    } catch {
        Write-ColorOutput "✗ Failed to set execution policy: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Show-SecurityRecommendations {
    Write-ColorOutput "=== Security Recommendations ===" "Cyan"
    Write-ColorOutput ""
    Write-ColorOutput "For Enterprise Environments:" "Yellow"
    Write-ColorOutput "  • Use 'RemoteSigned' policy (recommended)" "Green"
    Write-ColorOutput "  • Sign scripts with code signing certificates" "White"
    Write-ColorOutput "  • Use 'CurrentUser' scope to avoid system-wide changes" "White"
    Write-ColorOutput "  • Regularly review and audit execution policies" "White"
    Write-ColorOutput ""
    Write-ColorOutput "Policy Descriptions:" "Yellow"
    Write-ColorOutput "  • RemoteSigned: Local scripts run without signature, downloaded scripts require signature" "White"
    Write-ColorOutput "  • Unrestricted: All scripts run, but downloaded scripts show warning" "White"
    Write-ColorOutput "  • Bypass: No restrictions, no warnings (use with caution)" "White"
    Write-ColorOutput ""
}

function Start-InteractiveMode {
    Write-ColorOutput "=== PowerShell Execution Policy Helper ===" "Cyan"
    Write-ColorOutput "VMware Tools Auto-Upgrade Solution" "Gray"
    Write-ColorOutput ""
    
    # Show current policy
    Get-CurrentExecutionPolicy
    
    # Check if VMware Tools script can run
    $effectivePolicy = Get-ExecutionPolicy
    $canRun = $effectivePolicy -in @('RemoteSigned', 'Unrestricted', 'Bypass')
    
    if ($canRun) {
        Write-ColorOutput "✓ Current policy allows VMware Tools script execution" "Green"
    } else {
        Write-ColorOutput "✗ Current policy may prevent VMware Tools script execution" "Red"
        Write-ColorOutput "  Recommended action: Set policy to RemoteSigned" "Yellow"
    }
    
    Write-ColorOutput ""
    Show-SecurityRecommendations
    
    # Interactive options
    Write-ColorOutput "Options:" "Yellow"
    Write-ColorOutput "1. Set RemoteSigned for CurrentUser (recommended)" "White"
    Write-ColorOutput "2. Set RemoteSigned for LocalMachine (requires admin)" "White"
    Write-ColorOutput "3. Set Bypass for current process only (temporary)" "White"
    Write-ColorOutput "4. Custom configuration" "White"
    Write-ColorOutput "5. Exit without changes" "White"
    Write-ColorOutput ""
    
    $choice = Read-Host "Select option (1-5)"
    
    switch ($choice) {
        "1" {
            Set-RecommendedPolicy -TargetScope "CurrentUser" -TargetPolicy "RemoteSigned"
        }
        "2" {
            Set-RecommendedPolicy -TargetScope "LocalMachine" -TargetPolicy "RemoteSigned"
        }
        "3" {
            Set-RecommendedPolicy -TargetScope "Process" -TargetPolicy "Bypass"
            Write-ColorOutput "Note: This setting is temporary and applies only to current PowerShell session" "Yellow"
        }
        "4" {
            $customScope = Read-Host "Enter scope (CurrentUser/LocalMachine/Process)"
            $customPolicy = Read-Host "Enter policy (RemoteSigned/Unrestricted/Bypass)"
            
            if ($customScope -in @('CurrentUser', 'LocalMachine', 'Process') -and 
                $customPolicy -in @('RemoteSigned', 'Unrestricted', 'Bypass')) {
                Set-RecommendedPolicy -TargetScope $customScope -TargetPolicy $customPolicy
            } else {
                Write-ColorOutput "Invalid scope or policy specified" "Red"
            }
        }
        "5" {
            Write-ColorOutput "No changes made" "Gray"
            return
        }
        default {
            Write-ColorOutput "Invalid selection" "Red"
            return
        }
    }
    
    Write-ColorOutput ""
    Write-ColorOutput "Updated execution policy:" "Yellow"
    Get-CurrentExecutionPolicy
}

# Main execution logic
if ($Temporary) {
    Write-ColorOutput "Setting temporary execution policy for current process..." "Yellow"
    Set-RecommendedPolicy -TargetScope "Process" -TargetPolicy "Bypass"
} elseif ($PSBoundParameters.ContainsKey('Policy')) {
    # Non-interactive mode with parameters
    Set-RecommendedPolicy -TargetScope $Scope -TargetPolicy $Policy
} else {
    # Interactive mode
    Start-InteractiveMode
}

Write-ColorOutput ""
Write-ColorOutput "Execution policy configuration completed!" "Green"
Write-ColorOutput "You can now run the VMware Tools Auto-Upgrade script." "White"