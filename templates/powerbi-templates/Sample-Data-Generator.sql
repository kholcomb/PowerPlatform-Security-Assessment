-- Power Automate Security Assessment Dashboard - Sample Data Generator
-- This script generates sample data for testing the Power BI dashboard template

-- =====================================================
-- CREATE SAMPLE DATA TABLES
-- =====================================================

-- Sample Environments
DECLARE @Environments TABLE (
    EnvironmentID NVARCHAR(100),
    EnvironmentName NVARCHAR(200),
    EnvironmentType NVARCHAR(50),
    Region NVARCHAR(100),
    SecurityLevel NVARCHAR(50),
    DLPPolicies INT,
    ActiveFlows INT,
    LastAssessed DATETIME,
    RiskLevel NVARCHAR(50),
    ComplianceStatus NVARCHAR(50)
);

INSERT INTO @Environments VALUES
('ENV001', 'Production Environment', 'Production', 'US East', 'High', 5, 45, '2024-01-15', 'Medium', 'Compliant'),
('ENV002', 'Development Environment', 'Development', 'US West', 'Medium', 2, 28, '2024-01-14', 'Low', 'Compliant'),
('ENV003', 'UAT Environment', 'UAT', 'Europe', 'Medium', 3, 15, '2024-01-13', 'High', 'Non-Compliant'),
('ENV004', 'Sandbox Environment', 'Sandbox', 'Asia Pacific', 'Basic', 1, 8, '2024-01-12', 'Low', 'Partial'),
('ENV005', 'Trial Environment', 'Trial', 'US Central', 'Standard', 0, 12, '2024-01-11', 'High', 'Non-Compliant'),
('ENV006', 'Finance Production', 'Production', 'Europe', 'High', 4, 22, '2024-01-10', 'Medium', 'Compliant'),
('ENV007', 'HR Development', 'Development', 'US East', 'Medium', 2, 18, '2024-01-09', 'Low', 'Compliant'),
('ENV008', 'Marketing Sandbox', 'Sandbox', 'US West', 'Basic', 1, 6, '2024-01-08', 'Medium', 'Partial');

-- Sample Users
DECLARE @Users TABLE (
    UserID NVARCHAR(100),
    UserName NVARCHAR(200),
    Email NVARCHAR(200),
    Department NVARCHAR(100),
    Role NVARCHAR(100),
    FlowsOwned INT,
    FlowsShared INT,
    LastActivity DATETIME,
    RiskLevel NVARCHAR(50),
    HasAdminAccess BIT
);

INSERT INTO @Users VALUES
('USR001', 'John Smith', 'john.smith@company.com', 'IT', 'System Administrator', 12, 25, '2024-01-14', 'High', 1),
('USR002', 'Sarah Johnson', 'sarah.johnson@company.com', 'Finance', 'Business Analyst', 8, 15, '2024-01-15', 'Medium', 0),
('USR003', 'Mike Chen', 'mike.chen@company.com', 'Marketing', 'Marketing Manager', 5, 8, '2024-01-13', 'Low', 0),
('USR004', 'Emily Davis', 'emily.davis@company.com', 'HR', 'HR Specialist', 6, 12, '2024-01-12', 'Medium', 0),
('USR005', 'David Wilson', 'david.wilson@company.com', 'Operations', 'Operations Manager', 10, 20, '2024-01-11', 'High', 1),
('USR006', 'Lisa Brown', 'lisa.brown@company.com', 'Sales', 'Sales Director', 4, 18, '2024-01-10', 'Low', 0),
('USR007', 'Tom Anderson', 'tom.anderson@company.com', 'IT', 'Developer', 15, 5, '2024-01-09', 'High', 0),
('USR008', 'Anna Taylor', 'anna.taylor@company.com', 'Finance', 'Financial Controller', 7, 10, '2024-01-08', 'Medium', 0),
('USR009', 'Robert Lee', 'robert.lee@company.com', 'Marketing', 'Digital Marketing Specialist', 3, 22, '2024-01-07', 'Low', 0),
('USR010', 'Jennifer White', 'jennifer.white@company.com', 'HR', 'HR Manager', 9, 16, '2024-01-06', 'Medium', 1);

