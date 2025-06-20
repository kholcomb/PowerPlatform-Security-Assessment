// Power Query M Language Script for Compliance Metrics Analysis
// File: ComplianceMetrics.m

let
    // Step 1: Source compliance data from multiple endpoints
    FlowsSource = Json.Document(Web.Contents("https://api.powerautomate.com/flows")),
    EnvironmentsSource = Json.Document(Web.Contents("https://api.powerautomate.com/environments")),
    PoliciesSource = Json.Document(Web.Contents("https://api.powerautomate.com/policies")),
    
    // Step 2: Convert flows to table
    FlowsTable = Table.FromRecords(FlowsSource[flows]),
    
    // Step 3: Compliance frameworks reference
    ComplianceFrameworks = #table(
        {"Framework", "RequiredControls", "RiskWeight", "Priority"},
        {
            {"SOX", "Segregation of Duties,Audit Trail,Data Retention", 0.9, "Critical"},
            {"GDPR", "Data Protection,Consent Management,Right to be Forgotten", 0.85, "Critical"},
            {"HIPAA", "Data Encryption,Access Controls,Audit Logging", 0.8, "High"},
            {"PCI DSS", "Data Encryption,Network Security,Access Controls", 0.75, "High"},
            {"ISO 27001", "Information Security,Risk Management,Incident Response", 0.7, "Medium"},
            {"SOC 2", "Security,Availability,Processing Integrity", 0.65, "Medium"},
            {"NIST", "Identify,Protect,Detect,Respond,Recover", 0.6, "Medium"},
            {"COBIT", "Governance,Management,Risk,Compliance", 0.55, "Low"}
        }
    ),
    
    // Step 4: Add compliance scoring for each flow
    AddComplianceMetrics = Table.AddColumn(FlowsTable, "ComplianceMetrics", each
        let
            // Basic compliance checks
            HasAuditTrail = if [auditingEnabled] = true then 10 else 0,
            HasEncryption = if [isEncrypted] = true then 15 else 0,
            HasAccessControls = if [accessLevel] <> "Everyone" then 10 else 0,
            HasDocumentation = if [description] <> null and Text.Length([description]) > 50 then 5 else 0,
            HasOwnership = if [owner] <> null then 5 else 0,
            HasDataRetention = if [retentionPolicy] <> null then 10 else 0,
            HasMonitoring = if [monitoringEnabled] = true then 10 else 0,
            HasApprovalProcess = if [requiresApproval] = true then 15 else 0,
            HasBusinessJustification = if [businessJustification] <> null then 10 else 0,
            HasTestingEvidence = if [testingCompleted] = true then 10 else 0,
            
            // Calculate base compliance score
            BaseScore = HasAuditTrail + HasEncryption + HasAccessControls + HasDocumentation + 
                       HasOwnership + HasDataRetention + HasMonitoring + HasApprovalProcess + 
                       HasBusinessJustification + HasTestingEvidence,
            
            // Apply penalties for high-risk configurations
            ExternalConnectorPenalty = [externalConnectorCount] * 5,
            AdminPermissionPenalty = if [permissionLevel] = "Admin" then 20 else 0,
            SharedFlowPenalty = if [isShared] = true and [userCount] > 10 then 15 else 0,
            
            FinalScore = Number.Max({0, BaseScore - ExternalConnectorPenalty - AdminPermissionPenalty - SharedFlowPenalty})
        in
            [
                BaseScore = BaseScore,
                AuditTrail = HasAuditTrail,
                Encryption = HasEncryption,
                AccessControls = HasAccessControls,
                Documentation = HasDocumentation,
                Ownership = HasOwnership,
                DataRetention = HasDataRetention,
                Monitoring = HasMonitoring,
                ApprovalProcess = HasApprovalProcess,
                BusinessJustification = HasBusinessJustification,
                TestingEvidence = HasTestingEvidence,
                ExternalConnectorPenalty = ExternalConnectorPenalty,
                AdminPermissionPenalty = AdminPermissionPenalty,
                SharedFlowPenalty = SharedFlowPenalty,
                FinalScore = FinalScore
            ]),
    
    // Step 5: Expand compliance metrics
    ExpandedMetrics = Table.ExpandRecordColumn(AddComplianceMetrics, "ComplianceMetrics", 
        {"BaseScore", "AuditTrail", "Encryption", "AccessControls", "Documentation", 
         "Ownership", "DataRetention", "Monitoring", "ApprovalProcess", "BusinessJustification", 
         "TestingEvidence", "ExternalConnectorPenalty", "AdminPermissionPenalty", 
         "SharedFlowPenalty", "FinalScore"}),
    
    // Step 6: Add compliance level classification
    AddComplianceLevel = Table.AddColumn(ExpandedMetrics, "ComplianceLevel", each
        if [FinalScore] >= 80 then "Compliant"
        else if [FinalScore] >= 60 then "Partially Compliant"
        else if [FinalScore] >= 40 then "Non-Compliant"
        else "Critical Non-Compliance", type text),
    
    // Step 7: Add framework-specific compliance assessment
    AddFrameworkCompliance = Table.AddColumn(AddComplianceLevel, "FrameworkCompliance", each
        [
            SOX = if [AuditTrail] > 0 and [ApprovalProcess] > 0 and [Documentation] > 0 then "Pass" else "Fail",
            GDPR = if [Encryption] > 0 and [AccessControls] > 0 and [DataRetention] > 0 then "Pass" else "Fail",
            HIPAA = if [Encryption] > 0 and [AccessControls] > 0 and [AuditTrail] > 0 then "Pass" else "Fail",
            PCI_DSS = if [Encryption] > 0 and [AccessControls] > 0 and [Monitoring] > 0 then "Pass" else "Fail",
            ISO_27001 = if [AccessControls] > 0 and [Monitoring] > 0 and [Documentation] > 0 then "Pass" else "Fail",
            SOC_2 = if [AccessControls] > 0 and [Monitoring] > 0 and [ApprovalProcess] > 0 then "Pass" else "Fail"
        ]),
    
    // Step 8: Expand framework compliance
    ExpandedFramework = Table.ExpandRecordColumn(AddFrameworkCompliance, "FrameworkCompliance", 
        {"SOX", "GDPR", "HIPAA", "PCI_DSS", "ISO_27001", "SOC_2"}),
    
    // Step 9: Add overall framework compliance score
    AddFrameworkScore = Table.AddColumn(ExpandedFramework, "FrameworkComplianceScore", each
        let
            PassCount = List.Count(List.Select({[SOX], [GDPR], [HIPAA], [PCI_DSS], [ISO_27001], [SOC_2]}, each _ = "Pass")),
            TotalFrameworks = 6,
            Score = (PassCount / TotalFrameworks) * 100
        in
            Number.Round(Score, 1), type number),
    
    // Step 10: Add remediation priority
    AddRemediationPriority = Table.AddColumn(AddFrameworkScore, "RemediationPriority", each
        if [ComplianceLevel] = "Critical Non-Compliance" then "Immediate"
        else if [ComplianceLevel] = "Non-Compliant" and [userCount] > 50 then "High"
        else if [ComplianceLevel] = "Non-Compliant" then "Medium"
        else if [ComplianceLevel] = "Partially Compliant" and [externalConnectorCount] > 2 then "Medium"
        else "Low", type text),
    
    // Step 11: Add compliance gaps analysis
    AddComplianceGaps = Table.AddColumn(AddRemediationPriority, "ComplianceGaps", each
        let
            Gaps = {},
            GapsWithAudit = if [AuditTrail] = 0 then Gaps & {"Audit Trail"} else Gaps,
            GapsWithEncryption = if [Encryption] = 0 then GapsWithAudit & {"Encryption"} else GapsWithAudit,
            GapsWithAccess = if [AccessControls] = 0 then GapsWithEncryption & {"Access Controls"} else GapsWithEncryption,
            GapsWithDocs = if [Documentation] = 0 then GapsWithAccess & {"Documentation"} else GapsWithAccess,
            GapsWithOwnership = if [Ownership] = 0 then GapsWithDocs & {"Ownership"} else GapsWithDocs,
            GapsWithRetention = if [DataRetention] = 0 then GapsWithOwnership & {"Data Retention"} else GapsWithOwnership,
            GapsWithMonitoring = if [Monitoring] = 0 then GapsWithRetention & {"Monitoring"} else GapsWithRetention,
            GapsWithApproval = if [ApprovalProcess] = 0 then GapsWithMonitoring & {"Approval Process"} else GapsWithMonitoring,
            GapsWithJustification = if [BusinessJustification] = 0 then GapsWithApproval & {"Business Justification"} else GapsWithApproval,
            FinalGaps = if [TestingEvidence] = 0 then GapsWithJustification & {"Testing Evidence"} else GapsWithJustification
        in
            Text.Combine(FinalGaps, "; "), type text),
    
    // Step 12: Add estimated remediation effort
    AddRemediationEffort = Table.AddColumn(AddComplianceGaps, "RemediationEffortHours", each
        let
            GapsList = Text.Split([ComplianceGaps], "; "),
            EffortPerGap = 8, // Average hours per gap
            TotalEffort = List.Count(GapsList) * EffortPerGap,
            ComplexityMultiplier = if [externalConnectorCount] > 3 then 1.5
                                 else if [userCount] > 50 then 1.3
                                 else 1.0,
            FinalEffort = TotalEffort * ComplexityMultiplier
        in
            Number.Round(FinalEffort, 0), Int64.Type),
    
    // Step 13: Group by compliance level for summary
    ComplianceSummary = Table.Group(
        AddRemediationEffort,
        {"ComplianceLevel"},
        {
            {"FlowCount", each Table.RowCount(_), Int64.Type},
            {"AverageScore", each Number.Round(List.Average([FinalScore]), 2), type number},
            {"TotalRemediationHours", each List.Sum([RemediationEffortHours]), Int64.Type},
            {"HighPriorityCount", each List.Count(List.Select([RemediationPriority], each _ = "Immediate" or _ = "High")), Int64.Type}
        }
    ),
    
    // Step 14: Add compliance trend (requires historical data)
    AddComplianceTrend = Table.AddColumn(AddRemediationEffort, "ComplianceTrend", each
        // This would typically compare against historical data
        let
            CurrentScore = [FinalScore],
            // Simulated historical score (in production, this would come from historical data)
            HistoricalScore = CurrentScore - 5, // Placeholder
            Trend = if CurrentScore > HistoricalScore then "Improving"
                   else if CurrentScore < HistoricalScore then "Declining"
                   else "Stable"
        in
            Trend, type text),
    
    // Step 15: Final sort by compliance priority
    SortedData = Table.Sort(AddComplianceTrend, {
        {"RemediationPriority", Order.Ascending},
        {"FinalScore", Order.Ascending},
        {"userCount", Order.Descending}
    }),
    
    // Step 16: Add compliance rank
    AddComplianceRank = Table.AddIndexColumn(SortedData, "ComplianceRank", 1, 1),
    
    // Step 17: Final column selection
    FinalResult = Table.SelectColumns(AddComplianceRank, {
        "ComplianceRank",
        "id",
        "displayName",
        "owner",
        "ComplianceLevel",
        "FinalScore",
        "FrameworkComplianceScore",
        "SOX",
        "GDPR",
        "HIPAA",
        "PCI_DSS",
        "ISO_27001",
        "SOC_2",
        "RemediationPriority",
        "ComplianceGaps",
        "RemediationEffortHours",
        "ComplianceTrend",
        "userCount",
        "externalConnectorCount",
        "permissionLevel"
    })
in
    FinalResult