@{
    # PowerShell module requirements for VMware Tools Auto-Upgrade solution
    
    # Required PowerShell version
    PowerShellVersion = '5.1'
    
    # Required modules
    RequiredModules = @(
        @{
            ModuleName = 'VMware.PowerCLI'
            ModuleVersion = '13.0.0'
            Repository = 'PSGallery'
        },
        @{
            ModuleName = 'Pester'
            ModuleVersion = '5.0.0'
            Repository = 'PSGallery'
        }
    )
    
    # Optional modules for enhanced functionality
    OptionalModules = @(
        @{
            ModuleName = 'PSScriptAnalyzer'
            ModuleVersion = '1.21.0'
            Repository = 'PSGallery'
            Purpose = 'Code quality analysis'
        },
        @{
            ModuleName = 'ImportExcel'
            ModuleVersion = '7.8.0'
            Repository = 'PSGallery'
            Purpose = 'Excel report generation'
        }
    )
    
    # Installation script
    InstallScript = @'
# Install required PowerShell modules
Write-Host "Installing required PowerShell modules..." -ForegroundColor Green

# Install PowerCLI
if (-not (Get-Module -ListAvailable -Name VMware.PowerCLI)) {
    Install-Module -Name VMware.PowerCLI -Scope CurrentUser -Force -AllowClobber
    Write-Host "✓ VMware PowerCLI installed" -ForegroundColor Green
} else {
    Write-Host "✓ VMware PowerCLI already installed" -ForegroundColor Yellow
}

# Install Pester for testing
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Install-Module -Name Pester -Scope CurrentUser -Force -SkipPublisherCheck
    Write-Host "✓ Pester testing framework installed" -ForegroundColor Green
} else {
    Write-Host "✓ Pester already installed" -ForegroundColor Yellow
}

# Optional: Install PSScriptAnalyzer for code quality
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
    Write-Host "✓ PSScriptAnalyzer installed" -ForegroundColor Green
} else {
    Write-Host "✓ PSScriptAnalyzer already installed" -ForegroundColor Yellow
}

Write-Host "Module installation completed!" -ForegroundColor Green
'@
}