<#
.SYNOPSIS
    Batch execution example for VMware Tools Auto-Upgrade solution

.DESCRIPTION
    This example demonstrates how to execute the VMware Tools auto-upgrade
    script in batch mode for large enterprise environments with proper
    error handling, logging, and scheduling.

.NOTES
    Author: uldyssian-sh
    Version: 1.0
    Requires: VMware PowerCLI, Task Scheduler (for scheduling)
#>

# Configuration
$ScriptPath = Join-Path $PSScriptRoot "..\scripts\Enable-VMTools-AutoUpgrade-AllVMs.ps1"
$LogDirectory = "C:\Logs\VMTools-AutoUpgrade"
$vCenterServers = @(
    "vcenter-prod.example.com",
    "vcenter-dev.example.com",
    "vcenter-test.example.com"
)

# Batch configuration
$BatchSize = 25
$DelayBetweenBatches = 30  # seconds

# Create log directory if it doesn't exist
if (-not (Test-Path $LogDirectory)) {
    New-Item -Path $LogDirectory -ItemType Directory -Force
}

# Function to execute for single vCenter
function Invoke-VMToolsUpgrade {
    param(
        [string]$vCenterServer,
        [PSCredential]$Credential,
        [string]$LogPath,
        [int]$BatchSize = 25,
        [bool]$DryRun = $false
    )
    
    try {
        Write-Host "Processing vCenter: $vCenterServer" -ForegroundColor Green
        
        $params = @{
            vCenter = $vCenterServer
            Credential = $Credential
            BatchSize = $BatchSize
            LogPath = $LogPath
        }
        
        if ($DryRun) {
            $params.Add('DryRun', $true)
        }
        
        # Execute the main script
        & $ScriptPath @params -Force
        
        Write-Host "Completed processing: $vCenterServer" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Error "Failed to process $vCenterServer : $($_.Exception.Message)"
        return $false
    }
}

# Main execution function
function Start-BatchExecution {
    param(
        [bool]$DryRun = $true,
        [bool]$UseStoredCredentials = $false
    )
    
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $batchLogPath = Join-Path $LogDirectory "BatchExecution-$timestamp.log"
    
    # Start logging
    Start-Transcript -Path $batchLogPath -Append
    
    try {
        Write-Host "=== VMware Tools Auto-Upgrade Batch Execution ===" -ForegroundColor Cyan
        Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Cyan
        Write-Host "Mode: $(if ($DryRun) { 'DRY-RUN' } else { 'APPLY' })" -ForegroundColor Cyan
        Write-Host "Batch Size: $BatchSize VMs per batch" -ForegroundColor Cyan
        Write-Host "vCenter Servers: $($vCenterServers.Count)" -ForegroundColor Cyan
        Write-Host ""
        
        $results = @()
        
        foreach ($vCenter in $vCenterServers) {
            Write-Host "Processing vCenter: $vCenter" -ForegroundColor Yellow
            
            # Get credentials
            if ($UseStoredCredentials) {
                # Use Windows Credential Manager
                $credentialName = "vCenter-$($vCenter.Split('.')[0])"
                try {
                    $credential = Get-StoredCredential -Target $credentialName
                } catch {
                    Write-Warning "Stored credentials not found for $vCenter, prompting for credentials"
                    $credential = Get-Credential -Message "Enter credentials for $vCenter"
                }
            } else {
                $credential = Get-Credential -Message "Enter credentials for $vCenter"
            }
            
            # Execute for this vCenter
            $success = Invoke-VMToolsUpgrade -vCenterServer $vCenter -Credential $credential -LogPath $LogDirectory -BatchSize $BatchSize -DryRun $DryRun
            
            $results += [PSCustomObject]@{
                vCenter = $vCenter
                Success = $success
                Timestamp = Get-Date
            }
            
            # Delay between vCenter servers
            if ($vCenter -ne $vCenterServers[-1]) {
                Write-Host "Waiting $DelayBetweenBatches seconds before next vCenter..." -ForegroundColor Gray
                Start-Sleep -Seconds $DelayBetweenBatches
            }
        }
        
        # Summary
        Write-Host ""
        Write-Host "=== Batch Execution Summary ===" -ForegroundColor Cyan
        $successCount = ($results | Where-Object { $_.Success }).Count
        $failureCount = ($results | Where-Object { -not $_.Success }).Count
        
        Write-Host "Total vCenter Servers: $($results.Count)" -ForegroundColor White
        Write-Host "Successful: $successCount" -ForegroundColor Green
        Write-Host "Failed: $failureCount" -ForegroundColor Red
        
        if ($failureCount -gt 0) {
            Write-Host ""
            Write-Host "Failed vCenter Servers:" -ForegroundColor Red
            $results | Where-Object { -not $_.Success } | ForEach-Object {
                Write-Host "  - $($_.vCenter)" -ForegroundColor Red
            }
        }
        
        Write-Host ""
        Write-Host "Batch execution completed at: $(Get-Date)" -ForegroundColor Cyan
        Write-Host "Log file: $batchLogPath" -ForegroundColor Gray
        
    } finally {
        Stop-Transcript
    }
}