-- Sample Flows
DECLARE @Flows TABLE (
    FlowID NVARCHAR(100),
    FlowName NVARCHAR(200),
    EnvironmentID NVARCHAR(100),
    Owner NVARCHAR(100),
    State NVARCHAR(50),
    CreatedDate DATETIME,
    ModifiedDate DATETIME,
    RunCount INT,
    ConnectionCount INT,
    SharedUsers INT,
    RiskCategory NVARCHAR(50),
    HasSensitiveData BIT,
    UsesHTTP BIT,
    HasExternalConnections BIT
);

INSERT INTO @Flows VALUES
('FLOW001', 'Customer Data Sync', 'ENV001', 'USR001', 'Started', '2023-12-01', '2024-01-10', 1250, 3, 5, 'High', 1, 0, 1),
('FLOW002', 'Invoice Processing', 'ENV001', 'USR002', 'Started', '2023-11-15', '2024-01-08', 890, 2, 3, 'Medium', 1, 0, 0),
('FLOW003', 'Employee Onboarding', 'ENV002', 'USR004', 'Started', '2023-10-20', '2024-01-05', 156, 4, 8, 'High', 1, 1, 1),
('FLOW004', 'Marketing Campaign Tracker', 'ENV003', 'USR003', 'Stopped', '2023-09-12', '2023-12-15', 45, 1, 2, 'Low', 0, 0, 0),
('FLOW005', 'Expense Approval', 'ENV001', 'USR008', 'Started', '2023-08-30', '2024-01-12', 2340, 3, 12, 'Medium', 1, 0, 0),
('FLOW006', 'Lead Generation', 'ENV004', 'USR009', 'Started', '2024-01-01', '2024-01-14', 78, 2, 4, 'Low', 0, 1, 1),
('FLOW007', 'Inventory Management', 'ENV001', 'USR005', 'Started', '2023-07-15', '2024-01-11', 3450, 5, 15, 'High', 1, 0, 1),
('FLOW008', 'Document Approval', 'ENV002', 'USR007', 'Suspended', '2023-06-01', '2023-11-20', 234, 2, 6, 'Medium', 0, 0, 0),
('FLOW009', 'Time Tracking', 'ENV003', 'USR010', 'Started', '2023-05-10', '2024-01-09', 1876, 3, 25, 'Low', 0, 0, 0),
('FLOW010', 'Security Incident Response', 'ENV001', 'USR001', 'Started', '2023-04-22', '2024-01-13', 67, 4, 3, 'High', 1, 0, 1);

-- Sample Connections
DECLARE @Connections TABLE (
    ConnectionID NVARCHAR(100),
    ConnectionName NVARCHAR(200),
    ConnectorType NVARCHAR(100),
    EnvironmentID NVARCHAR(100),
    FlowID NVARCHAR(100),
    AuthenticationType NVARCHAR(50),
    IsShared BIT,
    SecurityRating INT,
    LastUsed DATETIME,
    IsDeprecated BIT,
    RequiresMFA BIT
);

INSERT INTO @Connections VALUES
('CONN001', 'SharePoint Online', 'SharePoint', 'ENV001', 'FLOW001', 'OAuth2', 1, 4, '2024-01-14', 0, 1),
('CONN002', 'SQL Server Production', 'SQL Server', 'ENV001', 'FLOW001', 'SQL Server', 0, 3, '2024-01-14', 0, 0),
('CONN003', 'Outlook 365', 'Office 365 Outlook', 'ENV001', 'FLOW002', 'OAuth2', 1, 5, '2024-01-13', 0, 1),
('CONN004', 'Azure AD', 'Azure AD', 'ENV002', 'FLOW003', 'Service Principal', 0, 5, '2024-01-12', 0, 1),
('CONN005', 'HTTP Webhook', 'HTTP', 'ENV003', 'FLOW004', 'Anonymous', 1, 1, '2023-12-15', 1, 0),
('CONN006', 'Dynamics 365', 'Dynamics 365', 'ENV001', 'FLOW005', 'OAuth2', 0, 4, '2024-01-11', 0, 1),
('CONN007', 'Twitter API', 'Twitter', 'ENV004', 'FLOW006', 'API Key', 1, 2, '2024-01-10', 0, 0),
('CONN008', 'FTP Server', 'FTP', 'ENV001', 'FLOW007', 'Basic', 0, 2, '2024-01-09', 1, 0),
('CONN009', 'Teams', 'Microsoft Teams', 'ENV002', 'FLOW008', 'OAuth2', 1, 4, '2023-11-20', 0, 1),
('CONN010', 'Excel Online', 'Excel Online', 'ENV003', 'FLOW009', 'OAuth2', 1, 4, '2024-01-08', 0, 1),
('CONN011', 'Azure Key Vault', 'Azure Key Vault', 'ENV001', 'FLOW010', 'Service Principal', 0, 5, '2024-01-07', 0, 1),
('CONN012', 'OneDrive', 'OneDrive for Business', 'ENV001', 'FLOW001', 'OAuth2', 1, 4, '2024-01-06', 0, 1);

