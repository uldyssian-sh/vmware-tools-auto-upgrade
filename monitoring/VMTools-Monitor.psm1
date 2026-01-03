<#
.SYNOPSIS
    Monitoring and reporting module for VMware Tools Auto-Upgrade solution

.DESCRIPTION
    This PowerShell module provides monitoring, reporting, and analytics
    capabilities for the VMware Tools auto-upgrade solution in enterprise
    environments.

.NOTES
    Author: uldyssian-sh
    Version: 1.0
    Requires: VMware PowerCLI
#>

# Module variables
$script:LogPath = $null
$script:ReportPath = $null

function Initialize-VMToolsMonitoring {
    <#
    .SYNOPSIS
        Initialize monitoring configuration
    
    .PARAMETER LogPath
        Path for log files
        
    .PARAMETER ReportPath
        Path for report files
    #>
    [CmdletBinding()]
    param(
        [string]$LogPath = "C:\Logs\VMTools-Monitoring",
        [string]$ReportPath = "C:\Reports\VMTools"
    )
    
    $script:LogPath = $LogPath
    $script:ReportPath = $ReportPath
    
    # Create directories if they don't exist
    @($LogPath, $ReportPath) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -Path $_ -ItemType Directory -Force | Out-Null
        }
    }
    
    Write-Verbose "VMTools monitoring initialized - Logs: $LogPath, Reports: $ReportPath"
}

function Get-VMToolsStatus {
    <#
    .SYNOPSIS
        Get comprehensive VMware Tools status across all VMs
    
    .PARAMETER vCenter
        vCenter Server to query
        
    .PARAMETER Credential
        vCenter credentials
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$vCenter,
        
        [Parameter(Mandatory = $false)]
        [PSCredential]$Credential
    )
    
    try {
        # Connect to vCenter
        if ($Credential) {
            $connection = Connect-VIServer -Server $vCenter -Credential $Credential -ErrorAction Stop
        } else {
            $connection = Connect-VIServer -Server $vCenter -ErrorAction Stop
        }
        
        Write-Verbose "Connected to vCenter: $vCenter"
        
        # Get all VMs with Tools information
        $vms = Get-VM | Select-Object @{
            Name = 'VMName'
            Expression = { $_.Name }
        }, @{
            Name = 'PowerState'
            Expression = { $_.PowerState }
        }, @{
            Name = 'ToolsStatus'
            Expression = { $_.ExtensionData.Guest.ToolsStatus }
        }, @{
            Name = 'ToolsVersion'
            Expression = { $_.ExtensionData.Guest.ToolsVersion }
        }, @{
            Name = 'ToolsUpgradePolicy'
            Expression = { $_.ExtensionData.Config.Tools.ToolsUpgradePolicy }
        }, @{
            Name = 'GuestOS'
            Expression = { $_.Guest.OSFullName }
        }, @{
            Name = 'Cluster'
            Expression = { (Get-Cluster -VM $_).Name }
        }, @{
            Name = 'Host'
            Expression = { $_.VMHost.Name }
        }, @{
            Name = 'LastBootTime'
            Expression = { $_.ExtensionData.Runtime.BootTime }
        }, @{
            Name = 'Timestamp'
            Expression = { Get-Date }
        }
        
        # Disconnect from vCenter
        Disconnect-VIServer -Server $connection -Confirm:$false
        
        return $vms
        
    } catch {
        Write-Error "Failed to get VMware Tools status: $($_.Exception.Message)"
        return $null
    }
}

function New-VMToolsReport {
    <#
    .SYNOPSIS
        Generate comprehensive VMware Tools status report
    
    .PARAMETER VMData
        VM data from Get-VMToolsStatus
        
    .PARAMETER ReportType
        Type of report (Summary, Detailed, Compliance)
        
    .PARAMETER OutputFormat
        Output format (HTML, CSV, JSON)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$VMData,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Summary', 'Detailed', 'Compliance')]
        [string]$ReportType = 'Summary',
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('HTML', 'CSV', 'JSON')]
        [string]$OutputFormat = 'HTML'
    )
    
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $reportName = "VMTools-Report-$ReportType-$timestamp"
    
    switch ($ReportType) {
        'Summary' {
            $report = New-SummaryReport -VMData $VMData
        }
        'Detailed' {
            $report = New-DetailedReport -VMData $VMData
        }
        'Compliance' {
            $report = New-ComplianceReport -VMData $VMData
        }
    }
    
    # Output report in specified format
    $outputPath = Join-Path $script:ReportPath "$reportName.$($OutputFormat.ToLower())"
    
    switch ($OutputFormat) {
        'HTML' {
            $report | ConvertTo-Html -Title "VMware Tools Report - $ReportType" | Out-File -FilePath $outputPath
        }
        'CSV' {
            $report | Export-Csv -Path $outputPath -NoTypeInformation
        }
        'JSON' {
            $report | ConvertTo-Json -Depth 3 | Out-File -FilePath $outputPath
        }
    }
    
    Write-Output "Report generated: $outputPath"
    return $outputPath
}

