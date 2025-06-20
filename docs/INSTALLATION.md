# Installation and Setup Guide

This guide provides step-by-step instructions for installing and configuring the Power Automate Security Assessment Tool.

## System Requirements

### PowerShell Version
- **Windows**: PowerShell 5.1 or PowerShell 7.x
- **macOS/Linux**: PowerShell 7.x or later
- **Azure Cloud Shell**: Supported (PowerShell 7.x available)

### Operating System Support
- Windows 10/11 (recommended)
- Windows Server 2016 or later
- macOS 10.15 or later
- Ubuntu 18.04 LTS or later

### Network Requirements
- Internet connectivity for Microsoft 365/Power Platform APIs
- Access to PowerShell Gallery (for module installation)
- Corporate firewall must allow PowerShell Gallery and Microsoft service endpoints

## Prerequisites

### Required Permissions
- **Power Platform Administrator** role
- **Global Administrator** role (for environment creation assessment)
- **Azure AD permissions** for security group validation

### Microsoft 365 Licensing
- Power Platform plan (P1, P2, or included in Microsoft 365)
- Azure AD Premium (for advanced security features)

## Installation Steps

### Step 1: Verify PowerShell Version
```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Required: 5.1.x or 7.x.x
```

### Step 2: Set Execution Policy (Windows)
```powershell
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify execution policy
Get-ExecutionPolicy -List
```

### Step 3: Install Required PowerShell Modules
```powershell
# Install Power Apps Administration module
Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Force -AllowClobber

# Install Power Apps PowerShell module
Install-Module -Name Microsoft.PowerApps.PowerShell -Force -AllowClobber

# Verify module installation
Get-Module -Name Microsoft.PowerApps* -ListAvailable
```

### Step 4: Download Assessment Script
```powershell
# Option 1: Download from repository
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/your-repo/PowerAutomate-SecurityAssessment.ps1" -OutFile "PowerAutomate-SecurityAssessment.ps1"

# Option 2: Clone entire repository
git clone https://github.com/your-repo/powerplatform-security-assessment.git
cd powerplatform-security-assessment
```

### Step 5: Initial Authentication
```powershell
# Connect to Power Platform
Add-PowerAppsAccount

# Verify connection
Get-AdminPowerAppEnvironment | Select-Object DisplayName, EnvironmentName | Format-Table
```

## Module Version Requirements

### Microsoft.PowerApps.Administration.PowerShell
- **Minimum Version**: 2.0.150
- **Recommended**: Latest available
- **Installation**: `Install-Module -Name Microsoft.PowerApps.Administration.PowerShell`

### Microsoft.PowerApps.PowerShell
- **Minimum Version**: 1.0.20
- **Recommended**: Latest available
- **Installation**: `Install-Module -Name Microsoft.PowerApps.PowerShell`

### Version Compatibility Check
```powershell
# Check installed versions
Get-Module -Name Microsoft.PowerApps.Administration.PowerShell -ListAvailable | Select-Object Version
Get-Module -Name Microsoft.PowerApps.PowerShell -ListAvailable | Select-Object Version

# Update to latest versions
Update-Module -Name Microsoft.PowerApps.Administration.PowerShell
Update-Module -Name Microsoft.PowerApps.PowerShell
```

## Authentication Methods

### Interactive Authentication (Recommended)
```powershell
# Standard interactive login
Add-PowerAppsAccount

# With specific tenant
Add-PowerAppsAccount -TenantID "your-tenant-id"
```

### Service Principal Authentication (Automation)
```powershell
# Using client credentials
$credential = Get-Credential
Add-PowerAppsAccount -Username $credential.UserName -Password $credential.Password

# Using certificate authentication
Add-PowerAppsAccount -CertificateThumbprint "thumbprint" -ApplicationId "app-id" -TenantId "tenant-id"
```

### Azure Cloud Shell
```bash
# PowerShell modules are pre-installed in Cloud Shell
# Simply connect to Power Platform
Add-PowerAppsAccount
```

## Configuration Validation

