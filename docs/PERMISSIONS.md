# Required Roles and Permissions

This document outlines the exact roles and permissions needed to run the Power Automate Security Assessment Tool.

## Required Azure AD Roles

### **Primary Role: Power Platform Administrator**
- **Azure AD Role**: `Power Platform Administrator`
- **Required**: ✅ **MANDATORY**
- **Purpose**: Provides read access to all Power Platform environments and resources
- **Scope**: Tenant-wide Power Platform administration

### **Alternative Role: Global Administrator**
- **Azure AD Role**: `Global Administrator`
- **Required**: ✅ **ALTERNATIVE** (if Power Platform Administrator not available)
- **Purpose**: Includes all Power Platform Administrator permissions
- **Scope**: Full tenant administration (more permissions than needed)

## Detailed Permission Requirements

### **Power Platform Permissions**

| Permission | PowerShell Cmdlet | Purpose | Risk Level |
|------------|-------------------|---------|------------|
| **Read Environments** | `Get-AdminPowerAppEnvironment` | List and analyze all environments | Read-only |
| **Read DLP Policies** | `Get-AdminDlpPolicy` | Assess data loss prevention configurations | Read-only |
| **Read Environment Roles** | `Get-AdminPowerAppEnvironmentRoleAssignment` | Analyze user permissions and access | Read-only |
| **Read Connections** | `Get-AdminPowerAppConnection` | Evaluate connector security and usage | Read-only |
| **Read Flows** | `Get-AdminFlow` | Assess flow security and configurations | Read-only |
| **Read Flow Ownership** | `Get-AdminFlowOwnerRole` | Analyze flow sharing and ownership | Read-only |

### **Azure AD Permissions (Inherited)**

| Permission | Purpose | Auto-Granted |
|------------|---------|--------------|
| **Read Users** | Analyze user access patterns | ✅ Via Power Platform role |
| **Read Groups** | Validate security group assignments | ✅ Via Power Platform role |
| **Read Service Principals** | Identify automated access | ✅ Via Power Platform role |

## Permission Verification

### **Quick Permission Check**
```powershell
# Test if you have required permissions
function Test-PowerPlatformPermissions {
    Write-Host "🔍 Testing Power Platform Permissions..." -ForegroundColor Yellow
    
    $permissions = @{
        "Environments" = $false
        "DLP Policies" = $false
        "User Roles" = $false
        "Connections" = $false
        "Flows" = $false
    }
    
    try {
        # Test environment access
        $envs = Get-AdminPowerAppEnvironment -ErrorAction Stop
        $permissions["Environments"] = $true
        Write-Host "✅ Environment Access: $($envs.Count) environments" -ForegroundColor Green
    } catch {
        Write-Host "❌ Environment Access: Failed" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
    }
    
    if ($permissions["Environments"] -and $envs.Count -gt 0) {
        $testEnv = $envs[0].EnvironmentName
        
        try {
            # Test DLP policy access
            $dlp = Get-AdminDlpPolicy -EnvironmentName $testEnv -ErrorAction Stop
            $permissions["DLP Policies"] = $true
            Write-Host "✅ DLP Policy Access: Available" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  DLP Policy Access: Limited" -ForegroundColor Yellow
        }
        
        try {
            # Test user role access
            $roles = Get-AdminPowerAppEnvironmentRoleAssignment -EnvironmentName $testEnv -ErrorAction Stop
            $permissions["User Roles"] = $true
            Write-Host "✅ User Role Access: $($roles.Count) role assignments" -ForegroundColor Green
        } catch {
            Write-Host "❌ User Role Access: Failed" -ForegroundColor Red
        }
        
        try {
            # Test connection access
            $conns = Get-AdminPowerAppConnection -EnvironmentName $testEnv -ErrorAction Stop
            $permissions["Connections"] = $true
            Write-Host "✅ Connection Access: $($conns.Count) connections" -ForegroundColor Green
        } catch {
            Write-Host "❌ Connection Access: Failed" -ForegroundColor Red
        }
        
        try {
            # Test flow access
            $flows = Get-AdminFlow -EnvironmentName $testEnv -ErrorAction Stop
            $permissions["Flows"] = $true
            Write-Host "✅ Flow Access: $($flows.Count) flows" -ForegroundColor Green
        } catch {
            Write-Host "❌ Flow Access: Failed" -ForegroundColor Red
        }
    }
    
    $requiredPermissions = @("Environments", "User Roles", "Connections", "Flows")
    $hasRequired = $requiredPermissions | Where-Object { $permissions[$_] -eq $true }
    
    if ($hasRequired.Count -eq $requiredPermissions.Count) {
        Write-Host "`n✅ All required permissions verified!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "`n❌ Missing required permissions. Contact your administrator." -ForegroundColor Red
        return $false
    }
}

