# Excel Dashboard Configuration Guide

## Overview
This guide provides detailed instructions for configuring and customizing the Excel dashboards for the Power Automate Security Assessment Tool.

## Dashboard Architecture

### Worksheet Structure
1. **Executive Summary**: High-level KPIs and executive reporting
2. **Security Dashboard**: Detailed security metrics and analysis
3. **Risk Analysis**: Comprehensive risk assessment views
4. **Compliance Report**: Compliance framework status
5. **Trend Analysis**: Historical trend visualization
6. **Raw Data**: Source data tables
7. **Settings**: Configuration and parameters

## Executive Summary Dashboard

### KPI Cards Configuration

#### Overall Security Score
```excel
Cell: B2
Formula: =ROUND(AVERAGE('Raw Data'!ComplianceScore),0)
Format: Large number with gauge visualization
Target: 85 (Good), 70 (Acceptable), <70 (Needs Attention)
Colors: Green (>85), Yellow (70-85), Red (<70)
```

#### Critical Risk Flows
```excel
Cell: B3
Formula: =COUNTIFS('Raw Data'!RiskLevel,"High",'Raw Data'!BusinessImpact,"Critical")
Format: Number with alert icon
Threshold: >5 triggers alert
Conditional Formatting: Red background if >10
```

#### Compliance Rate
```excel
Cell: B4
Formula: =ROUND((COUNTIF('Raw Data'!ComplianceScore,">70")/COUNTA('Raw Data'!ComplianceScore))*100,1)
Format: Percentage with trend arrow
Target: >95%
Trend Calculation: Compare with previous period
```

### Chart Configurations

#### Risk Distribution Doughnut Chart
```json
{
  "chartType": "doughnut",
  "dataRange": "PivotTable1!A1:B4",
  "position": "A10:F25",
  "title": "Flow Distribution by Risk Level",
  "colors": ["#70AD47", "#FFC000", "#C5504B"],
  "dataLabels": {
    "showValue": true,
    "showPercentage": true,
    "position": "outsideEnd"
  },
  "legend": {
    "position": "right",
    "fontSize": 10
  }
}
```

#### Compliance Histogram
```json
{
  "chartType": "column",
  "dataRange": "ComplianceHistogram!A1:B11",
  "position": "H10:L25",
  "title": "Compliance Score Distribution",
  "xAxis": {
    "title": "Compliance Score Range",
    "categories": ["0-10", "11-20", "21-30", "31-40", "41-50", "51-60", "61-70", "71-80", "81-90", "91-100"]
  },
  "yAxis": {
    "title": "Number of Flows",
    "minimum": 0
  },
  "colors": ["#2F5597"]
}
```

## Security Dashboard Configuration

### Risk Heatmap Setup
```excel
// Data preparation for heatmap
=SUMPRODUCT(
  (RiskMatrix[BusinessImpact]="Critical")*
  (RiskMatrix[RiskLevel]="High")*
  (RiskMatrix[Count])
)

// Position: A27:H40
// Color Scale: Red (High) to Green (Low)
// Cell Size: 50x25 pixels
```

### Top Risk Flows Table
```excel
Source: 'Raw Data'!A1:P1000
Filter: RiskLevel = "High" OR ComplianceScore < 40
Sort: RiskLevel DESC, ComplianceScore ASC
Columns:
  - Flow Name (A27:B40)
  - Owner (C27:C40)
  - Risk Level (D27:D40)
  - Compliance Score (E27:E40)
  - Business Impact (F27:F40)
  - Last Modified (G27:G40)
```

### Conditional Formatting Rules

#### Risk Level Formatting
```excel
Range: D27:D40 (Risk Level column)
Rules:
  - "High": Background=#FFCCCC, Font=#AA0000, Bold=True
  - "Medium": Background=#FFFF99, Font=#FF8800
  - "Low": Background=#CCFFCC, Font=#00AA00
```

#### Compliance Score Heat Scale
```excel
Range: E27:E40 (Compliance Score column)
Type: 3-Color Scale
Minimum: Red (#F8696B) at 0
Midpoint: Yellow (#FFEB9C) at 50
Maximum: Green (#63BE7B) at 100
```

## Pivot Table Configurations

### Risk Level Summary Pivot
```excel
Name: PivotTable1
Location: Dashboard!A45:D50
Source Data: 'Raw Data'!A:Z
Configuration:
  Rows: RiskLevel
  Values: Count of FlowID
  Sort: RiskLevel (Custom order: High, Medium, Low)
  Grand Totals: Show for rows and columns
```

### Connector Security Analysis Pivot
```excel
Name: ConnectorSecurityPivot
Location: Dashboard!F45:K55
Source Data: 'Connector Analysis'!A:Z
Configuration:
  Rows: SecurityRisk
  Columns: UsageFrequency
  Values: Count of ConnectorName
  Filters: DataClassification (Page Filter)
```

