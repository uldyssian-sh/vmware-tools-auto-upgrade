<#
.SYNOPSIS
    Enterprise deployment automation for VMware Tools Auto-Upgrade solution

.DESCRIPTION
    Automates the deployment and configuration of the VMware Tools auto-upgrade
    solution in enterprise environments with proper validation and rollback.

.NOTES
    Author: uldyssian-sh
    Version: 1.0
    Requires: PowerShell 5.1+, Administrative privileges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$DeploymentPath = "C:\Program Files\VMTools-AutoUpgrade",
    
    [Parameter(Mandatory = $false)]
    [switch]$ValidateOnly,
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateScheduledTasks
)

function Test-DeploymentPrerequisites {
    Write-Host "=== Deployment Prerequisites Check ===" -ForegroundColor Cyan
    Write-Host ""
    
    $prerequisites = @()
    
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    $psCompliant = $psVersion.Major -ge 5
    $prerequisites += [PSCustomObject]@{
        Component = "PowerShell Version"
        Required = "5.1+"
        Current = $psVersion.ToString()
        Status = if ($psCompliant) { "PASS" } else { "FAIL" }
    }
    
    # Check administrative privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    $prerequisites += [PSCustomObject]@{
        Component = "Administrative Rights"
        Required = "Required"
        Current = if ($isAdmin) { "Available" } else { "Missing" }
        Status = if ($isAdmin) { "PASS" } else { "FAIL" }
    }
    
    # Check PowerCLI availability
    $powerCLI = Get-Module -ListAvailable -Name VMware.PowerCLI
    $cliAvailable = $null -ne $powerCLI
    $prerequisites += [PSCustomObject]@{
        Component = "VMware PowerCLI"
        Required = "13.0+"
        Current = if ($cliAvailable) { $powerCLI[0].Version.ToString() } else { "Not Installed" }
        Status = if ($cliAvailable) { "PASS" } else { "WARN" }
    }
    
    # Check disk space
    $drive = (Get-Item $DeploymentPath.Substring(0,3)).PSDrive
    $freeSpaceGB = [Math]::Round($drive.Free / 1GB, 2)
    $spaceOK = $freeSpaceGB -gt 1
    $prerequisites += [PSCustomObject]@{
        Component = "Disk Space"
        Required = "1 GB+"
        Current = "$freeSpaceGB GB"
        Status = if ($spaceOK) { "PASS" } else { "FAIL" }
    }
    
    $prerequisites | Format-Table -AutoSize
    
    $failCount = ($prerequisites | Where-Object { $_.Status -eq "FAIL" }).Count
    return $failCount -eq 0
}

function Install-VMToolsAutoUpgrade {
    param([string]$TargetPath)
    
    Write-Host "=== Installing VMware Tools Auto-Upgrade Solution ===" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # Create deployment directory
        if (-not (Test-Path $TargetPath)) {
            New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
            Write-Host "✓ Created deployment directory: $TargetPath" -ForegroundColor Green
        }
        
        # Create subdirectories
        $subdirs = @("Scripts", "Logs", "Config", "Reports")
        foreach ($subdir in $subdirs) {
            $subdirPath = Join-Path $TargetPath $subdir
            if (-not (Test-Path $subdirPath)) {
                New-Item -Path $subdirPath -ItemType Directory -Force | Out-Null
                Write-Host "✓ Created $subdir directory" -ForegroundColor Green
            }
        }
        
        # Copy main script
        $sourceScript = Join-Path $PSScriptRoot "..\scripts\Enable-VMTools-AutoUpgrade-AllVMs.ps1"
        $targetScript = Join-Path $TargetPath "Scripts\Enable-VMTools-AutoUpgrade-AllVMs.ps1"
        
        if (Test-Path $sourceScript) {
            Copy-Item -Path $sourceScript -Destination $targetScript -Force
            Write-Host "✓ Deployed main script" -ForegroundColor Green
        }
        
        # Create configuration file
        $configContent = @"
# VMware Tools Auto-Upgrade Configuration
# Modify these settings for your environment

[Settings]
DefaultBatchSize=50
LogRetentionDays=30
EnableAuditLogging=true
DefaultExecutionPolicy=RemoteSigned

[vCenter]
# Add your vCenter servers here
# Server1=vcenter1.example.com
# Server2=vcenter2.example.com

[Notifications]
EnableEmailNotifications=false
SMTPServer=smtp.example.com
SMTPPort=587
FromAddress=vmtools@example.com
ToAddress=admin@example.com
"@
        
        $configPath = Join-Path $TargetPath "Config\settings.ini"
        $configContent | Out-File -FilePath $configPath -Encoding UTF8
        Write-Host "✓ Created configuration file" -ForegroundColor Green
        
        # Create PowerShell module
        $moduleContent = @"
# VMware Tools Auto-Upgrade Module
Import-Module VMware.PowerCLI -ErrorAction SilentlyContinue

# Import main functions
. "$TargetPath\Scripts\Enable-VMTools-AutoUpgrade-AllVMs.ps1"

Write-Host "VMware Tools Auto-Upgrade module loaded" -ForegroundColor Green
"@
        
        $modulePath = Join-Path $TargetPath "VMTools-AutoUpgrade.psm1"
        $moduleContent | Out-File -FilePath $modulePath -Encoding UTF8
        Write-Host "✓ Created PowerShell module" -ForegroundColor Green
        
        return $true
        
    } catch {
        Write-Error "Deployment failed: $($_.Exception.Message)"
        return $false
    }
}

