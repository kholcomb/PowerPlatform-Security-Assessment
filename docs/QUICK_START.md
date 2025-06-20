# Quick Start Guide

Get up and running with the Power Automate Security Assessment Tool in 5 minutes.

## Prerequisites Check ✅

Before starting, ensure you have:
- [ ] PowerShell 5.1 or later
- [ ] Power Platform Administrator role
- [ ] Internet connectivity
- [ ] Write permissions to local directory

## 5-Minute Quick Start

### Step 1: Download and Setup (1 minute)

```powershell
# Navigate to project directory
cd C:\PowerPlatform

# Verify PowerShell version
$PSVersionTable.PSVersion
# Should be 5.1.x or 7.x.x
```

### Step 2: Install Dependencies (2 minutes)

```powershell
# Install required PowerShell modules
Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Force -AllowClobber
Install-Module -Name Microsoft.PowerApps.PowerShell -Force -AllowClobber

# Verify installation
Get-Module -Name Microsoft.PowerApps* -ListAvailable
```

### Step 3: Connect to Power Platform (1 minute)

```powershell
# Authenticate to Power Platform
Add-PowerAppsAccount

# Verify connection
Get-AdminPowerAppEnvironment | Select-Object DisplayName, EnvironmentName -First 3
```

### Step 4: Run Your First Assessment (1 minute)

```powershell
# Run basic assessment
.\src\PowerAutomate-SecurityAssessment.ps1

# Assessment will create a report in the current directory
# Look for: PowerAutomate-SecurityAssessment-YYYYMMDD-HHMMSS.html
```

### Step 5: View Results (30 seconds)

```powershell
# Open the generated HTML report
Invoke-Item .\PowerAutomate-SecurityAssessment-*.html

# Or explore the output directory
explorer .\output\reports\
```

## 🎉 Success!

You should now see a comprehensive security assessment report showing:
- **Security Summary**: Overall risk score and findings count
- **Environment Analysis**: DLP policies and configuration issues
- **User Access Review**: Role assignments and privilege analysis
- **Connection Security**: High-risk connectors and authentication
- **Flow Security**: Trigger analysis and sharing permissions

---

## Next Steps

### Option A: Power BI Integration (5 more minutes)

```powershell
# Export for Power BI
.\src\PowerAutomate-SecurityAssessment.ps1 -ExportFormat "PowerBI" -OutputPath "C:\PowerBI-Data"

# Follow instructions in: C:\PowerBI-Data\PowerBI-ImportInstructions.txt
```

### Option B: Excel Integration (3 more minutes)

```powershell
# Export for Excel
.\src\PowerAutomate-SecurityAssessment.ps1 -ExportFormat "Excel" -OutputPath "C:\Excel-Data"

# Open: C:\Excel-Data\Excel-PowerQuery-Instructions.txt
```

### Option C: API Setup for Real-time Monitoring (10 more minutes)

```powershell
# Deploy REST API
.\scripts\Deploy-SecurityAPI.ps1 -Install -Configure -Start

# Test API
Invoke-RestMethod -Uri "http://localhost:8080/api/summary" -Headers @{"X-API-Key"="your-api-key"}
```

---

## Common Commands Reference

### Basic Assessment Commands

```powershell
# Assess all environments
.\src\PowerAutomate-SecurityAssessment.ps1

# Assess specific environment
.\src\PowerAutomate-SecurityAssessment.ps1 -EnvironmentName "Production"

# Different export formats
.\src\PowerAutomate-SecurityAssessment.ps1 -ExportFormat "JSON"
.\src\PowerAutomate-SecurityAssessment.ps1 -ExportFormat "CSV"
.\src\PowerAutomate-SecurityAssessment.ps1 -ExportFormat "PowerBI"
```

### Useful Shortcuts

```powershell
# Quick assessment with verbose output
.\src\PowerAutomate-SecurityAssessment.ps1 -Verbose

# Preview what would be assessed (no actual execution)
.\src\PowerAutomate-SecurityAssessment.ps1 -WhatIf

# Custom output location
.\src\PowerAutomate-SecurityAssessment.ps1 -OutputPath "C:\SecurityReports"
```

