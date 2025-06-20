# Troubleshooting Guide

This guide provides solutions to common issues encountered when using the Power Automate Security Assessment Tool.

## Common Issues and Solutions

### Authentication and Connection Issues

#### Issue: "Failed to connect to Power Platform"
```
Error: Failed to connect to Power Platform: Access denied
```

**Possible Causes:**
- Not authenticated to Power Platform
- Insufficient permissions
- Network connectivity issues

**Solutions:**
```powershell
# Solution 1: Re-authenticate
Add-PowerAppsAccount

# Solution 2: Use specific tenant
Add-PowerAppsAccount -TenantID "your-tenant-id"

# Solution 3: Use device code authentication (for MFA)
Add-PowerAppsAccount -UseDeviceAuthentication

# Solution 4: Verify connection
Get-AdminPowerAppEnvironment | Select-Object DisplayName -First 1
```

#### Issue: "The user or administrator has not consented to use the application"
```
Error: AADSTS65001: The user or administrator has not consented to use the application
```

**Solutions:**
1. **Admin Consent Required**: Contact Global Administrator for app consent
2. **Use Different Authentication Method**:
   ```powershell
   Add-PowerAppsAccount -UseDeviceAuthentication
   ```
3. **Check Tenant Settings**: Verify Power Platform admin permissions

#### Issue: Multi-Factor Authentication (MFA) Prompt Loop
```
Error: Multiple MFA prompts or authentication timeout
```

**Solutions:**
```powershell
# Use device code authentication
Add-PowerAppsAccount -UseDeviceAuthentication

# Clear cached credentials
Clear-PowerAppsAccounts

# Use modern authentication
Add-PowerAppsAccount -UseModernAuthentication
```

### Module Installation Issues

#### Issue: "Module 'Microsoft.PowerApps.Administration.PowerShell' not found"
```
Error: The specified module 'Microsoft.PowerApps.Administration.PowerShell' was not loaded
```

**Solutions:**
```powershell
# Solution 1: Install missing modules
Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Force -AllowClobber
Install-Module -Name Microsoft.PowerApps.PowerShell -Force -AllowClobber

# Solution 2: Install for current user only
Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Scope CurrentUser -Force

# Solution 3: Import manually if installed
Import-Module Microsoft.PowerApps.Administration.PowerShell
Import-Module Microsoft.PowerApps.PowerShell

# Solution 4: Check installation
Get-Module -Name Microsoft.PowerApps* -ListAvailable
```

#### Issue: "Cannot install PowerShell modules from PSGallery"
```
Error: Unable to download from URI 'https://www.powershellgallery.com/api/v2'
```

**Solutions:**
```powershell
# Solution 1: Configure PSGallery as trusted
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# Solution 2: Configure proxy (if behind corporate firewall)
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

# Solution 3: Manual download and install
Save-Module -Name Microsoft.PowerApps.Administration.PowerShell -Path "C:\Modules"
Import-Module "C:\Modules\Microsoft.PowerApps.Administration.PowerShell"

# Solution 4: Use alternative source
Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Repository PSGallery -Force
```

#### Issue: "Module version compatibility"
```
Error: Module version X.X.X is not compatible with PowerShell version Y.Y.Y
```

**Solutions:**
```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# For PowerShell 5.1 - install specific version
Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -RequiredVersion "2.0.150" -Force

# For PowerShell 7+ - install latest
Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Force

# Update PowerShell (Windows)
winget install Microsoft.PowerShell
```

### Permission and Access Issues

#### Issue: "Access denied to environment"
```
Error: Access to the environment 'Environment-ID' is denied
```

**Solutions:**
1. **Verify Administrator Role**:
   ```powershell
   # Check current user permissions
   Get-AdminPowerAppEnvironmentRoleAssignment -EnvironmentName "Default"
   ```

2. **Request Environment Access**: Contact environment administrator

3. **Use Service Principal** (for automation):
   ```powershell
   $credential = Get-Credential
   Add-PowerAppsAccount -Username $credential.UserName -Password $credential.Password
   ```

#### Issue: "Insufficient privileges to complete operation"
```
Error: Insufficient privileges to complete the operation
```

**Required Roles:**
- Power Platform Administrator
- Global Administrator (for tenant-wide assessment)
- Environment Administrator (for specific environments)

**Verification:**
```powershell
# Test admin access
try {
    Get-AdminPowerAppEnvironment | Select-Object DisplayName -First 1
    Write-Host "Admin access confirmed" -ForegroundColor Green
} catch {
    Write-Host "Admin access required" -ForegroundColor Red
}
```

### Script Execution Issues

#### Issue: "Execution policy restriction"
```
Error: Cannot be loaded because running scripts is disabled on this system
```

**Solutions:**
```powershell
# Solution 1: Set execution policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Solution 2: Bypass for single execution
PowerShell -ExecutionPolicy Bypass -File "PowerAutomate-SecurityAssessment.ps1"

# Solution 3: Unblock downloaded script
Unblock-File -Path "PowerAutomate-SecurityAssessment.ps1"

# Verify execution policy
Get-ExecutionPolicy -List
```

