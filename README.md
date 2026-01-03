# VMware Tools Auto-Upgrade PowerCLI Solution

[![PowerCLI](https://img.shields.io/badge/PowerCLI-Compatible-blue.svg)](https://github.com/uldyssian-sh/vmware-tools-auto-upgrade)
[![VMware](https://img.shields.io/badge/VMware-vSphere-green.svg)](https://github.com/uldyssian-sh/vmware-tools-auto-upgrade)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/uldyssian-sh/vmware-tools-auto-upgrade)](https://github.com/uldyssian-sh/vmware-tools-auto-upgrade/releases)
[![Issues](https://img.shields.io/github/issues/uldyssian-sh/vmware-tools-auto-upgrade)](https://github.com/uldyssian-sh/vmware-tools-auto-upgrade/issues)
[![Stars](https://img.shields.io/github/stars/uldyssian-sh/vmware-tools-auto-upgrade)](https://github.com/uldyssian-sh/vmware-tools-auto-upgrade/stargazers)

## 📋 Overview

This PowerCLI solution provides enterprise-grade automation for bulk-enabling VMware Tools auto-upgrade on power-on across all virtual machines in a vCenter environment. The script implements a safe, controlled approach with dry-run capabilities and comprehensive before/after reporting.

## 🎯 Key Features

- **Bulk Operations**: Process all VMs in vCenter simultaneously
- **Safe Execution**: Dry-run mode for validation before applying changes
- **Minimal Impact**: Changes only the ToolsUpgradePolicy, leaving other VM configurations untouched
- **Comprehensive Reporting**: Before/after state comparison with detailed diff analysis
- **Error Handling**: Robust error handling with detailed logging
- **Enterprise Ready**: Suitable for production environments with thousands of VMs

## 🚀 Quick Start

### Prerequisites

- **PowerCLI**: VMware PowerCLI module installed and loaded
- **vCenter Access**: Administrative privileges on target vCenter Server
- **PowerShell**: PowerShell 5.1 or later (Windows PowerShell or PowerShell Core)

### Installation

```powershell
# Clone the repository
git clone https://github.com/uldyssian-sh/vmware-tools-auto-upgrade.git
cd vmware-tools-auto-upgrade

# Import PowerCLI module (if not already loaded)
Import-Module VMware.PowerCLI

# Run the script
.\Enable-VMTools-AutoUpgrade-AllVMs.ps1
```

## 📖 Usage Guide

### Basic Usage

1. **Run in Dry-Run Mode** (recommended first step):
   ```powershell
   .\Enable-VMTools-AutoUpgrade-AllVMs.ps1
   # Select 'D' for dry-run when prompted
   ```

2. **Apply Changes** (after validating dry-run results):
   ```powershell
   .\Enable-VMTools-AutoUpgrade-AllVMs.ps1
   # Select 'A' for apply when prompted
   ```

### Interactive Prompts

The script will prompt for:
- **vCenter Server**: FQDN or IP address of your vCenter Server
- **Credentials**: vCenter administrator credentials
- **Execution Mode**: Dry-run (D) or Apply (A)
- **Confirmation**: Final confirmation before applying changes

### Sample Output

```
=== VMware Tools Auto-Upgrade on Power-On (ALL VMs) ===

Enter vCenter FQDN or IP: vcenter.example.com
Mode: (D)ry-run or (A)pply [D/A]: D

DRY-RUN mode. No changes will be made.

=== BEFORE (All VMs) ===
VMName          PowerState ToolsUpgradePolicy
------          ---------- ------------------
VM-001          PoweredOn  manual
VM-002          PoweredOff upgradeAtPowerCycle
VM-003          PoweredOn  

VMs that do NOT have auto-upgrade enabled (candidates):
VMName          PowerState ToolsUpgradePolicy
------          ---------- ------------------
VM-001          PoweredOn  manual
VM-003          PoweredOn  

Total candidates: 2

DRY-RUN complete. No changes performed.
```

## 🔧 Technical Details

### How It Works

1. **Discovery Phase**: Scans all VMs in vCenter and collects current ToolsUpgradePolicy settings
2. **Analysis Phase**: Identifies VMs that don't have auto-upgrade enabled
3. **Execution Phase**: Uses ReconfigVM() API to set ToolsUpgradePolicy to "upgradeAtPowerCycle"
4. **Validation Phase**: Verifies changes and provides before/after comparison

### Configuration Changes

The script modifies only one VM property:
- **ToolsUpgradePolicy**: Set to `upgradeAtPowerCycle`

All other VM configuration settings remain unchanged.

### Safety Features

- **Dry-Run Mode**: Preview changes without applying them
- **Confirmation Prompts**: Multiple confirmation steps before applying changes
- **Error Handling**: Graceful error handling with detailed error messages
- **State Validation**: Before/after state comparison to verify successful changes

## 📁 Repository Structure

```
vmware-tools-auto-upgrade/
├── scripts/
│   └── Enable-VMTools-AutoUpgrade-AllVMs.ps1
├── docs/
│   ├── USAGE.md
│   ├── TROUBLESHOOTING.md
│   └── API-REFERENCE.md
├── examples/
│   ├── sample-output.txt
│   └── batch-execution.ps1
├── tests/
│   └── Test-VMToolsUpgrade.ps1
└── README.md
```

## 🛡️ Security Considerations

### Credentials Management
- Use secure credential storage (Windows Credential Manager)
- Implement least-privilege access principles
- Consider using service accounts for automation

### Network Security
- Ensure secure connections to vCenter (HTTPS)
- Validate SSL certificates in production environments
- Use network segmentation for management traffic

### Audit and Compliance
- Log all operations for audit purposes
- Implement change approval processes
- Document all configuration changes

## 🔍 Troubleshooting

### Common Issues

#### PowerCLI Not Loaded
```powershell
# Solution: Import PowerCLI module
Import-Module VMware.PowerCLI
```

#### Connection Issues
```powershell
# Check network connectivity
Test-NetConnection -ComputerName vcenter.example.com -Port 443

# Verify credentials
$cred = Get-Credential
Connect-VIServer -Server vcenter.example.com -Credential $cred
```

#### Permission Errors
- Verify user has VM configuration privileges
- Check vCenter permissions for ReconfigVM operations
- Ensure user has access to all target VMs

### Debug Mode

Enable verbose logging for troubleshooting:
```powershell
$VerbosePreference = "Continue"
.\Enable-VMTools-AutoUpgrade-AllVMs.ps1
```

## 📊 Performance Considerations

### Large Environments
- **Batch Processing**: Script processes VMs sequentially to avoid overwhelming vCenter
- **Resource Usage**: Minimal impact on vCenter resources
- **Execution Time**: Approximately 1-2 seconds per VM for configuration changes

### Optimization Tips
- Run during maintenance windows for large environments
- Consider filtering VMs by specific criteria if needed
- Monitor vCenter performance during execution

## 🤝 Contributing

We welcome contributions to improve this solution:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/enhancement`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/enhancement`)
5. Create a Pull Request

### Development Guidelines
- Follow PowerShell best practices and style guidelines
- Include comprehensive error handling
- Add appropriate comments and documentation
- Test thoroughly in lab environments before production use

## �  Contributors

- **uldyssian-sh LT** - *Project Maintainer* - [uldyssian-sh](https://github.com/uldyssian-sh)
- **dependabot[bot]** - *Dependency Updates* - [dependabot](https://github.com/dependabot)
- **actions-user** - *Automated Workflows* - GitHub Actions

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/uldyssian-sh/vmware-tools-auto-upgrade/issues)
- **Discussions**: [GitHub Discussions](https://github.com/uldyssian-sh/vmware-tools-auto-upgrade/discussions)
- **Documentation**: [Project Wiki](https://github.com/uldyssian-sh/vmware-tools-auto-upgrade/wiki)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📚 References

- VMware vSphere API Reference Documentation
- PowerCLI Cmdlet Reference Guide
- VMware Tools Installation and Configuration Guide
- vSphere Security Best Practices Documentation

---

**Maintained by**: [uldyssian-sh](https://github.com/uldyssian-sh)

⭐ Star this repository if you find it helpful!

**Disclaimer**: Use of this code is at your own risk. Author bears no responsibility for any damages caused by the code.