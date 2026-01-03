#Requires -Version 5.1
#Requires -Modules VMware.PowerCLI

<#
.SYNOPSIS
    Performance monitoring and optimization module for VMware Tools Auto-Upgrade operations.

.DESCRIPTION
    This module provides comprehensive performance monitoring, metrics collection, and optimization
    recommendations for bulk VMware Tools auto-upgrade operations in enterprise environments.

.PARAMETER VCenterServer
    The vCenter Server FQDN or IP address to monitor.

.PARAMETER MonitoringDuration
    Duration in minutes to monitor performance metrics (default: 30 minutes).

.PARAMETER OutputPath
    Path to save performance reports and metrics (default: ./reports).

.PARAMETER EnableRealTimeMonitoring
    Enable real-time performance monitoring during operations.

.EXAMPLE
    .\Performance-Monitor.ps1 -VCenterServer "vcenter.example.com" -MonitoringDuration 60

.EXAMPLE
    .\Performance-Monitor.ps1 -VCenterServer "vcenter.example.com" -EnableRealTimeMonitoring

.NOTES
    Author: uldyssian-sh
    Version: 1.0.0
    Requires: VMware PowerCLI 13.0.0 or later
    Enterprise-grade performance monitoring for VMware Tools automation
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VCenterServer,
    
    [Parameter(Mandatory = $false)]
    [int]$MonitoringDuration = 30,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./reports",
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableRealTimeMonitoring
)

# Initialize performance monitoring
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Performance metrics collection
class PerformanceMetrics {
    [datetime]$Timestamp
    [double]$CPUUsagePercent
    [double]$MemoryUsagePercent
    [double]$NetworkLatencyMs
    [int]$ActiveVMOperations
    [int]$QueuedOperations
    [double]$OperationThroughput
    [string]$PerformanceStatus
}

# Performance monitoring functions
function Initialize-PerformanceMonitoring {
    param(
        [string]$VCenter,
        [string]$ReportPath
    )
    
    Write-Host "=== VMware Tools Auto-Upgrade Performance Monitor ===" -ForegroundColor Cyan
    Write-Host "Initializing performance monitoring for: $VCenter" -ForegroundColor Green
    
    # Create reports directory
    if (-not (Test-Path $ReportPath)) {
        New-Item -Path $ReportPath -ItemType Directory -Force | Out-Null
        Write-Host "Created reports directory: $ReportPath" -ForegroundColor Yellow
    }
    
    # Initialize performance counters
    $script:PerformanceData = @()
    $script:StartTime = Get-Date
    $script:OperationCount = 0
    
    Write-Host "Performance monitoring initialized successfully" -ForegroundColor Green
}

function Get-VCenterPerformanceMetrics {
    param(
        [string]$VCenter
    )
    
    try {
        # Collect vCenter performance metrics
        $vcStats = Get-Stat -Entity (Get-VMHost) -Stat "cpu.usage.average","mem.usage.average" -Realtime -MaxSamples 1
        
        $cpuUsage = ($vcStats | Where-Object {$_.MetricId -eq "cpu.usage.average"} | Measure-Object -Property Value -Average).Average
        $memUsage = ($vcStats | Where-Object {$_.MetricId -eq "mem.usage.average"} | Measure-Object -Property Value -Average).Average
        
        # Network latency test
        $latency = Test-Connection -ComputerName $VCenter -Count 1 | Select-Object -ExpandProperty ResponseTime
        
        # Active operations count
        $activeTasks = Get-Task -Status Running | Measure-Object | Select-Object -ExpandProperty Count
        
        # Create performance metrics object
        $metrics = [PerformanceMetrics]::new()
        $metrics.Timestamp = Get-Date
        $metrics.CPUUsagePercent = [math]::Round($cpuUsage, 2)
        $metrics.MemoryUsagePercent = [math]::Round($memUsage, 2)
        $metrics.NetworkLatencyMs = $latency
        $metrics.ActiveVMOperations = $activeTasks
        $metrics.QueuedOperations = 0  # Placeholder for queue monitoring
        $metrics.OperationThroughput = [math]::Round($script:OperationCount / ((Get-Date) - $script:StartTime).TotalMinutes, 2)
        
        # Determine performance status
        if ($cpuUsage -gt 80 -or $memUsage -gt 85 -or $latency -gt 100) {
            $metrics.PerformanceStatus = "Critical"
        } elseif ($cpuUsage -gt 60 -or $memUsage -gt 70 -or $latency -gt 50) {
            $metrics.PerformanceStatus = "Warning"
        } else {
            $metrics.PerformanceStatus = "Optimal"
        }
        
        return $metrics
    }
    catch {
        Write-Warning "Failed to collect performance metrics: $($_.Exception.Message)"
        return $null
    }
}

