# Project Structure

This document outlines the organization of the Power Automate Security Assessment Tool project.

## Directory Structure

```
PowerPlatform/
├── README.md                           # Main project overview and quick start
├── LICENSE                             # MIT License
├── PROJECT_STRUCTURE.md               # This file - project organization guide
│
├── src/                               # Core source code
│   ├── PowerAutomate-SecurityAssessment.ps1  # Main assessment script
│   ├── PowerAutomate-SecurityAPI.ps1          # REST API server
│   ├── API-Authentication.ps1                 # API authentication module
│   └── API-Endpoints.ps1                      # API endpoint handlers
│
├── scripts/                           # Deployment and utility scripts
│   ├── Deploy-SecurityAPI.ps1                 # API deployment automation
│   ├── Install-Dependencies.ps1               # Dependency installation
│   ├── Setup-Environment.ps1                  # Environment configuration
│   └── Start-Assessment.ps1                   # Quick start script
│
├── config/                            # Configuration files
│   ├── API-Config.json                        # API server configuration
│   ├── API-OpenAPI.json                       # OpenAPI specification
│   ├── assessment-config.json                 # Default assessment settings
│   └── environment-examples.json              # Sample environment configs
│
├── docs/                              # Documentation
│   ├── INSTALLATION.md                        # Installation guide
│   ├── CONFIGURATION.md                       # Configuration guide
│   ├── USAGE.md                              # Usage examples and scenarios
│   ├── QUICK_START.md                        # Quick start guide
│   ├── SECURITY_METHODOLOGY.md               # Assessment methodology
│   ├── BI-INTEGRATION.md                     # Business intelligence integration
│   ├── TROUBLESHOOTING.md                    # Common issues and solutions
│   ├── SAMPLE_REPORTS.md                     # Example outputs
│   └── API_REFERENCE.md                      # API documentation
│
├── templates/                         # Templates for various platforms
│   ├── powerbi-templates/                     # Power BI dashboard templates
│   │   ├── README.md                          # Power BI template guide
│   │   ├── PowerAutomate-Security-Dashboard-Template.json
│   │   ├── DAX-Measures.dax                   # DAX formulas
│   │   ├── Data-Model-Schema.json             # Data model specification
│   │   ├── Dashboard-Pages-Layout.json        # Page layout specifications
│   │   ├── Visualization-Specifications.json  # Visual formatting
│   │   ├── Power-BI-Template-Instructions.md  # Implementation guide
│   │   └── Sample-Data-Generator.sql          # Test data generator
│   │
│   └── excel-templates/                       # Excel templates and automation
│       ├── Excel_Enhancement_Summary.md       # Excel integration overview
│       ├── workbook-templates/                # Excel workbook templates
│       │   ├── SecurityAssessmentTemplate.xlsx
│       │   └── ExcelOnlineCompatibility.xlsx
│       ├── power-query/                       # Power Query templates
│       │   ├── SecurityAssessment.pqx
│       │   └── ConnectorAnalysis.pqx
│       ├── vba-macros/                        # VBA automation scripts
│       │   ├── SecurityAssessmentMacros.vba
│       │   └── DataImportMacros.vba
│       ├── m-scripts/                         # M language scripts
│       │   ├── SecurityDataTransformation.m
│       │   ├── ConnectorSecurityAnalysis.m
│       │   └── ComplianceMetrics.m
│       ├── dashboard-templates/               # Dashboard configurations
│       │   ├── SecurityDashboard.json
│       │   └── ExecutiveDashboard.json
│       └── documentation/                     # Excel-specific docs
│           ├── Excel_Setup_Guide.md
│           ├── Power_Query_Reference.md
│           └── Dashboard_Configuration_Guide.md
│
├── output/                            # Default output directory (created at runtime)
│   ├── reports/                               # Generated reports
│   ├── exports/                               # Data exports
│   └── logs/                                  # Application logs
│
└── tests/                             # Test files and sample data
    ├── sample-data/                           # Sample assessment data
    ├── unit-tests/                            # PowerShell unit tests
    └── integration-tests/                     # Integration test scenarios
```

## File Descriptions

### Core Source Files (`src/`)

| File | Purpose | Dependencies |
|------|---------|--------------|
| `PowerAutomate-SecurityAssessment.ps1` | Main assessment engine | Power Platform PowerShell modules |
| `PowerAutomate-SecurityAPI.ps1` | REST API server | .NET HttpListener |
| `API-Authentication.ps1` | Authentication handlers | Cryptography modules |
| `API-Endpoints.ps1` | API endpoint logic | Assessment engine |

### Scripts (`scripts/`)