# Run the permission test
Test-PowerPlatformPermissions
```

## Role Assignment Instructions

### **For Global Administrators**

1. **Assign Power Platform Administrator Role**:
   ```
   Azure AD Portal → Roles and administrators → Power Platform Administrator → Add assignments
   ```

2. **Verify Assignment**:
   - User appears in Power Platform Administrator role
   - Can access Power Platform Admin Center

### **For Users Requesting Access**

**Request Template**:
```
Subject: Power Platform Administrator Access for Security Assessment

Hi [Admin Team],

I need Power Platform Administrator role to run security assessments on our Power Platform environments.

Purpose: Security compliance and risk assessment
Tool: Power Automate Security Assessment Tool
Access Type: Read-only analysis of environments, users, connections, and flows
Duration: [Permanent/Temporary - specify timeframe]

The tool only performs read operations and does not modify any configurations.

Required permissions:
- View all Power Platform environments
- Read DLP policies and configurations  
- Analyze user access and permissions
- Review connection and flow security

Please assign the "Power Platform Administrator" Azure AD role.

Thanks,
[Your Name]
```

## Security Considerations

### **Read-Only Access** ✅
- Tool performs **NO WRITE OPERATIONS**
- Only reads configurations and metadata
- Cannot modify environments, users, or flows
- Safe for production environments

### **Data Access Scope**
| Data Type | Access Level | Security Risk |
|-----------|--------------|---------------|
| **Environment Metadata** | Read-only | 🟢 Low |
| **User Role Assignments** | Read-only | 🟡 Medium |
| **Connection Configurations** | Read-only | 🟡 Medium |
| **Flow Definitions** | Read-only | 🟡 Medium |
| **DLP Policy Settings** | Read-only | 🟢 Low |

### **Data Handling**
- **No PII Collection**: Tool does not access personal data within flows
- **Metadata Only**: Analyzes configurations, not data content
- **Local Storage**: Reports stored locally, not transmitted externally
- **Audit Trail**: All operations logged for compliance

## Alternative Access Methods

### **Service Principal Authentication** (Enterprise)

For automated/scheduled assessments:

1. **Create Service Principal**:
   ```powershell
   # Azure CLI
   az ad sp create-for-rbac --name "PowerPlatform-SecurityAssessment"
   ```

2. **Assign Power Platform Administrator**:
   ```
   Azure AD Portal → Enterprise Applications → [Your App] → Permissions
   ```

3. **Configure Authentication**:
   ```powershell
   # Use client credentials
   $credential = New-Object System.Management.Automation.PSCredential($clientId, $clientSecret)
   Add-PowerAppsAccount -Username $credential.UserName -Password $credential.Password
   ```

### **Delegated Access** (Limited Environments)

For specific environment assessment:

1. **Environment Admin Role**: Can assess specific environments only
2. **Environment Maker Role**: Limited visibility, not recommended

## Troubleshooting Access Issues

### **Common Error Messages**

#### "Access denied to environment"
```
Cause: Insufficient permissions or environment-specific restrictions
Solution: 
1. Verify Power Platform Administrator role
2. Check environment security settings
3. Contact Global Administrator
```

#### "The user or administrator has not consented to use the application"
```
Cause: PowerShell module consent required
Solution:
1. Run: Add-PowerAppsAccount -UseDeviceAuthentication
2. Complete admin consent process
3. Retry connection
```

#### "You do not have permission to perform this action"
```
Cause: Missing specific Power Platform permissions
Solution:
1. Verify role assignment propagation (can take 15 minutes)
2. Sign out and sign back in
3. Check conditional access policies
```

### **Permission Escalation Process**

1. **Self-Service** (if available):
   - Use Privileged Identity Management (PIM)
   - Request time-limited Power Platform Administrator access

2. **IT Request Process**:
   - Submit formal access request
   - Include business justification
   - Specify temporary vs. permanent access

3. **Emergency Access**:
   - Contact Global Administrator directly
   - Explain security assessment urgency
   - Request temporary role assignment

## Compliance and Governance

### **Audit Requirements**
- Tool usage should be logged and monitored
- Regular access reviews for Power Platform Administrator role
- Document security assessment schedules and findings

### **Least Privilege Principle**
- Use Power Platform Administrator (not Global Administrator)
- Consider temporary role assignments for one-time assessments
- Remove access when no longer needed

### **Risk Management**
- Tool provides read-only security assessment
- Does not modify any Power Platform configurations
- Generates reports for security improvement
- Supports compliance and governance initiatives

## Summary

**Minimum Required Role**: Power Platform Administrator  
**Access Type**: Read-only  
**Security Risk**: Low (no write operations)  
**Business Justification**: Security compliance and risk assessment

The tool is designed to provide comprehensive security visibility while maintaining strict read-only access to ensure production environment safety.