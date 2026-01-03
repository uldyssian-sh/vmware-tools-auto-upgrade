<#
.SYNOPSIS
    Bulk-enable VMware Tools auto-upgrade on power-on for all VMs in vCenter.

.DESCRIPTION
    This script enables VMware Tools auto-upgrade on power-on for all virtual machines
    in a vCenter environment. It provides both dry-run and apply modes for safe execution,
    with comprehensive before/after reporting and error handling.

.PARAMETER vCenter
    The vCenter Server FQDN or IP address (optional - will prompt if not provided)

.PARAMETER Credential
    PSCredential object for vCenter authentication (optional - will prompt if not provided)

.PARAMETER DryRun
    Switch parameter to run in dry-run mode (no changes applied)

.PARAMETER Force
    Switch parameter to skip confirmation prompts

.EXAMPLE
    .\Enable-VMTools-AutoUpgrade-AllVMs.ps1
    Interactive mode with prompts for vCenter and credentials

.EXAMPLE
    .\Enable-VMTools-AutoUpgrade-AllVMs.ps1 -vCenter "vcenter.example.com" -DryRun
    Dry-run mode with specified vCenter server

.EXAMPLE
    $cred = Get-Credential
    .\Enable-VMTools-AutoUpgrade-AllVMs.ps1 -vCenter "vcenter.example.com" -Credential $cred -Force
    Apply mode with credentials and no confirmation prompts

.NOTES
    Author: uldyssian-sh
    Version: 1.0
    Requires: VMware PowerCLI
    
.LINK
    https://github.com/uldyssian-sh/vmware-tools-auto-upgrade
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$vCenter,
    
    [Parameter(Mandatory = $false)]
    [PSCredential]$Credential,
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [int]$BatchSize = 50,
    
    [Parameter(Mandatory = $false)]
    [string]$LogPath = $null
)

# Script configuration
$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"

# Initialize logging
$LogFile = "VMTools-AutoUpgrade-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$LogPath = Join-Path $PSScriptRoot $LogFile

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Write-Output $LogEntry | Tee-Object -FilePath $LogPath -Append
}

function Test-PowerCLI {
    <#
    .SYNOPSIS
        Validates PowerCLI availability and configuration
    #>
    Write-Log "Checking PowerCLI availability..."
    
    if (-not (Get-Command Connect-VIServer -ErrorAction SilentlyContinue)) {
        Write-Error "PowerCLI not loaded. Please run: Import-Module VMware.PowerCLI"
        return $false
    }
    
    # Configure PowerCLI settings for enterprise environments
    try {
        Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false | Out-Null
        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
        Write-Log "PowerCLI configuration updated successfully"
        return $true
    }
    catch {
        Write-Log "Warning: Could not update PowerCLI configuration: $($_.Exception.Message)" "WARN"
        return $true  # Continue execution even if configuration fails
    }
}