-- Sample Security Findings
DECLARE @SecurityFindings TABLE (
    FindingID NVARCHAR(50),
    EnvironmentID NVARCHAR(100),
    FlowID NVARCHAR(100),
    FlowName NVARCHAR(200),
    Category NVARCHAR(100),
    Severity NVARCHAR(50),
    RiskScore INT,
    Description NVARCHAR(1000),
    Recommendation NVARCHAR(1000),
    Status NVARCHAR(50),
    DateFound DATETIME,
    LastUpdated DATETIME,
    AssignedTo NVARCHAR(100),
    BusinessImpact NVARCHAR(50),
    Remediation NVARCHAR(1000)
);

INSERT INTO @SecurityFindings VALUES
('SF001', 'ENV001', 'FLOW001', 'Customer Data Sync', 'Data Protection', 'High', 4, 'Flow processes customer PII without proper encryption', 'Implement field-level encryption for sensitive data', 'Open', '2024-01-10', '2024-01-10', 'Security Team', 'High', 'Pending security review'),
('SF002', 'ENV001', 'FLOW001', 'Customer Data Sync', 'Network Security', 'Medium', 3, 'Connection uses non-secure HTTP endpoint', 'Migrate to HTTPS endpoint', 'In Progress', '2024-01-09', '2024-01-12', 'Dev Team', 'Medium', 'Endpoint migration in progress'),
('SF003', 'ENV003', 'FLOW004', 'Marketing Campaign Tracker', 'Authentication', 'Critical', 5, 'Anonymous authentication allows unrestricted access', 'Implement proper authentication mechanism', 'Open', '2024-01-08', '2024-01-08', 'IT Admin', 'High', 'Authentication redesign required'),
('SF004', 'ENV002', 'FLOW003', 'Employee Onboarding', 'Access Control', 'High', 4, 'Flow has excessive user permissions', 'Review and reduce user access permissions', 'Resolved', '2024-01-07', '2024-01-14', 'HR Manager', 'Medium', 'Permissions updated'),
('SF005', 'ENV001', 'FLOW007', 'Inventory Management', 'Connector Security', 'Medium', 3, 'FTP connection uses deprecated protocol', 'Upgrade to SFTP or secure alternative', 'Open', '2024-01-06', '2024-01-06', 'Operations', 'Medium', 'Evaluating alternatives'),
('SF006', 'ENV005', NULL, NULL, 'Configuration', 'High', 4, 'Environment lacks DLP policies', 'Implement comprehensive DLP policies', 'Open', '2024-01-05', '2024-01-05', 'Compliance', 'High', 'Policy development started'),
('SF007', 'ENV001', 'FLOW005', 'Expense Approval', 'Data Governance', 'Low', 2, 'Flow lacks proper data retention policies', 'Define and implement data retention schedule', 'In Progress', '2024-01-04', '2024-01-11', 'Finance', 'Low', 'Retention policy being drafted'),
('SF008', 'ENV004', 'FLOW006', 'Lead Generation', 'Compliance', 'Medium', 3, 'Third-party connector not approved for use', 'Use approved connectors or get approval', 'Open', '2024-01-03', '2024-01-03', 'Marketing', 'Medium', 'Approval process initiated'),
('SF009', 'ENV001', 'FLOW010', 'Security Incident Response', 'Access Control', 'Low', 2, 'Flow accessible to too many users', 'Restrict access to security team only', 'Resolved', '2024-01-02', '2024-01-13', 'Security Team', 'Low', 'Access restricted'),
('SF010', 'ENV003', NULL, NULL, 'Configuration', 'Critical', 5, 'Environment security settings misconfigured', 'Review and correct security configuration', 'Open', '2024-01-01', '2024-01-01', 'IT Admin', 'High', 'Security review scheduled'),
('SF011', 'ENV002', 'FLOW008', 'Document Approval', 'Flow Design', 'Medium', 3, 'Flow suspended due to security concerns', 'Address security issues and reactivate', 'In Progress', '2023-12-28', '2024-01-10', 'Dev Team', 'Medium', 'Security fixes in development'),
('SF012', 'ENV001', 'FLOW002', 'Invoice Processing', 'Data Protection', 'Medium', 3, 'Financial data transmitted without encryption', 'Enable encryption for financial data', 'Open', '2023-12-25', '2023-12-25', 'Finance', 'High', 'Encryption implementation planned'),
('SF013', 'ENV006', NULL, NULL, 'Compliance', 'Low', 2, 'Missing audit trail configuration', 'Enable comprehensive audit logging', 'Resolved', '2023-12-20', '2024-01-05', 'Compliance', 'Low', 'Audit logging enabled'),
('SF014', 'ENV007', NULL, NULL, 'Configuration', 'Medium', 3, 'Insufficient backup and recovery setup', 'Implement proper backup strategy', 'Open', '2023-12-15', '2023-12-15', 'IT Admin', 'Medium', 'Backup solution evaluation'),
('SF015', 'ENV008', NULL, NULL, 'Access Control', 'High', 4, 'Guest user access not properly controlled', 'Review and restrict guest access', 'In Progress', '2023-12-10', '2024-01-08', 'IT Admin', 'High', 'Guest access policy update'),
('SF016', 'ENV001', 'FLOW001', 'Customer Data Sync', 'Connector Security', 'Low', 2, 'Connection reference uses outdated version', 'Update to latest connector version', 'Resolved', '2023-12-05', '2024-01-09', 'Dev Team', 'Low', 'Connector updated'),
('SF017', 'ENV002', 'FLOW009', 'Time Tracking', 'Data Governance', 'Low', 1, 'Employee time data retention exceeds policy', 'Implement automatic data cleanup', 'Open', '2023-12-01', '2023-12-01', 'HR', 'Low', 'Cleanup script development'),
('SF018', 'ENV004', NULL, NULL, 'Authentication', 'Medium', 3, 'Multi-factor authentication not enforced', 'Enable MFA for all users', 'Open', '2023-11-28', '2023-11-28', 'IT Admin', 'Medium', 'MFA rollout planning'),
('SF019', 'ENV005', NULL, NULL, 'Network Security', 'High', 4, 'Firewall rules too permissive', 'Implement least privilege network access', 'Open', '2023-11-25', '2023-11-25', 'Network Team', 'High', 'Firewall rule review'),
('SF020', 'ENV003', 'FLOW003', 'Employee Onboarding', 'Flow Design', 'Critical', 5, 'Hardcoded credentials found in flow', 'Remove hardcoded credentials, use Key Vault', 'Resolved', '2023-11-20', '2024-01-12', 'Security Team', 'High', 'Credentials moved to Key Vault');

