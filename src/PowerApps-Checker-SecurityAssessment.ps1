#Requires -Modules Microsoft.PowerApps.Checker.PowerShell

<#
.SYNOPSIS
    PowerApps Solution Checker Security Assessment Tool
.DESCRIPTION
    Analyzes PowerApps solutions for security vulnerabilities, performance issues, and best practice violations.
    Supports commercial and government cloud environments (GCC, GCC High, DOD).
.PARAMETER SolutionPath
    Path to the solution file (.zip) to analyze
.PARAMETER OutputPath
    Path to save the assessment report (default: current directory)
.PARAMETER ExportFormat
    Export format: JSON, CSV, or HTML (default: HTML)
.PARAMETER CloudEnvironment
    Cloud environment: Commercial, GCC, GCCHigh, or DOD (default: Commercial)
.PARAMETER ClientApplicationId
    Azure AD Application ID for authentication
.PARAMETER TenantId
    Azure AD Tenant ID
.PARAMETER ClientApplicationSecret
    Azure AD Application Secret (secure string)
.PARAMETER Ruleset
    Specific ruleset to use (optional, defaults to all except AppSource Certification)
.PARAMETER IncludeDetailedResults
    Include detailed SARIF results in the output
.EXAMPLE
    .\PowerApps-Checker-SecurityAssessment.ps1 -SolutionPath "C:\Solutions\MySolution.zip" -CloudEnvironment "Commercial"
.EXAMPLE
    .\PowerApps-Checker-SecurityAssessment.ps1 -SolutionPath "C:\Solutions\MySolution.zip" -CloudEnvironment "GCCHigh" -ClientApplicationId "guid" -TenantId "guid"
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$SolutionPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV", "HTML")]
    [string]$ExportFormat = "HTML",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Commercial", "GCC", "GCCHigh", "DOD")]
    [string]$CloudEnvironment = "Commercial",
    
    [Parameter(Mandatory = $false)]
    [string]$ClientApplicationId,
    
    [Parameter(Mandatory = $false)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $false)]
    [System.Security.SecureString]$ClientApplicationSecret,
    
    [Parameter(Mandatory = $false)]
    [string]$Ruleset,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeDetailedResults
)

# Global variables for assessment results
$Global:CheckerAssessmentResults = @{
    Timestamp = Get-Date
    CloudEnvironment = $CloudEnvironment
    SolutionFile = (Get-Item $SolutionPath).Name
    SolutionSize = [math]::Round((Get-Item $SolutionPath).Length / 1MB, 2)
    AnalysisResults = $null
    SecurityFindings = @()
    PerformanceFindings = @()
    BestPracticeFindings = @()
    DeprecatedApiFindings = @()
    Summary = @{}
    RulesetsUsed = @()
    DetailedResults = $null
}

# Cloud environment configurations
$CloudConfigurations = @{
    Commercial = @{
        Endpoint = "prod"
        Geography = "UnitedStates"
        AuthEndpoint = "https://login.microsoftonline.com"
        GraphEndpoint = "https://graph.microsoft.com"
    }
    GCC = @{
        Endpoint = "usgov"
        Geography = "USGov"
        AuthEndpoint = "https://login.microsoftonline.com"
        GraphEndpoint = "https://graph.microsoft.com"
    }
    GCCHigh = @{
        Endpoint = "usgovhigh"
        Geography = "USGovHigh"
        AuthEndpoint = "https://login.microsoftonline.us"
        GraphEndpoint = "https://graph.microsoft.us"
    }
    DOD = @{
        Endpoint = "dod"
        Geography = "USGovDoD"
        AuthEndpoint = "https://login.microsoftonline.us"
        GraphEndpoint = "https://graph.microsoft.us"
    }
}

