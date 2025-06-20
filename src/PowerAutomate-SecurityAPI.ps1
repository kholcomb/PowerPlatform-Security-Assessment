#Requires -Modules Microsoft.PowerApps.Administration.PowerShell, Microsoft.PowerApps.PowerShell

<#
.SYNOPSIS
    Power Automate Security Assessment REST API Server
.DESCRIPTION
    A lightweight PowerShell-based REST API server that provides endpoints for accessing
    Power Automate security assessment data. Designed for integration with BI tools like
    Power BI, Tableau, and other analytics platforms.
.PARAMETER Port
    The port number for the API server (default: 8080)
.PARAMETER ConfigPath
    Path to the API configuration file (default: API-Config.json)
.PARAMETER EnableSwagger
    Enable OpenAPI/Swagger documentation endpoint
.PARAMETER LogLevel
    Logging level: Debug, Info, Warning, Error (default: Info)
.EXAMPLE
    .\PowerAutomate-SecurityAPI.ps1 -Port 8080 -EnableSwagger
#>

param(
    [Parameter(Mandatory = $false)]
    [int]$Port = 8080,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "API-Config.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableSwagger,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Debug", "Info", "Warning", "Error")]
    [string]$LogLevel = "Info"
)

# Import required modules
. "$PSScriptRoot\API-Authentication.ps1"
. "$PSScriptRoot\API-Endpoints.ps1"

# Global variables
$Global:ApiConfig = $null
$Global:AssessmentCache = @{}
$Global:ApiStats = @{
    StartTime = Get-Date
    TotalRequests = 0
    SuccessfulRequests = 0
    FailedRequests = 0
    LastRequestTime = $null
}

function Write-ApiLog {
    param(
        [string]$Message,
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$Level = "Info",
        [string]$Component = "API"
    )
    
    $levelOrder = @{ "Debug" = 0; "Info" = 1; "Warning" = 2; "Error" = 3 }
    if ($levelOrder[$Level] -lt $levelOrder[$LogLevel]) { return }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "Debug" { "Cyan" }
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
    }
    
    Write-Host "[$timestamp] [$Component] [$Level] $Message" -ForegroundColor $color
    
    # Also log to file if configured
    if ($Global:ApiConfig.LogFile) {
        "[$timestamp] [$Component] [$Level] $Message" | Out-File -FilePath $Global:ApiConfig.LogFile -Append -Encoding UTF8
    }
}

function Initialize-ApiConfig {
    param([string]$ConfigPath)
    
    Write-ApiLog "Loading API configuration from $ConfigPath" "Info"
    
    if (-not (Test-Path $ConfigPath)) {
        Write-ApiLog "Configuration file not found, creating default configuration" "Warning"
        $defaultConfig = @{
            Server = @{
                Port = 8080
                MaxConcurrentRequests = 10
                RequestTimeoutSeconds = 30
                EnableCors = $true
                AllowedOrigins = @("*")
                AllowedMethods = @("GET", "POST", "OPTIONS")
                AllowedHeaders = @("Content-Type", "Authorization", "X-API-Key")
            }
            Authentication = @{
                Enabled = $true
                Type = "ApiKey"
                ApiKeys = @()
                JwtSecret = ""
                TokenExpirationMinutes = 60
            }
            Security = @{
                EnableHttps = $false
                CertificateThumbprint = ""
                RateLimitingEnabled = $true
                MaxRequestsPerMinute = 100
                TrustedProxies = @()
            }
            Cache = @{
                Enabled = $true
                DefaultTtlMinutes = 15
                MaxCacheSize = 100
            }
            Logging = @{
                Level = "Info"
                File = "api-log.txt"
                MaxFileSizeMB = 10
            }
            Assessment = @{
                DataRefreshIntervalMinutes = 60
                AutoRefreshEnabled = $true
                DefaultEnvironment = ""
            }
        }
        
        $defaultConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding UTF8
        Write-ApiLog "Default configuration created at $ConfigPath" "Info"
    }
    
    try {
        $Global:ApiConfig = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        Write-ApiLog "Configuration loaded successfully" "Info"
        
        # Override port if specified in parameters
        if ($Port -ne 8080) {
            $Global:ApiConfig.Server.Port = $Port
        }
        
        # Set log file path if specified
        if ($Global:ApiConfig.Logging.File) {
            $Global:ApiConfig.LogFile = Join-Path $PSScriptRoot $Global:ApiConfig.Logging.File
        }
        
    } catch {
        Write-ApiLog "Failed to load configuration: $($_.Exception.Message)" "Error"
        throw
    }
}

