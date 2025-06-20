# Power Automate Security Assessment API - BI Tools Connection Guide

This guide provides instructions for connecting various Business Intelligence (BI) tools to the Power Automate Security Assessment API to create comprehensive security dashboards and reports.

## Table of Contents

- [API Overview](#api-overview)
- [Authentication Setup](#authentication-setup)
- [Power BI Integration](#power-bi-integration)
- [Tableau Integration](#tableau-integration)
- [Excel Power Query](#excel-power-query)
- [Other BI Tools](#other-bi-tools)
- [Sample Queries](#sample-queries)
- [Troubleshooting](#troubleshooting)

## API Overview

The Power Automate Security Assessment API provides REST endpoints for accessing security assessment data:

- **Base URL**: `http://localhost:8080` (default)
- **Authentication**: API Key or Bearer Token
- **Format**: JSON responses with pagination support
- **CORS**: Enabled for web-based tools

### Available Endpoints

| Endpoint | Description | Use Case |
|----------|-------------|----------|
| `/api/summary` | Overall security metrics | Executive dashboards, KPIs |
| `/api/environments` | Environment details | Environment risk analysis |
| `/api/users` | User access data | Access governance reports |
| `/api/connections` | Connection security | Data connector risk analysis |
| `/api/flows` | Flow analysis | Automation security monitoring |
| `/api/findings` | Security findings | Detailed security reporting |
| `/api/health` | API health status | Monitoring dashboards |

## Authentication Setup

### API Key Authentication

1. **Obtain an API Key** from the `API-Config.json` file or create a new one:
   ```powershell
   # Create a new API key
   . .\API-Authentication.ps1
   Add-ApiKey -Name "PowerBI-Dashboard" -Description "Power BI connection" -Permissions @("read")
   ```

2. **Use the API Key** in your requests:
   - **Header**: `X-API-Key: your-api-key-here`
   - **Alternative**: `Authorization: ApiKey your-api-key-here`

### Default API Keys

The configuration includes these pre-configured keys for testing:

- **Power BI**: `powerbi-key-123456789abcdef`
- **Tableau**: `tableau-key-987654321fedcba`
- **Admin**: `admin-key-abcdef123456789`

> **Security Note**: Change these default keys in production environments.

## Power BI Integration

### Method 1: Web Data Source

1. **Open Power BI Desktop**
2. **Get Data** → **Web**
3. **Configure the connection**:
   ```
   URL: http://localhost:8080/api/summary
   ```
4. **Add Headers** (Advanced options):
   ```
   X-API-Key: powerbi-key-123456789abcdef
   ```

### Method 2: Blank Query with Power Query

1. **Get Data** → **Blank Query**
2. **Advanced Editor** and paste:
   ```m
   let
       ApiKey = "powerbi-key-123456789abcdef",
       BaseUrl = "http://localhost:8080/api/",
       Headers = [#"X-API-Key" = ApiKey, #"Content-Type" = "application/json"],
       
       // Summary Data
       SummaryUrl = BaseUrl & "summary",
       SummaryResponse = Json.Document(Web.Contents(SummaryUrl, [Headers=Headers])),
       
       // Convert to table for Power BI
       SummaryTable = Record.ToTable(SummaryResponse[overview])
   in
       SummaryTable
   ```

### Method 3: Multiple Endpoints Query

```m
let
    ApiKey = "powerbi-key-123456789abcdef",
    BaseUrl = "http://localhost:8080/api/",
    Headers = [#"X-API-Key" = ApiKey],
    
    // Function to get data from any endpoint
    GetApiData = (endpoint as text) =>
        let
            Url = BaseUrl & endpoint,
            Response = Json.Document(Web.Contents(Url, [Headers=Headers]))
        in
            Response,
    
    // Get all data sources
    Summary = GetApiData("summary"),
    Environments = GetApiData("environments"),
    Users = GetApiData("users"),
    Connections = GetApiData("connections"),
    Flows = GetApiData("flows"),
    Findings = GetApiData("findings"),
    
    // Create a summary table
    SummaryData = [
        TotalEnvironments = Summary[overview][totalEnvironments],
        TotalUsers = Summary[overview][totalUsers],
        TotalConnections = Summary[overview][totalConnections],
        TotalFlows = Summary[overview][totalFlows],
        HighRiskFindings = Summary[security][highRiskFindings],
        MediumRiskFindings = Summary[security][mediumRiskFindings],
        LowRiskFindings = Summary[security][lowRiskFindings],
        OverallRiskScore = Summary[security][overallRiskScore]
    ],
    
    ResultTable = Record.ToTable(SummaryData)
in
    ResultTable
```

### Power BI Data Model Setup

1. **Create Relationships**:
   - Environments → Users (environmentName)
   - Environments → Connections (environmentName)
   - Environments → Flows (environmentName)
   - Environments → Findings (environmentName)

2. **Key Measures**:
   ```dax
   Total Risk Score = SUMX(Findings, Findings[riskScore])
   High Risk Count = COUNTROWS(FILTER(Findings, Findings[riskLevel] = "HIGH"))
   Security Compliance % = DIVIDE([Total Environments] - [High Risk Environments], [Total Environments], 0) * 100
   ```

3. **Recommended Visuals**:
   - Card: Total environments, users, connections, flows
   - Gauge: Overall risk score
   - Pie Chart: Risk distribution (High/Medium/Low)
   - Bar Chart: Findings by environment
   - Matrix: Environment risk details

## Tableau Integration

### Method 1: Web Data Connector

1. **Connect to Data** → **To a Server** → **Web Data Connector**
2. **Enter URL**: `http://localhost:8080/api/summary`
3. **Add Custom Headers**:
   ```
   X-API-Key: tableau-key-987654321fedcba
   ```

### Method 2: JSON Connector

1. **Connect to Data** → **JSON File**
2. **Paste URL**: `http://localhost:8080/api/summary`
3. **Configure Authentication**: Custom Headers
4. **Add Header**: `X-API-Key: tableau-key-987654321fedcba`

### Tableau Data Source Configuration

```json
{
  "connectionType": "webdata",
  "url": "http://localhost:8080/api/summary",
  "headers": {
    "X-API-Key": "tableau-key-987654321fedcba"
  },
  "refreshable": true,
  "incrementalRefresh": false
}
```

### Multiple Endpoints in Tableau

Create separate data sources for each endpoint:

1. **Summary Data Source**: `/api/summary`
2. **Environments Data Source**: `/api/environments`
3. **Users Data Source**: `/api/users`
4. **Connections Data Source**: `/api/connections`
5. **Flows Data Source**: `/api/flows`
6. **Findings Data Source**: `/api/findings`

Join them using the `environmentName` field.

## Excel Power Query

### Simple Connection

1. **Data** → **Get Data** → **From Web**
2. **URL**: `http://localhost:8080/api/summary`
3. **Advanced** → **HTTP request header parameters**:
   - Name: `X-API-Key`
   - Value: `powerbi-key-123456789abcdef`

### Advanced Power Query Script

```m
let
    // Configuration
    ApiKey = "powerbi-key-123456789abcdef",
    BaseUrl = "http://localhost:8080/api/",
    
    // Headers
    Headers = [#"X-API-Key" = ApiKey, #"Content-Type" = "application/json"],
    
    // Function to fetch data
    FetchData = (endpoint as text) =>
        let
            Url = BaseUrl & endpoint,
            Response = Json.Document(Web.Contents(Url, [Headers=Headers]))
        in
            Response,
    
    // Get summary data
    SummaryData = FetchData("summary"),
    
    // Transform to table
    OverviewTable = Record.ToTable(SummaryData[overview]),
    SecurityTable = Record.ToTable(SummaryData[security]),
    
    // Combine tables
    CombinedData = Table.Combine({
        Table.AddColumn(OverviewTable, "Category", each "Overview"),
        Table.AddColumn(SecurityTable, "Category", each "Security")
    })
in
    CombinedData
```

### Excel Dashboard Setup

1. **Create Pivot Tables** from the Power Query data
2. **Key Metrics**:
   - Total Environments (Count)
   - High Risk Findings (Sum)
   - Security Score (Average)
   - Compliance Rate (Calculated)

3. **Charts**:
   - Risk Distribution (Pie Chart)
   - Environment Risk Scores (Bar Chart)
   - Findings Trend (Line Chart)

## Other BI Tools

### Grafana

```json
{
  "type": "json",
  "url": "http://localhost:8080/api/summary",
  "headers": {
    "X-API-Key": "admin-key-abcdef123456789"
  }
}
```

### QlikSense

```qvs
LOAD * FROM [http://localhost:8080/api/summary]
(
    HTTPHEADER "X-API-Key" "admin-key-abcdef123456789"
);
```

### Looker Studio (Google Data Studio)

1. **Create a Data Source** → **Community Connectors**
2. **Use the Generic REST API Connector**
3. **Configure**:
   - URL: `http://localhost:8080/api/summary`
   - Headers: `X-API-Key: admin-key-abcdef123456789`

## Sample Queries

### Get High-Risk Environments

```bash
curl -H "X-API-Key: your-api-key" \
     "http://localhost:8080/api/environments?riskLevel=HIGH"
```

### Get Users Requiring Review

```bash
curl -H "X-API-Key: your-api-key" \
     "http://localhost:8080/api/users?requiresReview=true"
```

### Get High-Risk Connections

```bash
curl -H "X-API-Key: your-api-key" \
     "http://localhost:8080/api/connections?isHighRisk=true"
```

### Get Security Findings for Specific Environment

```bash
curl -H "X-API-Key: your-api-key" \
     "http://localhost:8080/api/findings?environmentName=Production&riskLevel=HIGH"
```

### Pagination Example

```bash
curl -H "X-API-Key: your-api-key" \
     "http://localhost:8080/api/flows?page=1&pageSize=50"
```

## Troubleshooting

### Common Issues

#### 1. Authentication Failed (401)

**Problem**: API returns 401 Unauthorized
**Solutions**:
- Verify API key is correct
- Check header format: `X-API-Key: your-key-here`
- Ensure API authentication is enabled in config

#### 2. CORS Errors

**Problem**: Browser-based tools can't connect
**Solutions**:
- Verify CORS is enabled in `API-Config.json`
- Check `AllowedOrigins` includes your domain
- For development, use `"*"` for allowed origins

#### 3. Connection Timeout

**Problem**: Requests timeout or fail
**Solutions**:
- Check API server is running
- Verify correct port and URL
- Check firewall settings
- Increase timeout in BI tool settings

#### 4. Empty or Invalid Data

**Problem**: No data returned or invalid JSON
**Solutions**:
- Test endpoint manually with curl/Postman
- Check API logs for errors
- Verify assessment data cache is populated
- Refresh assessment data: `POST /api/refresh`

#### 5. Rate Limiting (429)

**Problem**: Too Many Requests error
**Solutions**:
- Reduce refresh frequency
- Increase rate limits in config
- Use pagination for large datasets
- Implement caching in BI tool

### Power BI Specific Issues

#### Data Refresh Failures

1. **Check Credentials**: Ensure API key is stored securely
2. **Gateway Configuration**: Configure on-premises data gateway if needed
3. **Scheduled Refresh**: Set appropriate refresh schedule (not too frequent)

#### Performance Issues

1. **Use Query Folding**: Structure queries to push filtering to API
2. **Enable Compression**: Use `gzip` compression if available
3. **Pagination**: Implement pagination for large datasets

### Tableau Specific Issues

#### Web Data Connector Errors

1. **HTTPS Requirements**: Some Tableau versions require HTTPS
2. **CORS Configuration**: Ensure proper CORS headers
3. **JSON Structure**: Verify JSON response format compatibility

### Data Refresh Best Practices

1. **Scheduled Refresh**: Set up automated refresh schedules
2. **Incremental Refresh**: Use timestamp-based filtering where possible
3. **Error Handling**: Implement retry logic for failed requests
4. **Monitoring**: Monitor API performance and adjust accordingly

### Security Considerations

1. **API Key Storage**: Store API keys securely
2. **Network Security**: Use HTTPS in production
3. **Access Control**: Limit API key permissions
4. **Audit Logging**: Monitor API usage and access

## Support and Resources

- **API Documentation**: View OpenAPI spec at `/swagger` endpoint
- **Health Check**: Monitor API status at `/api/health`
- **Logs**: Check API logs for detailed error information
- **Configuration**: Review `API-Config.json` for settings

For additional support or feature requests, please contact the Power Platform Security Team.