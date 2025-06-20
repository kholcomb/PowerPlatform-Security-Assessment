# Power Query M Language Reference for Security Assessment

## Overview
This document provides comprehensive reference for the Power Query M language scripts used in the Power Automate Security Assessment Tool.

## Core M Language Functions

### Data Source Connection
```m
// Basic API Connection
Source = Json.Document(Web.Contents("https://api.powerautomate.com/endpoint", [
    Headers=[
        #"Authorization"="Bearer " & AccessToken,
        #"Content-Type"="application/json"
    ]
]))

// With Error Handling
Source = try Json.Document(Web.Contents(ApiUrl)) otherwise #table({}, {})
```

### Data Type Transformations
```m
// Convert column types
TypedColumns = Table.TransformColumnTypes(SourceTable, {
    {"id", type text},
    {"displayName", type text},
    {"createdTime", type datetimezone},
    {"isEncrypted", type logical},
    {"connectionCount", Int64.Type}
})
```

### Adding Calculated Columns
```m
// Risk Level Calculation
AddRiskLevel = Table.AddColumn(SourceTable, "RiskLevel", each 
    if [permissionLevel] = "Admin" and [externalConnections] > 0 then "High"
    else if [permissionLevel] = "Admin" or [externalConnections] > 0 then "Medium"
    else "Low", type text)

// Compliance Score Calculation
AddComplianceScore = Table.AddColumn(SourceTable, "ComplianceScore", each
    let
        BaseScore = 100,
        AdminPenalty = if [permissionLevel] = "Admin" then 20 else 0,
        ExternalPenalty = [externalConnections] * 10,
        EncryptionPenalty = if [isEncrypted] = false then 15 else 0
    in
        Number.Max({0, BaseScore - AdminPenalty - ExternalPenalty - EncryptionPenalty}))
```

## Security Assessment Functions

### Risk Classification Function
```m
ClassifyRisk = (permissionLevel as text, externalConnections as number, isEncrypted as logical) =>
    let
        BaseRisk = if permissionLevel = "Admin" then 3
                  else if permissionLevel = "User" then 2
                  else 1,
        ExternalRisk = if externalConnections > 2 then 2
                      else if externalConnections > 0 then 1
                      else 0,
        EncryptionRisk = if isEncrypted = false then 1 else 0,
        TotalRisk = BaseRisk + ExternalRisk + EncryptionRisk,
        RiskLevel = if TotalRisk >= 5 then "Critical"
                   else if TotalRisk >= 4 then "High"
                   else if TotalRisk >= 2 then "Medium"
                   else "Low"
    in
        RiskLevel
```

### Compliance Scoring Function
```m
CalculateComplianceScore = (flow as record) =>
    let
        // Base compliance checks
        AuditTrail = if Record.HasFields(flow, "auditingEnabled") and flow[auditingEnabled] = true then 15 else 0,
        Encryption = if Record.HasFields(flow, "isEncrypted") and flow[isEncrypted] = true then 20 else 0,
        AccessControl = if Record.HasFields(flow, "accessLevel") and flow[accessLevel] <> "Everyone" then 15 else 0,
        Documentation = if Record.HasFields(flow, "description") and Text.Length(flow[description]) > 50 then 10 else 0,
        Ownership = if Record.HasFields(flow, "owner") and flow[owner] <> null then 10 else 0,
        Monitoring = if Record.HasFields(flow, "monitoringEnabled") and flow[monitoringEnabled] = true then 10 else 0,
        ApprovalProcess = if Record.HasFields(flow, "requiresApproval") and flow[requiresApproval] = true then 20 else 0,
        
        // Calculate penalties
        ExternalPenalty = if Record.HasFields(flow, "externalConnections") then flow[externalConnections] * 3 else 0,
        UserCountPenalty = if Record.HasFields(flow, "userCount") and flow[userCount] > 50 then 10 else 0,
        
        // Final score calculation
        BaseScore = AuditTrail + Encryption + AccessControl + Documentation + Ownership + Monitoring + ApprovalProcess,
        FinalScore = Number.Max({0, BaseScore - ExternalPenalty - UserCountPenalty})
    in
        FinalScore
```

### Business Impact Assessment
```m
AssessBusinessImpact = (connectorCount as number, userCount as number, criticalData as logical) =>
    let
        ConnectorImpact = if connectorCount > 5 then 3
                         else if connectorCount > 3 then 2
                         else if connectorCount > 1 then 1
                         else 0,
        UserImpact = if userCount > 100 then 3
                    else if userCount > 50 then 2
                    else if userCount > 10 then 1
                    else 0,
        DataImpact = if criticalData = true then 2 else 0,
        TotalImpact = ConnectorImpact + UserImpact + DataImpact,
        ImpactLevel = if TotalImpact >= 6 then "Critical"
                     else if TotalImpact >= 4 then "High"
                     else if TotalImpact >= 2 then "Medium"
                     else "Low"
    in
        ImpactLevel
```

## Connector Security Analysis