-- Sample Date Table (past 2 years)
DECLARE @DateTable TABLE (
    Date DATE,
    Year INT,
    Quarter NVARCHAR(2),
    Month NVARCHAR(20),
    MonthNumber INT,
    Week INT,
    DayOfWeek NVARCHAR(10),
    IsWeekend BIT
);

DECLARE @StartDate DATE = '2022-01-01';
DECLARE @EndDate DATE = GETDATE();
DECLARE @CurrentDate DATE = @StartDate;

WHILE @CurrentDate <= @EndDate
BEGIN
    INSERT INTO @DateTable
    SELECT 
        @CurrentDate,
        YEAR(@CurrentDate),
        'Q' + CAST(DATEPART(QUARTER, @CurrentDate) AS VARCHAR(1)),
        DATENAME(MONTH, @CurrentDate),
        MONTH(@CurrentDate),
        DATEPART(WEEK, @CurrentDate),
        DATENAME(WEEKDAY, @CurrentDate),
        CASE WHEN DATEPART(WEEKDAY, @CurrentDate) IN (1, 7) THEN 1 ELSE 0 END
        
    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
END

-- =====================================================
-- OUTPUT SAMPLE DATA AS INSERT STATEMENTS
-- =====================================================

PRINT '-- SAMPLE DATA FOR POWER BI DASHBOARD';
PRINT '-- Generated on: ' + CAST(GETDATE() AS NVARCHAR(20));
PRINT '';

