' VBA Macros for Power Automate Security Assessment Tool
' Module: SecurityAssessmentMacros

Option Explicit

' Global variables
Dim wsMain As Worksheet
Dim wsDashboard As Worksheet
Dim wsRawData As Worksheet
Dim wsSettings As Worksheet

' Initialize worksheets
Sub InitializeWorksheets()
    Set wsMain = ThisWorkbook.Worksheets("Dashboard")
    Set wsDashboard = ThisWorkbook.Worksheets("Dashboard")
    Set wsRawData = ThisWorkbook.Worksheets("Raw Data")
    Set wsSettings = ThisWorkbook.Worksheets("Settings")
End Sub

' Main data refresh function
Sub RefreshAllData()
    On Error GoTo ErrorHandler
    
    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual
    
    Call InitializeWorksheets
    Call UpdateRefreshStatus("Starting data refresh...")
    
    ' Refresh all Power Query connections
    Call RefreshPowerQueries
    
    ' Update pivot tables
    Call RefreshPivotTables
    
    ' Update charts
    Call UpdateCharts
    
    ' Apply conditional formatting
    Call ApplyConditionalFormatting
    
    ' Update dashboard KPIs
    Call UpdateDashboardKPIs
    
    Application.Calculation = xlCalculationAutomatic
    Application.ScreenUpdating = True
    
    Call UpdateRefreshStatus("Data refresh completed successfully at " & Now())
    
    MsgBox "Security assessment data has been refreshed successfully!", vbInformation, "Refresh Complete"
    
    Exit Sub
    
ErrorHandler:
    Application.Calculation = xlCalculationAutomatic
    Application.ScreenUpdating = True
    Call UpdateRefreshStatus("Error during refresh: " & Err.Description)
    MsgBox "An error occurred during data refresh: " & Err.Description, vbCritical, "Refresh Error"
End Sub

' Refresh Power Query connections
Sub RefreshPowerQueries()
    Dim conn As WorkbookConnection
    Dim qt As QueryTable
    
    Call UpdateRefreshStatus("Refreshing Power Query connections...")
    
    ' Refresh all Power Query connections
    For Each conn In ThisWorkbook.Connections
        If conn.Type = xlConnectionTypeOLEDB Or conn.Type = xlConnectionTypeODBC Then
            conn.Refresh
        End If
    Next conn
    
    ' Refresh query tables
    For Each qt In wsRawData.QueryTables
        qt.Refresh BackgroundQuery:=False
    Next qt
    
    Call UpdateRefreshStatus("Power Query refresh completed")
End Sub

' Refresh all pivot tables
Sub RefreshPivotTables()
    Dim pt As PivotTable
    Dim ws As Worksheet
    
    Call UpdateRefreshStatus("Refreshing pivot tables...")
    
    For Each ws In ThisWorkbook.Worksheets
        For Each pt In ws.PivotTables
            pt.RefreshTable
        Next pt
    Next ws
    
    Call UpdateRefreshStatus("Pivot table refresh completed")
End Sub

' Update charts with latest data
Sub UpdateCharts()
    Dim cht As ChartObject
    Dim ws As Worksheet
    
    Call UpdateRefreshStatus("Updating charts...")
    
    For Each ws In ThisWorkbook.Worksheets
        For Each cht In ws.ChartObjects
            cht.Chart.Refresh
        Next cht
    Next ws
    
    Call UpdateRefreshStatus("Chart updates completed")
End Sub

' Apply conditional formatting for risk levels
Sub ApplyConditionalFormatting()
    Dim rng As Range
    Dim fc As FormatCondition
    
    Call UpdateRefreshStatus("Applying conditional formatting...")
    
    ' Risk level formatting on dashboard
    Set rng = wsDashboard.Range("RiskScores")
    rng.FormatConditions.Delete
    
    ' High risk (Red)
    Set fc = rng.FormatConditions.Add(xlCellValue, xlLess, 40)
    With fc.Interior
        .Color = RGB(255, 199, 206)
        .Pattern = xlSolid
    End With
    fc.Font.Color = RGB(156, 0, 6)
    
    ' Medium risk (Yellow)
    Set fc = rng.FormatConditions.Add(xlCellValue, xlBetween, 40, 70)
    With fc.Interior
        .Color = RGB(255, 235, 156)
        .Pattern = xlSolid
    End With
    fc.Font.Color = RGB(156, 101, 0)
    
    ' Low risk (Green)
    Set fc = rng.FormatConditions.Add(xlCellValue, xlGreater, 70)
    With fc.Interior
        .Color = RGB(198, 239, 206)
        .Pattern = xlSolid
    End With
    fc.Font.Color = RGB(0, 97, 0)
    
    Call UpdateRefreshStatus("Conditional formatting applied")