### Department Risk Analysis Pivot
```excel
Name: DepartmentRiskPivot
Location: 'Risk Analysis'!A5:H25
Source Data: 'Raw Data'!A:Z
Configuration:
  Rows: OwnerDomain, RiskLevel
  Values: 
    - Count of FlowID
    - Average of ComplianceScore
    - Sum of UserCount
  Sort: Count of FlowID (Descending)
```

## Slicer Configuration

### Risk Level Slicer
```json
{
  "name": "RiskLevelSlicer",
  "position": "N10:P16",
  "sourceColumn": "'Raw Data'!RiskLevel",
  "title": "Filter by Risk Level",
  "style": "SlicerStyleLight2",
  "buttons": {
    "columns": 1,
    "height": 25,
    "width": 80
  },
  "connections": [
    "PivotTable1",
    "ConnectorSecurityPivot",
    "DepartmentRiskPivot"
  ]
}
```

### Date Range Slicer
```json
{
  "name": "DateRangeSlicer",
  "position": "N18:P24",
  "sourceColumn": "'Raw Data'!CreatedDate",
  "title": "Filter by Creation Date",
  "style": "SlicerStyleLight3",
  "dateFiltering": {
    "enabled": true,
    "defaultPeriod": "Last 6 Months"
  }
}
```

## Chart Customization

### Advanced Chart Settings

#### Risk Trend Line Chart
```json
{
  "chartType": "lineWithMarkers",
  "dataRange": "'Trend Analysis'!A2:E13",
  "position": "'Trend Analysis'!A2:H20",
  "title": "Security Risk Trends Over Time",
  "series": [
    {
      "name": "High Risk Count",
      "color": "#C5504B",
      "lineStyle": "solid",
      "markerStyle": "circle",
      "markerSize": 6
    },
    {
      "name": "Medium Risk Count", 
      "color": "#FFC000",
      "lineStyle": "solid",
      "markerStyle": "square",
      "markerSize": 6
    },
    {
      "name": "Low Risk Count",
      "color": "#70AD47", 
      "lineStyle": "solid",
      "markerStyle": "diamond",
      "markerSize": 6
    }
  ],
  "axes": {
    "x": {
      "title": "Month",
      "format": "mmm yyyy",
      "majorUnit": 1
    },
    "y": {
      "title": "Number of Flows",
      "minimum": 0,
      "majorUnit": 10
    }
  },
  "legend": {
    "position": "bottom",
    "fontSize": 10
  },
  "plotArea": {
    "border": "none",
    "fill": "automatic"
  }
}
```

#### Compliance Gauge Chart
```json
{
  "chartType": "gauge",
  "dataRange": "Dashboard!B4",
  "position": "Dashboard!M5:P12",
  "title": "Overall Compliance Rate",
  "gauge": {
    "minimum": 0,
    "maximum": 100,
    "ranges": [
      {"min": 0, "max": 60, "color": "#FF0000", "label": "Critical"},
      {"min": 60, "max": 80, "color": "#FFC000", "label": "Needs Improvement"},
      {"min": 80, "max": 95, "color": "#70AD47", "label": "Good"},
      {"min": 95, "max": 100, "color": "#00AA00", "label": "Excellent"}
    ],
    "needle": {
      "color": "#000000",
      "width": 3
    },
    "labels": {
      "fontSize": 8,
      "color": "#666666"
    }
  }
}
```

## Interactive Features

### Dynamic Filtering Setup

#### Cascading Filters
```excel
// Business Unit -> Department -> Owner hierarchy
BusinessUnitFilter = UNIQUE('Raw Data'[BusinessUnit])
DepartmentFilter = FILTER('Raw Data'[Department], 
  'Raw Data'[BusinessUnit] = SelectedBusinessUnit)
OwnerFilter = FILTER('Raw Data'[Owner], 
  'Raw Data'[Department] = SelectedDepartment)
```

#### Cross-Filter Configuration
```json
{
  "slicerConnections": {
    "RiskLevelSlicer": ["PivotTable1", "ConnectorPivot", "TrendChart"],
    "DateRangeSlicer": ["All"],
    "BusinessUnitSlicer": ["DepartmentPivot", "OwnerTable"]
  },
  "chartInteractions": {
    "RiskDistributionChart": {
      "highlightOthers": true,
      "filterTables": ["TopRisksTable"]
    }
  }
}
```

### Drill-Down Functionality

#### Chart Drill-Down
```vba
Private Sub Chart_SeriesChange(ByVal SeriesIndex As Long, ByVal PointIndex As Long)
    Dim selectedRiskLevel As String
    selectedRiskLevel = ActiveChart.SeriesCollection(SeriesIndex).Points(PointIndex).DataLabel.Text
    
    ' Filter detailed table based on selection
    With Worksheets("Risk Analysis").ListObjects("RiskDetailTable")
        .Range.AutoFilter Field:=3, Criteria1:=selectedRiskLevel
    End With
End Sub
```

