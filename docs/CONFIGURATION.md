# Configuration Guide

This guide covers all configuration options for the Power Automate Security Assessment Tool.

## Overview

The tool uses multiple configuration methods:
- **Command-line parameters** - Runtime options
- **Configuration files** - Persistent settings  
- **Environment variables** - System-level configuration
- **Interactive prompts** - Guided setup

## Configuration Files

### Assessment Configuration (`config/assessment-config.json`)

```json
{
  "assessment": {
    "defaultOutputPath": "./output/reports",
    "defaultExportFormat": "HTML",
    "includePersonalData": false,
    "maxEnvironments": 50,
    "timeoutMinutes": 120,
    "retryAttempts": 3
  },
  "security": {
    "riskThresholds": {
      "high": 8,
      "medium": 4,
      "low": 1
    },
    "connectorRiskLevels": {
      "SQL Server": "HIGH",
      "SharePoint": "MEDIUM", 
      "Office 365 Outlook": "MEDIUM",
      "Common Data Service": "LOW"
    }
  },
  "reporting": {
    "includeExecutiveSummary": true,
    "includeDetailedFindings": true,
    "includeRecommendations": true,
    "includeTrendAnalysis": false
  },
  "compliance": {
    "frameworks": ["SOX", "GDPR", "HIPAA"],
    "includeComplianceMapping": true,
    "generateComplianceReport": false
  }
}
```

### API Configuration (`config/API-Config.json`)

```json
{
  "server": {
    "port": 8080,
    "host": "localhost",
    "enableHttps": false,
    "certificatePath": "",
    "certificatePassword": ""
  },
  "authentication": {
    "enabled": true,
    "defaultApiKey": "your-secure-api-key-here",
    "jwtSecret": "your-jwt-secret-here",
    "tokenExpirationHours": 24,
    "apiKeys": {
      "powerbi": "powerbi-integration-key",
      "excel": "excel-integration-key", 
      "admin": "admin-access-key"
    }
  },
  "security": {
    "enableCors": true,
    "allowedOrigins": ["*"],
    "rateLimitEnabled": true,
    "maxRequestsPerMinute": 100,
    "enableHttpsRedirect": false
  },
  "caching": {
    "enabled": true,
    "ttlMinutes": 30,
    "maxCacheSize": "100MB"
  },
  "logging": {
    "level": "Information",
    "enableFileLogging": true,
    "logPath": "./output/logs",
    "maxLogFileSize": "10MB",
    "retentionDays": 30
  }
}
```

## Command-Line Parameters

### PowerAutomate-SecurityAssessment.ps1

| Parameter | Type | Description | Default | Example |
|-----------|------|-------------|---------|---------|
| `EnvironmentName` | String | Specific environment to assess | All environments | `"Production"` |
| `OutputPath` | String | Report output directory | Current directory | `"C:\Reports"` |
| `ExportFormat` | String | Export format | `"HTML"` | `"PowerBI"`, `"Excel"`, `"SQL"` |
| `SqlConnectionString` | String | SQL Server connection | None | `"Server=myServer;Database=PowerPlatformSecurity;Integrated Security=true"` |
| `PowerBIWorkspace` | String | Power BI workspace name | None | `"Security Analytics"` |
| `CreatePowerBIDataset` | Switch | Create Power BI dataset | False | Present to enable |
| `ConfigFile` | String | Custom config file path | `./config/assessment-config.json` | `"C:\Config\custom.json"` |
| `Verbose` | Switch | Enable verbose logging | False | Present to enable |
| `WhatIf` | Switch | Preview actions without execution | False | Present to enable |

#### Usage Examples:

```powershell
# Basic assessment with default settings
.\src\PowerAutomate-SecurityAssessment.ps1

# Assess specific environment with Power BI export
.\src\PowerAutomate-SecurityAssessment.ps1 -EnvironmentName "Production" -ExportFormat "PowerBI" -OutputPath "C:\PowerBI-Data"

# Full assessment with SQL Server export
.\src\PowerAutomate-SecurityAssessment.ps1 -ExportFormat "SQL" -SqlConnectionString "Server=myServer;Database=PowerPlatformSecurity;Integrated Security=true"

# Excel export with custom configuration
.\src\PowerAutomate-SecurityAssessment.ps1 -ExportFormat "Excel" -ConfigFile "C:\MyConfig\custom-config.json" -Verbose

# Preview mode to see what would be assessed
.\src\PowerAutomate-SecurityAssessment.ps1 -WhatIf -Verbose
```