function Start-PerformanceMonitoring {
    param(
        [string]$VCenter,
        [int]$Duration,
        [string]$ReportPath,
        [bool]$RealTime
    )
    
    Write-Host "Starting performance monitoring for $Duration minutes..." -ForegroundColor Yellow
    
    $endTime = (Get-Date).AddMinutes($Duration)
    $sampleInterval = if ($RealTime) { 10 } else { 60 }  # seconds
    
    while ((Get-Date) -lt $endTime) {
        $metrics = Get-VCenterPerformanceMetrics -VCenter $VCenter
        
        if ($metrics) {
            $script:PerformanceData += $metrics
            
            if ($RealTime) {
                Write-Host "[$($metrics.Timestamp.ToString('HH:mm:ss'))] CPU: $($metrics.CPUUsagePercent)% | Memory: $($metrics.MemoryUsagePercent)% | Latency: $($metrics.NetworkLatencyMs)ms | Status: $($metrics.PerformanceStatus)" -ForegroundColor $(
                    switch ($metrics.PerformanceStatus) {
                        "Optimal" { "Green" }
                        "Warning" { "Yellow" }
                        "Critical" { "Red" }
                    }
                )
            }
            
            # Performance alerts
            if ($metrics.PerformanceStatus -eq "Critical") {
                Write-Warning "CRITICAL: Performance degradation detected! Consider reducing batch size or scheduling during off-hours."
            }
        }
        
        Start-Sleep -Seconds $sampleInterval
    }
    
    Write-Host "Performance monitoring completed" -ForegroundColor Green
}

function Generate-PerformanceReport {
    param(
        [string]$ReportPath,
        [string]$VCenter
    )
    
    if ($script:PerformanceData.Count -eq 0) {
        Write-Warning "No performance data collected"
        return
    }
    
    Write-Host "Generating performance report..." -ForegroundColor Yellow
    
    # Calculate statistics
    $avgCPU = ($script:PerformanceData | Measure-Object -Property CPUUsagePercent -Average).Average
    $maxCPU = ($script:PerformanceData | Measure-Object -Property CPUUsagePercent -Maximum).Maximum
    $avgMemory = ($script:PerformanceData | Measure-Object -Property MemoryUsagePercent -Average).Average
    $maxMemory = ($script:PerformanceData | Measure-Object -Property MemoryUsagePercent -Maximum).Maximum
    $avgLatency = ($script:PerformanceData | Measure-Object -Property NetworkLatencyMs -Average).Average
    $maxLatency = ($script:PerformanceData | Measure-Object -Property NetworkLatencyMs -Maximum).Maximum
    
    # Performance status distribution
    $statusCounts = $script:PerformanceData | Group-Object -Property PerformanceStatus | Select-Object Name, Count
    
    # Generate report content
    $reportContent = @"
# VMware Tools Auto-Upgrade Performance Report

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**vCenter Server**: $VCenter
**Monitoring Duration**: $((Get-Date) - $script:StartTime)
**Total Samples**: $($script:PerformanceData.Count)

## Performance Summary

### CPU Usage
- **Average**: $([math]::Round($avgCPU, 2))%
- **Maximum**: $([math]::Round($maxCPU, 2))%

### Memory Usage
- **Average**: $([math]::Round($avgMemory, 2))%
- **Maximum**: $([math]::Round($maxMemory, 2))%

### Network Latency
- **Average**: $([math]::Round($avgLatency, 2))ms
- **Maximum**: $([math]::Round($maxLatency, 2))ms

### Performance Status Distribution
$($statusCounts | ForEach-Object { "- **$($_.Name)**: $($_.Count) samples" } | Out-String)

## Recommendations

$(if ($maxCPU -gt 80) { "⚠️ **High CPU Usage Detected**: Consider reducing batch size or scheduling operations during off-peak hours.`n" })
$(if ($maxMemory -gt 85) { "⚠️ **High Memory Usage Detected**: Monitor vCenter memory usage and consider increasing vCenter resources.`n" })
$(if ($maxLatency -gt 100) { "⚠️ **High Network Latency Detected**: Check network connectivity and consider running operations from a system closer to vCenter.`n" })
$(if ($maxCPU -le 60 -and $maxMemory -le 70 -and $maxLatency -le 50) { "✅ **Optimal Performance**: System performance is within acceptable ranges for bulk operations.`n" })

## Optimization Tips

1. **Batch Size Optimization**: For environments with >1000 VMs, use batch sizes of 25-50 VMs
2. **Timing**: Schedule bulk operations during maintenance windows
3. **Resource Monitoring**: Monitor vCenter resources during large operations
4. **Network Optimization**: Ensure low-latency connection to vCenter
5. **Parallel Processing**: Consider parallel processing for large environments (vSphere 7.0+)

## Detailed Metrics

| Timestamp | CPU % | Memory % | Latency (ms) | Active Ops | Status |
|-----------|-------|----------|--------------|------------|--------|
$($script:PerformanceData | ForEach-Object { "| $($_.Timestamp.ToString('HH:mm:ss')) | $($_.CPUUsagePercent) | $($_.MemoryUsagePercent) | $($_.NetworkLatencyMs) | $($_.ActiveVMOperations) | $($_.PerformanceStatus) |" } | Out-String)

---
**Report Generated by**: VMware Tools Auto-Upgrade Performance Monitor
**Author**: uldyssian-sh
"@

    # Save report
    $reportFile = Join-Path $ReportPath "performance-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    $reportContent | Out-File -FilePath $reportFile -Encoding UTF8
    
    Write-Host "Performance report saved: $reportFile" -ForegroundColor Green
    
    # Export raw data to CSV
    $csvFile = Join-Path $ReportPath "performance-data-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    $script:PerformanceData | Export-Csv -Path $csvFile -NoTypeInformation
    
    Write-Host "Raw performance data exported: $csvFile" -ForegroundColor Green
}

