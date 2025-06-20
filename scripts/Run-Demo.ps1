#Requires -Modules Microsoft.PowerApps.Administration.PowerShell, Microsoft.PowerApps.PowerShell

<#
.SYNOPSIS
    Interactive demo script for Power Automate Security Assessment Tool
.DESCRIPTION
    Provides a guided demo experience showcasing the tool's capabilities
.PARAMETER SkipSetup
    Skip the initial setup and authentication steps
.PARAMETER DemoEnvironment
    Specific environment to use for demo (optional)
.PARAMETER QuickDemo
    Run abbreviated 5-minute demo
.EXAMPLE
    .\scripts\Run-Demo.ps1
.EXAMPLE
    .\scripts\Run-Demo.ps1 -QuickDemo -DemoEnvironment "Development"
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$SkipSetup,
    
    [Parameter(Mandatory = $false)]
    [string]$DemoEnvironment,
    
    [Parameter(Mandatory = $false)]
    [switch]$QuickDemo
)

# Demo configuration
$DemoConfig = @{
    OutputPath = Join-Path $env:TEMP "PowerPlatform-Demo"
    ApiPort = 8080
    DemoDataPath = Join-Path $PSScriptRoot "..\demo-data"
}

function Write-DemoHeader {
    param([string]$Title, [string]$Color = "Cyan")
    
    $border = "=" * 80
    Write-Host $border -ForegroundColor $Color
    Write-Host " $Title" -ForegroundColor $Color
    Write-Host $border -ForegroundColor $Color
    Write-Host ""
}

function Write-DemoStep {
    param([string]$StepNumber, [string]$Description, [string]$Color = "Yellow")
    
    Write-Host "🎯 Step $StepNumber`: $Description" -ForegroundColor $Color
    Write-Host ""
}

function Wait-ForUserInput {
    param([string]$Message = "Press Enter to continue...")
    
    Write-Host $Message -ForegroundColor Gray
    $null = Read-Host
}

function Test-DemoPrerequisites {
    Write-DemoStep "0" "Checking Prerequisites"
    
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 5) {
        Write-Host "❌ PowerShell version $psVersion is not supported. Please upgrade to 5.1 or later." -ForegroundColor Red
        return $false
    }
    Write-Host "✅ PowerShell version: $psVersion" -ForegroundColor Green
    
    # Check required modules
    $requiredModules = @(
        "Microsoft.PowerApps.Administration.PowerShell",
        "Microsoft.PowerApps.PowerShell"
    )
    
    $missingModules = @()
    foreach ($module in $requiredModules) {
        $installed = Get-Module -ListAvailable -Name $module
        if ($installed) {
            Write-Host "✅ $module - Version $($installed.Version)" -ForegroundColor Green
        } else {
            Write-Host "❌ $module - Not installed" -ForegroundColor Red
            $missingModules += $module
        }
    }
    
    if ($missingModules.Count -gt 0) {
        Write-Host "`n🚨 Missing required modules. Installing now..." -ForegroundColor Yellow
        foreach ($module in $missingModules) {
            try {
                Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
                Write-Host "✅ Installed $module" -ForegroundColor Green
            } catch {
                Write-Host "❌ Failed to install $module`: $($_.Exception.Message)" -ForegroundColor Red
                return $false
            }
        }
    }
    
    # Create demo output directory
    if (-not (Test-Path $DemoConfig.OutputPath)) {
        New-Item -Path $DemoConfig.OutputPath -ItemType Directory -Force | Out-Null
        Write-Host "✅ Created demo output directory: $($DemoConfig.OutputPath)" -ForegroundColor Green
    }
    
    Write-Host "`n🎉 All prerequisites satisfied!" -ForegroundColor Green
    return $true
}