function Write-CheckerLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success", "Finding")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        "Finding" { "Cyan" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-CheckerConnection {
    Write-CheckerLog "Testing PowerApps Checker connection for $CloudEnvironment environment..." "Info"
    
    try {
        $config = $CloudConfigurations[$CloudEnvironment]
        
        # For commercial environment, interactive auth is supported
        if ($CloudEnvironment -eq "Commercial" -and -not $ClientApplicationId) {
            Write-CheckerLog "Using interactive authentication for commercial environment" "Info"
            Add-PowerAppsAccount -Endpoint $config.Endpoint
        }
        else {
            # Service principal auth required for gov clouds or when specified
            if (-not $ClientApplicationId -or -not $TenantId) {
                throw "ClientApplicationId and TenantId are required for $CloudEnvironment environment"
            }
            
            Write-CheckerLog "Using service principal authentication" "Info"
            # Note: PowerApps Checker typically uses direct API calls with service principal
        }
        
        Write-CheckerLog "Successfully configured for $CloudEnvironment environment" "Success"
        return $true
    }
    catch {
        Write-CheckerLog "Failed to configure PowerApps Checker: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Get-CheckerRulesets {
    Write-CheckerLog "Retrieving available rulesets..." "Info"
    
    try {
        $config = $CloudConfigurations[$CloudEnvironment]
        $rulesets = Get-PowerAppsCheckerRulesets -Geography $config.Geography
        
        # Filter out AppSource Certification by default unless specified
        if (-not $Ruleset) {
            $selectedRulesets = $rulesets | Where-Object { $_.Name -ne 'AppSource Certification' }
            Write-CheckerLog "Selected all rulesets except AppSource Certification" "Info"
        }
        else {
            $selectedRulesets = $rulesets | Where-Object { $_.Name -eq $Ruleset }
            if (-not $selectedRulesets) {
                throw "Ruleset '$Ruleset' not found"
            }
            Write-CheckerLog "Selected ruleset: $Ruleset" "Info"
        }
        
        foreach ($rs in $selectedRulesets) {
            $Global:CheckerAssessmentResults.RulesetsUsed += @{
                Name = $rs.Name
                Id = $rs.Id
                Description = $rs.Description
            }
        }
        
        return $selectedRulesets
    }
    catch {
        Write-CheckerLog "Error retrieving rulesets: $($_.Exception.Message)" "Error"
        return $null
    }
}

function Invoke-SolutionAnalysis {
    param(
        [object]$Rulesets
    )
    
    Write-CheckerLog "Starting solution analysis..." "Info"
    Write-CheckerLog "Solution file: $SolutionPath" "Info"
    Write-CheckerLog "File size: $($Global:CheckerAssessmentResults.SolutionSize) MB" "Info"
    
    # Check file size limit (30MB)
    if ($Global:CheckerAssessmentResults.SolutionSize -gt 30) {
        Write-CheckerLog "Solution file exceeds 30MB limit. Consider using blob storage with SAS URI." "Warning"
    }
    
    try {
        $config = $CloudConfigurations[$CloudEnvironment]
        
        # Build parameters for Invoke-PowerAppsChecker
        $checkerParams = @{
            Geography = $config.Geography
            FileUnderAnalysis = $SolutionPath
            OutputDirectory = $OutputPath
            Ruleset = $Rulesets
        }
        
        # Add authentication parameters if provided
        if ($ClientApplicationId -and $TenantId) {
            $checkerParams.ClientApplicationId = $ClientApplicationId
            $checkerParams.TenantId = $TenantId
            
            if ($ClientApplicationSecret) {
                $checkerParams.ClientApplicationSecret = $ClientApplicationSecret
            }
        }
        
        Write-CheckerLog "Invoking PowerApps Checker analysis (this may take several minutes)..." "Info"
        $analyzeResult = Invoke-PowerAppsChecker @checkerParams
        
        $Global:CheckerAssessmentResults.AnalysisResults = $analyzeResult
        
        Write-CheckerLog "Analysis completed successfully" "Success"
        Write-CheckerLog "Report location: $($analyzeResult.DownloadedResultFile)" "Info"
        
        return $analyzeResult
    }
    catch {
        Write-CheckerLog "Error during solution analysis: $($_.Exception.Message)" "Error"
        return $null
    }
}

