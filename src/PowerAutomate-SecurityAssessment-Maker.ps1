#Requires -Modules Microsoft.PowerApps.PowerShell

<#
.SYNOPSIS
    Power Automate Security Assessment Tool - Maker Edition
.DESCRIPTION
    Limited security assessment for users with Maker role permissions.
    Analyzes only accessible environments, personal flows, and connections.
.PARAMETER OutputPath
    Path to save the assessment report (default: current directory)
.PARAMETER ExportFormat
    Export format: JSON, CSV, or HTML (default: HTML)
.EXAMPLE
    .\PowerAutomate-SecurityAssessment-Maker.ps1
.EXAMPLE
    .\PowerAutomate-SecurityAssessment-Maker.ps1 -ExportFormat "JSON"
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV", "HTML")]
    [string]$ExportFormat = "HTML"
)

# Global variables for assessment results
$Global:MakerAssessmentResults = @{
    Timestamp = Get-Date
    UserContext = @{}
    AccessibleEnvironments = @()
    PersonalFlows = @()
    PersonalConnections = @()
    SecurityFindings = @()
    LimitedScopeWarnings = @()
    Summary = @{}
}

function Write-MakerAssessmentLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-MakerConnection {
    Write-MakerAssessmentLog "Testing Power Platform connection with Maker permissions..." "Info"
    
    try {
        # Test basic connectivity
        $userInfo = Get-PowerAppTenant -ErrorAction Stop
        Write-MakerAssessmentLog "Successfully connected as: $($userInfo.DisplayName)" "Success"
        
        $Global:MakerAssessmentResults.UserContext = @{
            DisplayName = $userInfo.DisplayName
            TenantId = $userInfo.TenantId
            Role = "Maker"
            AssessmentScope = "Personal and Accessible Resources Only"
        }
        
        return $true
    }
    catch {
        Write-MakerAssessmentLog "Failed to connect to Power Platform: $($_.Exception.Message)" "Error"
        Write-MakerAssessmentLog "Please ensure you're logged in with: Add-PowerAppsAccount" "Info"
        return $false
    }
}

function Get-AccessibleEnvironments {
    Write-MakerAssessmentLog "Discovering accessible environments..." "Info"
    
    try {
        # Get environments where user has maker access
        $environments = Get-PowerAppEnvironment
        
        foreach ($env in $environments) {
            $envAssessment = @{
                EnvironmentId = $env.EnvironmentName
                DisplayName = $env.DisplayName
                Type = $env.EnvironmentType
                Region = $env.Location
                IsDefault = $env.Properties.isDefault
                AccessLevel = "Maker"
                SecurityFindings = @()
                LimitedVisibility = @()
            }
            
            # Limited security checks for makers
            if ($env.EnvironmentType -eq "Production" -and $env.Properties.isDefault) {
                $envAssessment.SecurityFindings += "Using default environment for production - REVIEW RECOMMENDED"
            }
            
            # Note limitations
            $envAssessment.LimitedVisibility += "Cannot view DLP policies (requires admin role)"
            $envAssessment.LimitedVisibility += "Cannot view other users' access (requires admin role)"
            $envAssessment.LimitedVisibility += "Cannot view environment security groups"
            
            $Global:MakerAssessmentResults.AccessibleEnvironments += $envAssessment
        }
        
        Write-MakerAssessmentLog "Found $($environments.Count) accessible environment(s)" "Success"
        
    } catch {
        Write-MakerAssessmentLog "Error retrieving environments: $($_.Exception.Message)" "Warning"
        $Global:MakerAssessmentResults.LimitedScopeWarnings += "Could not retrieve environment information"
    }
}

