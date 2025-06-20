' VBA Macros for Automated Data Import
' Module: DataImportMacros

Option Explicit

' Import data from Power Automate API
Sub ImportSecurityData()
    On Error GoTo ErrorHandler
    
    Dim xmlHttp As Object
    Dim jsonResponse As String
    Dim apiUrl As String
    Dim ws As Worksheet
    
    Application.ScreenUpdating = False
    
    Set ws = ThisWorkbook.Worksheets("Raw Data")
    
    ' API configuration
    apiUrl = ThisWorkbook.Worksheets("Settings").Range("ApiEndpoint").Value
    
    ' Create HTTP request
    Set xmlHttp = CreateObject("MSXML2.XMLHTTP")
    
    With xmlHttp
        .Open "GET", apiUrl, False
        .setRequestHeader "Authorization", "Bearer " & GetAccessToken()
        .setRequestHeader "Content-Type", "application/json"
        .send
    End With
    
    If xmlHttp.Status = 200 Then
        jsonResponse = xmlHttp.responseText
        Call ParseAndImportJSON(jsonResponse, ws)
        Call UpdateRefreshStatus("Data import completed successfully")
    Else
        Err.Raise vbObjectError + 1, , "API request failed with status: " & xmlHttp.Status
    End If
    
    Set xmlHttp = Nothing
    Application.ScreenUpdating = True
    
    Exit Sub
    
ErrorHandler:
    Application.ScreenUpdating = True
    Call UpdateRefreshStatus("Error importing data: " & Err.Description)
    MsgBox "Error importing security data: " & Err.Description, vbCritical, "Import Error"
End Sub

' Parse JSON response and import to worksheet
Sub ParseAndImportJSON(jsonText As String, ws As Worksheet)
    Dim json As Object
    Dim flows As Object
    Dim flow As Object
    Dim row As Long
    Dim col As Long
    
    ' Clear existing data
    ws.Cells.Clear
    
    ' Set up headers
    ws.Range("A1:J1").Value = Array("FlowID", "FlowName", "Owner", "CreatedDate", "LastModified", _
                                   "PermissionLevel", "ExternalConnections", "IsEncrypted", "ConnectorCount", "UserCount")
    
    ' Parse JSON (simplified - would use JSON parser library in production)
    Set json = JsonConverter.ParseJson(jsonText)
    Set flows = json("flows")
    
    row = 2
    For Each flow In flows
        ws.Cells(row, 1).Value = flow("id")
        ws.Cells(row, 2).Value = flow("displayName")
        ws.Cells(row, 3).Value = flow("owner")
        ws.Cells(row, 4).Value = CDate(flow("createdTime"))
        ws.Cells(row, 5).Value = CDate(flow("lastModifiedTime"))
        ws.Cells(row, 6).Value = flow("permissionLevel")
        ws.Cells(row, 7).Value = flow("externalConnectionCount")
        ws.Cells(row, 8).Value = flow("isEncrypted")
        ws.Cells(row, 9).Value = flow("connectorCount")
        ws.Cells(row, 10).Value = flow("userCount")
        
        row = row + 1
    Next flow
    
    ' Format data
    ws.Range("A1:J1").Font.Bold = True
    ws.Range("D:E").NumberFormat = "mm/dd/yyyy hh:mm"
    ws.Columns.AutoFit
End Sub

' Get access token for API authentication
Function GetAccessToken() As String
    Dim clientId As String
    Dim clientSecret As String
    Dim tenantId As String
    Dim tokenUrl As String
    Dim postData As String
    Dim xmlHttp As Object
    Dim response As String
    
    ' Get credentials from settings
    With ThisWorkbook.Worksheets("Settings")
        clientId = .Range("ClientId").Value
        clientSecret = .Range("ClientSecret").Value
        tenantId = .Range("TenantId").Value
    End With
    
    tokenUrl = "https://login.microsoftonline.com/" & tenantId & "/oauth2/v2.0/token"
    postData = "grant_type=client_credentials" & _
               "&client_id=" & clientId & _
               "&client_secret=" & clientSecret & _
               "&scope=https://graph.microsoft.com/.default"
    
    Set xmlHttp = CreateObject("MSXML2.XMLHTTP")
    
    With xmlHttp
        .Open "POST", tokenUrl, False
        .setRequestHeader "Content-Type", "application/x-www-form-urlencoded"
        .send postData
    End With
    
    If xmlHttp.Status = 200 Then
        response = xmlHttp.responseText
        ' Parse token from response (simplified)
        GetAccessToken = ExtractTokenFromResponse(response)
    Else
        Err.Raise vbObjectError + 2, , "Token request failed: " & xmlHttp.Status
    End If
    
    Set xmlHttp = Nothing
End Function

