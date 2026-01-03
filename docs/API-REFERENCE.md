# API Reference

This document provides detailed API reference for the VMware Tools Auto-Upgrade PowerCLI solution.

## Script Parameters

### Enable-VMTools-AutoUpgrade-AllVMs.ps1

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `vCenter` | String | No | - | vCenter Server FQDN or IP address |
| `Credential` | PSCredential | No | - | vCenter authentication credentials |
| `DryRun` | Switch | No | False | Run in dry-run mode without applying changes |
| `Force` | Switch | No | False | Skip confirmation prompts |
| `BatchSize` | Int | No | 50 | Number of VMs to process in each batch |
| `LogPath` | String | No | - | Custom path for log file output |

#### Examples

```powershell
# Basic interactive usage
.\Enable-VMTools-AutoUpgrade-AllVMs.ps1

# Dry-run with specific vCenter
.\Enable-VMTools-AutoUpgrade-AllVMs.ps1 -vCenter "vcenter.example.com" -DryRun

# Batch processing with custom log location
.\Enable-VMTools-AutoUpgrade-AllVMs.ps1 -vCenter "vcenter.example.com" -BatchSize 25 -LogPath "C:\Logs"

# Silent execution with credentials
$cred = Get-Credential
.\Enable-VMTools-AutoUpgrade-AllVMs.ps1 -vCenter "vcenter.example.com" -Credential $cred -Force
```

## Internal Functions

### Test-PowerCLI
Validates PowerCLI module availability and version.

**Returns:** Boolean indicating PowerCLI readiness

### Connect-vCenterServer
Establishes secure connection to vCenter Server.

**Parameters:**
- `Server` (String): vCenter Server address
- `Credential` (PSCredential): Authentication credentials

**Returns:** VI Server connection object

### Get-VMToolsStatus
Retrieves current VMware Tools configuration for all VMs.

**Returns:** Array of VM objects with Tools status

### Set-VMToolsAutoUpgrade
Configures VMware Tools auto-upgrade policy for specified VMs.

**Parameters:**
- `VMs` (Array): Collection of VM objects to configure
- `BatchSize` (Int): Number of VMs to process per batch

**Returns:** Configuration results array

## vSphere API Integration

### ConfigSpec Objects
The script uses VMware vSphere ConfigSpec objects for VM reconfiguration:

```powershell
$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
$spec.Tools = New-Object VMware.Vim.ToolsConfigInfo
$spec.Tools.ToolsUpgradePolicy = "upgradeAtPowerCycle"
```

### Required Permissions
- `VirtualMachine.Config.Settings`
- `VirtualMachine.Interact.ToolsInstall`
- `System.Anonymous` (for connection)
- `System.View` (for inventory access)

## Error Handling

### Exception Types
- `VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.VimException`
- `System.Management.Automation.ParameterBindingException`
- `System.UnauthorizedAccessException`
- `System.TimeoutException`

### Error Codes
| Code | Description | Resolution |
|------|-------------|------------|
| 1001 | PowerCLI not available | Install VMware PowerCLI module |
| 1002 | vCenter connection failed | Check network and credentials |
| 1003 | Insufficient permissions | Verify user privileges |
| 1004 | VM reconfiguration failed | Check VM state and locks |

## Logging Format

### Log Entry Structure
```
[TIMESTAMP] [LEVEL] [COMPONENT] Message
```

### Log Levels
- `INFO`: General information
- `WARN`: Warning conditions
- `ERROR`: Error conditions
- `DEBUG`: Debug information (when enabled)

### Sample Log Entries
```
[2025-01-03 14:30:22] [INFO] [MAIN] Starting VMware Tools auto-upgrade process
[2025-01-03 14:30:23] [INFO] [CONNECT] Connected to vCenter: vcenter.example.com
[2025-01-03 14:30:25] [INFO] [SCAN] Found 150 VMs, 45 require configuration
[2025-01-03 14:30:30] [INFO] [CONFIG] Successfully configured VM: PROD-WEB-01
[2025-01-03 14:30:35] [WARN] [CONFIG] VM locked, skipping: PROD-DB-02
[2025-01-03 14:30:40] [INFO] [COMPLETE] Process completed: 44 success, 1 skipped
```

## Performance Metrics

### Typical Performance
- **Small Environment** (< 100 VMs): 1-2 minutes
- **Medium Environment** (100-500 VMs): 5-10 minutes  
- **Large Environment** (500+ VMs): 15-30 minutes

### Optimization Guidelines
- Use batch processing for large environments
- Run during maintenance windows
- Monitor vCenter performance during execution
- Consider network latency for remote vCenter connections

## Security Considerations

### Credential Handling
- Credentials are never stored or logged
- Use Windows Credential Manager for secure storage
- Support for service account automation

### Network Security
- All connections use HTTPS/SSL
- Certificate validation supported
- Network traffic encrypted end-to-end

### Audit Trail
- Complete operation logging
- Before/after state tracking
- Change attribution and timestamps