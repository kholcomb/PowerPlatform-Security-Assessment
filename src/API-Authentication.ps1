# API Authentication Module for Power Automate Security Assessment API
# Handles API key validation, JWT tokens, and security checks

function Test-ApiAuthentication {
    param(
        [System.Net.HttpListenerRequest]$Request
    )
    
    $authResult = @{
        IsValid = $false
        ErrorMessage = ""
        UserInfo = $null
        Permissions = @()
    }
    
    try {
        # Skip authentication if disabled
        if (-not $Global:ApiConfig.Authentication.Enabled) {
            $authResult.IsValid = $true
            $authResult.Permissions = @("read", "admin")
            return $authResult
        }
        
        # Extract authentication credentials
        $authHeader = $Request.Headers["Authorization"]
        $apiKeyHeader = $Request.Headers["X-API-Key"]
        
        if ($apiKeyHeader) {
            # API Key authentication
            $authResult = Test-ApiKeyAuthentication -ApiKey $apiKeyHeader
        }
        elseif ($authHeader) {
            # Bearer token authentication
            if ($authHeader.StartsWith("Bearer ")) {
                $token = $authHeader.Substring(7)
                $authResult = Test-JwtAuthentication -Token $token
            }
            elseif ($authHeader.StartsWith("ApiKey ")) {
                $apiKey = $authHeader.Substring(7)
                $authResult = Test-ApiKeyAuthentication -ApiKey $apiKey
            }
            else {
                $authResult.ErrorMessage = "Unsupported authentication scheme"
            }
        }
        else {
            $authResult.ErrorMessage = "Authentication required. Use X-API-Key header or Authorization: Bearer/ApiKey"
        }
        
    } catch {
        Write-ApiLog "Authentication error: $($_.Exception.Message)" "Error" "Auth"
        $authResult.ErrorMessage = "Authentication failed"
    }
    
    if ($authResult.IsValid) {
        Write-ApiLog "Authentication successful for user: $($authResult.UserInfo.Name)" "Debug" "Auth"
    } else {
        Write-ApiLog "Authentication failed: $($authResult.ErrorMessage)" "Warning" "Auth"
    }
    
    return $authResult
}

function Test-ApiKeyAuthentication {
    param([string]$ApiKey)
    
    $result = @{
        IsValid = $false
        ErrorMessage = ""
        UserInfo = $null
        Permissions = @()
    }
    
    if (-not $ApiKey) {
        $result.ErrorMessage = "API key is required"
        return $result
    }
    
    # Find matching API key in configuration
    $matchingKey = $Global:ApiConfig.Authentication.ApiKeys | Where-Object { $_.Key -eq $ApiKey }
    
    if (-not $matchingKey) {
        $result.ErrorMessage = "Invalid API key"
        return $result
    }
    
    # Check if key has expired
    if ($matchingKey.ExpiresAt) {
        $expirationDate = [DateTime]::Parse($matchingKey.ExpiresAt)
        if ((Get-Date) -gt $expirationDate) {
            $result.ErrorMessage = "API key has expired"
            return $result
        }
    }
    
    # Authentication successful
    $result.IsValid = $true
    $result.UserInfo = @{
        Name = $matchingKey.Name
        Description = $matchingKey.Description
        Created = $matchingKey.Created
        Type = "ApiKey"
    }
    $result.Permissions = $matchingKey.Permissions
    
    return $result
}

function Test-JwtAuthentication {
    param([string]$Token)
    
    $result = @{
        IsValid = $false
        ErrorMessage = ""
        UserInfo = $null
        Permissions = @()
    }
    
    if (-not $Token) {
        $result.ErrorMessage = "JWT token is required"
        return $result
    }
    
    try {
        # For production, use a proper JWT library
        # This is a simplified implementation for demonstration
        $tokenParts = $Token.Split('.')
        
        if ($tokenParts.Length -ne 3) {
            $result.ErrorMessage = "Invalid JWT token format"
            return $result
        }
        
        # Decode payload (in production, verify signature first)
        $payload = $tokenParts[1]
        
        # Add padding if needed for base64 decoding
        while ($payload.Length % 4 -ne 0) {
            $payload += '='
        }
        
        $payloadBytes = [System.Convert]::FromBase64String($payload.Replace('-', '+').Replace('_', '/'))
        $payloadJson = [System.Text.Encoding]::UTF8.GetString($payloadBytes)
        $payloadData = $payloadJson | ConvertFrom-Json
        
        # Check expiration
        if ($payloadData.exp) {
            $expiration = [DateTimeOffset]::FromUnixTimeSeconds($payloadData.exp).DateTime
            if ((Get-Date) -gt $expiration) {
                $result.ErrorMessage = "JWT token has expired"
                return $result
            }
        }
        
        # Authentication successful
        $result.IsValid = $true
        $result.UserInfo = @{
            Name = $payloadData.name ?? $payloadData.sub ?? "JWT User"
            Email = $payloadData.email ?? ""
            Subject = $payloadData.sub ?? ""
            Type = "JWT"
        }
        $result.Permissions = $payloadData.permissions ?? @("read")
        
    } catch {
        $result.ErrorMessage = "Invalid JWT token: $($_.Exception.Message)"
    }
    
    return $result
}

function Test-ApiPermission {
    param(
        [array]$UserPermissions,
        [string]$RequiredPermission
    )
    
    if (-not $RequiredPermission) {
        return $true
    }
    
    if ($UserPermissions -contains "admin") {
        return $true
    }
    
    return $UserPermissions -contains $RequiredPermission
}

