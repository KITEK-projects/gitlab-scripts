# ==============================
# CONFIG
# ==============================
$GitLabUrl   = "http://localhost"
$AdminToken  = "PASTE_ADMIN_TOKEN_HERE"
$UserCount   = 10

# ==============================
# HELPER: API CALL
# ==============================
function Invoke-GitLab {
    param (
        [string]$Method,
        [string]$Url,
        [object]$Body = $null,
        [string]$Token
    )

    $Headers = @{
        "PRIVATE-TOKEN" = $Token
    }

    if ($Body) {
        return Invoke-RestMethod `
            -Method $Method `
            -Uri $Url `
            -Headers $Headers `
            -Body ($Body | ConvertTo-Json -Depth 5) `
            -ContentType "application/json"
    } else {
        return Invoke-RestMethod `
            -Method $Method `
            -Uri $Url `
            -Headers $Headers
    }
}

# ==============================
# MAIN LOOP
# ==============================
for ($i = 1; $i -le $UserCount; $i++) {

    $Username = "user$i"
    $Email    = "user$i@user$i.ru"
    $Name     = "user$i@user$i.ru"
    $Password = "omsktec$i"

    Write-Host "----------------------------------------"
    Write-Host "Creating user $Username"

    # 1. Create user
    try {
        Invoke-GitLab -Method POST `
            -Url "$GitLabUrl/api/v4/users" `
            -Token $AdminToken `
            -Body @{
                email = $Email
                username = $Username
                name = $Name
                password = $Password
                skip_confirmation = $true
            }
    }
    catch {
        Write-Warning "User $Username already exists or failed"
    }

    # 2. Get user
    $User = Invoke-GitLab -Method GET `
        -Url "$GitLabUrl/api/v4/users?username=$Username" `
        -Token $AdminToken

    if (-not $User) {
        Write-Error "Failed to fetch user $Username"
        continue
    }

    $UserId = $User[0].id
    Write-Host "User ID = $UserId"

    # 3. Create PAT
    Write-Host "Creating token for $Username"
    $TokenResponse = Invoke-GitLab -Method POST `
        -Url "$GitLabUrl/api/v4/users/$UserId/personal_access_tokens" `
        -Token $AdminToken `
        -Body @{
            name = "auto-token"
            scopes = @("api")
        }

    $UserToken = $TokenResponse.token

    if (-not $UserToken) {
        Write-Error "Failed to create token for $Username"
        continue
    }

    # 4. Create project AS USER
    Write-Host "Creating project $Username as $Username"

    try {
        Invoke-GitLab -Method POST `
            -Url "$GitLabUrl/api/v4/projects" `
            -Token $UserToken `
            -Body @{
                name = $Username
                visibility = "public"
            }
    }
    catch {
        Write-Warning "Project $Username already exists or failed"
    }
}

Write-Host "`nDONE"