function Start-HttpListener {
    Write-ApiLog "Starting HTTP listener on port $($Global:ApiConfig.Server.Port)" "Info"
    
    $listener = New-Object System.Net.HttpListener
    $prefix = "http://localhost:$($Global:ApiConfig.Server.Port)/"
    $listener.Prefixes.Add($prefix)
    
    try {
        $listener.Start()
        Write-ApiLog "API server started successfully at $prefix" "Info"
        Write-ApiLog "Available endpoints:" "Info"
        Write-ApiLog "  GET  /api/summary     - Overall security metrics" "Info"
        Write-ApiLog "  GET  /api/environments - Environment details" "Info"
        Write-ApiLog "  GET  /api/users       - User access data" "Info"
        Write-ApiLog "  GET  /api/connections - Connection security data" "Info"
        Write-ApiLog "  GET  /api/flows       - Flow analysis data" "Info"
        Write-ApiLog "  GET  /api/findings    - Security findings" "Info"
        Write-ApiLog "  GET  /api/health      - API health status" "Info"
        if ($EnableSwagger) {
            Write-ApiLog "  GET  /swagger         - API documentation" "Info"
        }
        
        # Main request processing loop
        while ($listener.IsListening) {
            try {
                $context = $listener.GetContext()
                Process-ApiRequest -Context $context
            } catch {
                Write-ApiLog "Error processing request: $($_.Exception.Message)" "Error"
            }
        }
    } catch {
        Write-ApiLog "Failed to start HTTP listener: $($_.Exception.Message)" "Error"
        throw
    } finally {
        if ($listener.IsListening) {
            $listener.Stop()
            Write-ApiLog "HTTP listener stopped" "Info"
        }
    }
}

function Process-ApiRequest {
    param([System.Net.HttpListenerContext]$Context)
    
    $request = $Context.Request
    $response = $Context.Response
    
    $Global:ApiStats.TotalRequests++
    $Global:ApiStats.LastRequestTime = Get-Date
    
    $method = $request.HttpMethod
    $url = $request.Url.LocalPath
    $clientIp = $request.RemoteEndPoint.Address
    
    Write-ApiLog "Processing $method $url from $clientIp" "Debug"
    
    try {
        # Set CORS headers if enabled
        if ($Global:ApiConfig.Server.EnableCors) {
            Set-CorsHeaders -Response $response
        }
        
        # Handle preflight OPTIONS requests
        if ($method -eq "OPTIONS") {
            Send-ApiResponse -Response $response -StatusCode 200 -Data @{}
            return
        }
        
        # Rate limiting check
        if ($Global:ApiConfig.Security.RateLimitingEnabled) {
            if (-not (Test-RateLimit -ClientIp $clientIp)) {
                Send-ApiResponse -Response $response -StatusCode 429 -Data @{ error = "Rate limit exceeded" }
                return
            }
        }
        
        # Authentication check
        if ($Global:ApiConfig.Authentication.Enabled) {
            $authResult = Test-ApiAuthentication -Request $request
            if (-not $authResult.IsValid) {
                Send-ApiResponse -Response $response -StatusCode 401 -Data @{ error = $authResult.ErrorMessage }
                return
            }
        }
        
        # Route to appropriate endpoint handler
        $endpointResult = Invoke-ApiEndpoint -Method $method -Path $url -Request $request
        
        if ($endpointResult.Success) {
            Send-ApiResponse -Response $response -StatusCode $endpointResult.StatusCode -Data $endpointResult.Data
            $Global:ApiStats.SuccessfulRequests++
        } else {
            Send-ApiResponse -Response $response -StatusCode $endpointResult.StatusCode -Data @{ error = $endpointResult.ErrorMessage }
            $Global:ApiStats.FailedRequests++
        }
        
    } catch {
        Write-ApiLog "Unhandled error processing request: $($_.Exception.Message)" "Error"
        Send-ApiResponse -Response $response -StatusCode 500 -Data @{ error = "Internal server error" }
        $Global:ApiStats.FailedRequests++
    }
}

