[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ServerInstance,

    [Parameter(Mandatory)]
    [string]$Database,

    [Parameter(Mandatory)]
    [string]$AdminGroup,

    [Parameter(Mandatory)]
    [Guid]$AdminObjectId,

    [Parameter(Mandatory)]
    [string]$MigrationGroup,

    [Parameter(Mandatory)]
    [Guid]$MigrationObjectId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Escape-SqlIdentifier {
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    return $Value.Replace(']', ']]')
}

function Escape-SqlString {
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    return $Value.Replace("'", "''")
}

Write-Host "Authenticating with the Container Apps Job managed identity."

Connect-AzAccount `
    -Identity `
    -Environment AzureCloud `
    -ErrorAction Stop | Out-Null

$accessToken = (Get-AzAccessToken `
    -ResourceUrl 'https://database.windows.net/' `
    -ErrorAction Stop).Token

if ([string]::IsNullOrWhiteSpace($accessToken)) {
    throw 'Azure SQL access token could not be acquired.'
}

$escapedAdminGroup = Escape-SqlIdentifier $AdminGroup
$escapedMigrationGroup = Escape-SqlIdentifier $MigrationGroup

$sqlAdminGroup = Escape-SqlString $AdminGroup
$sqlMigrationGroup = Escape-SqlString $MigrationGroup

$query = @"
IF NOT EXISTS (
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'$sqlAdminGroup'
)
BEGIN
    CREATE USER [$escapedAdminGroup]
        FROM EXTERNAL PROVIDER
        WITH OBJECT_ID = '$AdminObjectId';
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members drm
    INNER JOIN sys.database_principals role_principal
        ON role_principal.principal_id = drm.role_principal_id
    INNER JOIN sys.database_principals member_principal
        ON member_principal.principal_id = drm.member_principal_id
    WHERE role_principal.name = N'db_owner'
      AND member_principal.name = N'$sqlAdminGroup'
)
BEGIN
    ALTER ROLE [db_owner]
        ADD MEMBER [$escapedAdminGroup];
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'$sqlMigrationGroup'
)
BEGIN
    CREATE USER [$escapedMigrationGroup]
        FROM EXTERNAL PROVIDER
        WITH OBJECT_ID = '$MigrationObjectId';
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members drm
    INNER JOIN sys.database_principals role_principal
        ON role_principal.principal_id = drm.role_principal_id
    INNER JOIN sys.database_principals member_principal
        ON member_principal.principal_id = drm.member_principal_id
    WHERE role_principal.name = N'db_ddladmin'
      AND member_principal.name = N'$sqlMigrationGroup'
)
BEGIN
    ALTER ROLE [db_ddladmin]
        ADD MEMBER [$escapedMigrationGroup];
END;
"@

Write-Host "Establishing SQL principals in '$Database' on '$ServerInstance'."

Invoke-Sqlcmd `
    -ServerInstance $ServerInstance `
    -Database $Database `
    -AccessToken $accessToken `
    -Query $query

Write-Host 'SQL principals established successfully.'