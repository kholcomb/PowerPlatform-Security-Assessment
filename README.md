# Power Automate Security Assessment Tool

A comprehensive PowerShell-based security assessment tool for Microsoft Power Platform environments, specifically designed to evaluate and report on Power Automate security posture.

## Overview

The Power Automate Security Assessment Tool provides automated security evaluation of Power Platform environments, analyzing users, connections, flows, and configurations to identify potential security risks and compliance issues.

## Features

### 🔍 Comprehensive Assessment Coverage
- **Environment Security**: DLP policies, security groups, environment configurations
- **User Access Analysis**: Role assignments, privileged access, service principal usage
- **Connection Security**: High-risk connectors, premium licensing, connection status
- **Flow Security**: External triggers, sharing permissions, dormant flows
- **Risk Classification**: Automated categorization of findings (High/Medium/Low risk)

### 📊 Flexible Reporting & BI Integration
- **Multiple Formats**: HTML, JSON, CSV, PowerBI, Excel, SQL export options
- **Executive Summary**: High-level security posture overview
- **Detailed Findings**: Granular security issue identification
- **Actionable Recommendations**: Specific remediation guidance
- **BI Tool Integration**: Native Power BI templates, Excel Power Query, SQL Server, REST API
- **Real-time Dashboards**: API endpoints for live monitoring and analysis

### 🎯 Risk-Based Prioritization
- **High Risk**: Immediate attention required (no DLP policies, admin access issues)
- **Medium Risk**: Review recommended (security group assignments, connector usage)
- **Low Risk**: Best practice improvements (flow sharing, dormant resources)

## Quick Start

### Prerequisites
- PowerShell 5.1 or later
- Power Platform administrator access
- Required PowerShell modules (see [Installation Guide](docs/INSTALLATION.md))

### Basic Usage
```powershell
# Install required modules
Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Force
Install-Module -Name Microsoft.PowerApps.PowerShell -Force

# Connect to Power Platform
Add-PowerAppsAccount

# Run assessment on all environments
.\PowerAutomate-SecurityAssessment.ps1

# Assess specific environment
.\PowerAutomate-SecurityAssessment.ps1 -EnvironmentName "Production"

# Custom output location and format
.\PowerAutomate-SecurityAssessment.ps1 -OutputPath "C:\Reports" -ExportFormat "HTML"

# Export for Power BI integration
.\PowerAutomate-SecurityAssessment.ps1 -ExportFormat "PowerBI" -OutputPath "C:\PowerBI-Data"

# Export for Excel analysis
.\PowerAutomate-SecurityAssessment.ps1 -ExportFormat "Excel" -OutputPath "C:\Excel-Data"

# Export to SQL Server
.\PowerAutomate-SecurityAssessment.ps1 -ExportFormat "SQL" -SqlConnectionString "Server=myServer;Database=PowerPlatformSecurity;Integrated Security=true"
```

## Security Assessment Areas

### Environment Security
- **DLP Policy Configuration**: Identifies environments without data loss prevention policies
- **Security Group Assignment**: Validates Azure AD security group assignments
- **Environment Type Validation**: Reviews production environment configurations
- **Regional Compliance**: Assesses data residency and regional settings

### User and Access Management
- **Privileged Access Review**: Identifies users with environment admin privileges
- **Service Principal Analysis**: Reviews automated access patterns
- **Role Assignment Validation**: Ensures principle of least privilege
- **External User Detection**: Identifies guest or external user access

### Connection and Connector Security
- **High-Risk Connector Identification**: Flags connectors with elevated data access
- **Premium Connector Licensing**: Validates proper licensing for premium connectors
- **Connection Health Monitoring**: Identifies inactive or failed connections
- **Data Source Security**: Reviews connection authentication methods

### Flow Security Analysis
- **External Trigger Assessment**: Identifies flows with HTTP/webhook triggers
- **Sharing and Ownership Review**: Analyzes flow sharing patterns
- **Dormant Flow Detection**: Identifies unused or outdated flows
- **Data Flow Mapping**: Traces data movement between systems

## Report Structure

### Executive Summary
- Environment count and overview
- Total security findings by risk level
- Key recommendations for immediate action
- Compliance status overview

