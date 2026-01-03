@{
    # Module manifest for VMware Tools Auto-Upgrade PowerCLI Solution
    
    RootModule = 'VMTools-AutoUpgrade.psm1'
    ModuleVersion = '1.0.2'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    
    Author = 'uldyssian-sh'
    CompanyName = 'Enterprise Solutions'
    Copyright = '(c) 2025 uldyssian-sh. All rights reserved.'
    
    Description = 'Enterprise PowerCLI solution for bulk VMware Tools auto-upgrade configuration across vCenter environments'
    
    PowerShellVersion = '5.1'
    
    RequiredModules = @(
        @{ModuleName = 'VMware.PowerCLI'; ModuleVersion = '13.0.0'}
    )
    
    FunctionsToExport = @(
        'Enable-VMToolsAutoUpgrade',
        'Get-VMToolsStatus',
        'New-VMToolsReport',
        'Start-VMToolsMonitoring'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('VMware', 'PowerCLI', 'vSphere', 'Enterprise', 'Automation', 'Tools')
            LicenseUri = 'https://github.com/uldyssian-sh/vmware-tools-auto-upgrade/blob/main/LICENSE'
            ProjectUri = 'https://github.com/uldyssian-sh/vmware-tools-auto-upgrade'
            ReleaseNotes = 'Enterprise-grade VMware Tools auto-upgrade automation with comprehensive monitoring and reporting capabilities.'
        }
    }
}