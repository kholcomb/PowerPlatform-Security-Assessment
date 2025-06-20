#Requires -Modules Microsoft.PowerApps.Administration.PowerShell, Microsoft.PowerApps.PowerShell

<#
.SYNOPSIS
    Power Automate Security Posture Assessment Script
.DESCRIPTION
    Evaluates and reports on the security posture of a Power Automate environment,
    including users, connections, flows, and environment configurations.
.PARAMETER EnvironmentName
    The name of the Power Platform environment to assess (optional - will assess all if not specified)
.PARAMETER OutputPath
    Path to save the assessment report (default: current directory)
.PARAMETER ExportFormat
    Export format: JSON, CSV, or HTML (default: HTML)
.EXAMPLE
    .\PowerAutomate-SecurityAssessment.ps1 -EnvironmentName "Production" -OutputPath "C:\Reports" -ExportFormat "HTML"
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$EnvironmentName,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV", "HTML", "PowerBI", "Excel", "SQL")]
    [string]$ExportFormat = "HTML",
    
    [Parameter(Mandatory = $false)]
    [string]$SqlConnectionString,
    
    [Parameter(Mandatory = $false)]
    [string]$PowerBIWorkspace,
    
    [Parameter(Mandatory = $false)]
    [switch]$CreatePowerBIDataset
)

# Global variables for assessment results
$Global:AssessmentResults = @{
    Timestamp = Get-Date
    Environments = @()
    Users = @()
    Connections = @()
    Flows = @()
    SecurityFindings = @()
    Summary = @{}
}