function New-SummaryReport {
    param([array]$VMData)
    
    $summary = [PSCustomObject]@{
        ReportType = 'Summary'
        GeneratedAt = Get-Date
        TotalVMs = $VMData.Count
        PoweredOnVMs = ($VMData | Where-Object { $_.PowerState -eq 'PoweredOn' }).Count
        PoweredOffVMs = ($VMData | Where-Object { $_.PowerState -eq 'PoweredOff' }).Count
        ToolsOK = ($VMData | Where-Object { $_.ToolsStatus -eq 'toolsOk' }).Count
        ToolsOld = ($VMData | Where-Object { $_.ToolsStatus -eq 'toolsOld' }).Count
        ToolsNotInstalled = ($VMData | Where-Object { $_.ToolsStatus -eq 'toolsNotInstalled' }).Count
        ToolsNotRunning = ($VMData | Where-Object { $_.ToolsStatus -eq 'toolsNotRunning' }).Count
        AutoUpgradeEnabled = ($VMData | Where-Object { $_.ToolsUpgradePolicy -eq 'upgradeAtPowerCycle' }).Count
        AutoUpgradeDisabled = ($VMData | Where-Object { $_.ToolsUpgradePolicy -ne 'upgradeAtPowerCycle' }).Count
    }
    
    return $summary
}

function New-DetailedReport {
    param([array]$VMData)
    
    return $VMData | Select-Object VMName, PowerState, ToolsStatus, ToolsVersion, 
                                  ToolsUpgradePolicy, GuestOS, Cluster, Host, 
                                  LastBootTime, Timestamp
}

function New-ComplianceReport {
    param([array]$VMData)
    
    $compliance = $VMData | ForEach-Object {
        $compliant = $_.ToolsUpgradePolicy -eq 'upgradeAtPowerCycle' -and 
                     $_.ToolsStatus -in @('toolsOk', 'toolsNotRunning')
        
        [PSCustomObject]@{
            VMName = $_.VMName
            PowerState = $_.PowerState
            ToolsStatus = $_.ToolsStatus
            ToolsUpgradePolicy = $_.ToolsUpgradePolicy
            Compliant = $compliant
            Issues = if (-not $compliant) {
                $issues = @()
                if ($_.ToolsUpgradePolicy -ne 'upgradeAtPowerCycle') {
                    $issues += 'Auto-upgrade not enabled'
                }
                if ($_.ToolsStatus -eq 'toolsOld') {
                    $issues += 'Tools version outdated'
                }
                if ($_.ToolsStatus -eq 'toolsNotInstalled') {
                    $issues += 'Tools not installed'
                }
                $issues -join '; '
            } else {
                'None'
            }
            Cluster = $_.Cluster
            Host = $_.Host
        }
    }
    
    return $compliance
}

function Start-VMToolsMonitoring {
    <#
    .SYNOPSIS
        Start continuous monitoring of VMware Tools status
    
    .PARAMETER vCenters
        Array of vCenter servers to monitor
        
    .PARAMETER Interval
        Monitoring interval in minutes
        
    .PARAMETER MaxIterations
        Maximum number of monitoring iterations (0 = infinite)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$vCenters,
        
        [Parameter(Mandatory = $false)]
        [int]$Interval = 60,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxIterations = 0
    )
    
    $iteration = 0
    
    do {
        $iteration++
        Write-Host "Starting monitoring iteration $iteration at $(Get-Date)" -ForegroundColor Green
        
        foreach ($vCenter in $vCenters) {
            try {
                Write-Host "Monitoring vCenter: $vCenter" -ForegroundColor Yellow
                
                $vmData = Get-VMToolsStatus -vCenter $vCenter
                if ($vmData) {
                    # Generate reports
                    $summaryReport = New-VMToolsReport -VMData $vmData -ReportType 'Summary' -OutputFormat 'JSON'
                    $complianceReport = New-VMToolsReport -VMData $vmData -ReportType 'Compliance' -OutputFormat 'CSV'
                    
                    Write-Host "  Reports generated for $vCenter" -ForegroundColor Green
                } else {
                    Write-Warning "Failed to collect data from $vCenter"
                }
                
            } catch {
                Write-Error "Error monitoring $vCenter : $($_.Exception.Message)"
            }
        }
        
        if ($MaxIterations -eq 0 -or $iteration -lt $MaxIterations) {
            Write-Host "Waiting $Interval minutes until next iteration..." -ForegroundColor Gray
            Start-Sleep -Seconds ($Interval * 60)
        }
        
    } while ($MaxIterations -eq 0 -or $iteration -lt $MaxIterations)
    
    Write-Host "Monitoring completed after $iteration iterations" -ForegroundColor Green
}

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-VMToolsMonitoring',
    'Get-VMToolsStatus',
    'New-VMToolsReport',
    'Start-VMToolsMonitoring'
)