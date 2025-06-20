#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Deployment and Startup Script for Power Automate Security Assessment API
.DESCRIPTION
    This script handles the deployment, configuration, and startup of the Power Automate 
    Security Assessment API server. It includes options for installing dependencies,
    configuring security, and setting up the service.
.PARAMETER Install
    Install required dependencies and modules
.PARAMETER Configure
    Configure the API settings interactively
.PARAMETER Start
    Start the API server
.PARAMETER Service
    Install as Windows service
.PARAMETER Port
    Port number for the API server (default: 8080)
.PARAMETER Https
    Enable HTTPS with self-signed certificate
.PARAMETER Production
    Configure for production environment
.EXAMPLE
    .\Deploy-SecurityAPI.ps1 -Install -Configure -Start
.EXAMPLE
    .\Deploy-SecurityAPI.ps1 -Service -Production -Port 443 -Https
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$Install,
    
    [Parameter(Mandatory = $false)]
    [switch]$Configure,
    
    [Parameter(Mandatory = $false)]
    [switch]$Start,
    
    [Parameter(Mandatory = $false)]
    [switch]$Service,
    
    [Parameter(Mandatory = $false)]
    [int]$Port = 8080,
    
    [Parameter(Mandatory = $false)]
    [switch]$Https,
    
    [Parameter(Mandatory = $false)]
    [switch]$Production,
    
    [Parameter(Mandatory = $false)]
    [switch]$Uninstall
)

# Global variables
$ScriptPath = $PSScriptRoot
$ServiceName = "PowerAutomateSecurityAPI"
$ServiceDisplayName = "Power Automate Security Assessment API"
$ServiceDescription = "REST API server for Power Automate security assessment data"
$LogPath = Join-Path $ScriptPath "deployment.log"

function Write-DeployLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
    $logMessage | Out-File -FilePath $LogPath -Append -Encoding UTF8
}

function Test-RunningAsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Dependencies {
    Write-DeployLog "Installing required dependencies..." "Info"
    
    try {
        # Check PowerShell execution policy
        $executionPolicy = Get-ExecutionPolicy
        if ($executionPolicy -eq "Restricted") {
            Write-DeployLog "Setting execution policy to RemoteSigned..." "Info"
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
        }
        
        # Install PowerShellGet if needed
        if (-not (Get-Module -ListAvailable -Name PowerShellGet)) {
            Write-DeployLog "Installing PowerShellGet module..." "Info"
            Install-Module -Name PowerShellGet -Force -AllowClobber
        }
        
        # Install NuGet provider
        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Write-DeployLog "Installing NuGet package provider..." "Info"
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        }
        
        # Install Power Platform modules
        $requiredModules = @(
            "Microsoft.PowerApps.Administration.PowerShell",
            "Microsoft.PowerApps.PowerShell"
        )
        
        foreach ($module in $requiredModules) {
            if (-not (Get-Module -ListAvailable -Name $module)) {
                Write-DeployLog "Installing $module..." "Info"
                Install-Module -Name $module -Force -AllowClobber -Scope AllUsers
            } else {
                Write-DeployLog "$module is already installed" "Success"
            }
        }
        
        # Install additional useful modules
        $optionalModules = @(
            "SqlServer",
            "ImportExcel"
        )
        
        foreach ($module in $optionalModules) {
            if (-not (Get-Module -ListAvailable -Name $module)) {
                Write-DeployLog "Installing optional module $module..." "Info"
                try {
                    Install-Module -Name $module -Force -AllowClobber -Scope AllUsers -ErrorAction SilentlyContinue
                } catch {
                    Write-DeployLog "Could not install $module (optional): $($_.Exception.Message)" "Warning"
                }
            }
        }
        
        Write-DeployLog "Dependencies installed successfully" "Success"
        
    } catch {
        Write-DeployLog "Error installing dependencies: $($_.Exception.Message)" "Error"
        throw
    }
}

