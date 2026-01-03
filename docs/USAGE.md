# Usage Guide

This guide provides detailed instructions for using the VMware Tools Auto-Upgrade PowerCLI solution.

## Prerequisites

### Software Requirements
- **PowerShell**: Version 5.1 or later (Windows PowerShell or PowerShell Core)
- **VMware PowerCLI**: Latest version recommended
- **vCenter Server**: Version 6.5 or later
- **Permissions**: VM configuration privileges in vCenter

### PowerCLI Installation
```powershell
# Install PowerCLI from PowerShell Gallery
Install-Module -Name VMware.PowerCLI -Scope CurrentUser

# Import the module
Import-Module VMware.PowerCLI
```

## Basic Usage

### Interactive Mode
The simplest way to run the script is in interactive mode:

```powershell
.\scripts\Enable-VMTools-AutoUpgrade-AllVMs.ps1
```

The script will prompt for:
1. vCenter Server FQDN or IP address
2. vCenter credentials
3. Execution mode (Dry-run or Apply)

### Command Line Parameters

#### Dry-Run Mode
```powershell
.\scripts\Enable-VMTools-AutoUpgrade-AllVMs.ps1 -vCenter "vcenter.example.com" -DryRun
```

#### Apply Mode with Credentials
```powershell
$cred = Get-Credential
.\scripts\Enable-VMTools-AutoUpgrade-AllVMs.ps1 -vCenter "vcenter.example.com" -Credential $cred
```

#### Silent Execution (No Prompts)
```powershell
$cred = Get-Credential
.\scripts\Enable-VMTools-AutoUpgrade-AllVMs.ps1 -vCenter "vcenter.example.com" -Credential $cred -Force
```

## Advanced Usage

### Batch Processing
For large environments, consider running during maintenance windows:

```powershell
# Schedule for off-hours execution
$trigger = New-ScheduledTaskTrigger -At "02:00AM" -Once
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\Enable-VMTools-AutoUpgrade-AllVMs.ps1"
Register-ScheduledTask -TaskName "VMTools-AutoUpgrade" -Trigger $trigger -Action $action
```

### Logging and Monitoring
The script automatically creates log files with timestamps:

```powershell
# Log files are created in the script directory
# Format: VMTools-AutoUpgrade-YYYYMMDD-HHMMSS.log

# Monitor log file in real-time
Get-Content "VMTools-AutoUpgrade-20250103-143022.log" -Wait
```

### Custom Filtering
To modify the script for specific VM filtering:

```powershell
# Example: Filter by VM name pattern
$targets = $beforeState | Where-Object { 
    $_.ToolsUpgradePolicy -ne "upgradeAtPowerCycle" -and
    $_.VMName -like "PROD-*"
}
```

## Output Examples

### Dry-Run Mode Output
```
=== VMware Tools Auto-Upgrade on Power-On (Enterprise Solution) ===

Enter vCenter FQDN or IP: vcenter.example.com
Execution mode: (D)ry-run or (A)pply [D/A]: D

DRY-RUN MODE: No changes will be applied

=== CURRENT STATE (All VMs) ===
VMName          PowerState ToolsUpgradePolicy ToolsStatus
------          ---------- ------------------ -----------
VM-WEB-01       PoweredOn  manual             toolsOk
VM-WEB-02       PoweredOn  upgradeAtPowerCycle toolsOk
VM-DB-01        PoweredOff                    toolsNotInstalled

VMs requiring auto-upgrade configuration:
VMName          PowerState ToolsUpgradePolicy ToolsStatus
------          ---------- ------------------ -----------
VM-WEB-01       PoweredOn  manual             toolsOk
VM-DB-01        PoweredOff                    toolsNotInstalled

Total VMs to be configured: 2

✓ DRY-RUN COMPLETE: No changes were applied
```

### Apply Mode Output
```
=== VMware Tools Auto-Upgrade on Power-On (Enterprise Solution) ===

APPLY MODE: Changes will be applied to matching VMs

Proceed with enabling auto-upgrade on these VMs? (Y/N): Y

Applying VMware Tools auto-upgrade configuration...
  ✓ SUCCESS - VM-WEB-01
  ✓ SUCCESS - VM-DB-01

=== BEFORE / AFTER COMPARISON ===
VMName    Before  After               Changed
------    ------  -----               -------
VM-WEB-01 manual  upgradeAtPowerCycle ✓ YES
VM-DB-01          upgradeAtPowerCycle ✓ YES

Total VMs changed: 2

✓ OPERATION COMPLETE
  - Successful configurations: 2
  - Failed configurations: 0
```

## Best Practices

### Pre-Execution Checklist
- [ ] Verify PowerCLI connectivity to vCenter
- [ ] Confirm sufficient privileges for VM reconfiguration
- [ ] Run in dry-run mode first to validate targets
- [ ] Schedule during maintenance windows for large environments
- [ ] Ensure adequate logging and monitoring

### Security Considerations
- Use dedicated service accounts for automation
- Store credentials securely (Windows Credential Manager)
- Enable audit logging in vCenter
- Review and approve changes through change management process

### Performance Optimization
- Run during low-activity periods
- Monitor vCenter performance during execution
- Consider batching for very large environments (1000+ VMs)
- Use dedicated management networks for PowerCLI connections

## Troubleshooting

### Common Issues

#### PowerCLI Not Found
```powershell
# Error: The term 'Connect-VIServer' is not recognized
# Solution: Install and import PowerCLI
Install-Module VMware.PowerCLI -Force
Import-Module VMware.PowerCLI
```

#### Connection Timeout
```powershell
# Error: Connection timeout to vCenter
# Solution: Check network connectivity and firewall rules
Test-NetConnection -ComputerName vcenter.example.com -Port 443
```

#### Insufficient Privileges
```powershell
# Error: Permission denied for VM reconfiguration
# Solution: Verify user has VM.Config.Settings privilege
```

### Debug Mode
Enable verbose logging for troubleshooting:

```powershell
$VerbosePreference = "Continue"
$DebugPreference = "Continue"
.\scripts\Enable-VMTools-AutoUpgrade-AllVMs.ps1 -Verbose -Debug
```

## Support

For additional support:
- Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
- Review [GitHub Issues](https://github.com/uldyssian-sh/vmware-tools-auto-upgrade/issues)
- Consult [VMware PowerCLI Documentation](https://developer.vmware.com/powercli)