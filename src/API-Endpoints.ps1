# API Endpoints Module for Power Automate Security Assessment API
# Handles all REST API endpoints and data transformation

function Invoke-ApiEndpoint {
    param(
        [string]$Method,
        [string]$Path,
        [System.Net.HttpListenerRequest]$Request
    )
    
    $result = @{
        Success = $false
        StatusCode = 404
        Data = @{}
        ErrorMessage = "Endpoint not found"
    }
    
    Write-ApiLog "Processing endpoint: $Method $Path" "Debug" "Endpoints"
    
    try {
        # Route to appropriate endpoint handler
        switch -Regex ($Path) {
            "^/api/summary/?$" {
                if ($Method -eq "GET") {
                    $result = Get-SummaryEndpoint
                }
            }
            "^/api/environments/?$" {
                if ($Method -eq "GET") {
                    $result = Get-EnvironmentsEndpoint -Request $Request
                }
            }
            "^/api/users/?$" {
                if ($Method -eq "GET") {
                    $result = Get-UsersEndpoint -Request $Request
                }
            }
            "^/api/connections/?$" {
                if ($Method -eq "GET") {
                    $result = Get-ConnectionsEndpoint -Request $Request
                }
            }
            "^/api/flows/?$" {
                if ($Method -eq "GET") {
                    $result = Get-FlowsEndpoint -Request $Request
                }
            }
            "^/api/findings/?$" {
                if ($Method -eq "GET") {
                    $result = Get-FindingsEndpoint -Request $Request
                }
            }
            "^/api/health/?$" {
                if ($Method -eq "GET") {
                    $result = Get-HealthEndpoint
                }
            }
            "^/api/refresh/?$" {
                if ($Method -eq "POST") {
                    $result = Post-RefreshEndpoint
                }
            }
            "^/swagger/?$" {
                if ($Method -eq "GET" -and $EnableSwagger) {
                    $result = Get-SwaggerEndpoint
                }
            }
            "^/api/auth/token/?$" {
                if ($Method -eq "POST") {
                    $result = Post-AuthTokenEndpoint -Request $Request
                }
            }
            default {
                $result.ErrorMessage = "Endpoint not found: $Method $Path"
            }
        }
        
    } catch {
        Write-ApiLog "Error in endpoint handler: $($_.Exception.Message)" "Error" "Endpoints"
        $result.Success = $false
        $result.StatusCode = 500
        $result.ErrorMessage = "Internal server error"
    }
    
    return $result
}