End Sub

' Update dashboard KPIs
Sub UpdateDashboardKPIs()
    Dim totalFlows As Long
    Dim highRiskFlows As Long
    Dim avgComplianceScore As Double
    Dim criticalConnectors As Long
    
    Call UpdateRefreshStatus("Updating dashboard KPIs...")
    
    ' Calculate KPIs from raw data
    totalFlows = Application.WorksheetFunction.CountA(wsRawData.Range("A:A")) - 1
    highRiskFlows = Application.WorksheetFunction.CountIf(wsRawData.Range("RiskLevel"), "High")
    avgComplianceScore = Application.WorksheetFunction.Average(wsRawData.Range("ComplianceScore"))
    criticalConnectors = Application.WorksheetFunction.CountIf(wsRawData.Range("BusinessImpact"), "Critical")
    
    ' Update dashboard cells
    With wsDashboard
        .Range("B2").Value = totalFlows
        .Range("B3").Value = highRiskFlows
        .Range("B4").Value = Round(avgComplianceScore, 1)
        .Range("B5").Value = criticalConnectors
        .Range("B6").Value = Round((highRiskFlows / totalFlows) * 100, 1) & "%"
    End With
    
    Call UpdateRefreshStatus("Dashboard KPIs updated")
End Sub

' Generate comprehensive security report
Sub GenerateSecurityReport()
    On Error GoTo ErrorHandler
    
    Application.ScreenUpdating = False
    
    Call InitializeWorksheets
    Call UpdateRefreshStatus("Generating security report...")
    
    ' Create new workbook for report
    Dim reportWb As Workbook
    Set reportWb = Workbooks.Add
    
    ' Copy dashboard to report
    wsDashboard.Copy Before:=reportWb.Sheets(1)
    
    ' Create executive summary
    Call CreateExecutiveSummary(reportWb)
    
    ' Create detailed findings
    Call CreateDetailedFindings(reportWb)
    
    ' Create recommendations
    Call CreateRecommendations(reportWb)
    
    ' Format report
    Call FormatSecurityReport(reportWb)
    
    ' Save report
    Dim reportPath As String
    reportPath = ThisWorkbook.Path & "\Security_Assessment_Report_" & Format(Now, "yyyymmdd_hhmmss") & ".xlsx"
    reportWb.SaveAs reportPath
    
    Application.ScreenUpdating = True
    
    Call UpdateRefreshStatus("Security report generated: " & reportPath)
    MsgBox "Security report generated successfully!" & vbCrLf & reportPath, vbInformation, "Report Generated"
    
    Exit Sub
    
ErrorHandler:
    Application.ScreenUpdating = True
    Call UpdateRefreshStatus("Error generating report: " & Err.Description)
    MsgBox "Error generating security report: " & Err.Description, vbCritical, "Report Error"
End Sub

' Create executive summary worksheet
Sub CreateExecutiveSummary(wb As Workbook)
    Dim ws As Worksheet
    Set ws = wb.Worksheets.Add
    ws.Name = "Executive Summary"
    
    With ws
        .Range("A1").Value = "Power Automate Security Assessment - Executive Summary"
        .Range("A1").Font.Size = 16
        .Range("A1").Font.Bold = True
        
        .Range("A3").Value = "Assessment Date:"
        .Range("B3").Value = Date
        .Range("A4").Value = "Total Flows Analyzed:"
        .Range("B4").Value = Application.WorksheetFunction.CountA(wsRawData.Range("A:A")) - 1
        
        .Range("A6").Value = "Key Findings:"
        .Range("A7").Value = "• High Risk Flows: " & Application.WorksheetFunction.CountIf(wsRawData.Range("RiskLevel"), "High")
        .Range("A8").Value = "• Average Compliance Score: " & Round(Application.WorksheetFunction.Average(wsRawData.Range("ComplianceScore")), 1)
        .Range("A9").Value = "• Critical Business Impact Flows: " & Application.WorksheetFunction.CountIf(wsRawData.Range("BusinessImpact"), "Critical")
        
        .Columns("A:B").AutoFit
    End With