#### Issue: "Script parameters not recognized"
```
Error: A parameter cannot be found that matches parameter name 'EnvironmentName'
```

**Solutions:**
```powershell
# Check parameter syntax
Get-Help .\PowerAutomate-SecurityAssessment.ps1 -Detailed

# Correct parameter usage
.\PowerAutomate-SecurityAssessment.ps1 -EnvironmentName "Production"

# List all environments to verify name
Get-AdminPowerAppEnvironment | Select-Object DisplayName, EnvironmentName
```

#### Issue: "Output directory access denied"
```
Error: Access to the path 'C:\Reports' is denied
```

**Solutions:**
```powershell
# Solution 1: Use alternative path
.\PowerAutomate-SecurityAssessment.ps1 -OutputPath "$env:USERPROFILE\Documents"

# Solution 2: Create directory with permissions
New-Item -Path "C:\Reports" -ItemType Directory -Force

# Solution 3: Use current directory
.\PowerAutomate-SecurityAssessment.ps1 -OutputPath "."

# Test path access
Test-Path "C:\Reports" -PathType Container
```

### Network and Connectivity Issues

#### Issue: "Unable to connect to Power Platform APIs"
```
Error: The remote server returned an error: (403) Forbidden
```

**Solutions:**
1. **Check Network Connectivity**:
   ```powershell
   Test-NetConnection -ComputerName "powerapps.com" -Port 443
   Test-NetConnection -ComputerName "powerplatform.com" -Port 443
   ```

2. **Configure Corporate Proxy**:
   ```powershell
   $proxy = New-Object System.Net.WebProxy("http://proxy.company.com:8080")
   $proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
   [System.Net.WebRequest]::DefaultWebProxy = $proxy
   ```

3. **Required Endpoints**: Ensure firewall allows access to:
   - `*.powerapps.com`
   - `*.powerplatform.com`
   - `*.dynamics.com`
   - `login.microsoftonline.com`

#### Issue: "SSL/TLS connection errors"
```
Error: The underlying connection was closed: Could not establish trust relationship
```

**Solutions:**
```powershell
# Solution 1: Update TLS settings
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Solution 2: Import certificates (if using corporate CA)
Import-Certificate -FilePath "corporate-ca.cer" -CertStoreLocation "Cert:\LocalMachine\Root"

# Solution 3: Bypass SSL validation (not recommended for production)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
```

### Performance and Timeout Issues

#### Issue: "Script execution timeout"
```
Error: Operation timed out after 120 seconds
```

**Solutions:**
```powershell
# Solution 1: Assess specific environment only
.\PowerAutomate-SecurityAssessment.ps1 -EnvironmentName "Production"

# Solution 2: Increase timeout (modify script)
# In script, find timeout settings and increase values

# Solution 3: Run during off-peak hours
# Schedule execution when fewer users are active
```

#### Issue: "Large environment assessment taking too long"
```
Status: Processing 1000+ flows in environment
```

**Optimization Strategies:**
1. **Parallel Processing**: Use PowerShell jobs for concurrent assessment
2. **Incremental Assessment**: Process environments separately
3. **Filtering**: Focus on specific resource types
4. **Scheduled Execution**: Run during maintenance windows

### Data and Reporting Issues

#### Issue: "Empty or incomplete reports"
```
Result: Report generated but contains no data
```

**Troubleshooting Steps:**
```powershell
# Check environment access
Get-AdminPowerAppEnvironment | Measure-Object

# Verify flow access
Get-AdminFlow | Measure-Object

# Test connection access
Get-AdminPowerAppConnection | Measure-Object

# Check for specific environment
Get-AdminFlow -EnvironmentName "your-environment-id" | Measure-Object
```

#### Issue: "HTML report not displaying correctly"
```
Problem: HTML report shows raw JSON or formatting issues
```

**Solutions:**
1. **Browser Compatibility**: Use modern browser (Chrome, Edge, Firefox)
2. **File Association**: Ensure .html files open in web browser
3. **Content Security**: If using corporate browser, check CSP settings
4. **File Encoding**: Verify UTF-8 encoding

#### Issue: "CSV export contains garbled characters"
```
Problem: Special characters not displaying correctly in Excel
```

**Solutions:**
```powershell
# Solution 1: Specify UTF-8 encoding when opening in Excel
# File > Import > Text/CSV > UTF-8 encoding

# Solution 2: Use Power Query for import
# Data > Get Data > From File > From Text/CSV

# Solution 3: Convert encoding
Get-Content "report.csv" | Out-File "report-utf8.csv" -Encoding UTF8
```

### Environment-Specific Issues

#### Issue: "Cannot access default environment"
```
Error: Access denied to default environment
```

**Solutions:**
1. **Check Default Environment Settings**: May have restricted access
2. **Use Specific Environment ID**: Target non-default environments
3. **Contact Tenant Administrator**: May need elevated permissions

