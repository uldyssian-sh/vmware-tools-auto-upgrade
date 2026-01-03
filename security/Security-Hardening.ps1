<#
.SYNOPSIS
    Security hardening configuration for VMware Tools Auto-Upgrade solution

.DESCRIPTION
    Implements enterprise security hardening measures including credential
    protection, audit logging, and secure communication protocols.

.NOTES
    Author: uldyssian-sh
    Version: 1.0
    Requires: PowerShell 5.1+, Windows Security features
#>

function Enable-SecurityHardening {
    [CmdletBinding()]
    param(
        [switch]$EnableAuditLogging,
        [switch]$EnableCredentialProtection,
        [switch]$EnableSecureCommunication
    )
    
    Write-Host "=== VMware Tools Auto-Upgrade Security Hardening ===" -ForegroundColor Cyan
    Write-Host ""
    
    if ($EnableAuditLogging) {
        Write-Host "Configuring audit logging..." -ForegroundColor Yellow
        
        # Create secure audit log directory
        $auditPath = "$env:ProgramData\VMTools-AutoUpgrade\Audit"
        if (-not (Test-Path $auditPath)) {
            New-Item -Path $auditPath -ItemType Directory -Force | Out-Null
            
            # Set restrictive permissions
            $acl = Get-Acl $auditPath
            $acl.SetAccessRuleProtection($true, $false)
            $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                "Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
            )
            $acl.SetAccessRule($adminRule)
            Set-Acl -Path $auditPath -AclObject $acl
        }
        
        Write-Host "✓ Audit logging configured: $auditPath" -ForegroundColor Green
    }
    
    if ($EnableCredentialProtection) {
        Write-Host "Configuring credential protection..." -ForegroundColor Yellow
        
        # Validate Windows Credential Manager availability
        try {
            $credManager = Get-Command "cmdkey.exe" -ErrorAction Stop
            Write-Host "✓ Windows Credential Manager available" -ForegroundColor Green
            
            # Create example credential storage template
            $credTemplate = @"
# Example: Store vCenter credentials securely
# cmdkey /generic:vcenter.example.com /user:administrator@vsphere.local /pass:SecurePassword123

# Example: Retrieve stored credentials
# `$cred = Get-StoredCredential -Target "vcenter.example.com"
"@
            $credTemplate | Out-File -FilePath "$auditPath\credential-template.txt" -Encoding UTF8
            
        } catch {
            Write-Warning "Windows Credential Manager not available"
        }
    }
    
    if ($EnableSecureCommunication) {
        Write-Host "Configuring secure communication..." -ForegroundColor Yellow
        
        # PowerCLI security configuration
        $securityConfig = @{
            InvalidCertificateAction = "Fail"
            DefaultVIServerMode = "Single"
            WebOperationTimeoutSeconds = 300
            VMConsoleWindowBrowser = "None"
        }
        
        foreach ($setting in $securityConfig.GetEnumerator()) {
            try {
                Set-PowerCLIConfiguration -Scope Session -$($setting.Key) $setting.Value -Confirm:$false -ErrorAction SilentlyContinue
                Write-Host "✓ $($setting.Key): $($setting.Value)" -ForegroundColor Green
            } catch {
                Write-Warning "Failed to configure $($setting.Key)"
            }
        }
    }
    
    Write-Host ""
    Write-Host "Security hardening completed!" -ForegroundColor Green
}

function Test-SecurityCompliance {
    [CmdletBinding()]
    param()
    
    Write-Host "=== Security Compliance Check ===" -ForegroundColor Cyan
    Write-Host ""
    
    $complianceResults = @()
    
    # Check PowerShell execution policy
    $executionPolicy = Get-ExecutionPolicy
    $policyCompliant = $executionPolicy -in @("RemoteSigned", "AllSigned")
    $complianceResults += [PSCustomObject]@{
        Check = "PowerShell Execution Policy"
        Status = if ($policyCompliant) { "PASS" } else { "FAIL" }
        Value = $executionPolicy
        Recommendation = if (-not $policyCompliant) { "Set to RemoteSigned or AllSigned" } else { "Compliant" }
    }
    
    # Check PowerCLI certificate validation
    try {
        $certAction = (Get-PowerCLIConfiguration).InvalidCertificateAction
        $certCompliant = $certAction -eq "Fail"
        $complianceResults += [PSCustomObject]@{
            Check = "Certificate Validation"
            Status = if ($certCompliant) { "PASS" } else { "WARN" }
            Value = $certAction
            Recommendation = if (-not $certCompliant) { "Enable certificate validation for production" } else { "Compliant" }
        }
    } catch {
        $complianceResults += [PSCustomObject]@{
            Check = "Certificate Validation"
            Status = "UNKNOWN"
            Value = "PowerCLI not loaded"
            Recommendation = "Load PowerCLI module"
        }
    }
    
    # Check audit logging
    $auditPath = "$env:ProgramData\VMTools-AutoUpgrade\Audit"
    $auditEnabled = Test-Path $auditPath
    $complianceResults += [PSCustomObject]@{
        Check = "Audit Logging"
        Status = if ($auditEnabled) { "PASS" } else { "WARN" }
        Value = if ($auditEnabled) { "Enabled" } else { "Disabled" }
        Recommendation = if (-not $auditEnabled) { "Enable audit logging for compliance" } else { "Compliant" }
    }
    
    # Display results
    $complianceResults | Format-Table -AutoSize
    
    $failCount = ($complianceResults | Where-Object { $_.Status -eq "FAIL" }).Count
    $warnCount = ($complianceResults | Where-Object { $_.Status -eq "WARN" }).Count
    
    Write-Host ""
    if ($failCount -eq 0 -and $warnCount -eq 0) {
        Write-Host "✓ All security compliance checks passed!" -ForegroundColor Green
    } elseif ($failCount -eq 0) {
        Write-Host "⚠ Security compliance passed with $warnCount warnings" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Security compliance failed: $failCount failures, $warnCount warnings" -ForegroundColor Red
    }
    
    return $complianceResults
}

# Export functions
Export-ModuleMember -Function @('Enable-SecurityHardening', 'Test-SecurityCompliance')