function Initialize-Configuration {
    Write-DeployLog "Configuring API settings..." "Info"
    
    try {
        $configPath = Join-Path $ScriptPath "API-Config.json"
        
        if (Test-Path $configPath) {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        } else {
            Write-DeployLog "Configuration file not found, creating default..." "Warning"
            # The default config will be created by the main API script
            return
        }
        
        # Interactive configuration if requested
        if ($Configure) {
            Write-Host "`n=== API Configuration Setup ===" -ForegroundColor Cyan
            
            # Server settings
            $newPort = Read-Host "Enter API port (current: $($config.Server.Port))"
            if ($newPort -and $newPort -match '^\d+$') {
                $config.Server.Port = [int]$newPort
            }
            
            $enableCors = Read-Host "Enable CORS? (current: $($config.Server.EnableCors)) [y/n]"
            if ($enableCors -eq 'y' -or $enableCors -eq 'yes') {
                $config.Server.EnableCors = $true
            } elseif ($enableCors -eq 'n' -or $enableCors -eq 'no') {
                $config.Server.EnableCors = $false
            }
            
            # Authentication settings
            $enableAuth = Read-Host "Enable authentication? (current: $($config.Authentication.Enabled)) [y/n]"
            if ($enableAuth -eq 'y' -or $enableAuth -eq 'yes') {
                $config.Authentication.Enabled = $true
                
                $generateNewKeys = Read-Host "Generate new API keys? [y/n]"
                if ($generateNewKeys -eq 'y' -or $generateNewKeys -eq 'yes') {
                    $config.Authentication.ApiKeys = @()
                    
                    # Generate new API keys
                    $keyNames = @("PowerBI", "Tableau", "Admin")
                    foreach ($keyName in $keyNames) {
                        $newKey = New-Object PSObject -Property @{
                            Key = [System.Web.Security.Membership]::GeneratePassword(32, 8)
                            Name = "$keyName Connection"
                            Description = "API key for $keyName dashboard connections"
                            Permissions = if ($keyName -eq "Admin") { @("read", "admin") } else { @("read") }
                            Created = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                            ExpiresAt = $null
                        }
                        $config.Authentication.ApiKeys += $newKey
                        Write-DeployLog "Generated API key for $keyName`: $($newKey.Key)" "Success"
                    }
                }
            } elseif ($enableAuth -eq 'n' -or $enableAuth -eq 'no') {
                $config.Authentication.Enabled = $false
            }
            
            # Security settings
            if ($Production) {
                Write-DeployLog "Applying production security settings..." "Info"
                $config.Security.RateLimitingEnabled = $true
                $config.Security.MaxRequestsPerMinute = 60
                $config.Authentication.Enabled = $true
                $config.Logging.Level = "Warning"
                
                if ($Https) {
                    $config.Security.EnableHttps = $true
                }
            }
            
            # Save configuration
            $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
            Write-DeployLog "Configuration saved to $configPath" "Success"
        }
        
        # Apply command line overrides
        if ($Port -ne 8080) {
            $config.Server.Port = $Port
            $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
            Write-DeployLog "Port updated to $Port" "Info"
        }
        
        if ($Https) {
            $config.Security.EnableHttps = $true
            $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
            Write-DeployLog "HTTPS enabled" "Info"
        }
        
    } catch {
        Write-DeployLog "Error configuring API: $($_.Exception.Message)" "Error"
        throw
    }
}

function New-SelfSignedCertificateForAPI {
    Write-DeployLog "Creating self-signed certificate for HTTPS..." "Info"
    
    try {
        $cert = New-SelfSignedCertificate -DnsName "localhost", "127.0.0.1" -CertStoreLocation "cert:\LocalMachine\My" -KeyUsage DigitalSignature, KeyEncipherment -Type SSLServerAuthentication
        
        # Add certificate to trusted root
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreName]::Root, [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        $store.Add($cert)
        $store.Close()
        
        Write-DeployLog "Certificate created with thumbprint: $($cert.Thumbprint)" "Success"
        
        # Update configuration with certificate thumbprint
        $configPath = Join-Path $ScriptPath "API-Config.json"
        if (Test-Path $configPath) {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            $config.Security.CertificateThumbprint = $cert.Thumbprint
            $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
        }
        
        return $cert.Thumbprint
        
    } catch {
        Write-DeployLog "Error creating certificate: $($_.Exception.Message)" "Error"
        throw
    }
}