function Get-PersonalFlows {
    Write-MakerAssessmentLog "Analyzing personal flows..." "Info"
    
    try {
        # Get flows owned/accessible to current user
        $flows = Get-PowerAppFlow
        
        foreach ($flow in $flows) {
            $flowAssessment = @{
                FlowName = $flow.FlowName
                DisplayName = $flow.DisplayName
                EnvironmentName = $flow.EnvironmentName
                State = $flow.Enabled
                CreatedTime = $flow.CreatedTime
                LastModifiedTime = $flow.LastModifiedTime
                TriggerType = "Unknown" # Limited visibility for makers
                SecurityFindings = @()
                LimitedVisibility = @()
            }
            
            # Basic security checks makers can perform
            if ($flow.Enabled -and $flow.LastModifiedTime) {
                $daysSinceModified = (Get-Date) - [DateTime]$flow.LastModifiedTime
                if ($daysSinceModified.Days -gt 90) {
                    $flowAssessment.SecurityFindings += "Flow enabled but not modified in 90+ days - REVIEW NECESSITY"
                }
            }
            
            # Check if flow is shared (limited visibility)
            try {
                $flowDetails = Get-PowerAppFlow -FlowName $flow.FlowName
                if ($flowDetails.Properties.definition) {
                    # Can see some trigger information
                    $triggers = $flowDetails.Properties.definition.triggers
                    if ($triggers) {
                        $triggerTypes = $triggers.PSObject.Properties.Name
                        $flowAssessment.TriggerType = $triggerTypes -join ", "
                        
                        # Check for potentially risky triggers
                        foreach ($triggerName in $triggerTypes) {
                            $trigger = $triggers.$triggerName
                            if ($trigger.type -eq "Request") {
                                $flowAssessment.SecurityFindings += "HTTP trigger detected - VERIFY AUTHENTICATION REQUIREMENTS"
                            }
                        }
                    }
                }
            } catch {
                $flowAssessment.LimitedVisibility += "Cannot access detailed flow definition"
            }
            
            # Note maker limitations
            $flowAssessment.LimitedVisibility += "Cannot view sharing details (requires admin role)"
            $flowAssessment.LimitedVisibility += "Cannot see other owners (requires admin role)"
            $flowAssessment.LimitedVisibility += "Limited trigger security analysis"
            
            $Global:MakerAssessmentResults.PersonalFlows += $flowAssessment
        }
        
        Write-MakerAssessmentLog "Analyzed $($flows.Count) accessible flow(s)" "Success"
        
    } catch {
        Write-MakerAssessmentLog "Error retrieving flows: $($_.Exception.Message)" "Warning"
        $Global:MakerAssessmentResults.LimitedScopeWarnings += "Could not retrieve flow information"
    }
}

function Get-PersonalConnections {
    Write-MakerAssessmentLog "Analyzing personal connections..." "Info"
    
    try {
        # Get connections created/accessible to current user
        $connections = Get-PowerAppConnection
        
        foreach ($connection in $connections) {
            $connAssessment = @{
                ConnectionName = $connection.ConnectionName
                DisplayName = $connection.DisplayName
                ConnectorName = $connection.ConnectorName
                EnvironmentName = $connection.EnvironmentName
                CreatedTime = $connection.CreatedTime
                Status = $connection.Statuses.status
                SecurityFindings = @()
                LimitedVisibility = @()
            }
            
            # Security checks makers can perform
            $highRiskConnectors = @("SQL Server", "File System", "FTP", "SFTP")
            if ($connection.ConnectorName -in $highRiskConnectors) {
                $connAssessment.SecurityFindings += "High-risk connector in use - REVIEW DATA ACCESS PATTERNS"
            }
            
            $premiumConnectors = @("SQL Server", "SharePoint", "Common Data Service", "Dataverse")
            if ($connection.ConnectorName -in $premiumConnectors) {
                $connAssessment.SecurityFindings += "Premium connector - VERIFY LICENSING COMPLIANCE"
            }
            
            # Check connection health
            if ($connection.Statuses.status -ne "Connected") {
                $connAssessment.SecurityFindings += "Connection not active - POTENTIAL SECURITY RISK"
            }
            
            # Note limitations
            $connAssessment.LimitedVisibility += "Cannot view connection authentication details"
            $connAssessment.LimitedVisibility += "Cannot see connection usage by other flows"
            $connAssessment.LimitedVisibility += "Limited connection security analysis"
            
            $Global:MakerAssessmentResults.PersonalConnections += $connAssessment
        }
        
        Write-MakerAssessmentLog "Analyzed $($connections.Count) accessible connection(s)" "Success"
        
    } catch {
        Write-MakerAssessmentLog "Error retrieving connections: $($_.Exception.Message)" "Warning"
        $Global:MakerAssessmentResults.LimitedScopeWarnings += "Could not retrieve connection information"
    }
}