-- Output Environments
PRINT '-- Environments Table';
SELECT 
    'INSERT INTO Environments VALUES (''' + 
    EnvironmentID + ''', ''' + 
    EnvironmentName + ''', ''' + 
    EnvironmentType + ''', ''' + 
    Region + ''', ''' + 
    ISNULL(SecurityLevel, '') + ''', ' + 
    CAST(DLPPolicies AS VARCHAR(10)) + ', ' + 
    CAST(ActiveFlows AS VARCHAR(10)) + ', ''' + 
    CONVERT(VARCHAR(19), LastAssessed, 120) + ''', ''' + 
    ISNULL(RiskLevel, '') + ''', ''' + 
    ISNULL(ComplianceStatus, '') + ''');' AS InsertStatement
FROM @Environments;

PRINT '';

-- Output Users
PRINT '-- Users Table';
SELECT 
    'INSERT INTO Users VALUES (''' + 
    UserID + ''', ''' + 
    UserName + ''', ''' + 
    Email + ''', ''' + 
    ISNULL(Department, '') + ''', ''' + 
    ISNULL(Role, '') + ''', ' + 
    CAST(FlowsOwned AS VARCHAR(10)) + ', ' + 
    CAST(FlowsShared AS VARCHAR(10)) + ', ''' + 
    ISNULL(CONVERT(VARCHAR(19), LastActivity, 120), '') + ''', ''' + 
    ISNULL(RiskLevel, '') + ''', ' + 
    CAST(HasAdminAccess AS VARCHAR(1)) + ');' AS InsertStatement
FROM @Users;

PRINT '';

-- Output Flows
PRINT '-- Flows Table';
SELECT 
    'INSERT INTO Flows VALUES (''' + 
    FlowID + ''', ''' + 
    FlowName + ''', ''' + 
    EnvironmentID + ''', ''' + 
    Owner + ''', ''' + 
    State + ''', ''' + 
    CONVERT(VARCHAR(19), CreatedDate, 120) + ''', ''' + 
    CONVERT(VARCHAR(19), ModifiedDate, 120) + ''', ' + 
    CAST(RunCount AS VARCHAR(10)) + ', ' + 
    CAST(ConnectionCount AS VARCHAR(10)) + ', ' + 
    CAST(SharedUsers AS VARCHAR(10)) + ', ''' + 
    ISNULL(RiskCategory, '') + ''', ' + 
    CAST(HasSensitiveData AS VARCHAR(1)) + ', ' + 
    CAST(UsesHTTP AS VARCHAR(1)) + ', ' + 
    CAST(HasExternalConnections AS VARCHAR(1)) + ');' AS InsertStatement
FROM @Flows;

PRINT '';

-- Output Connections
PRINT '-- Connections Table';
SELECT 
    'INSERT INTO Connections VALUES (''' + 
    ConnectionID + ''', ''' + 
    ConnectionName + ''', ''' + 
    ConnectorType + ''', ''' + 
    EnvironmentID + ''', ''' + 
    ISNULL(FlowID, '') + ''', ''' + 
    AuthenticationType + ''', ' + 
    CAST(IsShared AS VARCHAR(1)) + ', ' + 
    CAST(SecurityRating AS VARCHAR(1)) + ', ''' + 
    ISNULL(CONVERT(VARCHAR(19), LastUsed, 120), '') + ''', ' + 
    CAST(IsDeprecated AS VARCHAR(1)) + ', ' + 
    CAST(RequiresMFA AS VARCHAR(1)) + ');' AS InsertStatement
FROM @Connections;

PRINT '';

-- Output Security Findings
PRINT '-- Security Findings Table';
SELECT 
    'INSERT INTO SecurityFindings VALUES (''' + 
    FindingID + ''', ''' + 
    EnvironmentID + ''', ''' + 
    ISNULL(FlowID, '') + ''', ''' + 
    ISNULL(FlowName, '') + ''', ''' + 
    Category + ''', ''' + 
    Severity + ''', ' + 
    CAST(RiskScore AS VARCHAR(1)) + ', ''' + 
    REPLACE(Description, '''', '''''') + ''', ''' + 
    REPLACE(Recommendation, '''', '''''') + ''', ''' + 
    Status + ''', ''' + 
    CONVERT(VARCHAR(19), DateFound, 120) + ''', ''' + 
    CONVERT(VARCHAR(19), LastUpdated, 120) + ''', ''' + 
    ISNULL(AssignedTo, '') + ''', ''' + 
    ISNULL(BusinessImpact, '') + ''', ''' + 
    REPLACE(ISNULL(Remediation, ''), '''', '''''') + ''');' AS InsertStatement
