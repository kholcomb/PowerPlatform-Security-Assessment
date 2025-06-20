# Excel Power Query Security Assessment Setup Guide

## Overview
This guide provides comprehensive instructions for setting up and configuring the Excel Power Query templates for the Power Automate Security Assessment Tool.

## Prerequisites
- Microsoft Excel 2016 or later (Excel 365 recommended)
- Power Query add-in (included in Excel 2016+)
- Appropriate API credentials for Power Automate
- Administrative permissions for data connections

## Quick Start Guide

### 1. Initial Setup
1. Download all template files from the `/excel-templates/` directory
2. Open Excel and enable the following features:
   - Power Query (Data tab)
   - VBA Macros (Developer tab)
   - External data connections

### 2. Configure API Credentials
1. Open the `SecurityAssessmentTemplate.xlsx` file
2. Navigate to the `Settings` worksheet
3. Enter your API credentials:
   ```
   Client ID: [Your Azure App Registration Client ID]
   Client Secret: [Your Azure App Registration Client Secret]
   Tenant ID: [Your Azure Tenant ID]
   API Endpoint: https://api.powerautomate.com/security-assessment
   ```

### 3. Import Power Query Scripts
1. Go to Data > Get Data > From Other Sources > Blank Query
2. Open the Advanced Editor
3. Copy and paste the content from each `.m` file:
   - `SecurityDataTransformation.m`
   - `ConnectorSecurityAnalysis.m`
   - `ComplianceMetrics.m`
4. Save each query with appropriate names

### 4. Import VBA Macros
1. Press Alt+F11 to open VBA Editor
2. Insert new modules for each VBA file:
   - `SecurityAssessmentMacros.vba`
   - `DataImportMacros.vba`
3. Save and enable macros

## Detailed Configuration

### Power Query Connections

#### Security Assessment Data Connection
```m
// Connection String Configuration
Source = Json.Document(Web.Contents("https://api.powerautomate.com/security-assessment", [
    Headers=[
        #"Authorization"="Bearer " & #"Access Token",
        #"Content-Type"="application/json"
    ]
]))
```

#### Connector Analysis Connection
```m
// Connector Security Analysis
ConnectorSource = Json.Document(Web.Contents("https://api.powerautomate.com/connectors", [
    Headers=[
        #"Authorization"="Bearer " & #"Access Token",
        #"Content-Type"="application/json"
    ]
]))
```

### Worksheet Configuration

#### Dashboard Worksheet
- **Purpose**: Executive summary and key metrics
- **Key Elements**: 
  - KPI cards (A1:L8)
  - Risk distribution chart (A10:F25)
  - Compliance histogram (H10:L25)
  - Top risk flows table (A27:G40)

#### Raw Data Worksheet
- **Purpose**: Imported and processed data
- **Structure**:
  - Column A: Flow ID
  - Column B: Flow Name
  - Column C: Owner
  - Column D: Created Date
  - Column E: Last Modified
  - Column F: Permission Level
  - Column G: External Connections
  - Column H: Is Encrypted
  - Column I: Connector Count
  - Column J: User Count
  - Column K: Risk Level (calculated)
  - Column L: Compliance Score (calculated)

#### Settings Worksheet
- **Purpose**: Configuration and credentials
- **Structure**:
  - B1: Last Refresh Time
  - B2: Refresh Status
  - B3: Client ID
  - B4: Client Secret
  - B5: Tenant ID
  - B6: API Endpoint
  - B7: Auto Refresh Enabled
  - B8: Auto Refresh Time

### Pivot Table Configuration

#### Risk Level Summary
```excel
Source Data: 'Raw Data'!A:Z
Row Labels: RiskLevel
Values: Count of FlowID
Location: Dashboard!A45:D50
```

#### Connector Security Summary
```excel
Source Data: 'Connector Analysis'!A:Z
Row Labels: SecurityRisk
Column Labels: UsageFrequency
Values: Count of ConnectorName
Location: Dashboard!F45:J55
```

### Conditional Formatting Rules