function Set-UrlReservation {
    param([int]$Port, [string]$Protocol = "http")
    
    Write-DeployLog "Setting up URL reservation for $Protocol`:://+:$Port/" "Info"
    
    try {
        $url = "$Protocol`:://+:$Port/"
        
        # Check if reservation already exists
        $existing = netsh http show urlacl url=$url 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-DeployLog "URL reservation already exists" "Info"
            return
        }
        
        # Create URL reservation
        $result = netsh http add urlacl url=$url user="Everyone" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-DeployLog "URL reservation created successfully" "Success"
        } else {
            Write-DeployLog "Failed to create URL reservation: $result" "Warning"
        }
        
    } catch {
        Write-DeployLog "Error setting URL reservation: $($_.Exception.Message)" "Warning"
    }
}

function Install-WindowsService {
    Write-DeployLog "Installing Windows service..." "Info"
    
    try {
        # Check if service already exists
        $existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($existingService) {
            Write-DeployLog "Service $ServiceName already exists. Stopping and removing..." "Warning"
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
            Remove-Service -Name $ServiceName -ErrorAction SilentlyContinue
        }
        
        # Create service wrapper script
        $serviceScript = Join-Path $ScriptPath "ServiceWrapper.ps1"
        $serviceWrapperContent = @"
# Service Wrapper for Power Automate Security API
`$ErrorActionPreference = "Stop"

try {
    Set-Location "$ScriptPath"
    & ".\PowerAutomate-SecurityAPI.ps1" -Port $Port
} catch {
    Write-EventLog -LogName Application -Source "$ServiceName" -EventId 1000 -EntryType Error -Message "Service error: `$(`$_.Exception.Message)"
    throw
}
"@
        $serviceWrapperContent | Out-File -FilePath $serviceScript -Encoding UTF8
        
        # Create service using NSSM (if available) or sc.exe
        if (Get-Command nssm -ErrorAction SilentlyContinue) {
            Write-DeployLog "Using NSSM to create service..." "Info"
            
            & nssm install $ServiceName "powershell.exe" "-ExecutionPolicy Bypass -File `"$serviceScript`""
            & nssm set $ServiceName Description "$ServiceDescription"
            & nssm set $ServiceName Start SERVICE_AUTO_START
            & nssm set $ServiceName AppStdout (Join-Path $ScriptPath "service-stdout.log")
            & nssm set $ServiceName AppStderr (Join-Path $ScriptPath "service-stderr.log")
            
        } else {
            Write-DeployLog "NSSM not found, using sc.exe..." "Info"
            
            $binaryPath = "powershell.exe -ExecutionPolicy Bypass -File `"$serviceScript`""
            & sc.exe create $ServiceName binPath= $binaryPath DisplayName= "$ServiceDisplayName" start= auto
            & sc.exe description $ServiceName "$ServiceDescription"
        }
        
        # Create event log source
        try {
            if (-not [System.Diagnostics.EventLog]::SourceExists($ServiceName)) {
                New-EventLog -LogName Application -Source $ServiceName
            }
        } catch {
            Write-DeployLog "Could not create event log source: $($_.Exception.Message)" "Warning"
        }
        
        Write-DeployLog "Windows service installed successfully" "Success"
        
    } catch {
        Write-DeployLog "Error installing Windows service: $($_.Exception.Message)" "Error"
        throw
    }
}

function Remove-WindowsService {
    Write-DeployLog "Uninstalling Windows service..." "Info"
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            if ($service.Status -eq "Running") {
                Stop-Service -Name $ServiceName -Force
                Write-DeployLog "Service stopped" "Info"
            }
            
            # Remove using NSSM or sc.exe
            if (Get-Command nssm -ErrorAction SilentlyContinue) {
                & nssm remove $ServiceName confirm
            } else {
                & sc.exe delete $ServiceName
            }
            
            Write-DeployLog "Service removed successfully" "Success"
        } else {
            Write-DeployLog "Service $ServiceName not found" "Warning"
        }
        
        # Remove service wrapper script
        $serviceScript = Join-Path $ScriptPath "ServiceWrapper.ps1"
        if (Test-Path $serviceScript) {
            Remove-Item -Path $serviceScript -Force
        }
        
    } catch {
        Write-DeployLog "Error removing Windows service: $($_.Exception.Message)" "Error"
        throw
    }
}

function Start-APIServer {
    Write-DeployLog "Starting API server..." "Info"
    
    try {
        $apiScript = Join-Path $ScriptPath "PowerAutomate-SecurityAPI.ps1"
        
        if (-not (Test-Path $apiScript)) {
            throw "API script not found at $apiScript"
        }
        
        # Test Power Platform connection first
        Write-DeployLog "Testing Power Platform connection..." "Info"
        try {
            Import-Module Microsoft.PowerApps.Administration.PowerShell -Force
            $environments = Get-AdminPowerAppEnvironment -ErrorAction Stop
            Write-DeployLog "Power Platform connection successful ($($environments.Count) environments found)" "Success"
        } catch {
            Write-DeployLog "Warning: Power Platform connection failed. API will run with limited functionality." "Warning"
            Write-DeployLog "Error: $($_.Exception.Message)" "Warning"
            Write-DeployLog "To connect to Power Platform, run: Add-PowerAppsAccount" "Info"
        }
        
        # Start the API server
        $arguments = @("-Port", $Port)
        if ($Production) {
            $arguments += @("-LogLevel", "Warning")
        }
        
        Write-DeployLog "Starting API server on port $Port..." "Info"
        Write-DeployLog "Use Ctrl+C to stop the server" "Info"
        Write-DeployLog "API will be available at: http://localhost:$Port" "Info"
        
        & $apiScript @arguments
        
    } catch {
        Write-DeployLog "Error starting API server: $($_.Exception.Message)" "Error"
        throw
    }
}

function Test-APIEndpoints {
    param([int]$Port = 8080)
    
    Write-DeployLog "Testing API endpoints..." "Info"
    
    try {
        $baseUrl = "http://localhost:$Port"
        $headers = @{ "X-API-Key" = "admin-key-abcdef123456789" }
        
        # Test health endpoint
        try {
            $response = Invoke-RestMethod -Uri "$baseUrl/api/health" -Method GET -Headers $headers -TimeoutSec 10
            Write-DeployLog "Health endpoint: OK" "Success"
        } catch {
            Write-DeployLog "Health endpoint: FAILED - $($_.Exception.Message)" "Error"
        }
        
        # Test summary endpoint
        try {
            $response = Invoke-RestMethod -Uri "$baseUrl/api/summary" -Method GET -Headers $headers -TimeoutSec 10
            Write-DeployLog "Summary endpoint: OK" "Success"
        } catch {
            Write-DeployLog "Summary endpoint: FAILED - $($_.Exception.Message)" "Error"
        }
        
        Write-DeployLog "API testing completed" "Info"
        
    } catch {
        Write-DeployLog "Error testing API endpoints: $($_.Exception.Message)" "Error"
    }
}

function Show-DeploymentSummary {
    Write-Host "`n" -NoNewline
    Write-Host "=== Power Automate Security API Deployment Summary ===" -ForegroundColor Cyan
    Write-Host ""
    
    $configPath = Join-Path $ScriptPath "API-Config.json"
    if (Test-Path $configPath) {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        
        Write-Host "Server Configuration:" -ForegroundColor Yellow
        Write-Host "  Port: $($config.Server.Port)"
        Write-Host "  CORS: $($config.Server.EnableCors)"
        Write-Host "  Authentication: $($config.Authentication.Enabled)"
        Write-Host "  HTTPS: $($config.Security.EnableHttps)"
        Write-Host "  Rate Limiting: $($config.Security.RateLimitingEnabled)"
        Write-Host ""
        
        if ($config.Authentication.Enabled -and $config.Authentication.ApiKeys.Count -gt 0) {
            Write-Host "API Keys:" -ForegroundColor Yellow
            foreach ($key in $config.Authentication.ApiKeys) {
                Write-Host "  $($key.Name): $($key.Key)" -ForegroundColor Green
            }
            Write-Host ""
        }
    }
    
    Write-Host "Available Endpoints:" -ForegroundColor Yellow
    $protocol = if ($config.Security.EnableHttps) { "https" } else { "http" }
    $port = $config.Server.Port
    Write-Host "  Health: $protocol`://localhost:$port/api/health"
    Write-Host "  Summary: $protocol`://localhost:$port/api/summary"
    Write-Host "  Environments: $protocol`://localhost:$port/api/environments"
    Write-Host "  Users: $protocol`://localhost:$port/api/users"
    Write-Host "  Connections: $protocol`://localhost:$port/api/connections"
    Write-Host "  Flows: $protocol`://localhost:$port/api/flows"
    Write-Host "  Findings: $protocol`://localhost:$port/api/findings"
    Write-Host ""
    
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Connect to Power Platform: Add-PowerAppsAccount"
    Write-Host "  2. Test API: Invoke-RestMethod -Uri '$protocol`://localhost:$port/api/health'"
    Write-Host "  3. Connect BI tools using the provided API keys"
    Write-Host "  4. Review BI-Connection-Guide.md for detailed instructions"
    Write-Host ""
    
    Write-Host "Support:" -ForegroundColor Yellow
    Write-Host "  Logs: $LogPath"
    Write-Host "  Configuration: $configPath"
    Write-Host "  Documentation: BI-Connection-Guide.md"
    Write-Host ""
}

# Main execution
function Main {
    Write-Host "=== Power Automate Security API Deployment ===" -ForegroundColor Cyan
    Write-Host "Version: 1.0" -ForegroundColor Cyan
    Write-Host ""
    
    # Check admin privileges for service installation
    if ($Service -and -not (Test-RunningAsAdmin)) {
        Write-DeployLog "Service installation requires administrator privileges" "Error"
        Write-Host "Please run this script as Administrator for service installation" -ForegroundColor Red
        exit 1
    }
    
    try {
        if ($Uninstall) {
            Write-DeployLog "Uninstalling API service..." "Info"
            Remove-WindowsService
            Write-DeployLog "Uninstallation completed" "Success"
            return
        }
        
        if ($Install) {
            Install-Dependencies
        }
        
        if ($Configure -or $Production -or $Port -ne 8080 -or $Https) {
            Initialize-Configuration
        }
        
        if ($Https) {
            New-SelfSignedCertificateForAPI
        }
        
        # Set URL reservation for HTTP.SYS
        if (Test-RunningAsAdmin) {
            $protocol = if ($Https) { "https" } else { "http" }
            Set-UrlReservation -Port $Port -Protocol $protocol
        }
        
        if ($Service) {
            Install-WindowsService
            
            Write-Host "Starting service..." -ForegroundColor Green
            Start-Service -Name $ServiceName
            
            Write-DeployLog "Service started successfully" "Success"
            
            # Test the API after a brief delay
            Start-Sleep -Seconds 5
            Test-APIEndpoints -Port $Port
            
        } elseif ($Start) {
            Start-APIServer
        }
        
        if (-not $Start) {
            Show-DeploymentSummary
        }
        
    } catch {
        Write-DeployLog "Deployment failed: $($_.Exception.Message)" "Error"
        Write-Host "Deployment failed. Check the log file: $LogPath" -ForegroundColor Red
        exit 1
    }
}

# Execute main function
Main