function Set-CorsHeaders {
    param([System.Net.HttpListenerResponse]$Response)
    
    $allowedOrigins = $Global:ApiConfig.Server.AllowedOrigins -join ","
    $allowedMethods = $Global:ApiConfig.Server.AllowedMethods -join ","
    $allowedHeaders = $Global:ApiConfig.Server.AllowedHeaders -join ","
    
    $Response.Headers.Add("Access-Control-Allow-Origin", $allowedOrigins)
    $Response.Headers.Add("Access-Control-Allow-Methods", $allowedMethods)
    $Response.Headers.Add("Access-Control-Allow-Headers", $allowedHeaders)
    $Response.Headers.Add("Access-Control-Max-Age", "86400")
}

function Send-ApiResponse {
    param(
        [System.Net.HttpListenerResponse]$Response,
        [int]$StatusCode = 200,
        [object]$Data = @{},
        [string]$ContentType = "application/json"
    )
    
    $Response.StatusCode = $StatusCode
    $Response.ContentType = "$ContentType; charset=utf-8"
    
    $jsonResponse = $Data | ConvertTo-Json -Depth 10 -Compress
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
    
    $Response.ContentLength64 = $buffer.Length
    $Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $Response.OutputStream.Close()
    
    Write-ApiLog "Response sent: $StatusCode ($($buffer.Length) bytes)" "Debug"
}

function Test-RateLimit {
    param([string]$ClientIp)
    
    # Simple in-memory rate limiting (for production, consider Redis or database)
    $rateLimitKey = "ratelimit_$ClientIp"
    $currentTime = Get-Date
    $windowStart = $currentTime.AddMinutes(-1)
    
    if (-not $Global:RateLimitCache) {
        $Global:RateLimitCache = @{}
    }
    
    if (-not $Global:RateLimitCache.ContainsKey($rateLimitKey)) {
        $Global:RateLimitCache[$rateLimitKey] = @()
    }
    
    # Clean old entries
    $Global:RateLimitCache[$rateLimitKey] = $Global:RateLimitCache[$rateLimitKey] | Where-Object { $_ -gt $windowStart }
    
    # Check if rate limit exceeded
    if ($Global:RateLimitCache[$rateLimitKey].Count -ge $Global:ApiConfig.Security.MaxRequestsPerMinute) {
        Write-ApiLog "Rate limit exceeded for $ClientIp" "Warning"
        return $false
    }
    
    # Add current request
    $Global:RateLimitCache[$rateLimitKey] += $currentTime
    
    return $true
}