function New-MakerSecuritySummary {
    Write-MakerAssessmentLog "Generating security summary..." "Info"
    
    $summary = @{
        AssessmentScope = "Maker Role - Personal Resources Only"
        AccessibleEnvironments = $Global:MakerAssessmentResults.AccessibleEnvironments.Count
        PersonalFlows = $Global:MakerAssessmentResults.PersonalFlows.Count
        PersonalConnections = $Global:MakerAssessmentResults.PersonalConnections.Count
        SecurityFindingsCount = 0
        LimitationsCount = $Global:MakerAssessmentResults.LimitedScopeWarnings.Count
        RecommendedActions = @()
        UpgradeRecommendations = @()
    }
    
    # Count security findings
    $allFindings = @()
    $allFindings += $Global:MakerAssessmentResults.AccessibleEnvironments | ForEach-Object { $_.SecurityFindings }
    $allFindings += $Global:MakerAssessmentResults.PersonalFlows | ForEach-Object { $_.SecurityFindings }
    $allFindings += $Global:MakerAssessmentResults.PersonalConnections | ForEach-Object { $_.SecurityFindings }
    
    $summary.SecurityFindingsCount = $allFindings.Count
    
    # Generate recommendations based on findings
    if ($Global:MakerAssessmentResults.PersonalFlows | Where-Object { $_.SecurityFindings -like "*HTTP trigger*" }) {
        $summary.RecommendedActions += "Review HTTP trigger security in your flows"
    }
    
    if ($Global:MakerAssessmentResults.PersonalConnections | Where-Object { $_.SecurityFindings -like "*High-risk connector*" }) {
        $summary.RecommendedActions += "Review high-risk connector usage and data access"
    }
    
    if ($Global:MakerAssessmentResults.PersonalFlows | Where-Object { $_.SecurityFindings -like "*90+ days*" }) {
        $summary.RecommendedActions += "Clean up unused or dormant flows"
    }
    
    # Upgrade recommendations
    $summary.UpgradeRecommendations += "Request Power Platform Administrator role for comprehensive security assessment"
    $summary.UpgradeRecommendations += "Work with your admin team to implement organization-wide security policies"
    $summary.UpgradeRecommendations += "Regular security reviews with administrator-level visibility"
    
    $Global:MakerAssessmentResults.Summary = $summary
}