' Extract token from OAuth response
Function ExtractTokenFromResponse(response As String) As String
    Dim startPos As Long
    Dim endPos As Long
    Dim token As String
    
    ' Find access_token in JSON response
    startPos = InStr(response, """access_token"":""") + 16
    endPos = InStr(startPos, response, """")
    
    If startPos > 16 And endPos > startPos Then
        token = Mid(response, startPos, endPos - startPos)
        ExtractTokenFromResponse = token
    Else
        Err.Raise vbObjectError + 3, , "Could not extract access token from response"
    End If
End Function

' Import from CSV file
Sub ImportFromCSV()
    Dim filePath As String
    Dim ws As Worksheet
    
    ' Get file path from user
    filePath = Application.GetOpenFilename("CSV Files (*.csv), *.csv", , "Select Security Data CSV File")
    
    If filePath <> "False" Then
        Set ws = ThisWorkbook.Worksheets("Raw Data")
        
        ' Import CSV data
        With ws.QueryTables.Add(Connection:="TEXT;" & filePath, Destination:=ws.Range("A1"))
            .TextFileParseType = xlDelimited
            .TextFileCommaDelimiter = True
            .TextFileColumnDataTypes = Array(xlTextFormat, xlTextFormat, xlTextFormat, _
                                           xlDateFormat, xlDateFormat, xlTextFormat, _
                                           xlGeneralFormat, xlTextFormat, xlGeneralFormat, xlGeneralFormat)
            .Refresh BackgroundQuery:=False
        End With
        
        Call UpdateRefreshStatus("CSV data imported from: " & filePath)
        MsgBox "CSV data imported successfully!", vbInformation, "Import Complete"
    End If
End Sub

' Export data to CSV
Sub ExportToCSV()
    Dim filePath As String
    Dim ws As Worksheet
    Dim lastRow As Long
    Dim lastCol As Long
    
    Set ws = ThisWorkbook.Worksheets("Raw Data")
    
    ' Get save path from user
    filePath = Application.GetSaveAsFilename(InitialFilename:="SecurityData_" & Format(Now, "yyyymmdd") & ".csv", _
                                           FileFilter:="CSV Files (*.csv), *.csv")
    
    If filePath <> "False" Then
        lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).row
        lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column
        
        ' Copy data to new workbook and save as CSV
        Dim tempWb As Workbook
        Set tempWb = Workbooks.Add
        
        ws.Range(ws.Cells(1, 1), ws.Cells(lastRow, lastCol)).Copy tempWb.Sheets(1).Range("A1")
        
        tempWb.SaveAs Filename:=filePath, FileFormat:=xlCSV
        tempWb.Close SaveChanges:=False
        
        Call UpdateRefreshStatus("Data exported to: " & filePath)
        MsgBox "Data exported successfully to: " & filePath, vbInformation, "Export Complete"
    End If
End Sub

' Validate imported data
Sub ValidateImportedData()
    Dim ws As Worksheet
    Dim lastRow As Long
    Dim validationResults As String
    Dim i As Long
    Dim errorCount As Long
    
    Set ws = ThisWorkbook.Worksheets("Raw Data")
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).row
    
    validationResults = "Data Validation Results:" & vbCrLf & vbCrLf
    errorCount = 0
    
    ' Check for missing required fields
    For i = 2 To lastRow
        If IsEmpty(ws.Cells(i, 1)) Or IsEmpty(ws.Cells(i, 2)) Then
            validationResults = validationResults & "Row " & i & ": Missing FlowID or FlowName" & vbCrLf
            errorCount = errorCount + 1
        End If
        
        If Not IsDate(ws.Cells(i, 4)) Then
            validationResults = validationResults & "Row " & i & ": Invalid CreatedDate format" & vbCrLf
            errorCount = errorCount + 1
        End If
        
        If ws.Cells(i, 7).Value < 0 Then
            validationResults = validationResults & "Row " & i & ": Invalid ExternalConnections count" & vbCrLf
            errorCount = errorCount + 1
        End If
    Next i
    
    If errorCount = 0 Then
        validationResults = validationResults & "All data passed validation checks!"
    Else
        validationResults = validationResults & vbCrLf & "Total errors found: " & errorCount
    End If
    
    ' Display results
    MsgBox validationResults, IIf(errorCount = 0, vbInformation, vbExclamation), "Data Validation"
    
    Call UpdateRefreshStatus("Data validation completed - " & errorCount & " errors found")
End Sub

' Clean and standardize imported data
Sub CleanImportedData()
    Dim ws As Worksheet
    Dim lastRow As Long
    Dim i As Long
    
    Set ws = ThisWorkbook.Worksheets("Raw Data")
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).row
    
    Application.ScreenUpdating = False
    
    For i = 2 To lastRow
        ' Trim whitespace
        ws.Cells(i, 2).Value = Trim(ws.Cells(i, 2).Value) ' FlowName
        ws.Cells(i, 3).Value = Trim(ws.Cells(i, 3).Value) ' Owner
        
        ' Standardize permission levels
        Select Case UCase(ws.Cells(i, 6).Value)
            Case "ADMINISTRATOR", "ADMIN"
                ws.Cells(i, 6).Value = "Admin"
            Case "USER", "STANDARD"
                ws.Cells(i, 6).Value = "User"
            Case "GUEST", "READ-ONLY"
                ws.Cells(i, 6).Value = "Guest"
        End Select
        
        ' Ensure boolean values are standardized
        If ws.Cells(i, 8).Value = "TRUE" Or ws.Cells(i, 8).Value = "1" Then
            ws.Cells(i, 8).Value = True
        ElseIf ws.Cells(i, 8).Value = "FALSE" Or ws.Cells(i, 8).Value = "0" Then
            ws.Cells(i, 8).Value = False
        End If
    Next i
    
    Application.ScreenUpdating = True
    
    Call UpdateRefreshStatus("Data cleaning completed")
    MsgBox "Data cleaning completed successfully!", vbInformation, "Cleaning Complete"
End Sub