### Deploy-SecurityAPI.ps1

| Parameter | Type | Description | Default | Example |
|-----------|------|-------------|---------|---------|
| `Install` | Switch | Install dependencies | False | Present to enable |
| `Configure` | Switch | Run configuration setup | False | Present to enable |
| `Start` | Switch | Start API server | False | Present to enable |
| `Service` | Switch | Install as Windows service | False | Present to enable |
| `Production` | Switch | Use production settings | False | Present to enable |
| `Port` | Integer | API server port | 8080 | `9090` |
| `ConfigFile` | String | API config file path | `./config/API-Config.json` | `"C:\Config\api.json"` |

#### Usage Examples:

```powershell
# Full deployment with default settings
.\scripts\Deploy-SecurityAPI.ps1 -Install -Configure -Start

# Production deployment as Windows service
.\scripts\Deploy-SecurityAPI.ps1 -Install -Service -Production -Port 443

# Development setup with custom port
.\scripts\Deploy-SecurityAPI.ps1 -Install -Configure -Start -Port 9090

# Configuration only (no installation)
.\scripts\Deploy-SecurityAPI.ps1 -Configure -ConfigFile "C:\MyConfig\api.json"
```

## Environment Variables

### Power Platform Connection

| Variable | Purpose | Example |
|----------|---------|---------|
| `POWERPLATFORM_TENANT_ID` | Azure AD Tenant ID | `12345678-1234-5678-9abc-123456789012` |
| `POWERPLATFORM_CLIENT_ID` | Service Principal ID | `87654321-4321-8765-cba9-987654321098` |
| `POWERPLATFORM_CLIENT_SECRET` | Service Principal Secret | `your-client-secret` |
| `POWERPLATFORM_ENVIRONMENT` | Default environment | `Default-12345678-1234-5678-9abc-123456789012` |

### API Configuration

| Variable | Purpose | Example |
|----------|---------|---------|
| `SECURITY_API_PORT` | API server port | `8080` |
| `SECURITY_API_KEY` | Default API key | `your-secure-api-key` |
| `SECURITY_API_HTTPS` | Enable HTTPS | `true` |
| `SECURITY_API_CERT_PATH` | Certificate file path | `C:\Certs\api.pfx` |

### Output Configuration

| Variable | Purpose | Example |
|----------|---------|---------|
| `SECURITY_OUTPUT_PATH` | Default output directory | `C:\SecurityReports` |
| `SECURITY_LOG_LEVEL` | Logging level | `Information` |
| `SECURITY_CACHE_TTL` | Cache time-to-live (minutes) | `30` |

## Interactive Configuration

### Setup Wizard

Run the interactive setup to configure all components:

```powershell
.\scripts\Setup-Environment.ps1 -Interactive
```

The wizard will guide you through:

1. **Power Platform Connection**
   - Authentication method selection
   - Credential configuration
   - Connection testing

2. **Assessment Settings**
   - Default export formats
   - Output directories
   - Risk thresholds

3. **API Configuration** 
   - Port and security settings
   - Authentication setup
   - SSL certificate configuration

4. **BI Integration**
   - Power BI workspace setup
   - Excel template configuration
   - SQL Server connection strings

5. **Logging and Monitoring**
   - Log levels and retention
   - Performance monitoring
   - Alert configuration

### Configuration Validation

Validate your configuration before running assessments:

```powershell
.\scripts\Validate-Configuration.ps1 -ConfigFile ".\config\assessment-config.json"
```

This will check:
- ✅ Configuration file syntax
- ✅ Power Platform connectivity
- ✅ Output directory permissions
- ✅ API endpoint accessibility
- ✅ Database connectivity (if configured)

## Advanced Configuration

### Custom Risk Scoring

Modify risk scoring in `assessment-config.json`:

```json
{
  "customRiskScoring": {
    "enabled": true,
    "rules": [
      {
        "condition": "EnvironmentType == 'Production' && DLPPolicyCount == 0",
        "riskScore": 10,
        "severity": "CRITICAL"
      },
      {
        "condition": "ConnectorName == 'SQL Server' && AuthMethod == 'Basic'",
        "riskScore": 9,
        "severity": "HIGH"
      }
    ]
  }
}
```

### Multi-Tenant Configuration

For organizations with multiple tenants:

```json
{
  "multiTenant": {
    "enabled": true,
    "tenants": [
      {
        "name": "Production",
        "tenantId": "12345678-1234-5678-9abc-123456789012",
        "clientId": "prod-client-id",
        "clientSecret": "prod-client-secret"
      },
      {
        "name": "Development", 
        "tenantId": "87654321-4321-8765-cba9-987654321098",
        "clientId": "dev-client-id",
        "clientSecret": "dev-client-secret"
      }
    ]
  }
}
```

### Compliance Framework Mapping

Configure compliance framework assessment:

```json
{
  "complianceFrameworks": {
    "SOX": {
      "enabled": true,
      "controls": [
        {
          "id": "SOX-01",
          "description": "Segregation of duties",
          "mappings": ["UserAccess.RoleType", "Flow.CreatedBy"]
        }
      ]
    },
    "GDPR": {
      "enabled": true,
      "dataClassification": ["PII", "Sensitive"],
      "retentionPolicies": true
    }
  }
}
```

### Performance Tuning

Optimize for large environments:

```json
{
  "performance": {
    "batchSize": 100,
    "parallelProcessing": true,
    "maxConcurrentRequests": 10,
    "cacheEnabled": true,
    "cacheTTLMinutes": 60,
    "timeoutSeconds": 300
  }
}
```

## Configuration Management

### Version Control

Track configuration changes:

```powershell
# Create configuration baseline
git add config/
git commit -m "Initial configuration baseline"

# Track changes
git diff config/assessment-config.json
```

### Environment-Specific Configs

Maintain separate configurations:

```
config/
├── assessment-config.json          # Base configuration
├── environments/
│   ├── development.json            # Development overrides
│   ├── staging.json                # Staging overrides  
│   └── production.json             # Production overrides
```

Usage:
```powershell
# Development environment
.\src\PowerAutomate-SecurityAssessment.ps1 -ConfigFile ".\config\environments\development.json"

# Production environment
.\src\PowerAutomate-SecurityAssessment.ps1 -ConfigFile ".\config\environments\production.json"
```

### Configuration Backup

Backup configurations before changes:

```powershell
# Create backup
Copy-Item -Path ".\config\" -Destination ".\config-backup-$(Get-Date -Format 'yyyyMMdd')" -Recurse

# Restore from backup
Copy-Item -Path ".\config-backup-20240115\*" -Destination ".\config\" -Recurse -Force
```

## Troubleshooting Configuration

### Common Configuration Issues

#### Authentication Failures
```
Issue: "Access denied to Power Platform"
Check: 
- Power Platform admin role assignment
- Correct tenant ID in configuration
- Valid client credentials
- Network connectivity
```

#### Permission Errors  
```
Issue: "Access denied to output directory"
Check:
- Directory exists and is writable
- User has sufficient permissions
- Path format is correct
- Disk space available
```

#### API Startup Failures
```
Issue: "Port already in use"
Check:
- Port availability (netstat -an | findstr :8080)
- Change port in configuration
- Stop conflicting services
- Run as administrator
```

### Configuration Validation Script

```powershell
# Validate all configurations
.\scripts\Test-Configuration.ps1 -Comprehensive

# Test specific components
.\scripts\Test-Configuration.ps1 -TestPowerPlatform
.\scripts\Test-Configuration.ps1 -TestAPI
.\scripts\Test-Configuration.ps1 -TestDatabase
```

### Reset to Defaults

Reset configuration to factory defaults:

```powershell
.\scripts\Reset-Configuration.ps1 -Component "Assessment"
.\scripts\Reset-Configuration.ps1 -Component "API"
.\scripts\Reset-Configuration.ps1 -All -Confirm
```

This guide provides comprehensive configuration options for all components of the Power Automate Security Assessment Tool, enabling customization for various organizational needs and deployment scenarios.