### Detailed Findings
Each assessment area includes:
- **Finding Description**: Clear explanation of the security issue
- **Risk Level**: High/Medium/Low classification
- **Impact Assessment**: Potential business and security impact
- **Remediation Steps**: Specific actions to address the finding
- **Resources Affected**: List of specific environments, users, or flows

### Recommendations
- **Immediate Actions**: High-priority security fixes
- **Policy Implementations**: Suggested governance policies
- **Best Practices**: Ongoing security improvements
- **Monitoring Setup**: Continuous assessment recommendations

## Advanced Usage

### Environment-Specific Assessment
```powershell
# Production environment only
.\PowerAutomate-SecurityAssessment.ps1 -EnvironmentName "Production Environment"

# Development environment with JSON output
.\PowerAutomate-SecurityAssessment.ps1 -EnvironmentName "Dev" -ExportFormat "JSON"
```

### Automated Reporting
```powershell
# Scheduled assessment with timestamp
$timestamp = Get-Date -Format "yyyyMMdd"
.\PowerAutomate-SecurityAssessment.ps1 -OutputPath "\\server\reports\$timestamp" -ExportFormat "HTML"
```

### Bulk Environment Processing
```powershell
# Assess multiple specific environments
$environments = @("Production", "UAT", "Development")
foreach ($env in $environments) {
    .\PowerAutomate-SecurityAssessment.ps1 -EnvironmentName $env -OutputPath "C:\Reports\$env"
}
```

## Output Files

### HTML Report (Default)
- Comprehensive web-based report with styling
- Executive summary dashboard
- Detailed findings with risk color coding
- Recommendations section
- Suitable for executive presentation

### JSON Export
- Machine-readable format
- Complete assessment data
- Suitable for integration with other tools
- Enables custom reporting and analysis

### CSV Export
- Generates multiple CSV files:
  - `*-Environments.csv`: Environment-specific findings
  - `*-Users.csv`: User and access analysis
  - `*-Connections.csv`: Connection security details
  - `*-Flows.csv`: Flow security assessment
- Suitable for data analysis and filtering

## Security Considerations

### Data Privacy
- No sensitive data is stored in assessment results
- Reports contain metadata and configuration information only
- User email addresses are included for access review purposes

### Permissions Required
- Power Platform administrator role
- Azure AD permissions for security group validation
- Environment access for detailed flow analysis

### Network Requirements
- Internet connectivity for Power Platform API access
- Corporate firewall may require proxy configuration
- Microsoft 365 service endpoints must be accessible

## Documentation

- [Installation Guide](docs/INSTALLATION.md) - Detailed setup instructions
- [Security Methodology](docs/SECURITY_METHODOLOGY.md) - Assessment criteria and standards
- [BI Integration Guide](docs/BI-INTEGRATION.md) - Power BI, Excel, SQL Server, and API integration
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Sample Reports](docs/SAMPLE_REPORTS.md) - Example outputs and interpretation

## Support and Contribution

### Getting Help
1. Check the [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
2. Review [Common Issues](#common-issues) section
3. Validate PowerShell module versions
4. Ensure proper Power Platform permissions

### Contributing
- Report issues via GitHub Issues
- Submit feature requests
- Contribute security check improvements
- Enhance documentation

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

### Version 1.0.0 (Current)
- Initial release
- Complete environment security assessment
- HTML, JSON, and CSV reporting
- Risk-based finding classification
- Executive summary generation

## Common Issues

### Authentication Errors
```
Error: Failed to connect to Power Platform
Solution: Run Add-PowerAppsAccount and verify admin permissions
```

### Module Not Found
```
Error: Module 'Microsoft.PowerApps.Administration.PowerShell' not found
Solution: Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Force
```

### Access Denied
```
Error: Access denied to environment
Solution: Verify Power Platform admin role assignment
```

## Related Tools

- [Power Platform CLI](https://docs.microsoft.com/power-platform/developer/cli/introduction)
- [Power Platform Admin PowerShell](https://docs.microsoft.com/power-platform/admin/powershell-getting-started)
- [Microsoft 365 Defender for Cloud Apps](https://docs.microsoft.com/cloud-app-security/)

---

**Disclaimer**: This tool is provided as-is for security assessment purposes. Always test in non-production environments first and ensure compliance with your organization's security policies.