#### Issue: "Mixed results across environments"
```
Problem: Some environments return data, others don't
```

**Diagnostic Steps:**
```powershell
# Test each environment individually
$environments = Get-AdminPowerAppEnvironment
foreach ($env in $environments) {
    try {
        $flows = Get-AdminFlow -EnvironmentName $env.EnvironmentName
        Write-Host "$($env.DisplayName): $($flows.Count) flows" -ForegroundColor Green
    } catch {
        Write-Host "$($env.DisplayName): ERROR - $($_.Exception.Message)" -ForegroundColor Red
    }
}
```

### Licensing and Compliance Issues

#### Issue: "Premium connector licensing warnings"
```
Warning: Premium connector detected but licensing unclear
```

**Resolution Steps:**
1. **Verify License Assignment**: Check user and environment licensing
2. **Review Usage Rights**: Confirm connector is included in license
3. **Contact Licensing Team**: Validate compliance requirements

#### Issue: "DLP policy conflicts"
```
Warning: Connector blocked by DLP but connection exists
```

**Investigation Process:**
1. **Review DLP Policy History**: Check for recent policy changes
2. **Validate Connection Status**: Confirm connection functionality
3. **Check Policy Scope**: Verify environment coverage
4. **Test Flow Execution**: Validate actual impact

## Diagnostic Commands

### Environment Diagnostic
```powershell
# Complete environment diagnostic
function Test-EnvironmentAccess {
    param([string]$EnvironmentName)
    
    Write-Host "Testing environment: $EnvironmentName" -ForegroundColor Yellow
    
    try {
        $env = Get-AdminPowerAppEnvironment -EnvironmentName $EnvironmentName
        Write-Host "✓ Environment accessible" -ForegroundColor Green
        
        $flows = Get-AdminFlow -EnvironmentName $EnvironmentName
        Write-Host "✓ Flows: $($flows.Count)" -ForegroundColor Green
        
        $connections = Get-AdminPowerAppConnection -EnvironmentName $EnvironmentName
        Write-Host "✓ Connections: $($connections.Count)" -ForegroundColor Green
        
        $users = Get-AdminPowerAppEnvironmentRoleAssignment -EnvironmentName $EnvironmentName
        Write-Host "✓ Users: $($users.Count)" -ForegroundColor Green
        
    } catch {
        Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}
```

### Module Diagnostic
```powershell
# PowerShell module diagnostic
function Test-PowerPlatformModules {
    $requiredModules = @(
        "Microsoft.PowerApps.Administration.PowerShell",
        "Microsoft.PowerApps.PowerShell"
    )
    
    foreach ($module in $requiredModules) {
        $installed = Get-Module -Name $module -ListAvailable
        if ($installed) {
            Write-Host "✓ $module version $($installed.Version)" -ForegroundColor Green
        } else {
            Write-Host "✗ $module not installed" -ForegroundColor Red
            Write-Host "  Install: Install-Module -Name $module -Force" -ForegroundColor Yellow
        }
    }
}
```

### Connection Diagnostic
```powershell
# Test Power Platform connectivity
function Test-PowerPlatformConnectivity {
    try {
        $tenant = Get-TenantDetailsFromGraph
        Write-Host "✓ Connected to tenant: $($tenant.displayName)" -ForegroundColor Green
        
        $environments = Get-AdminPowerAppEnvironment
        Write-Host "✓ Accessible environments: $($environments.Count)" -ForegroundColor Green
        
        return $true
    } catch {
        Write-Host "✗ Connection failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Run: Add-PowerAppsAccount" -ForegroundColor Yellow
        return $false
    }
}
```

## Getting Additional Help

### Log Collection
```powershell
# Enable verbose logging
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

# Start transcript for full logging
Start-Transcript -Path "assessment-log-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

# Run assessment with logging
.\PowerAutomate-SecurityAssessment.ps1 -Verbose

# Stop transcript
Stop-Transcript
```

### Version Information
```powershell
# Collect version information for support
$versionInfo = @{
    PowerShellVersion = $PSVersionTable.PSVersion
    OperatingSystem = $PSVersionTable.OS
    PowerAppsAdminModule = (Get-Module Microsoft.PowerApps.Administration.PowerShell -ListAvailable).Version
    PowerAppsModule = (Get-Module Microsoft.PowerApps.PowerShell -ListAvailable).Version
    ScriptVersion = "1.0.0"  # Update with actual script version
}

$versionInfo | ConvertTo-Json | Out-File "version-info.json"
```

### Support Information Collection
When reporting issues, include:
1. PowerShell version (`$PSVersionTable`)
2. Module versions (`Get-Module -Name Microsoft.PowerApps* -ListAvailable`)
3. Error messages (exact text)
4. Steps to reproduce
5. Environment details (tenant, region)
6. Network configuration (proxy, firewall)

For complex issues, consider engaging Microsoft Support with:
- Tenant ID
- Environment ID
- Timestamp of issue occurrence
- User account experiencing the issue