function Get-SummaryEndpoint {
    Write-ApiLog "Processing /api/summary endpoint" "Debug" "Endpoints"
    
    try {
        $assessmentData = Get-CachedAssessmentData
        
        $summary = @{
            timestamp = $assessmentData.Timestamp
            overview = @{
                totalEnvironments = $assessmentData.Summary.TotalEnvironments
                totalUsers = $assessmentData.Summary.TotalUsers  
                totalConnections = $assessmentData.Summary.TotalConnections
                totalFlows = $assessmentData.Summary.TotalFlows
            }
            security = @{
                highRiskFindings = $assessmentData.Summary.HighRiskFindings
                mediumRiskFindings = $assessmentData.Summary.MediumRiskFindings
                lowRiskFindings = $assessmentData.Summary.LowRiskFindings
                totalFindings = $assessmentData.Summary.HighRiskFindings + $assessmentData.Summary.MediumRiskFindings + $assessmentData.Summary.LowRiskFindings
                overallRiskScore = ($assessmentData.Summary.HighRiskFindings * 10) + ($assessmentData.Summary.MediumRiskFindings * 5) + $assessmentData.Summary.LowRiskFindings
            }
            riskDistribution = @{
                high = @{
                    count = $assessmentData.Summary.HighRiskFindings
                    percentage = if ($assessmentData.Summary.HighRiskFindings + $assessmentData.Summary.MediumRiskFindings + $assessmentData.Summary.LowRiskFindings -gt 0) { 
                        [math]::Round(($assessmentData.Summary.HighRiskFindings / ($assessmentData.Summary.HighRiskFindings + $assessmentData.Summary.MediumRiskFindings + $assessmentData.Summary.LowRiskFindings)) * 100, 1) 
                    } else { 0 }
                }
                medium = @{
                    count = $assessmentData.Summary.MediumRiskFindings
                    percentage = if ($assessmentData.Summary.HighRiskFindings + $assessmentData.Summary.MediumRiskFindings + $assessmentData.Summary.LowRiskFindings -gt 0) { 
                        [math]::Round(($assessmentData.Summary.MediumRiskFindings / ($assessmentData.Summary.HighRiskFindings + $assessmentData.Summary.MediumRiskFindings + $assessmentData.Summary.LowRiskFindings)) * 100, 1) 
                    } else { 0 }
                }
                low = @{
                    count = $assessmentData.Summary.LowRiskFindings
                    percentage = if ($assessmentData.Summary.HighRiskFindings + $assessmentData.Summary.MediumRiskFindings + $assessmentData.Summary.LowRiskFindings -gt 0) { 
                        [math]::Round(($assessmentData.Summary.LowRiskFindings / ($assessmentData.Summary.HighRiskFindings + $assessmentData.Summary.MediumRiskFindings + $assessmentData.Summary.LowRiskFindings)) * 100, 1) 
                    } else { 0 }
                }
            }
            recommendations = $assessmentData.Summary.Recommendations
            lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
        
        return @{
            Success = $true
            StatusCode = 200
            Data = $summary
        }
        
    } catch {
        Write-ApiLog "Error in summary endpoint: $($_.Exception.Message)" "Error" "Endpoints"
        return @{
            Success = $false
            StatusCode = 500
            ErrorMessage = "Failed to retrieve summary data"
        }
    }
}

function Get-EnvironmentsEndpoint {
    param([System.Net.HttpListenerRequest]$Request)
    
    Write-ApiLog "Processing /api/environments endpoint" "Debug" "Endpoints"
    
    try {
        $assessmentData = Get-CachedAssessmentData
        $queryParams = Get-QueryParameters -Request $Request
        
        $environments = @()
        foreach ($env in $assessmentData.Environments) {
            $envData = @{
                environmentId = $env.EnvironmentId
                displayName = $env.DisplayName
                environmentType = $env.Type
                region = $env.Region
                state = $env.State
                security = @{
                    hasSecurityGroup = if ($env.SecurityGroup) { $true } else { $false }
                    securityGroupId = $env.SecurityGroup
                    dlpPolicyCount = $env.DataLossPreventionPolicies.Count
                    dlpPolicies = $env.DataLossPreventionPolicies
                }
                risk = @{
                    findings = $env.SecurityFindings
                    findingCount = $env.SecurityFindings.Count
                    highRiskCount = ($env.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count
                    mediumRiskCount = ($env.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count
                    lowRiskCount = ($env.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count
                    riskScore = ($env.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count * 10 + ($env.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count * 5 + ($env.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count
                    riskLevel = if ((($env.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count * 10 + ($env.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count * 5 + ($env.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count) -gt 15) { "HIGH" } elseif ((($env.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count * 10 + ($env.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count * 5 + ($env.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count) -gt 5) { "MEDIUM" } else { "LOW" }
                }
                lastAssessed = $assessmentData.Timestamp
            }
            
            $environments += $envData
        }
        
        # Apply filters if specified
        if ($queryParams.ContainsKey("riskLevel")) {
            $environments = $environments | Where-Object { $_.risk.riskLevel -eq $queryParams["riskLevel"].ToUpper() }
        }
        
        if ($queryParams.ContainsKey("environmentType")) {
            $environments = $environments | Where-Object { $_.environmentType -eq $queryParams["environmentType"] }
        }
        
        # Apply pagination
        $totalCount = $environments.Count
        $page = if ($queryParams.ContainsKey("page")) { [int]$queryParams["page"] } else { 1 }
        $pageSize = if ($queryParams.ContainsKey("pageSize")) { [int]$queryParams["pageSize"] } else { 50 }
        
        $startIndex = ($page - 1) * $pageSize
        $endIndex = [math]::Min($startIndex + $pageSize - 1, $totalCount - 1)
        
        if ($startIndex -lt $totalCount) {
            $environments = $environments[$startIndex..$endIndex]
        } else {
            $environments = @()
        }
        
        return @{
            Success = $true
            StatusCode = 200
            Data = @{
                environments = $environments
                pagination = @{
                    page = $page
                    pageSize = $pageSize
                    totalCount = $totalCount
                    totalPages = [math]::Ceiling($totalCount / $pageSize)
                    hasNextPage = ($page * $pageSize) -lt $totalCount
                    hasPreviousPage = $page -gt 1
                }
                lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            }
        }
        
    } catch {
        Write-ApiLog "Error in environments endpoint: $($_.Exception.Message)" "Error" "Endpoints"
        return @{
            Success = $false
            StatusCode = 500
            ErrorMessage = "Failed to retrieve environment data"
        }
    }
}

function Get-UsersEndpoint {
    param([System.Net.HttpListenerRequest]$Request)
    
    Write-ApiLog "Processing /api/users endpoint" "Debug" "Endpoints"
    
    try {
        $assessmentData = Get-CachedAssessmentData
        $queryParams = Get-QueryParameters -Request $Request
        
        $users = @()
        foreach ($user in $assessmentData.Users) {
            $userData = @{
                principalDisplayName = $user.PrincipalDisplayName
                principalEmail = $user.PrincipalEmail
                principalType = $user.PrincipalType
                roleType = $user.RoleType
                environmentName = $user.EnvironmentName
                access = @{
                    isAdmin = if ($user.RoleType -eq "EnvironmentAdmin") { $true } else { $false }
                    isServicePrincipal = if ($user.PrincipalType -eq "ServicePrincipal") { $true } else { $false }
                    isExternalUser = if ($user.PrincipalType -eq "User" -and $user.PrincipalEmail -like "*#EXT#*") { $true } else { $false }
                }
                security = @{
                    findings = $user.SecurityFindings
                    findingCount = $user.SecurityFindings.Count
                    requiresReview = if ($user.SecurityFindings.Count -gt 0) { $true } else { $false }
                    riskScore = ($user.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count * 10 + ($user.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count * 5 + ($user.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count
                }
                lastAssessed = $assessmentData.Timestamp
            }
            
            $users += $userData
        }
        
        # Apply filters
        if ($queryParams.ContainsKey("environmentName")) {
            $users = $users | Where-Object { $_.environmentName -eq $queryParams["environmentName"] }
        }
        
        if ($queryParams.ContainsKey("roleType")) {
            $users = $users | Where-Object { $_.roleType -eq $queryParams["roleType"] }
        }
        
        if ($queryParams.ContainsKey("principalType")) {
            $users = $users | Where-Object { $_.principalType -eq $queryParams["principalType"] }
        }
        
        if ($queryParams.ContainsKey("requiresReview") -and [bool]::Parse($queryParams["requiresReview"])) {
            $users = $users | Where-Object { $_.security.requiresReview -eq $true }
        }
        
        # Apply pagination
        $totalCount = $users.Count
        $page = if ($queryParams.ContainsKey("page")) { [int]$queryParams["page"] } else { 1 }
        $pageSize = if ($queryParams.ContainsKey("pageSize")) { [int]$queryParams["pageSize"] } else { 100 }
        
        $startIndex = ($page - 1) * $pageSize
        $endIndex = [math]::Min($startIndex + $pageSize - 1, $totalCount - 1)
        
        if ($startIndex -lt $totalCount) {
            $users = $users[$startIndex..$endIndex]
        } else {
            $users = @()
        }
        
        return @{
            Success = $true
            StatusCode = 200
            Data = @{
                users = $users
                pagination = @{
                    page = $page
                    pageSize = $pageSize
                    totalCount = $totalCount
                    totalPages = [math]::Ceiling($totalCount / $pageSize)
                    hasNextPage = ($page * $pageSize) -lt $totalCount
                    hasPreviousPage = $page -gt 1
                }
                lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            }
        }
        
    } catch {
        Write-ApiLog "Error in users endpoint: $($_.Exception.Message)" "Error" "Endpoints"
        return @{
            Success = $false
            StatusCode = 500
            ErrorMessage = "Failed to retrieve user data"
        }
    }
}

function Get-ConnectionsEndpoint {
    param([System.Net.HttpListenerRequest]$Request)
    
    Write-ApiLog "Processing /api/connections endpoint" "Debug" "Endpoints"
    
    try {
        $assessmentData = Get-CachedAssessmentData
        $queryParams = Get-QueryParameters -Request $Request
        
        $connections = @()
        foreach ($conn in $assessmentData.Connections) {
            $connectionData = @{
                connectionName = $conn.ConnectionName
                displayName = $conn.DisplayName
                connectorName = $conn.ConnectorName
                environmentName = $conn.EnvironmentName
                createdBy = $conn.CreatedBy
                createdTime = $conn.CreatedTime
                status = $conn.Status
                connector = @{
                    isHighRisk = if ($conn.ConnectorName -in @("SQL Server", "File System", "FTP", "SFTP", "SharePoint")) { $true } else { $false }
                    isPremium = if ($conn.ConnectorName -in @("SQL Server", "SharePoint", "Common Data Service", "Dataverse")) { $true } else { $false }
                    category = Get-ConnectorCategory -ConnectorName $conn.ConnectorName
                }
                security = @{
                    findings = $conn.SecurityFindings
                    findingCount = $conn.SecurityFindings.Count
                    requiresAction = if ($conn.SecurityFindings.Count -gt 0) { $true } else { $false }
                    riskScore = ($conn.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count * 10 + ($conn.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count * 5 + ($conn.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count
                    riskLevel = if ((($conn.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count * 10 + ($conn.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count * 5 + ($conn.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count) -gt 10) { "HIGH" } elseif ((($conn.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count * 10 + ($conn.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count * 5 + ($conn.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count) -gt 3) { "MEDIUM" } else { "LOW" }
                }
                lastAssessed = $assessmentData.Timestamp
            }
            
            $connections += $connectionData
        }
        
        # Apply filters
        if ($queryParams.ContainsKey("environmentName")) {
            $connections = $connections | Where-Object { $_.environmentName -eq $queryParams["environmentName"] }
        }
        
        if ($queryParams.ContainsKey("connectorName")) {
            $connections = $connections | Where-Object { $_.connectorName -eq $queryParams["connectorName"] }
        }
        
        if ($queryParams.ContainsKey("isHighRisk") -and [bool]::Parse($queryParams["isHighRisk"])) {
            $connections = $connections | Where-Object { $_.connector.isHighRisk -eq $true }
        }
        
        if ($queryParams.ContainsKey("requiresAction") -and [bool]::Parse($queryParams["requiresAction"])) {
            $connections = $connections | Where-Object { $_.security.requiresAction -eq $true }
        }
        
        # Apply pagination
        $totalCount = $connections.Count
        $page = if ($queryParams.ContainsKey("page")) { [int]$queryParams["page"] } else { 1 }
        $pageSize = if ($queryParams.ContainsKey("pageSize")) { [int]$queryParams["pageSize"] } else { 100 }
        
        $startIndex = ($page - 1) * $pageSize
        $endIndex = [math]::Min($startIndex + $pageSize - 1, $totalCount - 1)
        
        if ($startIndex -lt $totalCount) {
            $connections = $connections[$startIndex..$endIndex]
        } else {
            $connections = @()
        }
        
        return @{
            Success = $true
            StatusCode = 200
            Data = @{
                connections = $connections
                pagination = @{
                    page = $page
                    pageSize = $pageSize
                    totalCount = $totalCount
                    totalPages = [math]::Ceiling($totalCount / $pageSize)
                    hasNextPage = ($page * $pageSize) -lt $totalCount
                    hasPreviousPage = $page -gt 1
                }
                lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            }
        }
        
    } catch {
        Write-ApiLog "Error in connections endpoint: $($_.Exception.Message)" "Error" "Endpoints"
        return @{
            Success = $false
            StatusCode = 500
            ErrorMessage = "Failed to retrieve connection data"
        }
    }
}

function Get-FlowsEndpoint {
    param([System.Net.HttpListenerRequest]$Request)
    
    Write-ApiLog "Processing /api/flows endpoint" "Debug" "Endpoints"
    
    try {
        $assessmentData = Get-CachedAssessmentData
        $queryParams = Get-QueryParameters -Request $Request
        
        $flows = @()
        foreach ($flow in $assessmentData.Flows) {
            $flowData = @{
                flowName = $flow.FlowName
                displayName = $flow.DisplayName
                environmentName = $flow.EnvironmentName
                createdBy = $flow.CreatedBy
                createdTime = $flow.CreatedTime
                state = $flow.State
                isEnabled = if ($flow.State) { $true } else { $false }
                trigger = @{
                    type = $flow.TriggerType
                    hasHttpTrigger = if ($flow.TriggerType -like "*Request*") { $true } else { $false }
                    hasManualTrigger = if ($flow.TriggerType -like "*Manual*") { $true } else { $false }
                    hasScheduledTrigger = if ($flow.TriggerType -like "*Recurrence*") { $true } else { $false }
                }
                security = @{
                    findings = $flow.SecurityFindings
                    findingCount = $flow.SecurityFindings.Count
                    requiresReview = if ($flow.SecurityFindings.Count -gt 0) { $true } else { $false }
                    riskScore = ($flow.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count * 10 + ($flow.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count * 5 + ($flow.SecurityFindings | Where-Object { $_ -notlike "*HIGH*" -and $_ -notlike "*MEDIUM*" }).Count
                    riskLevel = if ((($flow.SecurityFindings | Where-Object { $_ -like "*HIGH*" }).Count -gt 0)) { "HIGH" } elseif ((($flow.SecurityFindings | Where-Object { $_ -like "*MEDIUM*" }).Count -gt 0)) { "MEDIUM" } else { "LOW" }
                }
                lastAssessed = $assessmentData.Timestamp
            }
            
            $flows += $flowData
        }
        
        # Apply filters
        if ($queryParams.ContainsKey("environmentName")) {
            $flows = $flows | Where-Object { $_.environmentName -eq $queryParams["environmentName"] }
        }
        
        if ($queryParams.ContainsKey("isEnabled")) {
            $filterValue = [bool]::Parse($queryParams["isEnabled"])
            $flows = $flows | Where-Object { $_.isEnabled -eq $filterValue }
        }
        
        if ($queryParams.ContainsKey("hasHttpTrigger") -and [bool]::Parse($queryParams["hasHttpTrigger"])) {
            $flows = $flows | Where-Object { $_.trigger.hasHttpTrigger -eq $true }
        }
        
        if ($queryParams.ContainsKey("requiresReview") -and [bool]::Parse($queryParams["requiresReview"])) {
            $flows = $flows | Where-Object { $_.security.requiresReview -eq $true }
        }
        
        # Apply pagination
        $totalCount = $flows.Count
        $page = if ($queryParams.ContainsKey("page")) { [int]$queryParams["page"] } else { 1 }
        $pageSize = if ($queryParams.ContainsKey("pageSize")) { [int]$queryParams["pageSize"] } else { 100 }
        
        $startIndex = ($page - 1) * $pageSize
        $endIndex = [math]::Min($startIndex + $pageSize - 1, $totalCount - 1)
        
        if ($startIndex -lt $totalCount) {
            $flows = $flows[$startIndex..$endIndex]
        } else {
            $flows = @()
        }
        
        return @{
            Success = $true
            StatusCode = 200
            Data = @{
                flows = $flows
                pagination = @{
                    page = $page
                    pageSize = $pageSize
                    totalCount = $totalCount
                    totalPages = [math]::Ceiling($totalCount / $pageSize)
                    hasNextPage = ($page * $pageSize) -lt $totalCount
                    hasPreviousPage = $page -gt 1
                }
                lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            }
        }
        
    } catch {
        Write-ApiLog "Error in flows endpoint: $($_.Exception.Message)" "Error" "Endpoints"
        return @{
            Success = $false
            StatusCode = 500
            ErrorMessage = "Failed to retrieve flow data"
        }
    }
}

function Get-FindingsEndpoint {
    param([System.Net.HttpListenerRequest]$Request)
    
    Write-ApiLog "Processing /api/findings endpoint" "Debug" "Endpoints"
    
    try {
        $assessmentData = Get-CachedAssessmentData
        $queryParams = Get-QueryParameters -Request $Request
        
        $findings = @()
        $findingId = 1
        
        # Collect findings from all sources
        foreach ($env in $assessmentData.Environments) {
            foreach ($finding in $env.SecurityFindings) {
                $findings += @{
                    findingId = $findingId++
                    category = "Environment"
                    resourceType = "Environment"
                    resourceName = $env.DisplayName
                    environmentName = $env.DisplayName
                    finding = $finding
                    riskLevel = if ($finding -like "*HIGH*") { "HIGH" } elseif ($finding -like "*MEDIUM*") { "MEDIUM" } else { "LOW" }
                    riskScore = if ($finding -like "*HIGH*") { 10 } elseif ($finding -like "*MEDIUM*") { 5 } else { 1 }
                    detectedAt = $assessmentData.Timestamp
                }
            }
        }
        
        foreach ($user in $assessmentData.Users) {
            foreach ($finding in $user.SecurityFindings) {
                $findings += @{
                    findingId = $findingId++
                    category = "User Access"
                    resourceType = "User"
                    resourceName = $user.PrincipalDisplayName
                    environmentName = $user.EnvironmentName
                    finding = $finding
                    riskLevel = if ($finding -like "*HIGH*") { "HIGH" } elseif ($finding -like "*MEDIUM*") { "MEDIUM" } else { "LOW" }
                    riskScore = if ($finding -like "*HIGH*") { 10 } elseif ($finding -like "*MEDIUM*") { 5 } else { 1 }
                    detectedAt = $assessmentData.Timestamp
                }
            }
        }
        
        foreach ($conn in $assessmentData.Connections) {
            foreach ($finding in $conn.SecurityFindings) {
                $findings += @{
                    findingId = $findingId++
                    category = "Connection Security"
                    resourceType = "Connection"
                    resourceName = $conn.DisplayName
                    environmentName = $conn.EnvironmentName
                    finding = $finding
                    riskLevel = if ($finding -like "*HIGH*") { "HIGH" } elseif ($finding -like "*MEDIUM*") { "MEDIUM" } else { "LOW" }
                    riskScore = if ($finding -like "*HIGH*") { 10 } elseif ($finding -like "*MEDIUM*") { 5 } else { 1 }
                    detectedAt = $assessmentData.Timestamp
                }
            }
        }
        
        foreach ($flow in $assessmentData.Flows) {
            foreach ($finding in $flow.SecurityFindings) {
                $findings += @{
                    findingId = $findingId++
                    category = "Flow Security"
                    resourceType = "Flow"
                    resourceName = $flow.DisplayName
                    environmentName = $flow.EnvironmentName
                    finding = $finding
                    riskLevel = if ($finding -like "*HIGH*") { "HIGH" } elseif ($finding -like "*MEDIUM*") { "MEDIUM" } else { "LOW" }
                    riskScore = if ($finding -like "*HIGH*") { 10 } elseif ($finding -like "*MEDIUM*") { 5 } else { 1 }
                    detectedAt = $assessmentData.Timestamp
                }
            }
        }
        
        # Apply filters
        if ($queryParams.ContainsKey("riskLevel")) {
            $findings = $findings | Where-Object { $_.riskLevel -eq $queryParams["riskLevel"].ToUpper() }
        }
        
        if ($queryParams.ContainsKey("category")) {
            $findings = $findings | Where-Object { $_.category -eq $queryParams["category"] }
        }
        
        if ($queryParams.ContainsKey("environmentName")) {
            $findings = $findings | Where-Object { $_.environmentName -eq $queryParams["environmentName"] }
        }
        
        if ($queryParams.ContainsKey("resourceType")) {
            $findings = $findings | Where-Object { $_.resourceType -eq $queryParams["resourceType"] }
        }
        
        # Sort by risk score descending
        $findings = $findings | Sort-Object -Property riskScore -Descending
        
        # Apply pagination
        $totalCount = $findings.Count
        $page = if ($queryParams.ContainsKey("page")) { [int]$queryParams["page"] } else { 1 }
        $pageSize = if ($queryParams.ContainsKey("pageSize")) { [int]$queryParams["pageSize"] } else { 100 }
        
        $startIndex = ($page - 1) * $pageSize
        $endIndex = [math]::Min($startIndex + $pageSize - 1, $totalCount - 1)
        
        if ($startIndex -lt $totalCount) {
            $findings = $findings[$startIndex..$endIndex]
        } else {
            $findings = @()
        }
        
        return @{
            Success = $true
            StatusCode = 200
            Data = @{
                findings = $findings
                summary = @{
                    totalFindings = $totalCount
                    highRiskFindings = ($findings | Where-Object { $_.riskLevel -eq "HIGH" }).Count
                    mediumRiskFindings = ($findings | Where-Object { $_.riskLevel -eq "MEDIUM" }).Count
                    lowRiskFindings = ($findings | Where-Object { $_.riskLevel -eq "LOW" }).Count
                }
                pagination = @{
                    page = $page
                    pageSize = $pageSize
                    totalCount = $totalCount
                    totalPages = [math]::Ceiling($totalCount / $pageSize)
                    hasNextPage = ($page * $pageSize) -lt $totalCount
                    hasPreviousPage = $page -gt 1
                }
                lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            }
        }
        
    } catch {
        Write-ApiLog "Error in findings endpoint: $($_.Exception.Message)" "Error" "Endpoints"
        return @{
            Success = $false
            StatusCode = 500
            ErrorMessage = "Failed to retrieve finding data"
        }
    }
}

function Get-HealthEndpoint {
    Write-ApiLog "Processing /api/health endpoint" "Debug" "Endpoints"
    
    try {
        $uptime = (Get-Date) - $Global:ApiStats.StartTime
        
        $health = @{
            status = "healthy"
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            version = "1.0"
            uptime = @{
                totalSeconds = [math]::Round($uptime.TotalSeconds, 0)
                formatted = "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s"
            }
            statistics = @{
                totalRequests = $Global:ApiStats.TotalRequests
                successfulRequests = $Global:ApiStats.SuccessfulRequests
                failedRequests = $Global:ApiStats.FailedRequests
                successRate = if ($Global:ApiStats.TotalRequests -gt 0) { 
                    [math]::Round(($Global:ApiStats.SuccessfulRequests / $Global:ApiStats.TotalRequests) * 100, 2) 
                } else { 0 }
                lastRequestTime = if ($Global:ApiStats.LastRequestTime) { 
                    $Global:ApiStats.LastRequestTime.ToString("yyyy-MM-ddTHH:mm:ssZ") 
                } else { $null }
            }
            cache = @{
                enabled = $Global:ApiConfig.Cache.Enabled
                entryCount = $Global:AssessmentCache.Keys.Count
                lastRefresh = if ($Global:AssessmentCache.ContainsKey("assessment_data")) { 
                    $Global:AssessmentCache["assessment_data"].Timestamp.ToString("yyyy-MM-ddTHH:mm:ssZ") 
                } else { $null }
            }
            configuration = @{
                authenticationEnabled = $Global:ApiConfig.Authentication.Enabled
                corsEnabled = $Global:ApiConfig.Server.EnableCors
                rateLimitingEnabled = $Global:ApiConfig.Security.RateLimitingEnabled
                httpsEnabled = $Global:ApiConfig.Security.EnableHttps
            }
        }
        
        return @{
            Success = $true
            StatusCode = 200
            Data = $health
        }
        
    } catch {
        Write-ApiLog "Error in health endpoint: $($_.Exception.Message)" "Error" "Endpoints"
        return @{
            Success = $false
            StatusCode = 500
            ErrorMessage = "Health check failed"
        }
    }
}

function Post-RefreshEndpoint {
    Write-ApiLog "Processing /api/refresh endpoint" "Debug" "Endpoints"
    
    try {
        Update-AssessmentCache -Force
        
        return @{
            Success = $true
            StatusCode = 200
            Data = @{
                message = "Assessment data refresh initiated"
                timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            }
        }
        
    } catch {
        Write-ApiLog "Error in refresh endpoint: $($_.Exception.Message)" "Error" "Endpoints"
        return @{
            Success = $false
            StatusCode = 500
            ErrorMessage = "Failed to refresh assessment data"
        }
    }
}

function Get-SwaggerEndpoint {
    Write-ApiLog "Processing /swagger endpoint" "Debug" "Endpoints"
    
    try {
        $swaggerSpec = Get-Content -Path (Join-Path $PSScriptRoot "API-OpenAPI.json") -Raw
        
        return @{
            Success = $true
            StatusCode = 200
            Data = $swaggerSpec | ConvertFrom-Json
        }
        
    } catch {
        Write-ApiLog "Error in swagger endpoint: $($_.Exception.Message)" "Error" "Endpoints"
        return @{
            Success = $false
            StatusCode = 500
            ErrorMessage = "Failed to load API documentation"
        }
    }
}

function Post-AuthTokenEndpoint {
    param([System.Net.HttpListenerRequest]$Request)
    
    Write-ApiLog "Processing /api/auth/token endpoint" "Debug" "Endpoints"
    
    try {
        # This is a simplified token endpoint - in production, implement proper OAuth2/JWT
        $token = New-JwtToken -Subject "api-user" -Name "API User" -Email "" -Permissions @("read")
        
        return @{
            Success = $true
            StatusCode = 200
            Data = @{
                access_token = $token
                token_type = "Bearer"
                expires_in = $Global:ApiConfig.Authentication.TokenExpirationMinutes * 60
            }
        }
        
    } catch {
        Write-ApiLog "Error in auth token endpoint: $($_.Exception.Message)" "Error" "Endpoints"
        return @{
            Success = $false
            StatusCode = 500
            ErrorMessage = "Failed to generate authentication token"
        }
    }
}

function Get-QueryParameters {
    param([System.Net.HttpListenerRequest]$Request)
    
    $queryParams = @{}
    
    if ($Request.Url.Query) {
        $queryString = $Request.Url.Query.TrimStart('?')
        $pairs = $queryString.Split('&')
        
        foreach ($pair in $pairs) {
            $keyValue = $pair.Split('=', 2)
            if ($keyValue.Length -eq 2) {
                $key = [System.Web.HttpUtility]::UrlDecode($keyValue[0])
                $value = [System.Web.HttpUtility]::UrlDecode($keyValue[1])
                $queryParams[$key] = $value
            }
        }
    }
    
    return $queryParams
}

function Get-ConnectorCategory {
    param([string]$ConnectorName)
    
    $categories = @{
        "SharePoint" = "Productivity"
        "Office 365 Outlook" = "Email"
        "OneDrive for Business" = "Storage"
        "Microsoft Teams" = "Communication"
        "SQL Server" = "Database"
        "Common Data Service" = "Database"
        "Dataverse" = "Database"
        "Azure Blob Storage" = "Storage"
        "HTTP" = "Integration"
        "FTP" = "Integration"
        "SFTP" = "Integration"
        "File System" = "Storage"
    }
    
    return $categories[$ConnectorName] ?? "Other"
}

# Export functions for use in main API module
Export-ModuleMember -Function @(
    'Invoke-ApiEndpoint',
    'Get-SummaryEndpoint',
    'Get-EnvironmentsEndpoint', 
    'Get-UsersEndpoint',
    'Get-ConnectionsEndpoint',
    'Get-FlowsEndpoint',
    'Get-FindingsEndpoint',
    'Get-HealthEndpoint',
    'Post-RefreshEndpoint'
)