#### Table Drill-Down
```excel
// Hyperlink formula for drill-down
=HYPERLINK("#'Flow Details'!A" & MATCH(A2,'Flow Details'!A:A,0), A2)

// Dynamic sheet reference
=INDIRECT("'Flow Details'!" & ADDRESS(MATCH(A2,'Flow Details'!A:A,0), 1))
```

## Dashboard Themes and Styling

### Corporate Theme
```json
{
  "theme": "corporate",
  "colors": {
    "primary": "#2F5597",
    "secondary": "#70AD47",
    "accent": "#FFC000",
    "danger": "#C5504B",
    "warning": "#FF9900",
    "success": "#00AA00",
    "background": "#FFFFFF",
    "text": "#000000"
  },
  "fonts": {
    "title": "Calibri Light, 18pt, Bold",
    "subtitle": "Calibri, 14pt, Bold",
    "body": "Calibri, 11pt",
    "kpi": "Calibri, 24pt, Bold"
  },
  "borders": {
    "kpiCards": "Medium, #CCCCCC",
    "tables": "Thin, #2F5597",
    "charts": "None"
  }
}
```

### Security Theme
```json
{
  "theme": "security",
  "colors": {
    "primary": "#8B0000",
    "secondary": "#FF6347", 
    "accent": "#FFD700",
    "danger": "#FF0000",
    "warning": "#FFA500",
    "success": "#228B22",
    "background": "#F5F5F5",
    "text": "#2F2F2F"
  }
}
```

## Performance Optimization

### Chart Performance
```json
{
  "optimization": {
    "dataPoints": {
      "maximum": 1000,
      "sampling": "intelligent"
    },
    "animation": {
      "enabled": false,
      "duration": 0
    },
    "rendering": {
      "hardware": true,
      "antiAliasing": false
    }
  }
}
```

### Calculation Settings
```excel
// Optimize calculation for large datasets
Application.Calculation = xlCalculationManual
Application.ScreenUpdating = False
Application.EnableEvents = False

// Efficient formula patterns
=SUMPRODUCT((conditions)*(values))  // Instead of SUMIFS with multiple criteria
=INDEX(MATCH(...))                  // Instead of VLOOKUP
=COUNTIFS(...)                      // Instead of multiple COUNTIFs
```

## Mobile Responsiveness

### Mobile-Friendly Layout
```json
{
  "mobileSettings": {
    "breakpoints": {
      "tablet": 768,
      "mobile": 480
    },
    "adaptiveLayout": {
      "kpiCards": {
        "tablet": "2x3 grid",
        "mobile": "1x6 stack"
      },
      "charts": {
        "tablet": "reduce size",
        "mobile": "simplified view"
      }
    }
  }
}
```

## Accessibility Features

### Screen Reader Support
```json
{
  "accessibility": {
    "altText": {
      "charts": "Descriptive chart summaries",
      "kpiCards": "Metric name and value",
      "tables": "Column headers and data context"
    },
    "colorBlindness": {
      "usePatterns": true,
      "avoidRedGreen": true,
      "highContrast": true
    },
    "keyboardNavigation": {
      "tabOrder": "logical",
      "shortcuts": "available"
    }
  }
}
```

## Maintenance and Updates

### Regular Maintenance Tasks
1. **Weekly**:
   - Refresh data connections
   - Validate chart data ranges
   - Check conditional formatting rules

2. **Monthly**:
   - Review and update color schemes
   - Optimize slow-performing charts
   - Update data validation rules

3. **Quarterly**:
   - Full dashboard performance review
   - User feedback incorporation
   - Theme and style updates

### Version Control
```json
{
  "versioning": {
    "naming": "SecurityDashboard_v{major}.{minor}_{YYYYMMDD}",
    "changeLog": "Include in documentation sheet",
    "backups": "Maintain 3 previous versions"
  }
}
```

## Troubleshooting Common Issues

### Chart Display Problems
```excel
// Fix chart data range issues
ActiveChart.SetSourceData Source:=Range("Dashboard!A1:E10")

// Reset chart formatting
ActiveChart.ChartType = xlColumnClustered
ActiveChart.ApplyLayout(1)
```

### Performance Issues
```vba
' Optimize pivot table refresh
With ActiveSheet.PivotTables("PivotTable1")
    .PivotCache.MissingItemsLimit = xlMissingItemsNone
    .RefreshTable
End With
```

### Data Connection Errors
```vba
' Reconnect data sources
Dim conn As WorkbookConnection
For Each conn In ThisWorkbook.Connections
    If conn.Type = xlConnectionTypeOLEDB Then
        conn.Refresh
    End If
Next conn
```

This configuration guide provides the foundation for creating professional, interactive Excel dashboards for security assessment reporting. Customize the settings based on your specific requirements and organizational standards.