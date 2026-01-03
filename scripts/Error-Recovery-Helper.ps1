<#
.SYNOPSIS
    Error recovery helper for VMware Tools Auto-Upgrade operations

.DESCRIPTION
    Provides advanced error handling, retry logic, and recovery mechanisms
    for enterprise VMware Tools auto-upgrade operations.

.NOTES
    Author: uldyssian-sh
    Version: 1.0
    Requires: VMware PowerCLI
#>

function Invoke-RetryOperation {
    param(
        [scriptblock]$Operation,
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 5
    )
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            return & $Operation
        } catch {
            if ($i -eq $MaxRetries) {
                throw
            }
            Write-Warning "Operation failed (attempt $i/$MaxRetries): $($_.Exception.Message)"
            Start-Sleep -Seconds $DelaySeconds
        }
    }
}

function Test-VMReconfigurationCapability {
    param([string]$VMName)
    
    try {
        $vm = Get-VM -Name $VMName -ErrorAction Stop
        return $vm.PowerState -eq 'PoweredOn' -and -not $vm.ExtensionData.Runtime.ConsolidationNeeded
    } catch {
        return $false
    }
}

Export-ModuleMember -Function @('Invoke-RetryOperation', 'Test-VMReconfigurationCapability')