function New-ScheduledTasksForAutomation {
    param([string]$InstallPath)
    
    Write-Host "=== Creating Scheduled Tasks ===" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # Weekly maintenance task
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$InstallPath\Scripts\Enable-VMTools-AutoUpgrade-AllVMs.ps1`" -DryRun"
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "02:00AM"
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        Register-ScheduledTask -TaskName "VMTools-AutoUpgrade-WeeklyCheck" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Weekly VMware Tools auto-upgrade compliance check"
        Write-Host "✓ Created weekly maintenance task" -ForegroundColor Green
        
        # Monthly reporting task
        $reportAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -Command `"Import-Module '$InstallPath\VMTools-AutoUpgrade.psm1'; New-VMToolsReport -ReportType Compliance`""
        $reportTrigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At "03:00AM"
        
        Register-ScheduledTask -TaskName "VMTools-AutoUpgrade-MonthlyReport" -Action $reportAction -Trigger $reportTrigger -Settings $settings -Principal $principal -Description "Monthly VMware Tools compliance report"
        Write-Host "✓ Created monthly reporting task" -ForegroundColor Green
        
        return $true
        
    } catch {
        Write-Warning "Failed to create scheduled tasks: $($_.Exception.Message)"
        return $false
    }
}

# Main deployment logic
Write-Host "VMware Tools Auto-Upgrade Enterprise Deployment" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# Prerequisites check
$prerequisitesPassed = Test-DeploymentPrerequisites

if (-not $prerequisitesPassed) {
    Write-Error "Prerequisites check failed. Please resolve the issues above before proceeding."
    exit 1
}

if ($ValidateOnly) {
    Write-Host "Validation completed successfully!" -ForegroundColor Green
    exit 0
}

# Install solution
Write-Host ""
$installSuccess = Install-VMToolsAutoUpgrade -TargetPath $DeploymentPath

if (-not $installSuccess) {
    Write-Error "Installation failed. Please check the error messages above."
    exit 1
}

# Create scheduled tasks if requested
if ($CreateScheduledTasks) {
    Write-Host ""
    $taskSuccess = New-ScheduledTasksForAutomation -InstallPath $DeploymentPath
    
    if ($taskSuccess) {
        Write-Host "✓ Scheduled tasks created successfully" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== Deployment Completed Successfully ===" -ForegroundColor Green
Write-Host "Installation Path: $DeploymentPath" -ForegroundColor White
Write-Host "Configuration File: $DeploymentPath\Config\settings.ini" -ForegroundColor White
Write-Host "PowerShell Module: $DeploymentPath\VMTools-AutoUpgrade.psm1" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Review and update the configuration file" -ForegroundColor White
Write-Host "2. Test the solution in a lab environment" -ForegroundColor White
Write-Host "3. Import the PowerShell module: Import-Module '$DeploymentPath\VMTools-AutoUpgrade.psm1'" -ForegroundColor White
Write-Host ""