#### Risk Level Formatting
- **High Risk**: Red background (#FFCCCC), Dark red text (#AA0000)
- **Medium Risk**: Yellow background (#FFFF99), Dark orange text (#FF8800)
- **Low Risk**: Green background (#CCFFCC), Dark green text (#00AA00)

#### Compliance Score Formatting
- **Score < 40**: Red background (#FFE6E6)
- **Score 40-70**: Yellow background (#FFF2CC)
- **Score > 70**: Green background (#E2EFDA)

### Slicers Configuration

#### Department Slicer
```excel
Source: 'Raw Data'!Owner
Position: N2:P8
Style: SlicerStyleLight1
```

#### Risk Level Slicer
```excel
Source: 'Raw Data'!RiskLevel
Position: N10:P16
Style: SlicerStyleLight2
```

## VBA Macro Functions

### Main Functions

#### RefreshAllData()
- Refreshes all Power Query connections
- Updates pivot tables and charts
- Applies conditional formatting
- Updates dashboard KPIs

#### ImportSecurityData()
- Imports data from Power Automate API
- Handles authentication
- Parses JSON responses
- Validates imported data

#### GenerateSecurityReport()
- Creates comprehensive security report
- Generates executive summary
- Exports to separate workbook
- Formats for presentation

### Utility Functions

#### GetAccessToken()
- Handles OAuth authentication
- Retrieves access tokens
- Manages token refresh

#### ValidateImportedData()
- Checks data integrity
- Identifies missing fields
- Reports validation errors

## Excel Online Compatibility

### Supported Features
- Power Query connections (limited)
- Basic pivot tables
- Standard charts
- Conditional formatting
- Slicers and filters

### Limitations
- VBA macros not supported
- Advanced Power Query features limited
- External data connections restricted
- File system access not available

### Workarounds for Excel Online
1. Use Office Scripts instead of VBA
2. Pre-configure data connections
3. Use simpler chart types
4. Implement client-side filtering

## Troubleshooting

### Common Issues

#### Authentication Failures
- Verify Client ID, Client Secret, and Tenant ID
- Check Azure app registration permissions
- Ensure API endpoints are accessible

#### Data Refresh Errors
- Confirm network connectivity
- Validate API credentials
- Check data source availability

#### Performance Issues
- Limit data refresh frequency
- Optimize Power Query transformations
- Consider data source pagination

### Error Handling
```vba
On Error GoTo ErrorHandler
    ' Your code here
    Exit Sub
ErrorHandler:
    Call LogError(Err.Description)
    MsgBox "An error occurred: " & Err.Description
```

## Security Considerations

### Data Protection
- Store credentials securely
- Use encrypted connections
- Implement access controls
- Regular credential rotation

### Compliance
- Ensure GDPR compliance
- Maintain audit trails
- Document data processing
- Implement data retention policies

## Performance Optimization

### Power Query Optimization
- Minimize data transformations
- Use query folding where possible
- Filter data at source
- Optimize column selection

### Excel Optimization
- Disable automatic calculations during refresh
- Use efficient formulas
- Minimize volatile functions
- Optimize pivot table design

## Maintenance

### Regular Tasks
- Update API credentials
- Refresh data connections
- Review and update formulas
- Monitor performance

### Monthly Tasks
- Review security classifications
- Update compliance frameworks
- Validate data accuracy
- Optimize queries

### Quarterly Tasks
- Full security assessment
- Update documentation
- Review access permissions
- Performance audit

## Support and Resources

### Documentation
- Power Query M Language Reference
- Excel VBA Documentation
- Power Automate API Documentation
- Azure Authentication Guide

### Training Resources
- Excel Power Query Training
- VBA Programming Guide
- Security Assessment Best Practices
- Data Visualization Techniques

### Community Support
- Excel Power Query Forum
- Power Automate Community
- Microsoft Tech Community
- Stack Overflow

## Version History
- v1.0: Initial release
- v1.1: Added Excel Online compatibility
- v1.2: Enhanced security features
- v1.3: Improved performance optimization