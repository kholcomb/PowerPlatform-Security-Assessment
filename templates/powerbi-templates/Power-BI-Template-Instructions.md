# Power Automate Security Assessment Dashboard - Power BI Template Instructions

## Overview
This document provides detailed instructions for creating a comprehensive Power BI dashboard template for the Power Automate Security Assessment Tool. The template includes 6 main dashboard pages with advanced visualizations, DAX measures, and interactive features.

## Prerequisites
- Power BI Desktop (latest version)
- Power BI Pro or Premium license (for sharing and collaboration features)
- Access to Power Automate security assessment data
- Basic understanding of Power BI and DAX

## Template Structure

### Data Model Setup

#### 1. Create Data Tables
Create the following tables in your Power BI model:

**SecurityFindings Table:**
- FindingID (Text, Primary Key)
- EnvironmentID (Text)
- FlowID (Text)
- FlowName (Text)
- Category (Text)
- Severity (Text)
- RiskScore (Whole Number, 1-5 scale)
- Description (Text)
- Recommendation (Text)
- Status (Text)
- DateFound (Date/Time)
- LastUpdated (Date/Time)
- AssignedTo (Text)
- BusinessImpact (Text)
- Remediation (Text)

**Environments Table:**
- EnvironmentID (Text, Primary Key)
- EnvironmentName (Text)
- EnvironmentType (Text)
- Region (Text)
- SecurityLevel (Text)
- DLPPolicies (Whole Number)
- ActiveFlows (Whole Number)
- LastAssessed (Date/Time)
- RiskLevel (Text)
- ComplianceStatus (Text)

**Flows Table:**
- FlowID (Text, Primary Key)
- FlowName (Text)
- EnvironmentID (Text)
- Owner (Text)
- State (Text)
- CreatedDate (Date/Time)
- ModifiedDate (Date/Time)
- RunCount (Whole Number)
- ConnectionCount (Whole Number)
- SharedUsers (Whole Number)
- RiskCategory (Text)
- HasSensitiveData (True/False)
- UsesHTTP (True/False)
- HasExternalConnections (True/False)

**Connections Table:**
- ConnectionID (Text, Primary Key)
- ConnectionName (Text)
- ConnectorType (Text)
- EnvironmentID (Text)
- FlowID (Text)
- AuthenticationType (Text)
- IsShared (True/False)
- SecurityRating (Whole Number, 1-5 scale)
- LastUsed (Date/Time)
- IsDeprecated (True/False)
- RequiresMFA (True/False)

**Users Table:**
- UserID (Text, Primary Key)
- UserName (Text)
- Email (Text)
- Department (Text)
- Role (Text)
- FlowsOwned (Whole Number)
- FlowsShared (Whole Number)
- LastActivity (Date/Time)
- RiskLevel (Text)
- HasAdminAccess (True/False)

**DateTable:**
- Create using DAX: `DateTable = CALENDAR(DATE(2020,1,1), TODAY())`
- Add calculated columns for Year, Quarter, Month, Week, etc.

#### 2. Create Relationships
Set up the following relationships in Model view:
- SecurityFindings[EnvironmentID] → Environments[EnvironmentID] (Many-to-One)
- SecurityFindings[FlowID] → Flows[FlowID] (Many-to-One)
- Flows[EnvironmentID] → Environments[EnvironmentID] (Many-to-One)
- Connections[EnvironmentID] → Environments[EnvironmentID] (Many-to-One)
- Connections[FlowID] → Flows[FlowID] (Many-to-One)
- Flows[Owner] → Users[UserID] (Many-to-One)
- SecurityFindings[DateFound] → DateTable[Date] (Many-to-One)

### DAX Measures Implementation

#### 3. Create Calculated Measures
Import all DAX measures from the `DAX-Measures.dax` file. Key measures include:

**Executive Summary Measures:**
- Overall Security Score
- Total Security Findings
- Critical Findings
- Environments at Risk
- Flows with Issues

**Risk Assessment Measures:**
- Environment Risk Score
- Connection Security Score
- User Risk Score
- Compliance Score

**Trend Analysis Measures:**
- Security Trend MoM
- Findings This Month
- Resolved This Month
- Avg Open Finding Age

### Dashboard Pages Creation

#### 4. Page 1: Executive Summary
**Purpose:** High-level security posture overview