function New-JwtToken {
    param(
        [string]$Subject,
        [string]$Name,
        [string]$Email,
        [array]$Permissions = @("read"),
        [int]$ExpirationMinutes = $null
    )
    
    if (-not $ExpirationMinutes) {
        $ExpirationMinutes = $Global:ApiConfig.Authentication.TokenExpirationMinutes
    }
    
    $header = @{
        typ = "JWT"
        alg = "HS256"
    } | ConvertTo-Json -Compress
    
    $payload = @{
        sub = $Subject
        name = $Name
        email = $Email
        permissions = $Permissions
        iat = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        exp = [DateTimeOffset]::UtcNow.AddMinutes($ExpirationMinutes).ToUnixTimeSeconds()
        iss = "PowerAutomate-SecurityAPI"
    } | ConvertTo-Json -Compress
    
    $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
    $payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
    
    $headerBase64 = [System.Convert]::ToBase64String($headerBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
    $payloadBase64 = [System.Convert]::ToBase64String($payloadBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
    
    $signature = New-JwtSignature -Data "$headerBase64.$payloadBase64"
    
    return "$headerBase64.$payloadBase64.$signature"
}

function New-JwtSignature {
    param([string]$Data)
    
    $secretBytes = [System.Text.Encoding]::UTF8.GetBytes($Global:ApiConfig.Authentication.JwtSecret)
    $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($Data)
    
    $hmac = New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList $secretBytes
    $hashBytes = $hmac.ComputeHash($dataBytes)
    
    return [System.Convert]::ToBase64String($hashBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

function New-ApiKey {
    param(
        [string]$Name,
        [string]$Description = "",
        [array]$Permissions = @("read"),
        [DateTime]$ExpiresAt = $null
    )
    
    # Generate a secure API key
    $keyBytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($keyBytes)
    $apiKey = [System.Convert]::ToBase64String($keyBytes).Replace('+', '-').Replace('/', '_').TrimEnd('=')
    
    $newKey = @{
        Key = $apiKey
        Name = $Name
        Description = $Description
        Permissions = $Permissions
        Created = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        ExpiresAt = if ($ExpiresAt) { $ExpiresAt.ToString("yyyy-MM-ddTHH:mm:ssZ") } else { $null }
    }
    
    return $newKey
}

function Add-ApiKey {
    param(
        [string]$Name,
        [string]$Description = "",
        [array]$Permissions = @("read"),
        [DateTime]$ExpiresAt = $null,
        [string]$ConfigPath = "API-Config.json"
    )
    
    $newKey = New-ApiKey -Name $Name -Description $Description -Permissions $Permissions -ExpiresAt $ExpiresAt
    
    # Load current configuration
    $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
    
    # Add new key
    $config.Authentication.ApiKeys += $newKey
    
    # Save configuration
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding UTF8
    
    Write-ApiLog "New API key created: $($newKey.Name)" "Info" "Auth"
    Write-ApiLog "API Key: $($newKey.Key)" "Info" "Auth"
    
    return $newKey
}

function Remove-ApiKey {
    param(
        [string]$ApiKey,
        [string]$ConfigPath = "API-Config.json"
    )
    
    # Load current configuration
    $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
    
    # Remove the key
    $config.Authentication.ApiKeys = $config.Authentication.ApiKeys | Where-Object { $_.Key -ne $ApiKey }
    
    # Save configuration
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding UTF8
    
    Write-ApiLog "API key removed" "Info" "Auth"
}

function Get-ApiKeyInfo {
    param([string]$ApiKey)
    
    $matchingKey = $Global:ApiConfig.Authentication.ApiKeys | Where-Object { $_.Key -eq $ApiKey }
    
    if ($matchingKey) {
        return @{
            Name = $matchingKey.Name
            Description = $matchingKey.Description
            Permissions = $matchingKey.Permissions
            Created = $matchingKey.Created
            ExpiresAt = $matchingKey.ExpiresAt
            IsExpired = if ($matchingKey.ExpiresAt) { (Get-Date) -gt [DateTime]::Parse($matchingKey.ExpiresAt) } else { $false }
        }
    }
    
    return $null
}

function Test-SecureConnection {
    param([System.Net.HttpListenerRequest]$Request)
    
    # Check if HTTPS is required
    if ($Global:ApiConfig.Security.EnableHttps -and -not $Request.IsSecureConnection) {
        return @{
            IsSecure = $false
            ErrorMessage = "HTTPS connection required"
        }
    }
    
    # Check trusted proxies
    if ($Global:ApiConfig.Security.TrustedProxies.Count -gt 0) {
        $clientIp = $Request.RemoteEndPoint.Address.ToString()
        $forwardedFor = $Request.Headers["X-Forwarded-For"]
        
        if ($forwardedFor) {
            $originalIp = $forwardedFor.Split(',')[0].Trim()
            # In production, verify the proxy is trusted before using X-Forwarded-For
        }
    }
    
    return @{
        IsSecure = $true
        ErrorMessage = ""
    }
}

# Export functions for use in main API module
Export-ModuleMember -Function @(
    'Test-ApiAuthentication',
    'Test-ApiKeyAuthentication', 
    'Test-JwtAuthentication',
    'Test-ApiPermission',
    'New-JwtToken',
    'New-ApiKey',
    'Add-ApiKey',
    'Remove-ApiKey',
    'Get-ApiKeyInfo',
    'Test-SecureConnection'
)