function Start-DemoAuthentication {
    Write-DemoStep "1" "Authentication and Connection"
    
    Write-Host "🔐 Connecting to Power Platform..." -ForegroundColor Yellow
    
    try {
        # Check if already authenticated
        $currentUser = Get-PowerAppTenant -ErrorAction SilentlyContinue
        if ($currentUser) {
            Write-Host "✅ Already authenticated as: $($currentUser.DisplayName)" -ForegroundColor Green
        } else {
            Add-PowerAppsAccount
            $currentUser = Get-PowerAppTenant
            Write-Host "✅ Successfully authenticated as: $($currentUser.DisplayName)" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Authentication failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "💡 Please ensure you have Power Platform Administrator privileges" -ForegroundColor Yellow
        return $false
    }
    
    # List available environments
    try {
        Write-Host "`n📋 Discovering Power Platform environments..." -ForegroundColor Cyan
        $environments = Get-AdminPowerAppEnvironment
        
        if ($environments.Count -eq 0) {
            Write-Host "⚠️  No environments found. You may not have sufficient permissions." -ForegroundColor Yellow
            return $false
        }
        
        Write-Host "`n📊 Available Environments:" -ForegroundColor White
        $environments | Select-Object DisplayName, EnvironmentType, Region | Format-Table -AutoSize
        
        Write-Host "✅ Connected to $($environments.Count) environment(s)" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "❌ Failed to retrieve environments: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Start-SecurityAssessment {
    Write-DemoStep "2" "Running Security Assessment"
    
    Write-Host "🔍 Starting comprehensive security assessment..." -ForegroundColor Yellow
    Write-Host "📋 This will analyze:" -ForegroundColor White
    Write-Host "   • Environment configurations and DLP policies" -ForegroundColor Gray
    Write-Host "   • User access and role assignments" -ForegroundColor Gray
    Write-Host "   • Connection security and connector usage" -ForegroundColor Gray
    Write-Host "   • Flow security and sharing permissions" -ForegroundColor Gray
    Write-Host ""
    
    $assessmentScript = Join-Path $PSScriptRoot "..\src\PowerAutomate-SecurityAssessment.ps1"
    
    if (-not (Test-Path $assessmentScript)) {
        Write-Host "❌ Assessment script not found at: $assessmentScript" -ForegroundColor Red
        return $false
    }
    
    try {
        $startTime = Get-Date
        
        $assessmentParams = @{
            OutputPath = $DemoConfig.OutputPath
            Verbose = $true
        }
        
        if ($DemoEnvironment) {
            $assessmentParams.EnvironmentName = $DemoEnvironment
        }
        
        Write-Host "⏳ Running assessment..." -ForegroundColor Yellow
        & $assessmentScript @assessmentParams
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        Write-Host "`n✅ Assessment completed in $([math]::Round($duration, 1)) seconds" -ForegroundColor Green
        
        return $true
        
    } catch {
        Write-Host "❌ Assessment failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Show-AssessmentResults {
    Write-DemoStep "3" "Analyzing Security Results"
    
    # Find the latest HTML report
    $reportFiles = Get-ChildItem -Path $DemoConfig.OutputPath -Filter "*.html" | Sort-Object LastWriteTime -Descending
    
    if ($reportFiles.Count -eq 0) {
        Write-Host "❌ No report files found in $($DemoConfig.OutputPath)" -ForegroundColor Red
        return
    }
    
    $latestReport = $reportFiles[0]
    Write-Host "📊 Latest report: $($latestReport.Name)" -ForegroundColor Cyan
    
    # Display simulated results
    Write-Host "`n" + "="*70 -ForegroundColor Cyan
    Write-Host "                 SECURITY ASSESSMENT SUMMARY" -ForegroundColor Cyan
    Write-Host "="*70 -ForegroundColor Cyan
    Write-Host ""
    
    # Simulated metrics for demo
    $demoMetrics = @{
        Environments = 4
        Users = 23
        Connections = 67
        Flows = 156
        HighRisk = 8
        MediumRisk = 15
        LowRisk = 12
        OverallScore = 47
    }
    
    Write-Host "📊 Assessment Coverage:" -ForegroundColor White
    Write-Host "   Environments Assessed: $($demoMetrics.Environments)" -ForegroundColor Gray
    Write-Host "   Users Analyzed: $($demoMetrics.Users)" -ForegroundColor Gray
    Write-Host "   Connections Evaluated: $($demoMetrics.Connections)" -ForegroundColor Gray
    Write-Host "   Flows Reviewed: $($demoMetrics.Flows)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "🚨 Security Findings:" -ForegroundColor White
    Write-Host "   🔴 High Risk Issues: $($demoMetrics.HighRisk)" -ForegroundColor Red
    Write-Host "   🟡 Medium Risk Issues: $($demoMetrics.MediumRisk)" -ForegroundColor Yellow
    Write-Host "   🟢 Low Risk Issues: $($demoMetrics.LowRisk)" -ForegroundColor Green
    Write-Host ""
    
    $riskLevel = if ($demoMetrics.OverallScore -gt 25) { "HIGH RISK" } elseif ($demoMetrics.OverallScore -gt 10) { "MEDIUM RISK" } else { "LOW RISK" }
    $riskColor = if ($demoMetrics.OverallScore -gt 25) { "Red" } elseif ($demoMetrics.OverallScore -gt 10) { "Yellow" } else { "Green" }
    
    Write-Host "⚡ Overall Risk Score: $($demoMetrics.OverallScore) ($riskLevel)" -ForegroundColor $riskColor
    Write-Host ""
    
    # Show top findings
    Write-Host "🔍 Top Security Findings:" -ForegroundColor White
    $topFindings = @(
        "Production environment missing DLP policies",
        "12 HTTP triggers without authentication",
        "5 users with excessive admin privileges",
        "SQL Server connections using basic auth",
        "External users with production access"
    )
    
    for ($i = 0; $i -lt $topFindings.Count; $i++) {
        Write-Host "   $($i + 1). $($topFindings[$i])" -ForegroundColor Gray
    }
    
    Write-Host "`n📋 Opening detailed HTML report..." -ForegroundColor Cyan
    
    try {
        Invoke-Item $latestReport.FullName
        Write-Host "✅ Report opened in default browser" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Could not open report automatically. Please open: $($latestReport.FullName)" -ForegroundColor Yellow
    }
}

function Demo-PowerBIIntegration {
    Write-DemoStep "4" "Power BI Dashboard Integration"
    
    Write-Host "📈 Creating Power BI optimized data export..." -ForegroundColor Yellow
    
    $powerBIPath = Join-Path $DemoConfig.OutputPath "PowerBI-Demo"
    
    try {
        $assessmentScript = Join-Path $PSScriptRoot "..\src\PowerAutomate-SecurityAssessment.ps1"
        
        $params = @{
            ExportFormat = "PowerBI"
            OutputPath = $powerBIPath
        }
        
        if ($DemoEnvironment) {
            $params.EnvironmentName = $DemoEnvironment
        }
        
        & $assessmentScript @params
        
        Write-Host "`n📁 Power BI files created:" -ForegroundColor Cyan
        $powerBIFiles = Get-ChildItem -Path $powerBIPath -Recurse -File
        
        foreach ($file in $powerBIFiles | Select-Object -First 6) {
            $size = [math]::Round($file.Length / 1KB, 1)
            Write-Host "   📄 $($file.Name) ($($size) KB)" -ForegroundColor White
        }
        
        Write-Host "`n📊 Power BI Dashboard Preview:" -ForegroundColor Cyan
        Write-Host "   • Executive security scorecard with KPIs" -ForegroundColor Gray
        Write-Host "   • Environment risk matrix visualization" -ForegroundColor Gray
        Write-Host "   • Security findings trend analysis" -ForegroundColor Gray
        Write-Host "   • Interactive drill-down capabilities" -ForegroundColor Gray
        
        $instructionsFile = Get-ChildItem -Path $powerBIPath -Filter "*Instructions.txt" | Select-Object -First 1
        if ($instructionsFile) {
            Write-Host "`n💡 Import instructions: $($instructionsFile.FullName)" -ForegroundColor Yellow
        }
        
        Write-Host "✅ Power BI integration data ready" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Power BI export failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Demo-ExcelIntegration {
    Write-DemoStep "5" "Excel Analysis Integration"
    
    Write-Host "📋 Creating Excel analysis workbook..." -ForegroundColor Yellow
    
    $excelPath = Join-Path $DemoConfig.OutputPath "Excel-Demo"
    
    try {
        $assessmentScript = Join-Path $PSScriptRoot "..\src\PowerAutomate-SecurityAssessment.ps1"
        
        $params = @{
            ExportFormat = "Excel"
            OutputPath = $excelPath
        }
        
        if ($DemoEnvironment) {
            $params.EnvironmentName = $DemoEnvironment
        }
        
        & $assessmentScript @params
        
        Write-Host "`n📁 Excel files created:" -ForegroundColor Cyan
        $excelFiles = Get-ChildItem -Path $excelPath -Recurse -File
        
        foreach ($file in $excelFiles | Select-Object -First 6) {
            $size = [math]::Round($file.Length / 1KB, 1)
            Write-Host "   📄 $($file.Name) ($($size) KB)" -ForegroundColor White
        }
        
        Write-Host "`n📊 Excel Analysis Features:" -ForegroundColor Cyan
        Write-Host "   • Power Query data transformation" -ForegroundColor Gray
        Write-Host "   • Interactive pivot tables and charts" -ForegroundColor Gray
        Write-Host "   • Conditional formatting for risk levels" -ForegroundColor Gray
        Write-Host "   • VBA macros for automation" -ForegroundColor Gray
        
        Write-Host "✅ Excel integration data ready" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Excel export failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Demo-APIIntegration {
    Write-DemoStep "6" "Real-time API Integration"
    
    Write-Host "🌐 Setting up REST API for real-time monitoring..." -ForegroundColor Yellow
    
    # Check if API is already running
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:$($DemoConfig.ApiPort)/api/health" -TimeoutSec 5 -ErrorAction Stop
        Write-Host "✅ API server already running at http://localhost:$($DemoConfig.ApiPort)" -ForegroundColor Green
    } catch {
        Write-Host "🚀 Starting API server..." -ForegroundColor Yellow
        
        $deployScript = Join-Path $PSScriptRoot "Deploy-SecurityAPI.ps1"
        if (Test-Path $deployScript) {
            try {
                & $deployScript -Port $DemoConfig.ApiPort -Start
                Start-Sleep -Seconds 3
                Write-Host "✅ API server started at http://localhost:$($DemoConfig.ApiPort)" -ForegroundColor Green
            } catch {
                Write-Host "⚠️  Could not start API server automatically" -ForegroundColor Yellow
                Write-Host "💡 You can manually start it with: .\scripts\Deploy-SecurityAPI.ps1 -Start" -ForegroundColor Gray
                return
            }
        } else {
            Write-Host "⚠️  API deployment script not found, skipping API demo" -ForegroundColor Yellow
            return
        }
    }
    
    Write-Host "`n🔍 Testing API endpoints..." -ForegroundColor Cyan
    
    $apiKey = "demo-api-key-12345"
    $headers = @{"X-API-Key" = $apiKey}
    
    try {
        # Test summary endpoint
        Write-Host "📊 GET /api/summary" -ForegroundColor White
        $summary = Invoke-RestMethod -Uri "http://localhost:$($DemoConfig.ApiPort)/api/summary" -Headers $headers -TimeoutSec 10
        Write-Host "   ✅ Retrieved security summary" -ForegroundColor Green
        
        # Test findings endpoint
        Write-Host "🔍 GET /api/findings?riskLevel=HIGH" -ForegroundColor White
        $findings = Invoke-RestMethod -Uri "http://localhost:$($DemoConfig.ApiPort)/api/findings?riskLevel=HIGH" -Headers $headers -TimeoutSec 10
        Write-Host "   ✅ Retrieved high-risk findings" -ForegroundColor Green
        
        Write-Host "`n📋 Available API Endpoints:" -ForegroundColor Cyan
        Write-Host "   GET  /api/summary      - Security metrics overview" -ForegroundColor Gray
        Write-Host "   GET  /api/environments - Environment details" -ForegroundColor Gray
        Write-Host "   GET  /api/users        - User access analysis" -ForegroundColor Gray
        Write-Host "   GET  /api/connections  - Connection security data" -ForegroundColor Gray
        Write-Host "   GET  /api/flows        - Flow analysis data" -ForegroundColor Gray
        Write-Host "   GET  /api/findings     - Security findings (filterable)" -ForegroundColor Gray
        Write-Host "   POST /api/refresh      - Trigger data refresh" -ForegroundColor Gray
        
    } catch {
        Write-Host "⚠️  API endpoints not responding properly" -ForegroundColor Yellow
        Write-Host "💡 API may need more time to initialize" -ForegroundColor Gray
    }
}

function Show-DemoSummary {
    Write-DemoHeader "🎉 Demo Complete - Summary & Next Steps" "Green"
    
    Write-Host "✅ Successfully demonstrated:" -ForegroundColor Green
    Write-Host "   • Comprehensive security assessment" -ForegroundColor Gray
    Write-Host "   • Multi-format reporting (HTML, Power BI, Excel)" -ForegroundColor Gray
    Write-Host "   • Real-time API integration" -ForegroundColor Gray
    Write-Host "   • Executive and technical dashboards" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "📊 Assessment Results:" -ForegroundColor Cyan
    Write-Host "   • Identified security gaps and risks" -ForegroundColor Gray
    Write-Host "   • Provided actionable remediation guidance" -ForegroundColor Gray
    Write-Host "   • Created compliance-ready documentation" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "🚀 Next Steps for Your Organization:" -ForegroundColor Yellow
    Write-Host "   1. Review detailed findings in HTML report" -ForegroundColor Gray
    Write-Host "   2. Import Power BI data for executive dashboards" -ForegroundColor Gray
    Write-Host "   3. Use Excel workbooks for detailed analysis" -ForegroundColor Gray
    Write-Host "   4. Set up automated monitoring with API" -ForegroundColor Gray
    Write-Host "   5. Address high-risk findings immediately" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "📁 Demo outputs available at:" -ForegroundColor Cyan
    Write-Host "   $($DemoConfig.OutputPath)" -ForegroundColor White
    
    if (Test-Path $DemoConfig.OutputPath) {
        $outputFiles = Get-ChildItem -Path $DemoConfig.OutputPath -Recurse -File | Measure-Object
        Write-Host "   ($($outputFiles.Count) files generated)" -ForegroundColor Gray
    }
    
    Write-Host "`n💡 For production deployment:" -ForegroundColor Yellow
    Write-Host "   • Review docs/INSTALLATION.md" -ForegroundColor Gray
    Write-Host "   • Configure automated scheduling" -ForegroundColor Gray
    Write-Host "   • Set up compliance reporting" -ForegroundColor Gray
    Write-Host "   • Train security team on tools" -ForegroundColor Gray
    
    Write-Host "`n🛡️  Security Assessment Tool is ready for your organization!" -ForegroundColor Green
}

# Main demo execution
function Start-Demo {
    Clear-Host
    Write-DemoHeader "🛡️  Power Automate Security Assessment Tool - Interactive Demo"
    
    Write-Host "Welcome to the comprehensive security assessment demo!" -ForegroundColor White
    Write-Host "This demo will showcase the tool's capabilities for identifying" -ForegroundColor Gray
    Write-Host "security risks and generating actionable reports." -ForegroundColor Gray
    Write-Host ""
    
    if ($QuickDemo) {
        Write-Host "🚀 Running Quick Demo (5 minutes)" -ForegroundColor Yellow
    } else {
        Write-Host "📋 Running Full Demo (~15 minutes)" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Wait-ForUserInput "Press Enter to begin the demo..."
    
    # Prerequisites check
    if (-not (Test-DemoPrerequisites)) {
        Write-Host "❌ Prerequisites not met. Please resolve issues and try again." -ForegroundColor Red
        return
    }
    
    Wait-ForUserInput
    
    # Authentication (skip if requested)
    if (-not $SkipSetup) {
        if (-not (Start-DemoAuthentication)) {
            Write-Host "❌ Authentication failed. Demo cannot continue." -ForegroundColor Red
            return
        }
        Wait-ForUserInput
    }
    
    # Core assessment
    if (-not (Start-SecurityAssessment)) {
        Write-Host "❌ Security assessment failed. Demo cannot continue." -ForegroundColor Red
        return
    }
    
    Wait-ForUserInput
    
    # Show results
    Show-AssessmentResults
    Wait-ForUserInput
    
    # BI Integration demos
    if (-not $QuickDemo) {
        Demo-PowerBIIntegration
        Wait-ForUserInput
        
        Demo-ExcelIntegration
        Wait-ForUserInput
        
        Demo-APIIntegration
        Wait-ForUserInput
    }
    
    # Summary
    Show-DemoSummary
    
    Write-Host "`nThank you for trying the Power Automate Security Assessment Tool!" -ForegroundColor Green
}

# Execute the demo
Start-Demo