# Scheduled execution function
function Register-ScheduledExecution {
    param(
        [string]$TaskName = "VMTools-AutoUpgrade-Batch",
        [datetime]$ScheduleTime = (Get-Date).Date.AddDays(1).AddHours(2), # Tomorrow at 2 AM
        [bool]$DryRun = $false
    )
    
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -ScheduledExecution -DryRun:`$$DryRun"
    $trigger = New-ScheduledTaskTrigger -Once -At $ScheduleTime
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description "VMware Tools Auto-Upgrade Batch Execution"
    
    Write-Host "Scheduled task '$TaskName' registered for: $ScheduleTime" -ForegroundColor Green
}

# Command line parameter handling
param(
    [switch]$DryRun,
    [switch]$Apply,
    [switch]$ScheduledExecution,
    [switch]$UseStoredCredentials,
    [string]$ScheduleFor,
    [switch]$RegisterSchedule
)

# Main execution logic
if ($ScheduledExecution) {
    # Running as scheduled task
    Start-BatchExecution -DryRun:(-not $Apply) -UseStoredCredentials:$UseStoredCredentials
} elseif ($RegisterSchedule) {
    # Register scheduled task
    if ($ScheduleFor) {
        $scheduleTime = [datetime]::Parse($ScheduleFor)
    } else {
        $scheduleTime = (Get-Date).Date.AddDays(1).AddHours(2) # Default: tomorrow at 2 AM
    }
    Register-ScheduledExecution -ScheduleTime $scheduleTime -DryRun:(-not $Apply)
} else {
    # Interactive execution
    Write-Host "VMware Tools Auto-Upgrade Batch Execution" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "1. Run Dry-Run mode (recommended first)" -ForegroundColor White
    Write-Host "2. Run Apply mode (makes actual changes)" -ForegroundColor White
    Write-Host "3. Schedule for later execution" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Select option (1-3)"
    
    switch ($choice) {
        "1" {
            Start-BatchExecution -DryRun:$true -UseStoredCredentials:$UseStoredCredentials
        }
        "2" {
            $confirm = Read-Host "This will make actual changes to VMs. Continue? (Y/N)"
            if ($confirm -eq 'Y' -or $confirm -eq 'y') {
                Start-BatchExecution -DryRun:$false -UseStoredCredentials:$UseStoredCredentials
            }
        }
        "3" {
            $scheduleTime = Read-Host "Enter schedule time (MM/dd/yyyy HH:mm)"
            try {
                $parsedTime = [datetime]::Parse($scheduleTime)
                $mode = Read-Host "Schedule for (D)ry-run or (A)pply mode? (D/A)"
                $isDryRun = $mode -ne 'A' -and $mode -ne 'a'
                Register-ScheduledExecution -ScheduleTime $parsedTime -DryRun:$isDryRun
            } catch {
                Write-Error "Invalid date/time format. Use MM/dd/yyyy HH:mm"
            }
        }
        default {
            Write-Host "Invalid selection" -ForegroundColor Red
        }
    }
}

<#
.EXAMPLE
    # Interactive mode
    .\batch-execution.ps1

.EXAMPLE
    # Direct dry-run execution
    .\batch-execution.ps1 -DryRun

.EXAMPLE
    # Direct apply execution
    .\batch-execution.ps1 -Apply

.EXAMPLE
    # Schedule for specific time
    .\batch-execution.ps1 -RegisterSchedule -ScheduleFor "01/04/2025 02:00" -Apply

.EXAMPLE
    # Run as scheduled task (used by Task Scheduler)
    .\batch-execution.ps1 -ScheduledExecution -Apply -UseStoredCredentials
#>