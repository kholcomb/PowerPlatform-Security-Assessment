# Power Automate Security Assessment Dashboard

A comprehensive Power BI template for monitoring and analyzing security posture across Power Automate environments.

## 📊 Dashboard Overview

This template provides six specialized dashboard pages for complete security assessment:

### 1. Executive Summary
- **Overall Security Score** - Gauge showing security posture (0-100)
- **Key Metrics Cards** - Total findings, critical issues, environments at risk
- **Severity Distribution** - Donut chart of findings by severity level
- **Security Trends** - Line chart showing findings over time
- **Environment Risk Matrix** - Cross-tabular view of risks by environment

### 2. Environment Risk Analysis
- **Environment Summary Table** - Detailed environment information with risk scores
- **Risk Distribution** - Bar chart of environments by risk level
- **DLP Coverage Gauge** - Percentage of environments with DLP policies
- **Risk vs Flow Count Scatter** - Correlation analysis of risk and activity
- **Findings Treemap** - Hierarchical view of security issues by environment

### 3. User Access Management
- **User Metrics** - Total users, high risk users, admin users, orphaned flows
- **User Risk Analysis Table** - Detailed user information with risk classifications
- **Flow Ownership Distribution** - Bar chart of top flow owners
- **Users by Risk Level** - Donut chart of user risk distribution
- **Activity Trends** - Line chart of user activity over time

### 4. Connection Security
- **Connection Metrics** - Total, insecure, HTTP, and deprecated connections
- **Security Rating Distribution** - Bar chart of connections by security rating
- **Authentication Types** - Donut chart of authentication methods
- **Top Connector Types** - Horizontal bar chart of most used connectors
- **High-Risk Connections Table** - Detailed view of insecure connections

### 5. Flow Security Analysis
- **Flow Metrics** - Total, active, external, sensitive data, and high-risk flows
- **Risk Distribution** - Donut chart of flows by risk category
- **Flow States** - Bar chart showing flow status distribution
- **Usage vs Risk Scatter** - Analysis of flow activity and security risk
- **High-Risk Flows Table** - Detailed view of flows requiring attention

### 6. Detailed Findings
- **Interactive Filters** - Slicers for severity, category, status, and environment
- **Summary Cards** - Filtered findings count and average age
- **Comprehensive Findings Table** - Complete list with conditional formatting
- **Drill-through capabilities** - Navigate to detailed views

## 🗂️ File Structure

```
powerbi-templates/
├── PowerAutomate-Security-Dashboard-Template.json    # Main template specification
├── DAX-Measures.dax                                 # All DAX measures and calculations
├── Dashboard-Pages-Layout.json                      # Page layouts and visual specifications
├── Data-Model-Schema.json                          # Complete data model definition
├── Visualization-Specifications.json               # Visual formatting and theming
├── Sample-Data-Generator.sql                       # SQL script for sample data
├── Power-BI-Template-Instructions.md               # Detailed implementation guide
└── README.md                                       # This file
```

## 🚀 Quick Start

### 1. Data Model Setup
1. Create tables based on the schema in `Data-Model-Schema.json`
2. Import sample data using `Sample-Data-Generator.sql`
3. Establish relationships as specified in the template

### 2. DAX Measures
1. Copy all measures from `DAX-Measures.dax`
2. Create calculated columns as specified
3. Test measure calculations with sample data

### 3. Dashboard Creation
1. Follow the layout specifications in `Dashboard-Pages-Layout.json`
2. Apply visual formatting from `Visualization-Specifications.json`
3. Configure interactions and drill-through pages

### 4. Template Configuration
1. Set up data sources and refresh schedules
2. Configure row-level security if needed
3. Test all functionality with sample data

## 📋 Data Requirements

### Core Tables
- **SecurityFindings** - Main findings data with severity and category
- **Environments** - Power Platform environment information
- **Flows** - Flow details and risk characteristics
- **Connections** - Connector and connection security data
- **Users** - User information and access patterns
- **DateTable** - Date dimension for time-based analysis

### Data Sources
- Power Platform Admin Center APIs
- Custom security assessment tools
- Azure AD for user information
- Manual security audit results

## 🎨 Design Features

### Visual Theme
- **Primary Color**: Microsoft Blue (#0078D4)
- **Severity Colors**: Red (Critical), Orange (High), Yellow (Medium), Green (Low)
- **Typography**: Segoe UI font family
- **Consistent Formatting**: Standardized sizing and spacing

### Interactive Features
- **Cross-filtering**: Visuals interact to filter related data
- **Drill-through**: Navigate from summary to detailed views
- **Bookmarks**: Quick access to common filter states
- **Slicers**: Interactive filtering on multiple dimensions

### Accessibility
- Color-blind friendly palette
- High contrast mode support
- Screen reader compatibility
- Keyboard navigation support

## 📊 Key Metrics and KPIs

### Security Posture
- **Overall Security Score** (0-100 scale)
- **Critical Findings Count**
- **Environments at Risk**
- **Average Risk Score**

### Compliance Tracking
- **DLP Policy Coverage**
- **Compliance Score**
- **Open Findings Age**
- **Resolution Trends**

### Risk Analysis
- **Flow Risk Distribution**
- **Connection Security Ratings**
- **User Risk Classifications**
- **Environment Security Levels**

## 🔧 Customization Options

### Branding
- Update color scheme in theme configuration
- Modify logos and headers
- Adjust fonts and typography

### Metrics
- Add custom DAX measures
- Modify risk scoring algorithms
- Include additional KPIs

### Visuals
- Customize chart types and layouts
- Add new visualization pages
- Modify conditional formatting rules

## 📝 Implementation Checklist

- [ ] Set up data model and relationships
- [ ] Import and test DAX measures
- [ ] Create dashboard pages with specified layouts
- [ ] Configure visual formatting and theming
- [ ] Set up drill-through pages and interactions
- [ ] Create bookmarks and navigation
- [ ] Test with sample data
- [ ] Configure data refresh schedules
- [ ] Implement row-level security
- [ ] Document deployment procedures

## 🔍 Troubleshooting

### Common Issues
- **Slow Performance**: Check DAX measure efficiency, consider aggregation tables
- **Data Refresh Errors**: Verify data source connections and credentials
- **Visual Display Problems**: Review conditional formatting and data types
- **Filter Interactions**: Check cross-filter directions and relationships

### Performance Optimization
- Use DirectQuery for large datasets
- Implement incremental refresh
- Optimize DAX calculations
- Consider data model denormalization

## 📚 Additional Resources

### Documentation
- [Power BI Template Documentation](Power-BI-Template-Instructions.md)
- [DAX Measures Reference](DAX-Measures.dax)
- [Data Model Schema](Data-Model-Schema.json)

### Support
- Template issues and enhancements
- Data source configuration help
- Custom implementation assistance

## 📄 License

This template is provided for use in Power Platform security assessments and monitoring. Modify and distribute as needed for your organization's requirements.

---

**Version**: 1.0.0  
**Last Updated**: June 20, 2025  
**Compatibility**: Power BI Desktop (latest version), Power BI Service