---

## Troubleshooting Quick Fixes

### ❌ "Module not found" Error
```powershell
# Solution: Install modules with elevated privileges
Start-Process PowerShell -Verb RunAs
Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Force
```

### ❌ "Access denied" Error
```powershell
# Solution: Verify Power Platform admin role
Get-AdminPowerAppEnvironment | Measure-Object
# If this fails, contact your Global Administrator
```

### ❌ "Execution policy" Error
```powershell
# Solution: Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### ❌ Authentication Issues
```powershell
# Solution: Clear and re-authenticate
Remove-PowerAppsAccount
Add-PowerAppsAccount
```

---

## What You'll See in Your First Report

### 🟢 Good Security Posture
- ✅ DLP policies configured
- ✅ Appropriate user access levels
- ✅ Secure connector usage
- ✅ Proper flow governance

### 🟡 Areas for Improvement
- ⚠️ Some security groups not assigned
- ⚠️ Premium connectors without proper licensing
- ⚠️ Flows with multiple owners

### 🔴 Security Concerns
- ❌ No DLP policies (HIGH RISK)
- ❌ HTTP triggers without authentication
- ❌ Excessive admin privileges
- ❌ Failed connections

---

## Understanding Your Security Score

| Score Range | Risk Level | Action Required |
|-------------|------------|-----------------|
| 0-10 | 🟢 **LOW** | Monitor regularly |
| 11-25 | 🟡 **MEDIUM** | Plan improvements |
| 26+ | 🔴 **HIGH** | Immediate action needed |

### Risk Calculation
- **High Risk Finding**: +10 points
- **Medium Risk Finding**: +5 points  
- **Low Risk Finding**: +1 point

---

## Sample Output Structure

After running the assessment, you'll find:

```
output/
├── reports/
│   └── PowerAutomate-SecurityAssessment-20240115-143022.html    # Main report
├── exports/
│   ├── PowerAutomate-SecurityAssessment-20240115-143022.json   # Raw data
│   └── PowerAutomate-SecurityAssessment-20240115-143022-*.csv  # CSV files
└── logs/
    └── assessment-20240115.log                                 # Execution log
```

---

## Quick Reference Card

### Essential Commands
```powershell
# Install dependencies
Install-Module Microsoft.PowerApps.Administration.PowerShell -Force

# Connect
Add-PowerAppsAccount

# Run assessment  
.\src\PowerAutomate-SecurityAssessment.ps1

# Power BI export
.\src\PowerAutomate-SecurityAssessment.ps1 -ExportFormat "PowerBI"

# View environments
Get-AdminPowerAppEnvironment | Select DisplayName, EnvironmentType

# Check connection
Get-AdminPowerAppConnection | Select DisplayName, ConnectorName
```

### File Locations
- **Main Script**: `src\PowerAutomate-SecurityAssessment.ps1`
- **Configuration**: `config\assessment-config.json`
- **Documentation**: `docs\`
- **Templates**: `templates\powerbi-templates\`, `templates\excel-templates\`
- **Output**: `output\reports\`

### Getting Help
- **Detailed Guide**: `docs\USAGE.md`
- **Configuration**: `docs\CONFIGURATION.md`
- **Troubleshooting**: `docs\TROUBLESHOOTING.md`
- **BI Integration**: `docs\BI-INTEGRATION.md`

---

## Ready for More?

### 📊 Create Executive Dashboards
Follow the [BI Integration Guide](BI-INTEGRATION.md) to create stunning dashboards in Power BI or Excel.

### 🔧 Customize Your Assessment
Read the [Configuration Guide](CONFIGURATION.md) to tailor the assessment to your organization's needs.

### 🚀 Set Up Automation
Check the [Usage Guide](USAGE.md) for automated scheduling and continuous monitoring.

### 🔍 Deep Dive Analysis
Explore the [Security Methodology](SECURITY_METHODOLOGY.md) to understand how findings are classified and scored.

---

**🎯 Goal Achieved**: You now have a comprehensive security assessment of your Power Automate environment and know how to run regular assessments to maintain security posture visibility.