function Parse-SarifResults {
    param(
        [string]$ResultsPath
    )
    
    Write-CheckerLog "Parsing SARIF results..." "Info"
    
    try {
        # Extract and read the SARIF JSON file
        $extractPath = Join-Path $OutputPath "CheckerResults_Temp"
        Expand-Archive -Path $ResultsPath -DestinationPath $extractPath -Force
        
        $sarifFile = Get-ChildItem -Path $extractPath -Filter "*.sarif" -Recurse | Select-Object -First 1
        if (-not $sarifFile) {
            throw "SARIF file not found in results"
        }
        
        $sarifContent = Get-Content $sarifFile.FullName -Raw | ConvertFrom-Json
        
        # Process findings
        foreach ($run in $sarifContent.runs) {
            foreach ($result in $run.results) {
                $finding = @{
                    RuleId = $result.ruleId
                    Level = $result.level
                    Message = $result.message.text
                    Locations = @()
                }
                
                # Add location information if available
                if ($result.locations) {
                    foreach ($location in $result.locations) {
                        if ($location.physicalLocation) {
                            $finding.Locations += @{
                                File = $location.physicalLocation.artifactLocation.uri
                                Line = $location.physicalLocation.region.startLine
                            }
                        }
                    }
                }
                
                # Categorize findings
                switch -Wildcard ($result.ruleId) {
                    "*security*" { $Global:CheckerAssessmentResults.SecurityFindings += $finding }
                    "*performance*" { $Global:CheckerAssessmentResults.PerformanceFindings += $finding }
                    "*deprecated*" { $Global:CheckerAssessmentResults.DeprecatedApiFindings += $finding }
                    default { $Global:CheckerAssessmentResults.BestPracticeFindings += $finding }
                }
                
                # Also categorize by severity
                switch ($result.level) {
                    "error" { $Global:CheckerAssessmentResults.SecurityFindings += $finding }
                    "warning" { 
                        if ($result.ruleId -like "*perf*") {
                            $Global:CheckerAssessmentResults.PerformanceFindings += $finding
                        }
                        else {
                            $Global:CheckerAssessmentResults.BestPracticeFindings += $finding
                        }
                    }
                }
            }
        }
        
        # Store detailed results if requested
        if ($IncludeDetailedResults) {
            $Global:CheckerAssessmentResults.DetailedResults = $sarifContent
        }
        
        # Clean up temporary files
        Remove-Item -Path $extractPath -Recurse -Force
        
        Write-CheckerLog "Parsed $($sarifContent.runs[0].results.Count) findings" "Success"
    }
    catch {
        Write-CheckerLog "Error parsing SARIF results: $($_.Exception.Message)" "Warning"
    }
}

function New-CheckerSecuritySummary {
    Write-CheckerLog "Generating security summary..." "Info"
    
    $summary = @{
        TotalFindings = 0
        SecurityFindings = $Global:CheckerAssessmentResults.SecurityFindings.Count
        PerformanceFindings = $Global:CheckerAssessmentResults.PerformanceFindings.Count
        BestPracticeFindings = $Global:CheckerAssessmentResults.BestPracticeFindings.Count
        DeprecatedApiFindings = $Global:CheckerAssessmentResults.DeprecatedApiFindings.Count
        CriticalFindings = 0
        HighFindings = 0
        MediumFindings = 0
        LowFindings = 0
        RecommendedActions = @()
    }
    
    # Count findings by severity
    $allFindings = @()
    $allFindings += $Global:CheckerAssessmentResults.SecurityFindings
    $allFindings += $Global:CheckerAssessmentResults.PerformanceFindings
    $allFindings += $Global:CheckerAssessmentResults.BestPracticeFindings
    $allFindings += $Global:CheckerAssessmentResults.DeprecatedApiFindings
    
    foreach ($finding in $allFindings) {
        switch ($finding.Level) {
            "error" { $summary.CriticalFindings++ }
            "warning" { $summary.HighFindings++ }
            "note" { $summary.MediumFindings++ }
            default { $summary.LowFindings++ }
        }
    }
    
    $summary.TotalFindings = $allFindings.Count
    
    # Generate recommendations
    if ($summary.SecurityFindings -gt 0) {
        $summary.RecommendedActions += "Review and remediate security findings immediately"
    }
    if ($summary.DeprecatedApiFindings -gt 0) {
        $summary.RecommendedActions += "Update deprecated API usage to ensure future compatibility"
    }
    if ($summary.PerformanceFindings -gt 5) {
        $summary.RecommendedActions += "Optimize solution performance based on checker recommendations"
    }
    if ($summary.CriticalFindings -gt 0) {
        $summary.RecommendedActions += "Address critical findings before deployment"
    }
    
    # Add cloud-specific recommendations
    if ($CloudEnvironment -in @("GCCHigh", "DOD")) {
        $summary.RecommendedActions += "Ensure compliance with government cloud security requirements"
    }
    
    $Global:CheckerAssessmentResults.Summary = $summary
}