End Sub

' Create detailed findings worksheet
Sub CreateDetailedFindings(wb As Workbook)
    Dim ws As Worksheet
    Set ws = wb.Worksheets.Add
    ws.Name = "Detailed Findings"
    
    ' Copy filtered high-risk data
    wsRawData.Range("A1").CurrentRegion.AutoFilter Field:=wsRawData.Range("RiskLevel").Column, Criteria1:="High"
    wsRawData.Range("A1").CurrentRegion.SpecialCells(xlCellTypeVisible).Copy ws.Range("A1")
    wsRawData.AutoFilterMode = False
    
    ws.Range("A1").Font.Bold = True
End Sub

' Create recommendations worksheet
Sub CreateRecommendations(wb As Workbook)
    Dim ws As Worksheet
    Set ws = wb.Worksheets.Add
    ws.Name = "Recommendations"
    
    With ws
        .Range("A1").Value = "Security Recommendations"
        .Range("A1").Font.Size = 14
        .Range("A1").Font.Bold = True
        
        .Range("A3").Value = "Immediate Actions:"
        .Range("A4").Value = "1. Review and secure all high-risk flows"
        .Range("A5").Value = "2. Implement additional authentication for critical flows"
        .Range("A6").Value = "3. Audit external connector permissions"
        
        .Range("A8").Value = "Long-term Improvements:"
        .Range("A9").Value = "1. Establish regular security assessment schedule"
        .Range("A10").Value = "2. Implement automated compliance monitoring"
        .Range("A11").Value = "3. Provide security training for flow creators"
        
        .Columns("A:A").AutoFit
    End With
End Sub

' Format security report
Sub FormatSecurityReport(wb As Workbook)
    Dim ws As Worksheet
    
    For Each ws In wb.Worksheets
        ws.Range("A1").Font.Bold = True
        ws.Columns.AutoFit
        ws.Range("A1").Select
    Next ws
End Sub

' Export dashboard as PDF
Sub ExportDashboardToPDF()
    Dim pdfPath As String
    pdfPath = ThisWorkbook.Path & "\Security_Dashboard_" & Format(Now, "yyyymmdd_hhmmss") & ".pdf"
    
    wsDashboard.ExportAsFixedFormat Type:=xlTypePDF, Filename:=pdfPath, Quality:=xlQualityStandard
    
    MsgBox "Dashboard exported to PDF: " & pdfPath, vbInformation, "Export Complete"
End Sub

' Schedule automatic refresh
Sub ScheduleAutoRefresh()
    Dim refreshTime As Date
    refreshTime = TimeValue("08:00:00")
    
    Application.OnTime refreshTime, "RefreshAllData"
    
    wsSettings.Range("AutoRefreshTime").Value = refreshTime
    wsSettings.Range("AutoRefreshEnabled").Value = True
    
    MsgBox "Auto-refresh scheduled for " & Format(refreshTime, "hh:mm AM/PM"), vbInformation, "Refresh Scheduled"
End Sub

' Update refresh status
Sub UpdateRefreshStatus(statusText As String)
    wsSettings.Range("RefreshStatus").Value = statusText
    wsSettings.Range("LastRefreshTime").Value = Now()
    DoEvents
End Sub

' Workbook open event
Private Sub Workbook_Open()
    Call InitializeWorksheets
    
    ' Check if auto-refresh is enabled
    If wsSettings.Range("AutoRefreshEnabled").Value = True Then
        Call ScheduleAutoRefresh
    End If
End Sub

' Error handling utility
Sub LogError(errorDescription As String)
    Dim logRange As Range
    Set logRange = wsSettings.Range("ErrorLog")
    
    If IsEmpty(logRange.Value) Then
        logRange.Value = Now() & ": " & errorDescription
    Else
        logRange.Value = logRange.Value & vbCrLf & Now() & ": " & errorDescription
    End If
End Sub