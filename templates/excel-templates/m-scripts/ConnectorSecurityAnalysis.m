// Power Query M Language Script for Connector Security Analysis
// File: ConnectorSecurityAnalysis.m

let
    // Step 1: Source connector data
    ConnectorSource = Json.Document(Web.Contents("https://api.powerautomate.com/connectors", [
        Headers=[
            #"Authorization"="Bearer " & #"Access Token",
            #"Content-Type"="application/json"
        ]
    ])),
    
    // Step 2: Convert to table
    ConnectorTable = Table.FromRecords(ConnectorSource[connectors]),
    
    // Step 3: Security classification lookup table
    SecurityClassifications = #table(
        {"ConnectorName", "SecurityRisk", "ComplianceLevel", "DataClassification", "ThreatLevel"},
        {
            {"SharePoint", "Low", "High", "Internal", 1},
            {"OneDrive for Business", "Low", "High", "Internal", 1},
            {"Office 365 Outlook", "Medium", "High", "Internal", 2},
            {"Microsoft Teams", "Medium", "High", "Internal", 2},
            {"SQL Server", "High", "Medium", "Internal", 4},
            {"Azure SQL Database", "Medium", "High", "Internal", 3},
            {"HTTP", "Critical", "Low", "External", 5},
            {"HTTP with Azure AD", "High", "Medium", "External", 4},
            {"File System", "High", "Low", "Local", 4},
            {"FTP", "Critical", "Low", "External", 5},
            {"SFTP", "High", "Medium", "External", 4},
            {"Dropbox", "Medium", "Medium", "External", 3},
            {"Google Drive", "Medium", "Medium", "External", 3},
            {"Salesforce", "Medium", "High", "External", 3},
            {"Twitter", "Medium", "Low", "External", 3},
            {"Facebook", "Medium", "Low", "External", 3},
            {"Instagram", "Medium", "Low", "External", 3},
            {"LinkedIn", "Medium", "Medium", "External", 3},
            {"Slack", "Medium", "Medium", "External", 3},
            {"Trello", "Low", "Medium", "External", 2},
            {"Gmail", "High", "Medium", "External", 4},
            {"YouTube", "Low", "Low", "External", 2},
            {"Azure Blob Storage", "Medium", "High", "Internal", 3},
            {"Azure Key Vault", "Low", "High", "Internal", 1},
            {"Power BI", "Low", "High", "Internal", 1},
            {"Common Data Service", "Low", "High", "Internal", 1},
            {"Excel Online", "Low", "High", "Internal", 1},
            {"Word Online", "Low", "High", "Internal", 1},
            {"PowerApps", "Low", "High", "Internal", 1},
            {"Microsoft Forms", "Low", "High", "Internal", 1},
            {"Planner", "Low", "High", "Internal", 1},
            {"Yammer", "Medium", "Medium", "Internal", 2},
            {"Azure Logic Apps", "Medium", "High", "Internal", 3},
            {"Azure Functions", "High", "Medium", "Internal", 4},
            {"RSS", "Low", "Low", "External", 2},
            {"Weather", "Low", "Low", "External", 1},
            {"MSN Weather", "Low", "Low", "External", 1},
            {"Cognitive Services", "Medium", "High", "Internal", 3},
            {"Azure Cognitive Services", "Medium", "High", "Internal", 3}
        }
    ),
    
    // Step 4: Join connector data with security classifications
    JoinedData = Table.NestedJoin(
        ConnectorTable,
        {"name"},
        SecurityClassifications,
        {"ConnectorName"},
        "SecurityInfo",
        JoinKind.LeftOuter
    ),
    
    // Step 5: Expand security information
    ExpandedSecurity = Table.ExpandTableColumn(
        JoinedData,
        "SecurityInfo",
        {"SecurityRisk", "ComplianceLevel", "DataClassification", "ThreatLevel"},
        {"SecurityRisk", "ComplianceLevel", "DataClassification", "ThreatLevel"}
    ),
    
    // Step 6: Handle unclassified connectors
    HandleUnclassified = Table.ReplaceValue(
        ExpandedSecurity,
        null,
        "Unknown",
        Replacer.ReplaceValue,
        {"SecurityRisk", "ComplianceLevel", "DataClassification"}
    ),
    
    // Step 7: Add usage frequency classification
    AddUsageFrequency = Table.AddColumn(HandleUnclassified, "UsageFrequency", each
        if [flowCount] >= 100 then "Very High"
        else if [flowCount] >= 50 then "High"
        else if [flowCount] >= 20 then "Medium"
        else if [flowCount] >= 5 then "Low"
        else "Very Low", type text),
    
    // Step 8: Calculate security score
    AddSecurityScore = Table.AddColumn(AddUsageFrequency, "SecurityScore", each
        let
            BaseScore = 100,
            RiskPenalty = if [SecurityRisk] = "Critical" then 50
                         else if [SecurityRisk] = "High" then 35
                         else if [SecurityRisk] = "Medium" then 20
                         else if [SecurityRisk] = "Low" then 10
                         else 25, // Unknown
            ComplianceBonus = if [ComplianceLevel] = "High" then 10
                            else if [ComplianceLevel] = "Medium" then 5
                            else 0,
            UsageRiskPenalty = if [UsageFrequency] = "Very High" then 15
                              else if [UsageFrequency] = "High" then 10
                              else if [UsageFrequency] = "Medium" then 5
                              else 0,
            FinalScore = BaseScore - RiskPenalty + ComplianceBonus - UsageRiskPenalty
        in
            Number.Max({0, FinalScore}), type number),
    
    // Step 9: Add risk priority score
    AddRiskPriority = Table.AddColumn(AddSecurityScore, "RiskPriority", each
        let
            ThreatScore = if [ThreatLevel] = null then 3 else [ThreatLevel],
            UsageMultiplier = if [UsageFrequency] = "Very High" then 2.0
                            else if [UsageFrequency] = "High" then 1.5
                            else if [UsageFrequency] = "Medium" then 1.2
                            else 1.0,
            Priority = ThreatScore * UsageMultiplier
        in
            Number.Round(Priority, 2), type number),
    
    // Step 10: Add recommendation category
    AddRecommendation = Table.AddColumn(AddRiskPriority, "Recommendation", each
        if [SecurityRisk] = "Critical" then "Immediate Review Required"
        else if [SecurityRisk] = "High" and [UsageFrequency] = "Very High" then "Priority Review"
        else if [SecurityRisk] = "High" then "Security Review"
        else if [SecurityRisk] = "Medium" and [UsageFrequency] = "Very High" then "Monitor Closely"
        else if [SecurityRisk] = "Medium" then "Periodic Review"
        else if [SecurityRisk] = "Unknown" then "Classification Needed"
        else "Standard Monitoring", type text),
    
    // Step 11: Add compliance gap analysis
    AddComplianceGap = Table.AddColumn(AddRecommendation, "ComplianceGap", each
        if [ComplianceLevel] = "Low" and [DataClassification] = "Internal" then "High Gap"
        else if [ComplianceLevel] = "Low" then "Medium Gap"
        else if [ComplianceLevel] = "Medium" and [SecurityRisk] = "High" then "Medium Gap"
        else "Low Gap", type text),
    
    // Step 12: Calculate total risk exposure
    AddRiskExposure = Table.AddColumn(AddComplianceGap, "RiskExposure", each
        [flowCount] * (if [ThreatLevel] = null then 3 else [ThreatLevel]), Int64.Type),
    
    // Step 13: Group by security risk for summary
    SecurityRiskSummary = Table.Group(
        AddRiskExposure,
        {"SecurityRisk"},
        {
            {"ConnectorCount", each Table.RowCount(_), Int64.Type},
            {"TotalFlows", each List.Sum([flowCount]), Int64.Type},
            {"AverageSecurityScore", each Number.Round(List.Average([SecurityScore]), 2), type number},
            {"TotalRiskExposure", each List.Sum([RiskExposure]), Int64.Type},
            {"HighUsageConnectors", each List.Count(List.Select([UsageFrequency], each _ = "Very High" or _ = "High")), Int64.Type}
        }
    ),
    
    // Step 14: Sort by risk priority
    SortedByRisk = Table.Sort(AddRiskExposure, {
        {"RiskPriority", Order.Descending},
        {"RiskExposure", Order.Descending},
        {"SecurityScore", Order.Ascending}
    }),
    
    // Step 15: Add rank based on risk priority
    AddRiskRank = Table.AddIndexColumn(SortedByRisk, "RiskRank", 1, 1),
    
    // Step 16: Final column selection
    FinalResult = Table.SelectColumns(AddRiskRank, {
        "RiskRank",
        "name",
        "displayName",
        "publisher",
        "flowCount",
        "SecurityRisk",
        "ComplianceLevel",
        "DataClassification",
        "ThreatLevel",
        "UsageFrequency",
        "SecurityScore",
        "RiskPriority",
        "RiskExposure",
        "Recommendation",
        "ComplianceGap"
    })
in
    FinalResult