function Update-AssessmentCache {
    param([switch]$Force)
    
    $cacheKey = "assessment_data"
    $currentTime = Get-Date
    
    if (-not $Force -and $Global:AssessmentCache.ContainsKey($cacheKey)) {
        $lastUpdate = $Global:AssessmentCache[$cacheKey].Timestamp
        $cacheAge = ($currentTime - $lastUpdate).TotalMinutes
        
        if ($cacheAge -lt $Global:ApiConfig.Cache.DefaultTtlMinutes) {
            Write-ApiLog "Using cached assessment data (age: $([math]::Round($cacheAge, 1)) minutes)" "Debug"
            return
        }
    }
    
    Write-ApiLog "Refreshing assessment data cache" "Info"
    
    try {
        # Load the assessment script and run it
        $assessmentScript = Join-Path $PSScriptRoot "PowerAutomate-SecurityAssessment.ps1"
        if (-not (Test-Path $assessmentScript)) {
            throw "Assessment script not found at $assessmentScript"
        }
        
        # Run assessment and capture results
        Write-ApiLog "Running security assessment..." "Info"
        $tempOutputPath = Join-Path $env:TEMP "SecurityAPI-Assessment"
        New-Item -Path $tempOutputPath -ItemType Directory -Force | Out-Null
        
        # Execute the assessment script
        $job = Start-Job -ScriptBlock {
            param($ScriptPath, $OutputPath)
            & $ScriptPath -OutputPath $OutputPath -ExportFormat "JSON"
        } -ArgumentList $assessmentScript, $tempOutputPath
        
        # Wait for job completion with timeout
        $timeout = New-TimeSpan -Minutes 10
        $completed = Wait-Job -Job $job -Timeout $timeout
        
        if ($completed) {
            $assessmentResults = Receive-Job -Job $job
            Remove-Job -Job $job
            
            # Find the JSON output file
            $jsonFiles = Get-ChildItem -Path $tempOutputPath -Filter "*.json" | Sort-Object LastWriteTime -Descending
            if ($jsonFiles.Count -gt 0) {
                $jsonData = Get-Content -Path $jsonFiles[0].FullName -Raw | ConvertFrom-Json
                
                # Update cache
                $Global:AssessmentCache[$cacheKey] = @{
                    Data = $jsonData
                    Timestamp = $currentTime
                }
                
                Write-ApiLog "Assessment data cache updated successfully" "Info"
                
                # Cleanup temp files
                Remove-Item -Path $tempOutputPath -Recurse -Force -ErrorAction SilentlyContinue
            } else {
                throw "No JSON output file found"
            }
        } else {
            Remove-Job -Job $job -Force
            throw "Assessment script timed out"
        }
        
    } catch {
        Write-ApiLog "Failed to update assessment cache: $($_.Exception.Message)" "Error"
        
        # If we have stale cache data, use it
        if ($Global:AssessmentCache.ContainsKey($cacheKey)) {
            Write-ApiLog "Using stale cache data due to refresh failure" "Warning"
        } else {
            # Create empty cache entry
            $Global:AssessmentCache[$cacheKey] = @{
                Data = @{
                    Timestamp = $currentTime
                    Environments = @()
                    Users = @()
                    Connections = @()
                    Flows = @()
                    SecurityFindings = @()
                    Summary = @{
                        TotalEnvironments = 0
                        TotalUsers = 0
                        TotalConnections = 0
                        TotalFlows = 0
                        HighRiskFindings = 0
                        MediumRiskFindings = 0
                        LowRiskFindings = 0
                    }
                }
                Timestamp = $currentTime
            }
        }
    }
}

function Get-CachedAssessmentData {
    $cacheKey = "assessment_data"
    
    if (-not $Global:AssessmentCache.ContainsKey($cacheKey)) {
        Update-AssessmentCache -Force
    }
    
    return $Global:AssessmentCache[$cacheKey].Data
}

function Start-ApiServer {
    Write-ApiLog "=== Power Automate Security Assessment API ===" "Info"
    Write-ApiLog "Version: 1.0" "Info"
    Write-ApiLog "Log Level: $LogLevel" "Info"
    
    try {
        # Initialize configuration
        Initialize-ApiConfig -ConfigPath $ConfigPath
        
        # Test Power Platform connection
        Write-ApiLog "Testing Power Platform connection..." "Info"
        try {
            $environments = Get-AdminPowerAppEnvironment -ErrorAction Stop
            Write-ApiLog "Successfully connected to Power Platform ($($environments.Count) environments found)" "Info"
        } catch {
            Write-ApiLog "Warning: Could not connect to Power Platform. API will serve cached/sample data only." "Warning"
            Write-ApiLog "Error: $($_.Exception.Message)" "Warning"
        }
        
        # Initialize assessment cache
        if ($Global:ApiConfig.Assessment.AutoRefreshEnabled) {
            Write-ApiLog "Initializing assessment data cache..." "Info"
            Update-AssessmentCache -Force
        }
        
        # Start the HTTP listener
        Start-HttpListener
        
    } catch {
        Write-ApiLog "Failed to start API server: $($_.Exception.Message)" "Error"
        throw
    }
}

# Handle Ctrl+C gracefully
$Global:CtrlCPressed = $false
[Console]::TreatControlCAsInput = $true

Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Write-ApiLog "API server shutting down..." "Info"
} | Out-Null

# Auto-refresh timer if enabled
if ($Global:ApiConfig.Assessment.AutoRefreshEnabled) {
    $timer = New-Object System.Timers.Timer
    $timer.Interval = $Global:ApiConfig.Assessment.DataRefreshIntervalMinutes * 60000 # Convert to milliseconds
    $timer.AutoReset = $true
    
    Register-ObjectEvent -InputObject $timer -EventName Elapsed -Action {
        Update-AssessmentCache
    } | Out-Null
    
    $timer.Start()
}

# Start the API server
Start-ApiServer