function Export-CheckerAssessmentReport {
    param(
        [string]$OutputPath,
        [string]$Format
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $filename = "PowerApps-CheckerAssessment-$CloudEnvironment-$timestamp"
    
    switch ($Format) {
        "JSON" {
            $filepath = Join-Path $OutputPath "$filename.json"
            $Global:CheckerAssessmentResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $filepath -Encoding UTF8
        }
        "CSV" {
            $basePath = Join-Path $OutputPath $filename
            
            # Export findings to separate CSV files
            if ($Global:CheckerAssessmentResults.SecurityFindings.Count -gt 0) {
                $Global:CheckerAssessmentResults.SecurityFindings | Export-Csv -Path "$basePath-SecurityFindings.csv" -NoTypeInformation
            }
            if ($Global:CheckerAssessmentResults.PerformanceFindings.Count -gt 0) {
                $Global:CheckerAssessmentResults.PerformanceFindings | Export-Csv -Path "$basePath-PerformanceFindings.csv" -NoTypeInformation
            }
            if ($Global:CheckerAssessmentResults.BestPracticeFindings.Count -gt 0) {
                $Global:CheckerAssessmentResults.BestPracticeFindings | Export-Csv -Path "$basePath-BestPracticeFindings.csv" -NoTypeInformation
            }
            
            $filepath = "$basePath-*.csv"
        }
        "HTML" {
            $filepath = Join-Path $OutputPath "$filename.html"
            
            # Generate HTML report
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>PowerApps Solution Checker Security Assessment</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1400px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #0078d4 0%, #106ebe 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; text-align: center; }
        .cloud-badge { display: inline-block; background-color: #ffd700; color: #333; padding: 5px 15px; border-radius: 20px; font-weight: bold; margin-top: 10px; }
        .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 30px 0; }
        .metric-card { background-color: #f8f9fa; padding: 20px; border-radius: 8px; text-align: center; border: 2px solid #e9ecef; transition: transform 0.2s; }
        .metric-card:hover { transform: translateY(-5px); box-shadow: 0 5px 15px rgba(0,0,0,0.1); }
        .metric-value { font-size: 36px; font-weight: bold; margin: 10px 0; }
        .metric-label { color: #6c757d; font-size: 14px; text-transform: uppercase; }
        .critical { color: #dc3545; }
        .high { color: #fd7e14; }
        .medium { color: #ffc107; }
        .low { color: #28a745; }
        .finding-card { background-color: #fff; border: 1px solid #dee2e6; padding: 20px; margin: 10px 0; border-radius: 8px; }
        .finding-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
        .finding-rule { font-weight: bold; color: #495057; }
        .finding-level { padding: 5px 10px; border-radius: 5px; font-size: 12px; font-weight: bold; text-transform: uppercase; }
        .level-error { background-color: #dc3545; color: white; }
        .level-warning { background-color: #ffc107; color: #333; }
        .level-note { background-color: #17a2b8; color: white; }
        .finding-message { color: #6c757d; margin: 10px 0; }
        .finding-location { font-family: monospace; font-size: 12px; color: #007bff; }
        .section { margin: 40px 0; }
        .section-title { font-size: 24px; color: #333; margin-bottom: 20px; border-bottom: 2px solid #0078d4; padding-bottom: 10px; }
        .recommendation { background-color: #d1ecf1; border: 1px solid #bee5eb; padding: 15px; margin: 10px 0; border-radius: 6px; color: #0c5460; }
        .ruleset-info { background-color: #e8f4fd; padding: 15px; margin: 10px 0; border-radius: 6px; }
        .footer { margin-top: 40px; padding: 20px; background-color: #f8f9fa; border-radius: 8px; text-align: center; font-size: 12px; color: #666; }
        @media (max-width: 768px) {
            .summary-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ PowerApps Solution Checker Assessment</h1>
            <p>Security and Best Practice Analysis Report</p>
            <div class="cloud-badge">$CloudEnvironment Environment</div>
            <p style="margin-top: 15px;">Generated: $($Global:CheckerAssessmentResults.Timestamp)</p>
            <p>Solution: $($Global:CheckerAssessmentResults.SolutionFile) ($($Global:CheckerAssessmentResults.SolutionSize) MB)</p>
        </div>
        
        <div class="section">
            <h2 class="section-title">📊 Executive Summary</h2>
            <div class="summary-grid">
                <div class="metric-card">
                    <div class="metric-value">$($Global:CheckerAssessmentResults.Summary.TotalFindings)</div>
                    <div class="metric-label">Total Findings</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value critical">$($Global:CheckerAssessmentResults.Summary.CriticalFindings)</div>
                    <div class="metric-label">Critical</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value high">$($Global:CheckerAssessmentResults.Summary.HighFindings)</div>
                    <div class="metric-label">High</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value medium">$($Global:CheckerAssessmentResults.Summary.MediumFindings)</div>
                    <div class="metric-label">Medium</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value low">$($Global:CheckerAssessmentResults.Summary.LowFindings)</div>
                    <div class="metric-label">Low</div>
                </div>
            </div>
        </div>
        
        <div class="section">
            <h2 class="section-title">📋 Analysis Overview</h2>
            <div class="summary-grid">
                <div class="metric-card">
                    <div class="metric-value">$($Global:CheckerAssessmentResults.Summary.SecurityFindings)</div>
                    <div class="metric-label">Security Issues</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">$($Global:CheckerAssessmentResults.Summary.PerformanceFindings)</div>
                    <div class="metric-label">Performance Issues</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">$($Global:CheckerAssessmentResults.Summary.BestPracticeFindings)</div>
                    <div class="metric-label">Best Practice Issues</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">$($Global:CheckerAssessmentResults.Summary.DeprecatedApiFindings)</div>
                    <div class="metric-label">Deprecated APIs</div>
                </div>
            </div>
        </div>
        
        <div class="section">
            <h2 class="section-title">🔧 Rulesets Applied</h2>
"@
            
            foreach ($ruleset in $Global:CheckerAssessmentResults.RulesetsUsed) {
                $html += @"
            <div class="ruleset-info">
                <strong>$($ruleset.Name)</strong><br>
                <span style="color: #6c757d;">$($ruleset.Description)</span>
            </div>
"@
            }
            
            if ($Global:CheckerAssessmentResults.SecurityFindings.Count -gt 0) {
                $html += @"
        </div>
        
        <div class="section">
            <h2 class="section-title">🚨 Security Findings</h2>
"@
                foreach ($finding in $Global:CheckerAssessmentResults.SecurityFindings) {
                    $levelClass = "level-$($finding.Level)"
                    $html += @"
            <div class="finding-card">
                <div class="finding-header">
                    <span class="finding-rule">$($finding.RuleId)</span>
                    <span class="finding-level $levelClass">$($finding.Level)</span>
                </div>
                <div class="finding-message">$($finding.Message)</div>
"@
                    if ($finding.Locations.Count -gt 0) {
                        foreach ($location in $finding.Locations) {
                            $html += @"
                <div class="finding-location">📍 $($location.File):$($location.Line)</div>
"@
                        }
                    }
                    $html += @"
            </div>
"@
                }
            }
            
            if ($Global:CheckerAssessmentResults.PerformanceFindings.Count -gt 0) {
                $html += @"
        </div>
        
        <div class="section">
            <h2 class="section-title">⚡ Performance Findings</h2>
"@
                foreach ($finding in $Global:CheckerAssessmentResults.PerformanceFindings | Select-Object -First 10) {
                    $levelClass = "level-$($finding.Level)"
                    $html += @"
            <div class="finding-card">
                <div class="finding-header">
                    <span class="finding-rule">$($finding.RuleId)</span>
                    <span class="finding-level $levelClass">$($finding.Level)</span>
                </div>
                <div class="finding-message">$($finding.Message)</div>
            </div>
"@
                }
                
                if ($Global:CheckerAssessmentResults.PerformanceFindings.Count -gt 10) {
                    $html += @"
            <div style="text-align: center; color: #6c757d; margin: 20px 0;">
                ... and $($Global:CheckerAssessmentResults.PerformanceFindings.Count - 10) more performance findings
            </div>
"@
                }
            }
            
            $html += @"
        </div>
        
        <div class="section">
            <h2 class="section-title">💡 Recommendations</h2>
"@
            
            foreach ($recommendation in $Global:CheckerAssessmentResults.Summary.RecommendedActions) {
                $html += @"
            <div class="recommendation">
                <strong>Action Required:</strong> $recommendation
            </div>
"@
            }
            
            # Add cloud-specific recommendations
            if ($CloudEnvironment -in @("GCCHigh", "DOD")) {
                $html += @"
            <div class="recommendation" style="background-color: #fff3cd; border-color: #ffeaa7; color: #856404;">
                <strong>Government Cloud Notice:</strong> This solution will be deployed in a $CloudEnvironment environment. 
                Ensure all components meet government cloud compliance requirements and security standards.
            </div>
"@
            }
            
            $html += @"
        </div>
        
        <div class="footer">
            <p>PowerApps Solution Checker Security Assessment Tool</p>
            <p>Environment: $CloudEnvironment | Analysis completed in $($Global:CheckerAssessmentResults.AnalysisResults.Status)</p>
            <p>For detailed results, refer to the SARIF file: $($Global:CheckerAssessmentResults.AnalysisResults.DownloadedResultFile)</p>
        </div>
    </div>
</body>
</html>
"@
            
            $html | Out-File -FilePath $filepath -Encoding UTF8
        }
    }
    
    Write-CheckerLog "Report exported to: $filepath" "Success"
    return $filepath
}

# Main execution function
function Start-CheckerSecurityAssessment {
    Write-CheckerLog "Starting PowerApps Solution Checker Security Assessment" "Info"
    Write-CheckerLog "Target environment: $CloudEnvironment" "Info"
    
    # Validate solution file
    if (-not (Test-Path $SolutionPath)) {
        Write-CheckerLog "Solution file not found: $SolutionPath" "Error"
        return
    }
    
    # Test connection
    if (-not (Test-CheckerConnection)) {
        return
    }
    
    # Get rulesets
    $rulesets = Get-CheckerRulesets
    if (-not $rulesets) {
        Write-CheckerLog "Failed to retrieve rulesets" "Error"
        return
    }
    
    # Perform analysis
    $analysisResult = Invoke-SolutionAnalysis -Rulesets $rulesets
    if (-not $analysisResult) {
        Write-CheckerLog "Analysis failed" "Error"
        return
    }
    
    # Parse results
    if ($analysisResult.DownloadedResultFile) {
        Parse-SarifResults -ResultsPath $analysisResult.DownloadedResultFile
    }
    
    # Generate summary
    New-CheckerSecuritySummary
    
    # Export report
    $reportPath = Export-CheckerAssessmentReport -OutputPath $OutputPath -Format $ExportFormat
    
    Write-CheckerLog "Solution Checker assessment completed" "Success"
    Write-CheckerLog "Total findings: $($Global:CheckerAssessmentResults.Summary.TotalFindings)" "Info"
    Write-CheckerLog "Critical findings: $($Global:CheckerAssessmentResults.Summary.CriticalFindings)" $(if ($Global:CheckerAssessmentResults.Summary.CriticalFindings -gt 0) { "Warning" } else { "Info" })
    
    return $reportPath
}

# Execute the assessment
Start-CheckerSecurityAssessment