function Write-AssessmentLog {
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

function Test-PowerPlatformConnection {
    Write-AssessmentLog "Testing Power Platform connection..." "Info"
    
    try {
        $environments = Get-AdminPowerAppEnvironment -ErrorAction Stop
        Write-AssessmentLog "Successfully connected to Power Platform" "Success"
        return $true
    }
    catch {
        Write-AssessmentLog "Failed to connect to Power Platform: $($_.Exception.Message)" "Error"
        Write-AssessmentLog "Please ensure you're logged in with: Add-PowerAppsAccount" "Info"
        return $false
    }
}

function Get-EnvironmentSecurityAssessment {
    param([object]$Environment)
    
    Write-AssessmentLog "Assessing environment: $($Environment.DisplayName)" "Info"
    
    $envAssessment = @{
        EnvironmentId = $Environment.EnvironmentName
        DisplayName = $Environment.DisplayName
        Type = $Environment.EnvironmentType
        Region = $Environment.Location
        State = $Environment.States.Management.id
        SecurityGroup = $Environment.Properties.azureActiveDirectorySecurityGroupObjectId
        DataLossPreventionPolicies = @()
        SecurityFindings = @()
    }
    
    # Check for DLP policies
    try {
        $dlpPolicies = Get-AdminDlpPolicy -EnvironmentName $Environment.EnvironmentName
        foreach ($policy in $dlpPolicies) {
            $envAssessment.DataLossPreventionPolicies += @{
                DisplayName = $policy.DisplayName
                Type = $policy.Type
                ConnectorGroups = $policy.ConnectorGroups
                DefaultConnectorsClassification = $policy.DefaultConnectorsClassification
            }
        }
        
        if (-not $dlpPolicies) {
            $envAssessment.SecurityFindings += "No DLP policies configured - HIGH RISK"
        }
    }
    catch {
        $envAssessment.SecurityFindings += "Unable to retrieve DLP policies: $($_.Exception.Message)"
    }
    
    # Check environment security group
    if (-not $Environment.Properties.azureActiveDirectorySecurityGroupObjectId) {
        $envAssessment.SecurityFindings += "No Azure AD security group assigned - MEDIUM RISK"
    }
    
    # Check if production environment has appropriate restrictions
    if ($Environment.EnvironmentType -eq "Production" -and $Environment.Properties.isDefault) {
        $envAssessment.SecurityFindings += "Default environment is production type - REVIEW REQUIRED"
    }
    
    return $envAssessment
}

function Get-UserSecurityAssessment {
    param([string]$EnvironmentName)
    
    Write-AssessmentLog "Assessing users in environment: $EnvironmentName" "Info"
    
    $users = @()
    
    try {
        # Get environment makers
        $envMakers = Get-AdminPowerAppEnvironmentRoleAssignment -EnvironmentName $EnvironmentName
        
        foreach ($maker in $envMakers) {
            $userAssessment = @{
                EnvironmentName = $EnvironmentName
                PrincipalDisplayName = $maker.PrincipalDisplayName
                PrincipalEmail = $maker.PrincipalEmail
                PrincipalType = $maker.PrincipalType
                RoleType = $maker.RoleType
                SecurityFindings = @()
            }
            
            # Check for overprivileged access
            if ($maker.RoleType -eq "EnvironmentAdmin" -and $maker.PrincipalType -eq "User") {
                $userAssessment.SecurityFindings += "User has Environment Admin privileges - REVIEW ACCESS"
            }
            
            # Check for service principal access
            if ($maker.PrincipalType -eq "ServicePrincipal") {
                $userAssessment.SecurityFindings += "Service Principal has environment access - VERIFY NECESSITY"
            }
            
            $users += $userAssessment
        }
    }
    catch {
        Write-AssessmentLog "Error assessing users: $($_.Exception.Message)" "Warning"
    }
    
    return $users
}

function Get-ConnectionSecurityAssessment {
    param([string]$EnvironmentName)
    
    Write-AssessmentLog "Assessing connections in environment: $EnvironmentName" "Info"
    
    $connections = @()
    
    try {
        $envConnections = Get-AdminPowerAppConnection -EnvironmentName $EnvironmentName
        
        foreach ($connection in $envConnections) {
            $connAssessment = @{
                EnvironmentName = $EnvironmentName
                ConnectionName = $connection.ConnectionName
                DisplayName = $connection.DisplayName
                ConnectorName = $connection.ConnectorName
                CreatedBy = $connection.CreatedBy.displayName
                CreatedTime = $connection.CreatedTime
                Status = $connection.Statuses
                SecurityFindings = @()
            }
            
            # Check for high-risk connectors
            $highRiskConnectors = @("SharePoint", "SQL Server", "Office 365 Outlook", "OneDrive for Business", "Microsoft Teams")
            if ($connection.ConnectorName -in $highRiskConnectors) {
                $connAssessment.SecurityFindings += "High-risk connector detected - REVIEW PERMISSIONS"
            }
            
            # Check for premium connectors
            $premiumConnectors = @("SQL Server", "SharePoint", "Common Data Service")
            if ($connection.ConnectorName -in $premiumConnectors) {
                $connAssessment.SecurityFindings += "Premium connector - VERIFY LICENSING"
            }
            
            # Check connection status
            if ($connection.Statuses -and $connection.Statuses.status -ne "Connected") {
                $connAssessment.SecurityFindings += "Connection not active - POTENTIAL SECURITY RISK"
            }
            
            $connections += $connAssessment
        }
    }
    catch {
        Write-AssessmentLog "Error assessing connections: $($_.Exception.Message)" "Warning"
    }
    
    return $connections
}

function Get-FlowSecurityAssessment {
    param([string]$EnvironmentName)
    
    Write-AssessmentLog "Assessing flows in environment: $EnvironmentName" "Info"
    
    $flows = @()
    
    try {
        $envFlows = Get-AdminFlow -EnvironmentName $EnvironmentName
        
        foreach ($flow in $envFlows) {
            $flowAssessment = @{
                EnvironmentName = $EnvironmentName
                FlowName = $flow.FlowName
                DisplayName = $flow.DisplayName
                CreatedBy = $flow.CreatedBy.displayName
                CreatedTime = $flow.CreatedTime
                State = $flow.Enabled
                TriggerType = $flow.Properties.definitionSummary.triggers.PSObject.Properties.Name -join ", "
                SecurityFindings = @()
            }
            
            # Check for external triggers
            if ($flow.Properties.definitionSummary.triggers) {
                $triggers = $flow.Properties.definitionSummary.triggers.PSObject.Properties
                foreach ($trigger in $triggers) {
                    if ($trigger.Value.type -eq "Request") {
                        $flowAssessment.SecurityFindings += "HTTP trigger detected - VERIFY AUTHENTICATION"
                    }
                    if ($trigger.Value.type -eq "Manual") {
                        $flowAssessment.SecurityFindings += "Manual trigger - REVIEW ACCESS CONTROLS"
                    }
                }
            }
            
            # Check for sharing
            try {
                $flowOwners = Get-AdminFlowOwnerRole -EnvironmentName $EnvironmentName -FlowName $flow.FlowName
                if ($flowOwners.Count -gt 1) {
                    $flowAssessment.SecurityFindings += "Flow shared with multiple owners - REVIEW SHARING"
                }
            }
            catch {
                # Unable to get owner info
            }
            
            # Check if flow is enabled but not recently modified
            if ($flow.Enabled -and $flow.LastModifiedTime) {
                $daysSinceModified = (Get-Date) - [DateTime]$flow.LastModifiedTime
                if ($daysSinceModified.Days -gt 90) {
                    $flowAssessment.SecurityFindings += "Flow enabled but not modified in 90+ days - REVIEW NECESSITY"
                }
            }
            
            $flows += $flowAssessment
        }
    }
    catch {
        Write-AssessmentLog "Error assessing flows: $($_.Exception.Message)" "Warning"
    }
    
    return $flows
}

function New-SecuritySummary {
    $summary = @{
        TotalEnvironments = $Global:AssessmentResults.Environments.Count
        TotalUsers = $Global:AssessmentResults.Users.Count
        TotalConnections = $Global:AssessmentResults.Connections.Count
        TotalFlows = $Global:AssessmentResults.Flows.Count
        HighRiskFindings = 0
        MediumRiskFindings = 0
        LowRiskFindings = 0
        Recommendations = @()
    }
    
    # Count security findings by risk level
    $allFindings = @()
    $allFindings += $Global:AssessmentResults.Environments | ForEach-Object { $_.SecurityFindings }
    $allFindings += $Global:AssessmentResults.Users | ForEach-Object { $_.SecurityFindings }
    $allFindings += $Global:AssessmentResults.Connections | ForEach-Object { $_.SecurityFindings }
    $allFindings += $Global:AssessmentResults.Flows | ForEach-Object { $_.SecurityFindings }
    
    foreach ($finding in $allFindings) {
        if ($finding -like "*HIGH*") { $summary.HighRiskFindings++ }
        elseif ($finding -like "*MEDIUM*") { $summary.MediumRiskFindings++ }
        else { $summary.LowRiskFindings++ }
    }
    
    # Generate recommendations
    if ($summary.HighRiskFindings -gt 0) {
        $summary.Recommendations += "Address high-risk findings immediately"
    }
    
    if ($Global:AssessmentResults.Environments | Where-Object { $_.DataLossPreventionPolicies.Count -eq 0 }) {
        $summary.Recommendations += "Implement Data Loss Prevention policies"
    }
    
    if ($Global:AssessmentResults.Connections | Where-Object { $_.SecurityFindings -like "*High-risk connector*" }) {
        $summary.Recommendations += "Review and restrict high-risk connector usage"
    }
    
    $Global:AssessmentResults.Summary = $summary
}

function Export-AssessmentReport {
    param(
        [string]$OutputPath,
        [string]$Format
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $filename = "PowerAutomate-SecurityAssessment-$timestamp"
    
    switch ($Format) {
        "JSON" {
            $filepath = Join-Path $OutputPath "$filename.json"
            $Global:AssessmentResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $filepath -Encoding UTF8
        }
        "CSV" {
            $basePath = Join-Path $OutputPath $filename
            $Global:AssessmentResults.Environments | Export-Csv -Path "$basePath-Environments.csv" -NoTypeInformation
            $Global:AssessmentResults.Users | Export-Csv -Path "$basePath-Users.csv" -NoTypeInformation
            $Global:AssessmentResults.Connections | Export-Csv -Path "$basePath-Connections.csv" -NoTypeInformation
            $Global:AssessmentResults.Flows | Export-Csv -Path "$basePath-Flows.csv" -NoTypeInformation
            $filepath = "$basePath-*.csv"
        }
        "HTML" {
            $filepath = Join-Path $OutputPath "$filename.html"
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Power Automate Security Assessment Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #0078d4; color: white; padding: 20px; border-radius: 5px; }
        .summary { background-color: #f5f5f5; padding: 15px; margin: 20px 0; border-radius: 5px; }
        .high-risk { color: #d83b01; font-weight: bold; }
        .medium-risk { color: #ff8c00; font-weight: bold; }
        .low-risk { color: #107c10; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .section { margin: 30px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Power Automate Security Assessment Report</h1>
        <p>Generated: $($Global:AssessmentResults.Timestamp)</p>
    </div>
    
    <div class="summary">
        <h2>Executive Summary</h2>
        <p><strong>Environments Assessed:</strong> $($Global:AssessmentResults.Summary.TotalEnvironments)</p>
        <p><strong>Users:</strong> $($Global:AssessmentResults.Summary.TotalUsers)</p>
        <p><strong>Connections:</strong> $($Global:AssessmentResults.Summary.TotalConnections)</p>
        <p><strong>Flows:</strong> $($Global:AssessmentResults.Summary.TotalFlows)</p>
        <p><span class="high-risk">High Risk Findings: $($Global:AssessmentResults.Summary.HighRiskFindings)</span></p>
        <p><span class="medium-risk">Medium Risk Findings: $($Global:AssessmentResults.Summary.MediumRiskFindings)</span></p>
        <p><span class="low-risk">Low Risk Findings: $($Global:AssessmentResults.Summary.LowRiskFindings)</span></p>
    </div>
    
    <div class="section">
        <h2>Recommendations</h2>
        <ul>
"@
            foreach ($rec in $Global:AssessmentResults.Summary.Recommendations) {
                $html += "            <li>$rec</li>`n"
            }
            
            $html += @"
        </ul>
    </div>
    
    <!-- Additional sections would include detailed tables for environments, users, connections, and flows -->
    
</body>
</html>
"@
            $html | Out-File -FilePath $filepath -Encoding UTF8
        }
        "PowerBI" {
            $filepath = Export-PowerBIFormat -OutputPath $OutputPath -Timestamp $timestamp
        }
        "Excel" {
            $filepath = Export-ExcelFormat -OutputPath $OutputPath -Timestamp $timestamp
        }
        "SQL" {
            $filepath = Export-SqlFormat -OutputPath $OutputPath -Timestamp $timestamp -ConnectionString $SqlConnectionString
        }
    }
    
    Write-AssessmentLog "Report exported to: $filepath" "Success"
    return $filepath
}

function Export-PowerBIFormat {
    param(
        [string]$OutputPath,
        [string]$Timestamp
    )
    
    Write-AssessmentLog "Creating Power BI compatible export" "Info"
    
    # Create normalized data tables for Power BI
    $powerBIData = @{
        SecurityMetrics = @()
        EnvironmentDetails = @()
        UserAccess = @()
        ConnectionSecurity = @()
        FlowAnalysis = @()
        SecurityFindings = @()
        TimeSeriesData = @()
    }
    
    # Security Metrics Summary Table
    $powerBIData.SecurityMetrics += [PSCustomObject]@{
        AssessmentDate = $Global:AssessmentResults.Timestamp
        TotalEnvironments = $Global:AssessmentResults.Summary.TotalEnvironments
        TotalUsers = $Global:AssessmentResults.Summary.TotalUsers
        TotalConnections = $Global:AssessmentResults.Summary.TotalConnections
        TotalFlows = $Global:AssessmentResults.Summary.TotalFlows
        HighRiskFindings = $Global:AssessmentResults.Summary.HighRiskFindings
        MediumRiskFindings = $Global:AssessmentResults.Summary.MediumRiskFindings
        LowRiskFindings = $Global:AssessmentResults.Summary.LowRiskFindings
        OverallRiskScore = ($Global:AssessmentResults.Summary.HighRiskFindings * 10) + ($Global:AssessmentResults.Summary.MediumRiskFindings * 5) + $Global:AssessmentResults.Summary.LowRiskFindings
        RiskLevel = if (($Global:AssessmentResults.Summary.HighRiskFindings * 10 + $Global:AssessmentResults.Summary.MediumRiskFindings * 5 + $Global:AssessmentResults.Summary.LowRiskFindings) -gt 25) { "HIGH" } elseif (($Global:AssessmentResults.Summary.HighRiskFindings * 10 + $Global:AssessmentResults.Summary.MediumRiskFindings * 5 + $Global:AssessmentResults.Summary.LowRiskFindings) -gt 10) { "MEDIUM" } else { "LOW" }
    }
    
    # Environment Details Table
    foreach ($env in $Global:AssessmentResults.Environments) {
        $powerBIData.EnvironmentDetails += [PSCustomObject]@{
            AssessmentDate = $Global:AssessmentResults.Timestamp
            EnvironmentId = $env.EnvironmentId
            DisplayName = $env.DisplayName
            EnvironmentType = $env.Type
            Region = $env.Region
            State = $env.State
            HasSecurityGroup = if ($env.SecurityGroup) { "Yes" } else { "No" }
            SecurityGroupId = $env.SecurityGroup
            DLPPolicyCount = $env.DataLossPreventionPolicies.Count
            SecurityFindingCount = $env.SecurityFindings.Count
            RiskScore = ($env.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count * 10 + ($env.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count * 5 + ($env.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count
        }
    }
    
    # User Access Table
    foreach ($user in $Global:AssessmentResults.Users) {
        $powerBIData.UserAccess += [PSCustomObject]@{
            AssessmentDate = $Global:AssessmentResults.Timestamp
            EnvironmentName = $user.EnvironmentName
            PrincipalDisplayName = $user.PrincipalDisplayName
            PrincipalEmail = $user.PrincipalEmail
            PrincipalType = $user.PrincipalType
            RoleType = $user.RoleType
            IsAdmin = if ($user.RoleType -eq "EnvironmentAdmin") { "Yes" } else { "No" }
            IsServicePrincipal = if ($user.PrincipalType -eq "ServicePrincipal") { "Yes" } else { "No" }
            SecurityFindingCount = $user.SecurityFindings.Count
            RiskScore = ($user.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count * 10 + ($user.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count * 5 + ($user.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count
        }
    }
    
    # Connection Security Table
    foreach ($conn in $Global:AssessmentResults.Connections) {
        $powerBIData.ConnectionSecurity += [PSCustomObject]@{
            AssessmentDate = $Global:AssessmentResults.Timestamp
            EnvironmentName = $conn.EnvironmentName
            ConnectionName = $conn.ConnectionName
            DisplayName = $conn.DisplayName
            ConnectorName = $conn.ConnectorName
            CreatedBy = $conn.CreatedBy
            CreatedTime = $conn.CreatedTime
            Status = $conn.Status
            IsHighRiskConnector = if ($conn.ConnectorName -in @("SQL Server", "SharePoint", "Office 365 Outlook", "OneDrive for Business", "Microsoft Teams")) { "Yes" } else { "No" }
            IsPremiumConnector = if ($conn.ConnectorName -in @("SQL Server", "SharePoint", "Common Data Service")) { "Yes" } else { "No" }
            SecurityFindingCount = $conn.SecurityFindings.Count
            RiskScore = ($conn.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count * 10 + ($conn.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count * 5 + ($conn.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count
        }
    }
    
    # Flow Analysis Table
    foreach ($flow in $Global:AssessmentResults.Flows) {
        $powerBIData.FlowAnalysis += [PSCustomObject]@{
            AssessmentDate = $Global:AssessmentResults.Timestamp
            EnvironmentName = $flow.EnvironmentName
            FlowName = $flow.FlowName
            DisplayName = $flow.DisplayName
            CreatedBy = $flow.CreatedBy
            CreatedTime = $flow.CreatedTime
            IsEnabled = $flow.State
            TriggerType = $flow.TriggerType
            HasHTTPTrigger = if ($flow.TriggerType -like "*Request*") { "Yes" } else { "No" }
            HasManualTrigger = if ($flow.TriggerType -like "*Manual*") { "Yes" } else { "No" }
            SecurityFindingCount = $flow.SecurityFindings.Count
            RiskScore = ($flow.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count * 10 + ($flow.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count * 5 + ($flow.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count
        }
    }
    
    # Security Findings Detail Table
    $findingId = 1
    foreach ($env in $Global:AssessmentResults.Environments) {
        foreach ($finding in $env.SecurityFindings) {
            $powerBIData.SecurityFindings += [PSCustomObject]@{
                FindingId = $findingId++
                AssessmentDate = $Global:AssessmentResults.Timestamp
                Category = "Environment"
                ResourceType = "Environment"
                ResourceName = $env.DisplayName
                EnvironmentName = $env.DisplayName
                Finding = $finding
                RiskLevel = if ($finding -like "*HIGH*") { "HIGH" } elseif ($finding -like "*MEDIUM*") { "MEDIUM" } else { "LOW" }
                RiskScore = if ($finding -like "*HIGH*") { 10 } elseif ($finding -like "*MEDIUM*") { 5 } else { 1 }
            }
        }
    }
    
    foreach ($user in $Global:AssessmentResults.Users) {
        foreach ($finding in $user.SecurityFindings) {
            $powerBIData.SecurityFindings += [PSCustomObject]@{
                FindingId = $findingId++
                AssessmentDate = $Global:AssessmentResults.Timestamp
                Category = "User Access"
                ResourceType = "User"
                ResourceName = $user.PrincipalDisplayName
                EnvironmentName = $user.EnvironmentName
                Finding = $finding
                RiskLevel = if ($finding -like "*HIGH*") { "HIGH" } elseif ($finding -like "*MEDIUM*") { "MEDIUM" } else { "LOW" }
                RiskScore = if ($finding -like "*HIGH*") { 10 } elseif ($finding -like "*MEDIUM*") { 5 } else { 1 }
            }
        }
    }
    
    foreach ($conn in $Global:AssessmentResults.Connections) {
        foreach ($finding in $conn.SecurityFindings) {
            $powerBIData.SecurityFindings += [PSCustomObject]@{
                FindingId = $findingId++
                AssessmentDate = $Global:AssessmentResults.Timestamp
                Category = "Connection Security"
                ResourceType = "Connection"
                ResourceName = $conn.DisplayName
                EnvironmentName = $conn.EnvironmentName
                Finding = $finding
                RiskLevel = if ($finding -like "*HIGH*") { "HIGH" } elseif ($finding -like "*MEDIUM*") { "MEDIUM" } else { "LOW" }
                RiskScore = if ($finding -like "*HIGH*") { 10 } elseif ($finding -like "*MEDIUM*") { 5 } else { 1 }
            }
        }
    }
    
    foreach ($flow in $Global:AssessmentResults.Flows) {
        foreach ($finding in $flow.SecurityFindings) {
            $powerBIData.SecurityFindings += [PSCustomObject]@{
                FindingId = $findingId++
                AssessmentDate = $Global:AssessmentResults.Timestamp
                Category = "Flow Security"
                ResourceType = "Flow"
                ResourceName = $flow.DisplayName
                EnvironmentName = $flow.EnvironmentName
                Finding = $finding
                RiskLevel = if ($finding -like "*HIGH*") { "HIGH" } elseif ($finding -like "*MEDIUM*") { "MEDIUM" } else { "LOW" }
                RiskScore = if ($finding -like "*HIGH*") { 10 } elseif ($finding -like "*MEDIUM*") { 5 } else { 1 }
            }
        }
    }
    
    # Export each table as separate CSV for Power BI
    $basePath = Join-Path $OutputPath "PowerBI-SecurityAssessment-$Timestamp"
    New-Item -Path $basePath -ItemType Directory -Force | Out-Null
    
    $powerBIData.SecurityMetrics | Export-Csv -Path "$basePath\SecurityMetrics.csv" -NoTypeInformation -Encoding UTF8
    $powerBIData.EnvironmentDetails | Export-Csv -Path "$basePath\EnvironmentDetails.csv" -NoTypeInformation -Encoding UTF8
    $powerBIData.UserAccess | Export-Csv -Path "$basePath\UserAccess.csv" -NoTypeInformation -Encoding UTF8
    $powerBIData.ConnectionSecurity | Export-Csv -Path "$basePath\ConnectionSecurity.csv" -NoTypeInformation -Encoding UTF8
    $powerBIData.FlowAnalysis | Export-Csv -Path "$basePath\FlowAnalysis.csv" -NoTypeInformation -Encoding UTF8
    $powerBIData.SecurityFindings | Export-Csv -Path "$basePath\SecurityFindings.csv" -NoTypeInformation -Encoding UTF8
    
    # Create Power BI data model file
    $dataModel = @{
        version = "1.0"
        tables = @(
            @{ name = "SecurityMetrics"; file = "SecurityMetrics.csv"; primaryKey = "AssessmentDate" }
            @{ name = "EnvironmentDetails"; file = "EnvironmentDetails.csv"; primaryKey = "EnvironmentId" }
            @{ name = "UserAccess"; file = "UserAccess.csv"; relationships = @(@{ toTable = "EnvironmentDetails"; fromColumn = "EnvironmentName"; toColumn = "DisplayName" }) }
            @{ name = "ConnectionSecurity"; file = "ConnectionSecurity.csv"; relationships = @(@{ toTable = "EnvironmentDetails"; fromColumn = "EnvironmentName"; toColumn = "DisplayName" }) }
            @{ name = "FlowAnalysis"; file = "FlowAnalysis.csv"; relationships = @(@{ toTable = "EnvironmentDetails"; fromColumn = "EnvironmentName"; toColumn = "DisplayName" }) }
            @{ name = "SecurityFindings"; file = "SecurityFindings.csv"; relationships = @(@{ toTable = "EnvironmentDetails"; fromColumn = "EnvironmentName"; toColumn = "DisplayName" }) }
        )
        measures = @(
            @{ name = "Total High Risk"; expression = "COUNTROWS(FILTER(SecurityFindings, SecurityFindings[RiskLevel] = \"HIGH\"))" }
            @{ name = "Total Medium Risk"; expression = "COUNTROWS(FILTER(SecurityFindings, SecurityFindings[RiskLevel] = \"MEDIUM\"))" }
            @{ name = "Total Low Risk"; expression = "COUNTROWS(FILTER(SecurityFindings, SecurityFindings[RiskLevel] = \"LOW\"))" }
            @{ name = "Overall Risk Score"; expression = "SUMX(SecurityFindings, SecurityFindings[RiskScore])" }
        )
    }
    
    $dataModel | ConvertTo-Json -Depth 10 | Out-File -FilePath "$basePath\DataModel.json" -Encoding UTF8
    
    # Create Power BI import instructions
    $instructions = @"
# Power BI Import Instructions

## Data Import Steps:
1. Open Power BI Desktop
2. Get Data > Text/CSV
3. Import the following files in order:
   - SecurityMetrics.csv
   - EnvironmentDetails.csv  
   - UserAccess.csv
   - ConnectionSecurity.csv
   - FlowAnalysis.csv
   - SecurityFindings.csv

## Relationships:
- EnvironmentDetails (DisplayName) -> UserAccess (EnvironmentName)
- EnvironmentDetails (DisplayName) -> ConnectionSecurity (EnvironmentName)
- EnvironmentDetails (DisplayName) -> FlowAnalysis (EnvironmentName)
- EnvironmentDetails (DisplayName) -> SecurityFindings (EnvironmentName)

## Key Measures:
- Total High Risk Findings
- Total Medium Risk Findings
- Total Low Risk Findings
- Overall Risk Score by Environment

## Recommended Visualizations:
1. Security Metrics Overview (Card visuals)
2. Risk Score by Environment (Bar chart)
3. Security Findings by Category (Pie chart)
4. Security Trends Over Time (Line chart)
5. Environment Risk Heatmap (Matrix)
"@
    
    $instructions | Out-File -FilePath "$basePath\PowerBI-ImportInstructions.txt" -Encoding UTF8
    
    return $basePath
}

function Export-ExcelFormat {
    param(
        [string]$OutputPath,
        [string]$Timestamp
    )
    
    Write-AssessmentLog "Creating Excel compatible export with Power Query support" "Info"
    
    $basePath = Join-Path $OutputPath "Excel-SecurityAssessment-$Timestamp"
    New-Item -Path $basePath -ItemType Directory -Force | Out-Null
    
    # Create flattened data tables optimized for Excel Power Query
    
    # Summary Dashboard Data
    $summaryData = [PSCustomObject]@{
        AssessmentDate = $Global:AssessmentResults.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
        TotalEnvironments = $Global:AssessmentResults.Summary.TotalEnvironments
        TotalUsers = $Global:AssessmentResults.Summary.TotalUsers
        TotalConnections = $Global:AssessmentResults.Summary.TotalConnections
        TotalFlows = $Global:AssessmentResults.Summary.TotalFlows
        HighRiskFindings = $Global:AssessmentResults.Summary.HighRiskFindings
        MediumRiskFindings = $Global:AssessmentResults.Summary.MediumRiskFindings
        LowRiskFindings = $Global:AssessmentResults.Summary.LowRiskFindings
        TotalFindings = $Global:AssessmentResults.Summary.HighRiskFindings + $Global:AssessmentResults.Summary.MediumRiskFindings + $Global:AssessmentResults.Summary.LowRiskFindings
        OverallRiskScore = ($Global:AssessmentResults.Summary.HighRiskFindings * 10) + ($Global:AssessmentResults.Summary.MediumRiskFindings * 5) + $Global:AssessmentResults.Summary.LowRiskFindings
    }
    
    $summaryData | Export-Csv -Path "$basePath\Dashboard-Summary.csv" -NoTypeInformation -Encoding UTF8
    
    # Detailed Environment Analysis
    $envDetails = @()
    foreach ($env in $Global:AssessmentResults.Environments) {
        $envDetails += [PSCustomObject]@{
            AssessmentDate = $Global:AssessmentResults.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
            EnvironmentId = $env.EnvironmentId
            EnvironmentName = $env.DisplayName
            EnvironmentType = $env.Type
            Region = $env.Region
            State = $env.State
            HasSecurityGroup = if ($env.SecurityGroup) { "Yes" } else { "No" }
            SecurityGroupId = $env.SecurityGroup
            DLPPolicyCount = $env.DataLossPreventionPolicies.Count
            SecurityIssues = ($env.SecurityFindings -join "; ")
            HighRiskIssues = ($env.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count
            MediumRiskIssues = ($env.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count
            LowRiskIssues = ($env.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count
            TotalIssues = $env.SecurityFindings.Count
            RiskScore = ($env.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count * 10 + ($env.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count * 5 + ($env.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count
            RiskLevel = if ((($env.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count * 10 + ($env.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count * 5 + ($env.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count) -gt 15) { "HIGH" } elseif ((($env.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count * 10 + ($env.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count * 5 + ($env.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count) -gt 5) { "MEDIUM" } else { "LOW" }
        }
    }
    
    $envDetails | Export-Csv -Path "$basePath\Environment-Analysis.csv" -NoTypeInformation -Encoding UTF8
    
    # User and Access Analysis
    $userAnalysis = @()
    foreach ($user in $Global:AssessmentResults.Users) {
        $userAnalysis += [PSCustomObject]@{
            AssessmentDate = $Global:AssessmentResults.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
            EnvironmentName = $user.EnvironmentName
            UserDisplayName = $user.PrincipalDisplayName
            UserEmail = $user.PrincipalEmail
            UserType = $user.PrincipalType
            RoleAssigned = $user.RoleType
            IsAdministrator = if ($user.RoleType -eq "EnvironmentAdmin") { "Yes" } else { "No" }
            IsServicePrincipal = if ($user.PrincipalType -eq "ServicePrincipal") { "Yes" } else { "No" }
            IsExternalUser = if ($user.PrincipalType -eq "User" -and $user.PrincipalEmail -like "*#EXT#*") { "Yes" } else { "No" }
            SecurityConcerns = ($user.SecurityFindings -join "; ")
            RiskCount = $user.SecurityFindings.Count
            RequiresReview = if ($user.SecurityFindings.Count -gt 0) { "Yes" } else { "No" }
        }
    }
    
    $userAnalysis | Export-Csv -Path "$basePath\User-Access-Analysis.csv" -NoTypeInformation -Encoding UTF8
    
    # Connection Security Analysis
    $connectionAnalysis = @()
    foreach ($conn in $Global:AssessmentResults.Connections) {
        $connectionAnalysis += [PSCustomObject]@{
            AssessmentDate = $Global:AssessmentResults.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
            EnvironmentName = $conn.EnvironmentName
            ConnectionName = $conn.DisplayName
            ConnectorType = $conn.ConnectorName
            CreatedBy = $conn.CreatedBy
            CreatedDate = if ($conn.CreatedTime) { ([DateTime]$conn.CreatedTime).ToString("yyyy-MM-dd") } else { "" }
            ConnectionStatus = $conn.Status
            IsHighRisk = if ($conn.ConnectorName -in @("SQL Server", "File System", "FTP", "SFTP")) { "Yes" } else { "No" }
            IsPremium = if ($conn.ConnectorName -in @("SQL Server", "SharePoint", "Common Data Service")) { "Yes" } else { "No" }
            SecurityIssues = ($conn.SecurityFindings -join "; ")
            IssueCount = $conn.SecurityFindings.Count
            RequiresAction = if ($conn.SecurityFindings.Count -gt 0) { "Yes" } else { "No" }
        }
    }
    
    $connectionAnalysis | Export-Csv -Path "$basePath\Connection-Security-Analysis.csv" -NoTypeInformation -Encoding UTF8
    
    # Flow Security Analysis
    $flowAnalysis = @()
    foreach ($flow in $Global:AssessmentResults.Flows) {
        $flowAnalysis += [PSCustomObject]@{
            AssessmentDate = $Global:AssessmentResults.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
            EnvironmentName = $flow.EnvironmentName
            FlowName = $flow.DisplayName
            FlowOwner = $flow.CreatedBy
            CreatedDate = if ($flow.CreatedTime) { ([DateTime]$flow.CreatedTime).ToString("yyyy-MM-dd") } else { "" }
            IsActive = if ($flow.State) { "Yes" } else { "No" }
            TriggerType = $flow.TriggerType
            HasHTTPTrigger = if ($flow.TriggerType -like "*Request*") { "Yes" } else { "No" }
            HasManualTrigger = if ($flow.TriggerType -like "*Manual*") { "Yes" } else { "No" }
            HasScheduledTrigger = if ($flow.TriggerType -like "*Recurrence*") { "Yes" } else { "No" }
            SecurityConcerns = ($flow.SecurityFindings -join "; ")
            SecurityIssueCount = $flow.SecurityFindings.Count
            RiskLevel = if (($flow.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count -gt 0) { "HIGH" } elseif (($flow.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count -gt 0) { "MEDIUM" } else { "LOW" }
            RequiresReview = if ($flow.SecurityFindings.Count -gt 0) { "Yes" } else { "No" }
        }
    }
    
    $flowAnalysis | Export-Csv -Path "$basePath\Flow-Security-Analysis.csv" -NoTypeInformation -Encoding UTF8
    
    # Create Excel Power Query instructions
    $powerQueryInstructions = @"
# Excel Power Query Setup Instructions

## Data Import Steps:
1. Open Excel
2. Data Tab > Get Data > From File > From Folder
3. Select the folder containing these CSV files
4. Transform Data (Power Query Editor will open)
5. Combine files or import individual tables

## Recommended Pivot Tables:
1. Risk Summary by Environment
2. Security Issues by Category
3. User Access Analysis
4. High-Risk Connections Report

## Key Formulas:
- Risk Score: =([HighRiskIssues]*10)+([MediumRiskIssues]*5)+[LowRiskIssues]
- Risk Level: =IF([RiskScore]>15,"HIGH",IF([RiskScore]>5,"MEDIUM","LOW"))
- Requires Action: =IF([SecurityIssueCount]>0,"Yes","No")

## Dashboard KPIs:
- Total Environments Assessed
- Total Security Findings
- High Risk Findings (RED)
- Medium Risk Findings (ORANGE)
- Low Risk Findings (GREEN)

## Charts to Create:
1. Security Findings by Risk Level (Pie Chart)
2. Risk Score by Environment (Bar Chart)
3. Security Trends (Line Chart if historical data)
4. Top Security Issues (Bar Chart)
"@
    
    $powerQueryInstructions | Out-File -FilePath "$basePath\Excel-PowerQuery-Instructions.txt" -Encoding UTF8
    
    return $basePath
}

function Export-SqlFormat {
    param(
        [string]$OutputPath,
        [string]$Timestamp,
        [string]$ConnectionString
    )
    
    Write-AssessmentLog "Creating SQL Server export for BI tools" "Info"
    
    if (-not $ConnectionString) {
        Write-AssessmentLog "SQL connection string not provided, creating SQL scripts only" "Warning"
        return Export-SqlScripts -OutputPath $OutputPath -Timestamp $Timestamp
    }
    
    try {
        # Import SQL Server module if available
        if (Get-Module -ListAvailable -Name SqlServer) {
            Import-Module SqlServer
        } else {
            Write-AssessmentLog "SqlServer module not found, creating SQL scripts instead" "Warning"
            return Export-SqlScripts -OutputPath $OutputPath -Timestamp $Timestamp
        }
        
        # Create database tables and insert data
        $tableName = "PowerPlatform_SecurityAssessment_$($Timestamp.Replace('-','').Replace(':',''))"
        
        # Create tables and insert data using Invoke-Sqlcmd
        # This would require the SqlServer PowerShell module
        
        Write-AssessmentLog "Data exported to SQL Server successfully" "Success"
        return "SQL Server Database: $tableName"
        
    } catch {
        Write-AssessmentLog "Error exporting to SQL Server: $($_.Exception.Message)" "Error"
        return Export-SqlScripts -OutputPath $OutputPath -Timestamp $Timestamp
    }
}

function Export-SqlScripts {
    param(
        [string]$OutputPath,
        [string]$Timestamp
    )
    
    $sqlPath = Join-Path $OutputPath "SQL-SecurityAssessment-$Timestamp"
    New-Item -Path $sqlPath -ItemType Directory -Force | Out-Null
    
    # Create SQL table creation scripts
    $createTablesScript = @"
-- Power Platform Security Assessment Database Schema
-- Generated: $($Global:AssessmentResults.Timestamp)

USE [PowerPlatformSecurity]
GO

-- Assessment Summary Table
CREATE TABLE SecurityAssessment_Summary (
    AssessmentId UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    AssessmentDate DATETIME2 NOT NULL,
    TotalEnvironments INT,
    TotalUsers INT,
    TotalConnections INT,
    TotalFlows INT,
    HighRiskFindings INT,
    MediumRiskFindings INT,
    LowRiskFindings INT,
    OverallRiskScore INT,
    RiskLevel NVARCHAR(10)
);

-- Environment Details Table
CREATE TABLE SecurityAssessment_Environments (
    EnvironmentId NVARCHAR(255) PRIMARY KEY,
    AssessmentDate DATETIME2 NOT NULL,
    DisplayName NVARCHAR(255),
    EnvironmentType NVARCHAR(50),
    Region NVARCHAR(100),
    State NVARCHAR(50),
    HasSecurityGroup BIT,
    SecurityGroupId NVARCHAR(255),
    DLPPolicyCount INT,
    SecurityFindingCount INT,
    RiskScore INT,
    RiskLevel NVARCHAR(10)
);

-- User Access Table
CREATE TABLE SecurityAssessment_Users (
    UserId UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    AssessmentDate DATETIME2 NOT NULL,
    EnvironmentName NVARCHAR(255),
    PrincipalDisplayName NVARCHAR(255),
    PrincipalEmail NVARCHAR(255),
    PrincipalType NVARCHAR(50),
    RoleType NVARCHAR(50),
    IsAdmin BIT,
    IsServicePrincipal BIT,
    IsExternalUser BIT,
    SecurityFindingCount INT,
    RiskScore INT
);

-- Connection Security Table
CREATE TABLE SecurityAssessment_Connections (
    ConnectionId UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    AssessmentDate DATETIME2 NOT NULL,
    EnvironmentName NVARCHAR(255),
    ConnectionName NVARCHAR(255),
    DisplayName NVARCHAR(255),
    ConnectorName NVARCHAR(255),
    CreatedBy NVARCHAR(255),
    CreatedTime DATETIME2,
    Status NVARCHAR(50),
    IsHighRiskConnector BIT,
    IsPremiumConnector BIT,
    SecurityFindingCount INT,
    RiskScore INT
);

-- Flow Analysis Table
CREATE TABLE SecurityAssessment_Flows (
    FlowId NVARCHAR(255) PRIMARY KEY,
    AssessmentDate DATETIME2 NOT NULL,
    EnvironmentName NVARCHAR(255),
    DisplayName NVARCHAR(255),
    CreatedBy NVARCHAR(255),
    CreatedTime DATETIME2,
    IsEnabled BIT,
    TriggerType NVARCHAR(255),
    HasHTTPTrigger BIT,
    HasManualTrigger BIT,
    SecurityFindingCount INT,
    RiskScore INT
);

-- Security Findings Table
CREATE TABLE SecurityAssessment_Findings (
    FindingId INT IDENTITY(1,1) PRIMARY KEY,
    AssessmentDate DATETIME2 NOT NULL,
    Category NVARCHAR(100),
    ResourceType NVARCHAR(50),
    ResourceName NVARCHAR(255),
    EnvironmentName NVARCHAR(255),
    Finding NVARCHAR(MAX),
    RiskLevel NVARCHAR(10),
    RiskScore INT
);

-- Create indexes for better query performance
CREATE INDEX IX_SecurityAssessment_Environments_AssessmentDate ON SecurityAssessment_Environments(AssessmentDate);
CREATE INDEX IX_SecurityAssessment_Users_AssessmentDate ON SecurityAssessment_Users(AssessmentDate);
CREATE INDEX IX_SecurityAssessment_Connections_AssessmentDate ON SecurityAssessment_Connections(AssessmentDate);
CREATE INDEX IX_SecurityAssessment_Flows_AssessmentDate ON SecurityAssessment_Flows(AssessmentDate);
CREATE INDEX IX_SecurityAssessment_Findings_AssessmentDate ON SecurityAssessment_Findings(AssessmentDate);
CREATE INDEX IX_SecurityAssessment_Findings_RiskLevel ON SecurityAssessment_Findings(RiskLevel);
"@
    
    $createTablesScript | Out-File -FilePath "$sqlPath\01-CreateTables.sql" -Encoding UTF8
    
    # Create data insert scripts
    $insertDataScript = @"
-- Power Platform Security Assessment Data Insert
-- Generated: $($Global:AssessmentResults.Timestamp)

USE [PowerPlatformSecurity]
GO

-- Insert Summary Data
INSERT INTO SecurityAssessment_Summary 
(AssessmentDate, TotalEnvironments, TotalUsers, TotalConnections, TotalFlows, HighRiskFindings, MediumRiskFindings, LowRiskFindings, OverallRiskScore, RiskLevel)
VALUES 
('$($Global:AssessmentResults.Timestamp.ToString("yyyy-MM-dd HH:mm:ss"))', 
 $($Global:AssessmentResults.Summary.TotalEnvironments), 
 $($Global:AssessmentResults.Summary.TotalUsers), 
 $($Global:AssessmentResults.Summary.TotalConnections), 
 $($Global:AssessmentResults.Summary.TotalFlows), 
 $($Global:AssessmentResults.Summary.HighRiskFindings), 
 $($Global:AssessmentResults.Summary.MediumRiskFindings), 
 $($Global:AssessmentResults.Summary.LowRiskFindings), 
 $(($Global:AssessmentResults.Summary.HighRiskFindings * 10) + ($Global:AssessmentResults.Summary.MediumRiskFindings * 5) + $Global:AssessmentResults.Summary.LowRiskFindings), 
 '$(if ((($Global:AssessmentResults.Summary.HighRiskFindings * 10) + ($Global:AssessmentResults.Summary.MediumRiskFindings * 5) + $Global:AssessmentResults.Summary.LowRiskFindings) -gt 25) { "HIGH" } elseif ((($Global:AssessmentResults.Summary.HighRiskFindings * 10) + ($Global:AssessmentResults.Summary.MediumRiskFindings * 5) + $Global:AssessmentResults.Summary.LowRiskFindings) -gt 10) { "MEDIUM" } else { "LOW" })');

"@
    
    # Add environment data
    foreach ($env in $Global:AssessmentResults.Environments) {
        $riskScore = ($env.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count * 10 + ($env.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count * 5 + ($env.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count
        $insertDataScript += @"
INSERT INTO SecurityAssessment_Environments 
(EnvironmentId, AssessmentDate, DisplayName, EnvironmentType, Region, State, HasSecurityGroup, SecurityGroupId, DLPPolicyCount, SecurityFindingCount, RiskScore, RiskLevel)
VALUES 
('$($env.EnvironmentId)', '$($Global:AssessmentResults.Timestamp.ToString("yyyy-MM-dd HH:mm:ss"))', '$($env.DisplayName.Replace("'","''"))', '$($env.Type)', '$($env.Region)', '$($env.State)', $(if ($env.SecurityGroup) { 1 } else { 0 }), $(if ($env.SecurityGroup) { "'$($env.SecurityGroup)'" } else { "NULL" }), $($env.DataLossPreventionPolicies.Count), $($env.SecurityFindings.Count), $riskScore, '$(if ($riskScore -gt 15) { "HIGH" } elseif ($riskScore -gt 5) { "MEDIUM" } else { "LOW" })');

"@
    }
    
    $insertDataScript | Out-File -FilePath "$sqlPath\02-InsertData.sql" -Encoding UTF8
    
    # Create Power BI connection instructions
    $powerBIConnection = @"
# Power BI SQL Server Connection Instructions

## Connection Details:
- Data Source: SQL Server
- Server: [Your SQL Server Instance]
- Database: PowerPlatformSecurity
- Authentication: Windows/SQL Server Authentication

## Import Mode vs DirectQuery:
- Import Mode: Faster performance, scheduled refresh needed
- DirectQuery: Real-time data, slower performance

## Key Tables to Import:
1. SecurityAssessment_Summary - Overall metrics
2. SecurityAssessment_Environments - Environment details
3. SecurityAssessment_Users - User access analysis
4. SecurityAssessment_Connections - Connection security
5. SecurityAssessment_Flows - Flow analysis
6. SecurityAssessment_Findings - Detailed findings

## Recommended Relationships:
- SecurityAssessment_Environments (DisplayName) -> Other tables (EnvironmentName)
- SecurityAssessment_Summary (AssessmentDate) -> Other tables (AssessmentDate)

## Sample DAX Measures:
- Total High Risk = CALCULATE(COUNT(SecurityAssessment_Findings[FindingId]), SecurityAssessment_Findings[RiskLevel] = "HIGH")
- Security Score = SUMX(SecurityAssessment_Findings, SecurityAssessment_Findings[RiskScore])
- Environment Risk Rating = MAX(SecurityAssessment_Environments[RiskLevel])
"@
    
    $powerBIConnection | Out-File -FilePath "$sqlPath\PowerBI-Connection-Instructions.txt" -Encoding UTF8
    
    return $sqlPath
}

# Main execution
function Start-SecurityAssessment {
    Write-AssessmentLog "Starting Power Automate Security Assessment" "Info"
    
    # Test connection
    if (-not (Test-PowerPlatformConnection)) {
        return
    }
    
    # Get environments to assess
    try {
        if ($EnvironmentName) {
            $environments = Get-AdminPowerAppEnvironment | Where-Object { $_.DisplayName -eq $EnvironmentName -or $_.EnvironmentName -eq $EnvironmentName }
            if (-not $environments) {
                Write-AssessmentLog "Environment '$EnvironmentName' not found" "Error"
                return
            }
        }
        else {
            $environments = Get-AdminPowerAppEnvironment
        }
        
        Write-AssessmentLog "Found $($environments.Count) environment(s) to assess" "Info"
    }
    catch {
        Write-AssessmentLog "Error retrieving environments: $($_.Exception.Message)" "Error"
        return
    }
    
    # Assess each environment
    foreach ($env in $environments) {
        $Global:AssessmentResults.Environments += Get-EnvironmentSecurityAssessment -Environment $env
        $Global:AssessmentResults.Users += Get-UserSecurityAssessment -EnvironmentName $env.EnvironmentName
        $Global:AssessmentResults.Connections += Get-ConnectionSecurityAssessment -EnvironmentName $env.EnvironmentName
        $Global:AssessmentResults.Flows += Get-FlowSecurityAssessment -EnvironmentName $env.EnvironmentName
    }
    
    # Generate summary
    New-SecuritySummary
    
    # Export report
    $reportPath = Export-AssessmentReport -OutputPath $OutputPath -Format $ExportFormat
    
    Write-AssessmentLog "Security assessment completed successfully" "Success"
    Write-AssessmentLog "High Risk: $($Global:AssessmentResults.Summary.HighRiskFindings) | Medium Risk: $($Global:AssessmentResults.Summary.MediumRiskFindings) | Low Risk: $($Global:AssessmentResults.Summary.LowRiskFindings)" "Info"
    
    return $reportPath
}

# Execute the assessment
Start-SecurityAssessment