**Key Visuals:**
1. **Security Score Gauge** (Top Right)
   - Measure: Overall Security Score
   - Range: 0-100
   - Color bands: Red (0-40), Orange (40-70), Green (70-100)

2. **KPI Cards** (Top Row)
   - Total Findings, Critical Issues, Environments at Risk, Flows with Issues
   - Use conditional formatting for color coding

3. **Findings by Severity Donut Chart**
   - Category: SecurityFindings[Severity]
   - Values: Total Security Findings
   - Custom colors: Critical (Red), High (Orange), Medium (Yellow), Low (Green)

4. **Security Trends Line Chart**
   - X-axis: DateTable[Month]
   - Y-axis: Total Security Findings
   - Show data points and trend line

5. **Environment Risk Matrix**
   - Matrix visual with Environment Name as rows
   - Severity as columns, Findings count as values
   - Conditional formatting for heat map effect

#### 5. Page 2: Environment Risk Analysis
**Purpose:** Environment-specific security analysis

**Key Visuals:**
1. **Environment Summary Table**
   - Show environment details with risk scores
   - Conditional formatting based on risk levels

2. **Risk Level Distribution Bar Chart**
   - Categories: Environment Risk Score
   - Values: Count of environments

3. **DLP Coverage Gauge**
   - Measure: DLP Coverage Percentage
   - Target: 90%

4. **Environment Risk vs Flow Count Scatter Plot**
   - X-axis: Flows per Environment
   - Y-axis: Average Risk Score
   - Size: Total Security Findings
   - Enable quadrant analysis

5. **Findings by Environment Treemap**
   - Category: Environment Name
   - Size: Total Security Findings
   - Color: Average Risk Score

#### 6. Page 3: User Access Management
**Purpose:** User permissions and access analysis

**Key Visuals:**
1. **User Metrics Cards**
   - Total Users, High Risk Users, Admin Users, Orphaned Flows

2. **User Risk Analysis Table**
   - Show user details with risk classifications
   - Conditional formatting for risk levels

3. **Flow Ownership Distribution**
   - Horizontal bar chart showing top flow owners
   - Limit to top 10 users

4. **Users by Risk Level Donut Chart**
   - Categories: User Risk Level
   - Values: Count of users

5. **User Activity Trend**
   - Line chart showing active users over time

#### 7. Page 4: Connection Security
**Purpose:** Connector security and authentication analysis

**Key Visuals:**
1. **Connection Metrics Cards**
   - Total Connections, Insecure Connections, HTTP Connections, Deprecated

2. **Connection Security Score Gauge**
   - Range: 0-100%
   - Target: 85%

3. **Connections by Security Rating**
   - Bar chart with color coding (1=Red, 5=Green)

4. **Authentication Types Distribution**
   - Donut chart showing auth method breakdown

5. **Top Connector Types**
   - Horizontal bar chart showing most used connectors

6. **High-Risk Connections Table**
   - Filter for connections with security rating ≤ 2
   - Show connection details with conditional formatting

#### 8. Page 5: Flow Security Analysis
**Purpose:** Individual flow security assessment

**Key Visuals:**
1. **Flow Metrics Cards**
   - Total Flows, Active Flows, External Connections, Sensitive Data, High Risk

2. **Flow Risk Distribution Donut**
   - Categories: Flow Risk Category
   - Color coding: High (Red), Medium (Orange), Low (Green)

3. **Flow States Bar Chart**
   - Show distribution of flow states (Started, Stopped, Suspended)

4. **Flow Usage vs Risk Scatter Plot**
   - X-axis: Run Count
   - Y-axis: Connection Count
   - Size: Shared Users
   - Color: Risk Category

5. **High-Risk Flows Table**
   - Filter for high-risk flows only
   - Show flow details with risk indicators

#### 9. Page 6: Detailed Findings
**Purpose:** Comprehensive findings exploration

**Key Visuals:**
1. **Filter Slicers** (Top Row)
   - Severity Filter (List slicer)
   - Category Filter (Dropdown slicer)
   - Status Filter (List slicer)
   - Environment Filter (Dropdown slicer)

2. **Summary Cards**
   - Filtered Findings Count
   - Average Days Open