### Connector Classification
```m
// Security classification lookup
SecurityClassifications = #table(
    {"ConnectorName", "SecurityRisk", "DataClassification", "ThreatLevel"},
    {
        {"SharePoint", "Low", "Internal", 1},
        {"SQL Server", "High", "Internal", 4},
        {"HTTP", "Critical", "External", 5},
        {"Dropbox", "Medium", "External", 3}
    }
)

// Join with connector data
ClassifiedConnectors = Table.NestedJoin(
    ConnectorTable,
    {"name"},
    SecurityClassifications,
    {"ConnectorName"},
    "SecurityInfo",
    JoinKind.LeftOuter
)
```

### Usage Frequency Analysis
```m
AnalyzeUsageFrequency = (flowCount as number) =>
    if flowCount >= 100 then "Very High"
    else if flowCount >= 50 then "High"
    else if flowCount >= 20 then "Medium"
    else if flowCount >= 5 then "Low"
    else "Very Low"
```

### Security Score Calculation
```m
CalculateSecurityScore = (securityRisk as text, usageFrequency as text, complianceLevel as text) =>
    let
        BaseScore = 100,
        RiskPenalty = if securityRisk = "Critical" then 50
                     else if securityRisk = "High" then 35
                     else if securityRisk = "Medium" then 20
                     else if securityRisk = "Low" then 10
                     else 25,
        UsagePenalty = if usageFrequency = "Very High" then 15
                      else if usageFrequency = "High" then 10
                      else if usageFrequency = "Medium" then 5
                      else 0,
        ComplianceBonus = if complianceLevel = "High" then 10
                         else if complianceLevel = "Medium" then 5
                         else 0,
        FinalScore = BaseScore - RiskPenalty - UsagePenalty + ComplianceBonus
    in
        Number.Max({0, FinalScore})
```

## Data Transformation Patterns

### Date Calculations
```m
// Age calculations
AddFlowAge = Table.AddColumn(SourceTable, "FlowAgeDays", each 
    Duration.Days(DateTimeZone.UtcNow() - [createdTime]), Int64.Type)

// Last modified calculations
AddLastModified = Table.AddColumn(SourceTable, "DaysSinceModified", each
    Duration.Days(DateTimeZone.UtcNow() - [lastModifiedTime]), Int64.Type)

// Maintenance flag
AddMaintenanceFlag = Table.AddColumn(SourceTable, "NeedsMaintenance", each
    [DaysSinceModified] > 90 or [FlowAgeDays] > 365, type logical)
```

### Text Processing
```m
// Clean and standardize text
CleanFlowName = Table.TransformColumns(SourceTable, {
    {"displayName", each Text.Proper(Text.Trim(_)), type text}
})

// Extract domains from email addresses
ExtractDomain = Table.AddColumn(SourceTable, "OwnerDomain", each
    if Text.Contains([owner], "@") then 
        Text.AfterDelimiter([owner], "@")
    else 
        "Unknown", type text)
```

### Filtering and Sorting
```m
// Filter out test flows
FilterProductionFlows = Table.SelectRows(SourceTable, each 
    not Text.Contains(Text.Lower([displayName]), "test") and 
    not Text.Contains(Text.Lower([displayName]), "demo"))

// Sort by priority
SortByPriority = Table.Sort(SourceTable, {
    {"RiskLevel", Order.Ascending},
    {"ComplianceScore", Order.Ascending},
    {"BusinessImpact", Order.Descending}
})
```

## Advanced Aggregations

### Grouping and Summarizing
```m
// Group by risk level
RiskSummary = Table.Group(
    SourceTable,
    {"RiskLevel"},
    {
        {"FlowCount", each Table.RowCount(_), Int64.Type},
        {"AvgComplianceScore", each Number.Round(List.Average([ComplianceScore]), 2), Number.Type},
        {"TotalUsers", each List.Sum([UserCount]), Int64.Type},
        {"MaxExternalConnections", each List.Max([ExternalConnections]), Int64.Type}
    }
)

// Department analysis
DepartmentAnalysis = Table.Group(
    SourceTable,
    {"OwnerDomain"},
    {
        {"FlowCount", each Table.RowCount(_)},
        {"HighRiskCount", each List.Count(List.Select([RiskLevel], each _ = "High"))},
        {"AvgSecurityScore", each List.Average([SecurityScore])},
        {"ComplianceRate", each List.Count(List.Select([ComplianceScore], each _ > 70)) / Table.RowCount(_)}
    }
)
```

### Cross-Table Analysis
```m
// Join flows with connectors
FlowConnectorAnalysis = Table.NestedJoin(
    FlowsTable,
    {"ConnectorType"},
    ConnectorsTable,
    {"Name"},
    "ConnectorDetails",
    JoinKind.LeftOuter
)

// Expand connector security information
ExpandedAnalysis = Table.ExpandTableColumn(
    FlowConnectorAnalysis,
    "ConnectorDetails",
    {"SecurityRisk", "ComplianceLevel", "ThreatScore"},
    {"ConnectorSecurityRisk", "ConnectorComplianceLevel", "ConnectorThreatScore"}
)
```