function Get-OptimizationRecommendations {
    param(
        [string]$VCenter
    )
    
    Write-Host "=== Performance Optimization Recommendations ===" -ForegroundColor Cyan
    
    try {
        # Get environment information
        $vmCount = (Get-VM).Count
        $hostCount = (Get-VMHost).Count
        $datastoreCount = (Get-Datastore).Count
        
        Write-Host "Environment Analysis:" -ForegroundColor Yellow
        Write-Host "- Total VMs: $vmCount"
        Write-Host "- ESXi Hosts: $hostCount"
        Write-Host "- Datastores: $datastoreCount"
        
        # Provide recommendations based on environment size
        Write-Host "`nOptimization Recommendations:" -ForegroundColor Yellow
        
        if ($vmCount -lt 100) {
            Write-Host "✅ Small Environment (< 100 VMs):" -ForegroundColor Green
            Write-Host "  - Batch size: 10-25 VMs"
            Write-Host "  - Expected duration: 5-15 minutes"
            Write-Host "  - Resource impact: Minimal"
        }
        elseif ($vmCount -lt 500) {
            Write-Host "⚠️ Medium Environment (100-500 VMs):" -ForegroundColor Yellow
            Write-Host "  - Batch size: 25-50 VMs"
            Write-Host "  - Expected duration: 15-45 minutes"
            Write-Host "  - Resource impact: Moderate"
            Write-Host "  - Recommendation: Schedule during maintenance window"
        }
        elseif ($vmCount -lt 1000) {
            Write-Host "🔶 Large Environment (500-1000 VMs):" -ForegroundColor DarkYellow
            Write-Host "  - Batch size: 25-50 VMs"
            Write-Host "  - Expected duration: 45-90 minutes"
            Write-Host "  - Resource impact: High"
            Write-Host "  - Recommendation: Schedule during off-hours, monitor performance"
        }
        else {
            Write-Host "🔴 Enterprise Environment (1000+ VMs):" -ForegroundColor Red
            Write-Host "  - Batch size: 25-50 VMs (conservative)"
            Write-Host "  - Expected duration: 90+ minutes"
            Write-Host "  - Resource impact: Very High"
            Write-Host "  - Recommendation: Mandatory maintenance window, performance monitoring"
            Write-Host "  - Consider: Phased rollout across multiple sessions"
        }
        
        Write-Host "`nGeneral Best Practices:" -ForegroundColor Yellow
        Write-Host "- Always run dry-run mode first"
        Write-Host "- Monitor vCenter performance during operations"
        Write-Host "- Ensure adequate vCenter resources (CPU, Memory)"
        Write-Host "- Use low-latency network connection"
        Write-Host "- Schedule during low-activity periods"
        Write-Host "- Have rollback plan ready"
        
    }
    catch {
        Write-Warning "Failed to analyze environment: $($_.Exception.Message)"
    }
}

# Main execution
try {
    # Connect to vCenter if not already connected
    if (-not $global:DefaultVIServer -or $global:DefaultVIServer.Name -ne $VCenterServer) {
        Write-Host "Connecting to vCenter: $VCenterServer" -ForegroundColor Yellow
        $credential = Get-Credential -Message "Enter vCenter credentials"
        Connect-VIServer -Server $VCenterServer -Credential $credential -Force | Out-Null
    }
    
    # Initialize monitoring
    Initialize-PerformanceMonitoring -VCenter $VCenterServer -ReportPath $OutputPath
    
    # Get optimization recommendations
    Get-OptimizationRecommendations -VCenter $VCenterServer
    
    # Start performance monitoring if requested
    if ($MonitoringDuration -gt 0) {
        Start-PerformanceMonitoring -VCenter $VCenterServer -Duration $MonitoringDuration -ReportPath $OutputPath -RealTime $EnableRealTimeMonitoring
        Generate-PerformanceReport -ReportPath $OutputPath -VCenter $VCenterServer
    }
    
    Write-Host "`n=== Performance Monitoring Complete ===" -ForegroundColor Cyan
    Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
}
catch {
    Write-Error "Performance monitoring failed: $($_.Exception.Message)"
    exit 1
}
finally {
    # Cleanup
    $ProgressPreference = "Continue"
}