function Export-MakerAssessmentReport {
    param(
        [string]$OutputPath,
        [string]$Format
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $filename = "PowerAutomate-MakerAssessment-$timestamp"
    
    switch ($Format) {
        "JSON" {
            $filepath = Join-Path $OutputPath "$filename.json"
            $Global:MakerAssessmentResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $filepath -Encoding UTF8
        }
        "CSV" {
            $basePath = Join-Path $OutputPath $filename
            
            # Export separate CSV files for each data type
            if ($Global:MakerAssessmentResults.AccessibleEnvironments.Count -gt 0) {
                $Global:MakerAssessmentResults.AccessibleEnvironments | Export-Csv -Path "$basePath-Environments.csv" -NoTypeInformation
            }
            if ($Global:MakerAssessmentResults.PersonalFlows.Count -gt 0) {
                $Global:MakerAssessmentResults.PersonalFlows | Export-Csv -Path "$basePath-Flows.csv" -NoTypeInformation
            }
            if ($Global:MakerAssessmentResults.PersonalConnections.Count -gt 0) {
                $Global:MakerAssessmentResults.PersonalConnections | Export-Csv -Path "$basePath-Connections.csv" -NoTypeInformation
            }
            
            $filepath = "$basePath-*.csv"
        }
        "HTML" {
            $filepath = Join-Path $OutputPath "$filename.html"
            
            # Generate simplified HTML report
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Power Automate Maker Security Assessment Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; text-align: center; }
        .warning-box { background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .summary { background-color: #e8f4fd; padding: 20px; margin: 20px 0; border-radius: 8px; border-left: 5px solid #007bff; }
        .finding { background-color: #fff5f5; border: 1px solid #fed7d7; padding: 15px; margin: 10px 0; border-radius: 6px; }
        .recommendation { background-color: #f0fff4; border: 1px solid #9ae6b4; padding: 15px; margin: 10px 0; border-radius: 6px; }
        .limitation { background-color: #fffbf0; border: 1px solid #fbd38d; padding: 10px; margin: 5px 0; border-radius: 4px; font-style: italic; }
        .metric { display: inline-block; background-color: #4299e1; color: white; padding: 15px 20px; margin: 10px; border-radius: 8px; text-align: center; min-width: 120px; }
        .section { margin: 30px 0; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #f8f9fa; font-weight: bold; }
        .status-good { color: #38a169; font-weight: bold; }
        .status-warning { color: #d69e2e; font-weight: bold; }
        .status-error { color: #e53e3e; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ Power Automate Security Assessment</h1>
            <h2>Maker Edition Report</h2>
            <p>Generated: $($Global:MakerAssessmentResults.Timestamp)</p>
            <p>User: $($Global:MakerAssessmentResults.UserContext.DisplayName)</p>
        </div>
        
        <div class="warning-box">
            <h3>⚠️ Limited Scope Assessment</h3>
            <p><strong>Role:</strong> Maker (Limited Permissions)</p>
            <p><strong>Scope:</strong> Personal resources and accessible environments only</p>
            <p><strong>Limitation:</strong> This assessment cannot provide comprehensive organization-wide security analysis.</p>
            <p><strong>Recommendation:</strong> For full security assessment, contact your Power Platform Administrator.</p>
        </div>
        
        <div class="summary">
            <h2>📊 Assessment Summary</h2>
            <div style="text-align: center;">
                <div class="metric">
                    <div style="font-size: 24px; font-weight: bold;">$($Global:MakerAssessmentResults.Summary.AccessibleEnvironments)</div>
                    <div>Accessible Environments</div>
                </div>
                <div class="metric">
                    <div style="font-size: 24px; font-weight: bold;">$($Global:MakerAssessmentResults.Summary.PersonalFlows)</div>
                    <div>Personal Flows</div>
                </div>
                <div class="metric">
                    <div style="font-size: 24px; font-weight: bold;">$($Global:MakerAssessmentResults.Summary.PersonalConnections)</div>
                    <div>Personal Connections</div>
                </div>
                <div class="metric">
                    <div style="font-size: 24px; font-weight: bold;">$($Global:MakerAssessmentResults.Summary.SecurityFindingsCount)</div>
                    <div>Security Findings</div>
                </div>
            </div>
        </div>
        
        <div class="section">
            <h2>🏢 Accessible Environments</h2>
            <table>
                <thead>
                    <tr>
                        <th>Environment Name</th>
                        <th>Type</th>
                        <th>Region</th>
                        <th>Security Notes</th>
                    </tr>
                </thead>
                <tbody>
"@
            
            foreach ($env in $Global:MakerAssessmentResults.AccessibleEnvironments) {
                $securityNotes = if ($env.SecurityFindings.Count -gt 0) { $env.SecurityFindings -join "; " } else { "No issues identified" }
                $html += @"
                    <tr>
                        <td>$($env.DisplayName)</td>
                        <td>$($env.Type)</td>
                        <td>$($env.Region)</td>
                        <td>$securityNotes</td>
                    </tr>
"@
            }
            
            $html += @"
                </tbody>
            </table>
        </div>
        
        <div class="section">
            <h2>⚡ Personal Flows Analysis</h2>
            <table>
                <thead>
                    <tr>
                        <th>Flow Name</th>
                        <th>Status</th>
                        <th>Last Modified</th>
                        <th>Security Findings</th>
                    </tr>
                </thead>
                <tbody>
"@
            
            foreach ($flow in $Global:MakerAssessmentResults.PersonalFlows) {
                $status = if ($flow.State) { '<span class="status-good">Enabled</span>' } else { '<span class="status-warning">Disabled</span>' }
                $lastModified = if ($flow.LastModifiedTime) { ([DateTime]$flow.LastModifiedTime).ToString("yyyy-MM-dd") } else { "Unknown" }
                $findings = if ($flow.SecurityFindings.Count -gt 0) { $flow.SecurityFindings -join "; " } else { "No issues identified" }
                
                $html += @"
                    <tr>
                        <td>$($flow.DisplayName)</td>
                        <td>$status</td>
                        <td>$lastModified</td>
                        <td>$findings</td>
                    </tr>
"@
            }
            
            $html += @"
                </tbody>
            </table>
        </div>
        
        <div class="section">
            <h2>🔗 Personal Connections Analysis</h2>
            <table>
                <thead>
                    <tr>
                        <th>Connection Name</th>
                        <th>Connector Type</th>
                        <th>Status</th>
                        <th>Security Findings</th>
                    </tr>
                </thead>
                <tbody>
"@
            
            foreach ($conn in $Global:MakerAssessmentResults.PersonalConnections) {
                $status = if ($conn.Status -eq "Connected") { '<span class="status-good">Connected</span>' } else { '<span class="status-error">Disconnected</span>' }
                $findings = if ($conn.SecurityFindings.Count -gt 0) { $conn.SecurityFindings -join "; " } else { "No issues identified" }
                
                $html += @"
                    <tr>
                        <td>$($conn.DisplayName)</td>
                        <td>$($conn.ConnectorName)</td>
                        <td>$status</td>
                        <td>$findings</td>
                    </tr>
"@
            }
            
            $html += @"
                </tbody>
            </table>
        </div>
        
        <div class="section">
            <h2>💡 Recommendations</h2>
"@
            
            foreach ($action in $Global:MakerAssessmentResults.Summary.RecommendedActions) {
                $html += @"
            <div class="recommendation">
                <strong>Action:</strong> $action
            </div>
"@
            }
            
            $html += @"
            <h3>🚀 Upgrade Recommendations</h3>
"@
            
            foreach ($upgrade in $Global:MakerAssessmentResults.Summary.UpgradeRecommendations) {
                $html += @"
            <div class="recommendation">
                <strong>Upgrade:</strong> $upgrade
            </div>
"@
            }
            
            $html += @"
        </div>
        
        <div class="section">
            <h2>⚠️ Assessment Limitations</h2>
            <p>This assessment is limited by Maker role permissions and cannot provide:</p>
            <ul>
                <li>Organization-wide DLP policy analysis</li>
                <li>Complete user access and permission review</li>
                <li>Environment security group configurations</li>
                <li>Flows and connections owned by other users</li>
                <li>Comprehensive connector risk assessment</li>
                <li>Administrative security configurations</li>
            </ul>
            
            <div class="warning-box">
                <h4>🔒 For Complete Security Assessment</h4>
                <p>Contact your Power Platform Administrator to run the full security assessment tool with administrator privileges. This will provide comprehensive visibility into your organization's Power Platform security posture.</p>
            </div>
        </div>
        
        <div style="margin-top: 40px; padding: 20px; background-color: #f8f9fa; border-radius: 8px; text-align: center; font-size: 12px; color: #666;">
            <p>Power Automate Security Assessment Tool - Maker Edition</p>
            <p>This report provides limited security analysis based on Maker role permissions</p>
        </div>
    </div>
</body>
</html>
"@
            
            $html | Out-File -FilePath $filepath -Encoding UTF8
        }
    }
    
    Write-MakerAssessmentLog "Report exported to: $filepath" "Success"
    return $filepath
}

# Main execution function
function Start-MakerSecurityAssessment {
    Write-MakerAssessmentLog "Starting Power Automate Maker Security Assessment" "Info"
    
    # Test connection
    if (-not (Test-MakerConnection)) {
        return
    }
    
    # Perform maker-level assessments
    Get-AccessibleEnvironments
    Get-PersonalFlows
    Get-PersonalConnections
    
    # Generate summary
    New-MakerSecuritySummary
    
    # Export report
    $reportPath = Export-MakerAssessmentReport -OutputPath $OutputPath -Format $ExportFormat
    
    Write-MakerAssessmentLog "Maker security assessment completed" "Success"
    Write-MakerAssessmentLog "Security findings: $($Global:MakerAssessmentResults.Summary.SecurityFindingsCount)" "Info"
    Write-MakerAssessmentLog "Assessment limitations: $($Global:MakerAssessmentResults.Summary.LimitationsCount)" "Warning"
    
    return $reportPath
}

# Execute the assessment
Start-MakerSecurityAssessment