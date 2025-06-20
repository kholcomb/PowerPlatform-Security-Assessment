// Power Query M Language Script for Security Data Transformation
// File: SecurityDataTransformation.m

let
    // Step 1: Connect to data source
    Source = Json.Document(Web.Contents("https://api.powerautomate.com/security-assessment", [
        Headers=[
            #"Authorization"="Bearer " & #"Access Token",
            #"Content-Type"="application/json"
        ]
    ])),
    
    // Step 2: Extract flows data
    FlowsData = Source[flows],
    FlowsTable = Table.FromRecords(FlowsData),
    
    // Step 3: Data type transformations
    TypedColumns = Table.TransformColumnTypes(FlowsTable, {
        {"id", type text},
        {"displayName", type text},
        {"owner", type text},
        {"createdTime", type datetimezone},
        {"lastModifiedTime", type datetimezone},
        {"permissionLevel", type text},
        {"externalConnectionCount", Int64.Type},
        {"isEncrypted", type logical},
        {"connectorCount", Int64.Type},
        {"userCount", Int64.Type}
    }),
    
    // Step 4: Add calculated risk level column
    AddRiskLevel = Table.AddColumn(TypedColumns, "RiskLevel", each 
        if [permissionLevel] = "Admin" and [externalConnectionCount] > 0 then "High"
        else if [permissionLevel] = "Admin" or [externalConnectionCount] > 0 then "Medium"
        else "Low", type text),
    
    // Step 5: Add compliance score calculation
    AddComplianceScore = Table.AddColumn(AddRiskLevel, "ComplianceScore", each
        let
            BaseScore = 100,
            AdminPenalty = if [permissionLevel] = "Admin" then 20 else 0,
            ExternalPenalty = [externalConnectionCount] * 10,
            EncryptionPenalty = if [isEncrypted] = false then 15 else 0,
            UserCountPenalty = if [userCount] > 50 then 10 else 0,
            FinalScore = BaseScore - AdminPenalty - ExternalPenalty - EncryptionPenalty - UserCountPenalty
        in
            Number.Max({0, FinalScore}), type number),
    
    // Step 6: Add business impact classification
    AddBusinessImpact = Table.AddColumn(AddComplianceScore, "BusinessImpact", each
        if [connectorCount] > 5 and [userCount] > 50 then "Critical"
        else if [connectorCount] > 3 or [userCount] > 20 then "High"
        else if [connectorCount] > 1 or [userCount] > 5 then "Medium"
        else "Low", type text),
    
    // Step 7: Add security category based on connectors
    AddSecurityCategory = Table.AddColumn(AddBusinessImpact, "SecurityCategory", each
        if [externalConnectionCount] > 2 then "External Integration"
        else if [connectorCount] > 3 then "Complex Automation"
        else if [userCount] > 10 then "Shared Process"
        else "Standard Flow", type text),
    
    // Step 8: Add age calculation
    AddFlowAge = Table.AddColumn(AddSecurityCategory, "FlowAgeDays", each
        Duration.Days(DateTimeZone.UtcNow() - [createdTime]), Int64.Type),
    
    // Step 9: Add last modified age
    AddLastModifiedAge = Table.AddColumn(AddFlowAge, "DaysSinceModified", each
        Duration.Days(DateTimeZone.UtcNow() - [lastModifiedTime]), Int64.Type),
    
    // Step 10: Add maintenance flag
    AddMaintenanceFlag = Table.AddColumn(AddLastModifiedAge, "NeedsMaintenance", each
        [DaysSinceModified] > 90 or [FlowAgeDays] > 365, type logical),
    
    // Step 11: Filter out test flows (optional)
    FilterTestFlows = Table.SelectRows(AddMaintenanceFlag, each 
        not Text.Contains(Text.Lower([displayName]), "test") and 
        not Text.Contains(Text.Lower([displayName]), "demo")),
    
    // Step 12: Sort by risk level and compliance score
    SortedData = Table.Sort(FilterTestFlows, {
        {"RiskLevel", Order.Ascending}, 
        {"ComplianceScore", Order.Ascending},
        {"BusinessImpact", Order.Descending}
    }),
    
    // Step 13: Add row index for tracking
    AddIndex = Table.AddIndexColumn(SortedData, "RowIndex", 1, 1),
    
    // Step 14: Final column selection and ordering
    FinalColumns = Table.SelectColumns(AddIndex, {
        "RowIndex",
        "id",
        "displayName", 
        "owner",
        "createdTime",
        "lastModifiedTime",
        "FlowAgeDays",
        "DaysSinceModified",
        "permissionLevel",
        "externalConnectionCount",
        "isEncrypted",
        "connectorCount",
        "userCount",
        "RiskLevel",
        "ComplianceScore",
        "BusinessImpact",
        "SecurityCategory",
        "NeedsMaintenance"
    })
in
    FinalColumns