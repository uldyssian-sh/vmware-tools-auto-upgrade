# Troubleshooting Guide

This guide helps resolve common issues when using the VMware Tools Auto-Upgrade PowerCLI solution.

## Common Issues and Solutions

### PowerCLI Issues

#### PowerCLI Module Not Found
**Error:** `The term 'Connect-VIServer' is not recognized`

**Solution:**
```powershell
# Install PowerCLI
Install-Module -Name VMware.PowerCLI -Scope CurrentUser -Force

# Import the module
Import-Module VMware.PowerCLI

# Verify installation
Get-Module VMware.PowerCLI -ListAvailable
```

#### PowerCLI Version Compatibility
**Error:** `This version of PowerCLI is not supported`

**Solution:**
```powershell
# Update to latest version
Update-Module VMware.PowerCLI -Force

# Check version
Get-Module VMware.PowerCLI | Select-Object Version
```

### Connection Issues

#### vCenter Connection Timeout
**Error:** `Connection timeout to vCenter Server`

**Diagnosis:**
```powershell
# Test network connectivity
Test-NetConnection -ComputerName vcenter.example.com -Port 443

# Check DNS resolution
Resolve-DnsName vcenter.example.com
```

**Solutions:**
- Verify vCenter Server is accessible
- Check firewall rules (port 443)
- Validate DNS resolution
- Try connecting with vSphere Client first

#### SSL Certificate Issues
**Error:** `The underlying connection was closed: Could not establish trust relationship`

**Solution:**
```powershell
# Ignore SSL certificates (lab environments only)
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# For production, install proper certificates
Set-PowerCLIConfiguration -InvalidCertificateAction Fail -Confirm:$false
```

### Authentication Issues

#### Invalid Credentials
**Error:** `Login failed due to a bad username or password`

**Solutions:**
- Verify username and password
- Check domain authentication requirements
- Use UPN format: `user@domain.com`
- Try connecting manually first

#### Insufficient Privileges
**Error:** `Permission denied for VM reconfiguration`

**Required Privileges:**
- `VirtualMachine.Config.Settings`
- `VirtualMachine.Interact.ToolsInstall`
- `System.Anonymous`
- `System.View`

**Solution:**
```powershell
# Check current user permissions
$session = Get-View SessionManager
$session.CurrentSession.UserName
```

### VM Configuration Issues

#### VM is Locked
**Error:** `The object is already locked by another operation`

**Solutions:**
- Wait for current operation to complete
- Check for running snapshots or migrations
- Restart vCenter services if persistent

#### VM Tools Not Installed
**Warning:** `VMware Tools not installed on VM`

**Note:** This is expected behavior. The auto-upgrade setting will take effect when Tools are installed.

#### VM is Template
**Error:** `Cannot reconfigure VM template`

**Solution:** The script automatically filters out templates. If this error occurs, check VM inventory.

### Performance Issues

#### Slow Execution with Many VMs
**Symptoms:** Script takes very long time with large VM counts

**Solutions:**
```powershell
# Use batch processing
.\Enable-VMTools-AutoUpgrade-AllVMs.ps1 -BatchSize 25

# Run during maintenance windows
# Monitor vCenter performance
```

#### Memory Usage Issues
**Symptoms:** High memory usage during execution

**Solutions:**
- Reduce batch size
- Run on machine with adequate RAM
- Close other PowerShell sessions

### Script-Specific Issues

#### Dry-Run Shows No VMs
**Issue:** Dry-run mode shows 0 VMs to configure

**Diagnosis:**
```powershell
# Check VM inventory manually
Connect-VIServer -Server vcenter.example.com
Get-VM | Select-Object Name, @{N="ToolsUpgradePolicy";E={$_.ExtensionData.Config.Tools.ToolsUpgradePolicy}}
```

**Possible Causes:**
- All VMs already have auto-upgrade enabled
- Connection issues preventing VM enumeration
- Insufficient permissions to view VMs

#### Log Files Not Created
**Issue:** No log files generated

**Solutions:**
- Check write permissions in script directory
- Use `-LogPath` parameter to specify custom location
- Run PowerShell as administrator if needed

### Advanced Troubleshooting

#### Enable Debug Logging
```powershell
$VerbosePreference = "Continue"
$DebugPreference = "Continue"
.\Enable-VMTools-AutoUpgrade-AllVMs.ps1 -Verbose -Debug
```

#### PowerCLI Configuration Check
```powershell
# View current PowerCLI configuration
Get-PowerCLIConfiguration

# Reset to defaults if needed
Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Confirm:$false
```

#### vCenter Service Status
```powershell
# Check vCenter services (if you have access)
Get-Service | Where-Object {$_.Name -like "*vmware*"}
```

## Error Codes Reference

| Code | Description | Action |
|------|-------------|--------|
| 1001 | PowerCLI not available | Install PowerCLI module |
| 1002 | vCenter connection failed | Check connectivity and credentials |
| 1003 | Insufficient permissions | Verify user privileges |
| 1004 | VM reconfiguration failed | Check VM state and locks |
| 1005 | Batch processing error | Reduce batch size |
| 1006 | Logging error | Check file permissions |

## Performance Optimization

### Large Environment Best Practices
- Use batch processing (`-BatchSize 25-50`)
- Run during maintenance windows
- Monitor vCenter CPU and memory usage
- Use dedicated management network
- Consider multiple smaller runs instead of one large run

### Network Optimization
- Use wired connection for better stability
- Minimize network latency to vCenter
- Avoid running over VPN if possible
- Monitor network utilization during execution

## Getting Help

### Before Seeking Support
1. Enable verbose logging
2. Check all prerequisites
3. Test with small VM subset first
4. Review vCenter logs if accessible

### Information to Provide
- PowerShell version: `$PSVersionTable`
- PowerCLI version: `Get-Module VMware.PowerCLI`
- vCenter version
- Number of VMs in environment
- Complete error messages
- Log files (with sensitive data removed)

### Support Channels
- [GitHub Issues](https://github.com/uldyssian-sh/vmware-tools-auto-upgrade/issues)
- [GitHub Discussions](https://github.com/uldyssian-sh/vmware-tools-auto-upgrade/discussions)
- VMware PowerCLI Community Forums

## Prevention Tips

### Regular Maintenance
- Keep PowerCLI updated
- Monitor vCenter health
- Review VM inventory regularly
- Test scripts in lab environment first

### Best Practices
- Always run dry-run mode first
- Schedule during maintenance windows
- Monitor execution progress
- Maintain proper backups
- Document any customizations