FROM @SecurityFindings;

-- =====================================================
-- DATA VALIDATION QUERIES
-- =====================================================

PRINT '';
PRINT '-- DATA VALIDATION QUERIES';
PRINT '';

PRINT '-- Validate Security Findings by Severity';
SELECT 
    Severity,
    COUNT(*) as Count,
    AVG(CAST(RiskScore AS FLOAT)) as AvgRiskScore
FROM @SecurityFindings
GROUP BY Severity
ORDER BY 
    CASE Severity 
        WHEN 'Critical' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Medium' THEN 3
        WHEN 'Low' THEN 4
        ELSE 5
    END;

PRINT '';
PRINT '-- Validate Environment Risk Distribution';
SELECT 
    RiskLevel,
    COUNT(*) as Count,
    AVG(CAST(DLPPolicies AS FLOAT)) as AvgDLPPolicies,
    AVG(CAST(ActiveFlows AS FLOAT)) as AvgActiveFlows
FROM @Environments
GROUP BY RiskLevel
ORDER BY 
    CASE RiskLevel 
        WHEN 'Critical' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Medium' THEN 3
        WHEN 'Low' THEN 4
        ELSE 5
    END;

PRINT '';
PRINT '-- Validate Flow Risk Categories';
SELECT 
    RiskCategory,
    COUNT(*) as Count,
    AVG(CAST(RunCount AS FLOAT)) as AvgRunCount,
    SUM(CASE WHEN HasSensitiveData = 1 THEN 1 ELSE 0 END) as SensitiveDataFlows
FROM @Flows
GROUP BY RiskCategory
ORDER BY 
    CASE RiskCategory 
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
        ELSE 4
    END;

PRINT '';
PRINT '-- Validate Connection Security Ratings';
SELECT 
    SecurityRating,
    COUNT(*) as Count,
    AuthenticationType,
    SUM(CASE WHEN IsDeprecated = 1 THEN 1 ELSE 0 END) as DeprecatedCount
FROM @Connections
GROUP BY SecurityRating, AuthenticationType
ORDER BY SecurityRating, AuthenticationType;

PRINT '';
PRINT '-- Summary Statistics';
SELECT 
    'Total Environments' as Metric,
    COUNT(*) as Value
FROM @Environments
UNION ALL
SELECT 
    'Total Users' as Metric,
    COUNT(*) as Value
FROM @Users
UNION ALL
SELECT 
    'Total Flows' as Metric,
    COUNT(*) as Value
FROM @Flows
UNION ALL
SELECT 
    'Total Connections' as Metric,
    COUNT(*) as Value
FROM @Connections
UNION ALL
SELECT 
    'Total Security Findings' as Metric,
    COUNT(*) as Value
FROM @SecurityFindings
UNION ALL
SELECT 
    'Critical Findings' as Metric,
    COUNT(*) as Value
FROM @SecurityFindings
WHERE Severity = 'Critical'
UNION ALL
SELECT 
    'High Risk Findings' as Metric,
    COUNT(*) as Value
FROM @SecurityFindings
WHERE Severity = 'High'
UNION ALL
SELECT 
    'Open Findings' as Metric,
    COUNT(*) as Value
FROM @SecurityFindings
WHERE Status = 'Open';

PRINT '';
PRINT '-- Sample data generation completed successfully!';
PRINT '-- Use this data to populate your Power BI dashboard for testing.';