## Error Handling Patterns

### Null Value Handling
```m
// Handle null values in calculations
SafeCalculation = Table.AddColumn(SourceTable, "SafeScore", each
    let
        Score1 = if [Value1] = null then 0 else [Value1],
        Score2 = if [Value2] = null then 0 else [Value2],
        Result = Score1 + Score2
    in
        Result)

// Replace null with default values
HandleNulls = Table.ReplaceValue(
    SourceTable,
    null,
    "Unknown",
    Replacer.ReplaceValue,
    {"SecurityRisk", "ComplianceLevel"}
)
```

### Try-Otherwise Pattern
```m
// Safe API call with fallback
SafeApiCall = try 
    Json.Document(Web.Contents(ApiUrl))
otherwise 
    #table({"id", "name"}, {})

// Safe calculation with error handling
SafeTransformation = Table.AddColumn(SourceTable, "CalculatedField", each
    try 
        [Field1] / [Field2]
    otherwise 
        0)
```

## Performance Optimization

### Query Folding
```m
// Ensure query folding for SQL sources
OptimizedQuery = Table.SelectRows(
    Table.SelectColumns(SqlSource, {"id", "name", "createdDate"}),
    each [createdDate] > #date(2023, 1, 1)
)
```

### Lazy Evaluation
```m
// Use lazy evaluation for large datasets
LazyTransformation = Table.AddColumn(SourceTable, "ExpensiveCalculation", each
    if [ProcessFlag] = true then
        ComplexCalculation([Data])
    else
        null)
```

### Buffering Strategy
```m
// Buffer frequently accessed tables
BufferedLookup = Table.Buffer(LookupTable)

// Use buffered table in joins
JoinedData = Table.NestedJoin(
    SourceTable,
    {"Key"},
    BufferedLookup,
    {"Key"},
    "LookupData"
)
```

## Custom Functions

### Reusable Security Functions
```m
// Create custom function for reuse
fn_CalculateRiskScore = (
    permissionLevel as text,
    externalConnections as number,
    isEncrypted as logical,
    userCount as number
) =>
let
    BaseRisk = 
        if permissionLevel = "Admin" then 40
        else if permissionLevel = "User" then 20
        else 10,
    
    ExternalRisk = externalConnections * 15,
    EncryptionRisk = if isEncrypted then 0 else 25,
    UserRisk = if userCount > 50 then 20 else if userCount > 20 then 10 else 0,
    
    TotalRisk = BaseRisk + ExternalRisk + EncryptionRisk + UserRisk,
    RiskScore = Number.Min({100, TotalRisk})
in
    RiskScore

// Use custom function
ApplyRiskScore = Table.AddColumn(SourceTable, "RiskScore", each
    fn_CalculateRiskScore([PermissionLevel], [ExternalConnections], [IsEncrypted], [UserCount]))
```

## Testing and Validation

### Data Quality Checks
```m
// Validate required fields
ValidateData = Table.AddColumn(SourceTable, "ValidationErrors", each
    let
        Errors = {},
        ErrorsWithId = if [id] = null or [id] = "" then Errors & {"Missing ID"} else Errors,
        ErrorsWithName = if [name] = null or [name] = "" then ErrorsWithId & {"Missing Name"} else ErrorsWithId,
        ErrorsWithDate = if [createdDate] = null then ErrorsWithName & {"Missing Date"} else ErrorsWithName
    in
        Text.Combine(ErrorsWithDate, "; "))

// Filter valid records
ValidRecords = Table.SelectRows(ValidateData, each [ValidationErrors] = "")
```

### Data Type Validation
```m
// Ensure numeric fields are valid
ValidateNumbers = Table.TransformColumns(SourceTable, {
    {"UserCount", each if Value.Type(_) = type number and _ >= 0 then _ else 0, Int64.Type},
    {"ConnectorCount", each if Value.Type(_) = type number and _ >= 0 then _ else 0, Int64.Type}
})
```

## Documentation Standards

### Code Comments
```m
// Step 1: Source data from API
Source = Json.Document(Web.Contents(ApiUrl)),

// Step 2: Convert to table format
FlowsTable = Table.FromRecords(Source[flows]),

// Step 3: Apply data type transformations
TypedData = Table.TransformColumnTypes(FlowsTable, TypeMap),

// Step 4: Add calculated risk metrics
WithRiskMetrics = Table.AddColumn(TypedData, "RiskLevel", RiskCalculation)
```

### Function Documentation
```m
/*
Function: CalculateSecurityMetrics
Purpose: Calculate comprehensive security metrics for flows
Parameters:
  - flowData: Table containing flow information
  - securityConfig: Record containing security configuration
Returns: Table with added security metric columns
Dependencies: SecurityClassifications table
*/
fn_CalculateSecurityMetrics = (flowData as table, securityConfig as record) => ...
```

This reference guide provides the foundation for building robust Power Query solutions for security assessment. Refer to specific script files for implementation examples and advanced patterns.