| File | Purpose | Usage |
|------|---------|-------|
| `Deploy-SecurityAPI.ps1` | API server deployment | `.\Deploy-SecurityAPI.ps1 -Install -Start` |
| `Install-Dependencies.ps1` | Install required modules | `.\Install-Dependencies.ps1` |
| `Setup-Environment.ps1` | Configure environment | `.\Setup-Environment.ps1 -Interactive` |
| `Start-Assessment.ps1` | Quick assessment runner | `.\Start-Assessment.ps1 -Environment "Prod"` |

### Configuration Files (`config/`)

| File | Purpose | Format |
|------|---------|--------|
| `API-Config.json` | API server settings | JSON configuration |
| `API-OpenAPI.json` | API documentation | OpenAPI 3.0 specification |
| `assessment-config.json` | Default assessment parameters | JSON configuration |
| `environment-examples.json` | Sample environment configs | JSON examples |

### Documentation (`docs/`)

| File | Audience | Content |
|------|----------|---------|
| `INSTALLATION.md` | IT Administrators | Step-by-step installation |
| `CONFIGURATION.md` | System Administrators | Configuration options |
| `USAGE.md` | Security Analysts | Usage scenarios and examples |
| `QUICK_START.md` | All Users | Fast track to first assessment |
| `SECURITY_METHODOLOGY.md` | Security Teams | Assessment criteria and standards |
| `BI-INTEGRATION.md` | BI Developers | Integration with analytics tools |
| `TROUBLESHOOTING.md` | Support Teams | Common issues and solutions |
| `API_REFERENCE.md` | Developers | API endpoints and schemas |

### Templates (`templates/`)

#### Power BI Templates
- **Dashboard Templates**: Pre-built Power BI report templates
- **DAX Measures**: Calculated fields for security metrics
- **Data Models**: Relationship and schema specifications
- **Visualizations**: Chart and visual configurations

#### Excel Templates
- **Workbook Templates**: Pre-configured Excel workbooks
- **Power Query**: Data transformation templates
- **VBA Macros**: Automation and dashboard management
- **M Scripts**: Advanced data processing logic

## Usage Patterns

### For Security Analysts
```
1. Start with: docs/QUICK_START.md
2. Run: scripts/Start-Assessment.ps1
3. Analyze: Generated reports in output/reports/
4. Integrate: templates/powerbi-templates/ or templates/excel-templates/
```

### For System Administrators
```
1. Read: docs/INSTALLATION.md
2. Configure: config/ files
3. Deploy: scripts/Deploy-SecurityAPI.ps1
4. Monitor: output/logs/
```

### For BI Developers
```
1. Review: docs/BI-INTEGRATION.md
2. Use: templates/powerbi-templates/ or templates/excel-templates/
3. Connect: REST API endpoints or exported data
4. Customize: Dashboard templates and measures
```

### For Developers
```
1. Study: src/ source files
2. Reference: docs/API_REFERENCE.md
3. Test: tests/ scenarios
4. Extend: Add new endpoints or export formats
```

## Getting Started

### Quick Start (5 minutes)
```powershell
# 1. Install dependencies
.\scripts\Install-Dependencies.ps1

# 2. Run first assessment
.\scripts\Start-Assessment.ps1

# 3. View results
explorer .\output\reports\
```

### Full Setup (30 minutes)
```powershell
# 1. Read installation guide
Get-Content .\docs\INSTALLATION.md

# 2. Configure environment
.\scripts\Setup-Environment.ps1 -Interactive

# 3. Deploy API (optional)
.\scripts\Deploy-SecurityAPI.ps1 -Install -Configure

# 4. Run comprehensive assessment
.\src\PowerAutomate-SecurityAssessment.ps1 -ExportFormat "PowerBI"
```

## Maintenance

### Regular Tasks
- **Weekly**: Review `output/logs/` for issues
- **Monthly**: Update PowerShell modules
- **Quarterly**: Review and update `config/` files
- **Annually**: Update documentation and templates

### File Management
- **Logs**: Automatically rotated, 30-day retention
- **Reports**: Archived monthly to prevent disk usage
- **Exports**: Cleaned up after 90 days
- **Cache**: Cleared on service restart

## Development Guidelines

### Adding New Features
1. Update relevant source files in `src/`
2. Add configuration options to `config/`
3. Create deployment scripts in `scripts/`
4. Update documentation in `docs/`
5. Add templates if applicable

### File Naming Conventions
- **PowerShell Scripts**: `PascalCase-Action.ps1`
- **Configuration Files**: `kebab-case.json`
- **Documentation**: `UPPER_CASE.md`
- **Templates**: `PascalCase-Template.extension`

### Version Control
- **Source Files**: Track all changes
- **Configuration**: Template files only (not local configs)
- **Documentation**: All updates tracked
- **Templates**: Version with breaking changes
- **Output**: Excluded from version control

This structure ensures clear separation of concerns, easy navigation, and scalable organization as the project grows.