function Connect-vCenterServer {
    <#
    .SYNOPSIS
        Establishes connection to vCenter Server
    #>
    param(
        [string]$Server,
        [PSCredential]$Cred
    )
    
    Write-Log "Connecting to vCenter Server: $Server"
    
    try {
        $connection = Connect-VIServer -Server $Server -Credential $Cred -ErrorAction Stop
        Write-Log "Successfully connected to vCenter: $($connection.Name)"
        return $connection
    }
    catch {
        Write-Log "Failed to connect to vCenter: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Get-VMToolsStatus {
    <#
    .SYNOPSIS
        Retrieves current VMware Tools upgrade policy for all VMs
    #>
    Write-Log "Collecting current VMware Tools status for all VMs..."
    
    try {
        $vms = Get-VM
        Write-Log "Found $($vms.Count) virtual machines"
        
        $vmStatus = foreach ($vm in $vms) {
            $policy = $null
            try {
                $policy = $vm.ExtensionData.Config.Tools.ToolsUpgradePolicy
            }
            catch {
                Write-Log "Warning: Could not retrieve Tools policy for VM: $($vm.Name)" "WARN"
            }
            
            [PSCustomObject]@{
                VMName             = $vm.Name
                PowerState         = $vm.PowerState
                ToolsUpgradePolicy = $policy
                ToolsStatus        = $vm.ExtensionData.Guest.ToolsStatus
                ToolsVersion       = $vm.ExtensionData.Guest.ToolsVersion
                VMObject           = $vm
            }
        }
        
        Write-Log "Successfully collected status for $($vmStatus.Count) VMs"
        return $vmStatus
    }
    catch {
        Write-Log "Error collecting VM status: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Show-VMStatus {
    <#
    .SYNOPSIS
        Displays VM status in formatted table
    #>
    param(
        [array]$VMStatus,
        [string]$Title
    )
    
    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
    $VMStatus |
        Select-Object VMName, PowerState, ToolsUpgradePolicy, ToolsStatus |
        Sort-Object VMName |
        Format-Table -AutoSize
}

function Get-TargetVMs {
    <#
    .SYNOPSIS
        Identifies VMs that need Tools auto-upgrade configuration
    #>
    param([array]$AllVMs)
    
    $targets = $AllVMs | Where-Object { 
        $_.ToolsUpgradePolicy -ne "upgradeAtPowerCycle" 
    }
    
    Write-Log "Identified $($targets.Count) VMs requiring Tools auto-upgrade configuration"
    return $targets
}

function Set-VMToolsAutoUpgrade {
    <#
    .SYNOPSIS
        Applies VMware Tools auto-upgrade configuration to target VMs
    #>
    param([array]$TargetVMs)
    
    Write-Log "Starting VMware Tools auto-upgrade configuration for $($TargetVMs.Count) VMs"
    $successCount = 0
    $failureCount = 0
    
    foreach ($target in $TargetVMs) {
        $vmObj = $target.VMObject
        $vmExt = $vmObj.ExtensionData
        
        try {
            # Create minimal ConfigSpec affecting only Tools.ToolsUpgradePolicy
            $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
            $spec.Tools = New-Object VMware.Vim.ToolsConfigInfo
            $spec.Tools.ToolsUpgradePolicy = "upgradeAtPowerCycle"
            
            # Apply configuration change
            $vmExt.ReconfigVM($spec)
            
            Write-Host ("  ✓ SUCCESS - {0}" -f $vmObj.Name) -ForegroundColor Green
            Write-Log "Successfully configured auto-upgrade for VM: $($vmObj.Name)"
            $successCount++
        }
        catch {
            Write-Host ("  ✗ FAILED  - {0}: {1}" -f $vmObj.Name, $_.Exception.Message) -ForegroundColor Red
            Write-Log "Failed to configure VM: $($vmObj.Name) - $($_.Exception.Message)" "ERROR"
            $failureCount++
        }
    }
    
    Write-Log "Configuration complete. Success: $successCount, Failures: $failureCount"
    return @{
        Success = $successCount
        Failure = $failureCount
    }
}

function Show-ChangesSummary {
    <#
    .SYNOPSIS
        Displays before/after comparison for affected VMs
    #>
    param(
        [array]$BeforeState,
        [array]$AfterState
    )
    
    Write-Host "`n=== BEFORE / AFTER COMPARISON ===" -ForegroundColor Cyan
    
    $comparison = foreach ($before in $BeforeState) {
        $after = $AfterState | Where-Object { $_.VMName -eq $before.VMName }
        
        [PSCustomObject]@{
            VMName  = $before.VMName
            Before  = $before.ToolsUpgradePolicy
            After   = if ($after) { $after.ToolsUpgradePolicy } else { "N/A" }
            Changed = if ($after -and $after.ToolsUpgradePolicy -ne $before.ToolsUpgradePolicy) { "✓ YES" } else { "✗ NO" }
        }
    }
    
    $comparison | Sort-Object VMName | Format-Table -AutoSize
    
    $changedCount = ($comparison | Where-Object { $_.Changed -eq "✓ YES" }).Count
    Write-Host "Total VMs changed: $changedCount" -ForegroundColor Green
}

# Main execution block
try {
    Clear-Host
    Write-Host "=== VMware Tools Auto-Upgrade on Power-On (Enterprise Solution) ===" -ForegroundColor Cyan
    Write-Log "Script execution started"
    
    # Validate PowerCLI
    if (-not (Test-PowerCLI)) {
        exit 1
    }
    
    # Get vCenter connection details
    if (-not $vCenter) {
        $vCenter = (Read-Host "Enter vCenter FQDN or IP").Trim()
        if (-not $vCenter) {
            Write-Error "No vCenter server specified"
            exit 1
        }
    }
    
    if (-not $Credential) {
        $Credential = Get-Credential -Message "Enter vCenter credentials"
        if (-not $Credential) {
            Write-Error "No credentials provided"
            exit 1
        }
    }
    
    # Determine execution mode
    if (-not $DryRun -and -not $PSBoundParameters.ContainsKey('DryRun')) {
        $mode = (Read-Host "Execution mode: (D)ry-run or (A)pply [D/A]").Trim().ToUpper()
        if ($mode -notin @("D", "A")) { $mode = "D" }
        $DryRun = $mode -eq "D"
    }
    
    if ($DryRun) {
        Write-Host "`nDRY-RUN MODE: No changes will be applied" -ForegroundColor Yellow
        Write-Log "Executing in dry-run mode"
    } else {
        Write-Host "`nAPPLY MODE: Changes will be applied to matching VMs" -ForegroundColor Yellow
        Write-Log "Executing in apply mode"
    }
    
    # Connect to vCenter
    $viConnection = Connect-vCenterServer -Server $vCenter -Cred $Credential
    
    # Collect current state
    $beforeState = Get-VMToolsStatus
    Show-VMStatus -VMStatus $beforeState -Title "CURRENT STATE (All VMs)"
    
    # Identify target VMs
    $targetVMs = Get-TargetVMs -AllVMs $beforeState
    
    if (-not $targetVMs) {
        Write-Host "`n✓ All VMs already have VMware Tools auto-upgrade enabled" -ForegroundColor Green
        Write-Log "No VMs require configuration changes"
    } else {
        Write-Host "`nVMs requiring auto-upgrade configuration:" -ForegroundColor Yellow
        Show-VMStatus -VMStatus $targetVMs -Title "TARGET VMs (Requiring Changes)"
        Write-Host ("Total VMs to be configured: {0}" -f $targetVMs.Count) -ForegroundColor Yellow
        
        if ($DryRun) {
            Write-Host "`n✓ DRY-RUN COMPLETE: No changes were applied" -ForegroundColor Yellow
            Write-Log "Dry-run completed successfully"
        } else {
            # Confirmation for apply mode
            if (-not $Force) {
                $confirmation = Read-Host "`nProceed with enabling auto-upgrade on these VMs? (Y/N)"
                if ($confirmation -notin @("Y", "YES", "y", "yes")) {
                    Write-Host "Operation cancelled by user" -ForegroundColor Yellow
                    Write-Log "Operation cancelled by user"
                    exit 0
                }
            }
            
            # Apply changes
            Write-Host "`nApplying VMware Tools auto-upgrade configuration..." -ForegroundColor Cyan
            $results = Set-VMToolsAutoUpgrade -TargetVMs $targetVMs
            
            # Collect after state for affected VMs
            Start-Sleep -Seconds 2  # Allow time for changes to propagate
            $affectedVMNames = $targetVMs.VMName
            $afterState = Get-VMToolsStatus | Where-Object { $_.VMName -in $affectedVMNames }
            
            Show-VMStatus -VMStatus $afterState -Title "UPDATED STATE (Affected VMs)"
            Show-ChangesSummary -BeforeState $targetVMs -AfterState $afterState
            
            Write-Host "`n✓ OPERATION COMPLETE" -ForegroundColor Green
            Write-Host "  - Successful configurations: $($results.Success)" -ForegroundColor Green
            Write-Host "  - Failed configurations: $($results.Failure)" -ForegroundColor $(if ($results.Failure -gt 0) { "Red" } else { "Green" })
            
            Write-Log "Operation completed. Success: $($results.Success), Failures: $($results.Failure)"
        }
    }
}
catch {
    Write-Host "`n✗ SCRIPT ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Log "Script execution failed: $($_.Exception.Message)" "ERROR"
    exit 1
}
finally {
    # Cleanup
    if ($viConnection) {
        Disconnect-VIServer -Confirm:$false | Out-Null
        Write-Log "Disconnected from vCenter Server"
    }
    
    Write-Host "`nLog file created: $LogPath" -ForegroundColor Gray
    Write-Log "Script execution completed"
}