3. **Security Findings Detail Table**
   - Show all finding details
   - Conditional formatting for severity levels
   - Data bars for "Days Since Finding"
   - Default sorting: Severity (desc), Date Found (desc)

### Advanced Features Implementation

#### 10. Drill-Through Setup
**Flow Detail Drill-Through Page:**
1. Create hidden page "Flow Detail Drill"
2. Add FlowID as drill-through field
3. Include:
   - Flow name and owner cards
   - Flow security findings table
   - Flow connections table

**Environment Detail Drill-Through Page:**
1. Create hidden page "Environment Detail Drill"
2. Add EnvironmentID as drill-through field
3. Include:
   - Environment details cards
   - Environment findings table
   - Findings by category chart

#### 11. Bookmarks and Navigation
**Create Bookmarks:**
1. "Critical Issues Only" - Filter to show only critical findings
2. "Open Issues" - Show only unresolved findings
3. "Production Environments" - Focus on production environments
4. "High Risk Users" - Show high-risk user classification

**Navigation Setup:**
1. Add navigation buttons to each page
2. Use consistent styling and positioning
3. Include page icons for visual clarity
4. Test navigation flow between all pages

#### 12. Formatting and Theming
**Apply Consistent Theme:**
1. Primary Color: #0078D4 (Microsoft Blue)
2. Secondary Color: #106EBE
3. Accent Color: #FF4B4B (for alerts/critical items)
4. Background: #F8F9FA (Light gray)
5. Text: #323130 (Dark gray)

**Visual Formatting:**
1. Use consistent fonts (Segoe UI)
2. Apply conditional formatting for risk levels
3. Use data bars and color scales where appropriate
4. Ensure accessibility with high contrast colors

#### 13. Performance Optimization
**Optimize for Performance:**
1. Use DirectQuery for large datasets
2. Create aggregation tables for common queries
3. Implement row-level security if needed
4. Use SUMMARIZE and SUMMARIZECOLUMNS for complex measures
5. Avoid using CALCULATE unnecessarily in measures

### Data Refresh and Automation

#### 14. Data Source Configuration
**For Production Use:**
1. Configure data gateway for on-premises data
2. Set up service principal authentication for Power Platform APIs
3. Create parameterized queries for different environments
4. Implement incremental refresh for large datasets

**Refresh Schedule:**
1. Set up automatic refresh (daily recommended)
2. Configure failure notifications
3. Test refresh performance and optimize as needed

### Deployment Instructions

#### 15. Template Creation
**Create .pbit Template:**
1. Remove all data from tables (keep structure)
2. Save as Power BI Template (.pbit)
3. Include parameter prompts for:
   - Tenant ID
   - Environment IDs to analyze
   - Date range for analysis
   - API endpoint URLs

**Template Parameters:**
```
TenantID: Text parameter for tenant identification
EnvironmentFilter: Text parameter for specific environments
DateRangeStart: Date parameter for analysis start date
DateRangeEnd: Date parameter for analysis end date
APIEndpoint: Text parameter for data source endpoint
```

#### 16. Distribution and Maintenance
**Template Distribution:**
1. Test template with sample data
2. Create user documentation
3. Provide training materials
4. Set up support channels

**Maintenance Plan:**
1. Regular template updates for new features
2. Performance monitoring and optimization
3. User feedback collection and implementation
4. Security and compliance reviews

### Troubleshooting Common Issues

#### 17. Common Problems and Solutions
**Data Refresh Issues:**
- Check data source connectivity
- Verify authentication credentials
- Review gateway configuration
- Check for schema changes

**Performance Issues:**
- Review DAX measure efficiency
- Check for unnecessary relationships
- Optimize visual queries
- Consider data model redesign

**Visual Display Problems:**
- Verify data types and formats
- Check conditional formatting rules
- Review filter interactions
- Test on different screen sizes

### Security Considerations

#### 18. Security Best Practices
**Data Protection:**
1. Implement row-level security (RLS)
2. Use Azure AD groups for access control
3. Enable audit logging
4. Regular access reviews

**Compliance:**
1. Follow data governance policies
2. Implement data classification
3. Regular security assessments
4. Documentation of data lineage

This comprehensive template provides a robust foundation for Power Automate security assessment and monitoring. Regular updates and maintenance will ensure continued effectiveness and alignment with evolving security requirements.