### Test Script Execution
```powershell
# Basic connectivity test
.\PowerAutomate-SecurityAssessment.ps1 -EnvironmentName "Default" -ExportFormat "JSON"

# Verify output directory permissions
Test-Path "C:\Reports" -PathType Container
```

### Environment Access Verification
```powershell
# List accessible environments
Get-AdminPowerAppEnvironment | Select-Object DisplayName, EnvironmentName, EnvironmentType

# Test specific environment access
Get-AdminFlow -EnvironmentName "environment-guid-here" | Measure-Object
```

## Troubleshooting Installation Issues

### Module Installation Failures

#### Issue: Cannot install from PowerShell Gallery
```powershell
# Solution: Configure PowerShell Gallery as trusted
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# Alternative: Manual download
Save-Module -Name Microsoft.PowerApps.Administration.PowerShell -Path "C:\Modules"
Import-Module "C:\Modules\Microsoft.PowerApps.Administration.PowerShell"
```

#### Issue: Access denied during module installation
```powershell
# Solution: Install for current user only
Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Scope CurrentUser -Force
```

### Authentication Problems

#### Issue: Multi-factor authentication required
```powershell
# Solution: Use device code authentication
Add-PowerAppsAccount -UseDeviceAuthentication
```

#### Issue: Conditional access blocking sign-in
- Use compliant device for authentication
- Configure trusted location in Azure AD
- Contact IT administrator for policy exemption

### Network Connectivity Issues

#### Corporate Firewall Configuration
Required endpoints:
- `*.powerapps.com`
- `*.powerplatform.com` 
- `*.dynamics.com`
- `*.powershellgallery.com`
- `login.microsoftonline.com`

#### Proxy Configuration
```powershell
# Configure proxy for PowerShell
$proxy = New-Object System.Net.WebProxy("http://proxy.company.com:8080")
[System.Net.WebRequest]::DefaultWebProxy = $proxy

# Configure proxy authentication
$proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
```

## Security Considerations

### Credential Storage
- Never store credentials in scripts
- Use Windows Credential Manager for saved credentials
- Implement service principal authentication for automation

### Script Signing (Recommended)
```powershell
# Create self-signed certificate for script signing
New-SelfSignedCertificate -Subject "PowerShell Code Signing" -Type CodeSigning -KeyUsage DigitalSignature -FriendlyName "PowerShell Code Signing" -CertStoreLocation Cert:\CurrentUser\My

# Sign the script
Set-AuthenticodeSignature -FilePath "PowerAutomate-SecurityAssessment.ps1" -Certificate (Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert)
```

### Audit Logging
```powershell
# Enable PowerShell transcription for audit trail
Start-Transcript -Path "C:\Logs\PowerShell-Transcript-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

# Run assessment
.\PowerAutomate-SecurityAssessment.ps1

# Stop transcription
Stop-Transcript
```

## Automated Deployment

### Group Policy Deployment (Windows Domain)
1. Copy modules to central share
2. Create Group Policy to install modules
3. Deploy script via software deployment

### Microsoft Intune Deployment
1. Package script and modules
2. Create Win32 app package
3. Deploy to target device groups

### Azure Automation (Cloud-based)
```powershell
# Import modules to Automation Account
Import-Module -Name Microsoft.PowerApps.Administration.PowerShell -ModuleVersion "latest"

# Create runbook with assessment script
# Schedule execution for regular assessments
```

## Validation Checklist

- [ ] PowerShell version 5.1+ or 7.x installed
- [ ] Execution policy configured appropriately
- [ ] Required PowerShell modules installed and updated
- [ ] Power Platform administrator access verified
- [ ] Network connectivity to required endpoints confirmed
- [ ] Script execution successful with test environment
- [ ] Output directory accessible and writable
- [ ] Authentication method configured and tested

## Next Steps

After successful installation:
1. Review [Security Methodology](SECURITY_METHODOLOGY.md) for assessment criteria
2. Run initial assessment on non-production environment
3. Configure scheduled execution if needed
4. Set up monitoring and alerting for security findings

## Support

For installation issues:
- Check [Troubleshooting Guide](TROUBLESHOOTING.md)
- Verify PowerShell module compatibility
- Confirm Power Platform permissions
- Review corporate network policies