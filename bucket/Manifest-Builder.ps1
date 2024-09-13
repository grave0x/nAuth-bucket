[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Version,

    [string]$Description,
    [string]$Homepage,
    [string]$License,
    [string]$Notes,

    [Parameter(Mandatory = $true)]
    [string]$Url64,
    [string]$Hash64,

    [string]$Url32,
    [string]$Hash32,

    [string]$UrlArm64,
    [string]$HashArm64,

    [string]$PreInstall,
    [string]$PostInstall,
    [string]$Uninstaller,

    [string[]]$Bin,
    [string[]]$EnvAddPath,
    [string[]]$Persist,

    [string]$CheckverUrl,
    [string]$CheckverRegex,

    [string]$AutoupdateUrl64,
    [string]$AutoupdateUrl32,
    [string]$AutoupdateUrlArm64,
    [string]$AutoupdateHashUrl,
    [string]$AutoupdateHashRegex,

    [switch]$NoAutoupdate,
    [switch]$Force
)

function Add-IfNotNull($obj, $key, $value) {
    if ($null -ne $value -and $value -ne '') {
        $obj | Add-Member -NotePropertyName $key -NotePropertyValue $value
    }
}

function Add-Architecture($arch, $url, $hash) {
    if ($url) {
        $archObj = @{}
        Add-IfNotNull $archObj 'url' $url
        Add-IfNotNull $archObj 'hash' $hash
        return $archObj
    }
    return $null
}

# Initialize manifest object
$manifest = @{}

# Add basic properties
Add-IfNotNull $manifest 'version' $Version
Add-IfNotNull $manifest 'description' $Description
Add-IfNotNull $manifest 'homepage' $Homepage
Add-IfNotNull $manifest 'license' $License
Add-IfNotNull $manifest 'notes' $Notes

# Add architecture
$architecture = @{}
$arch64 = Add-Architecture '64bit' $Url64 $Hash64
$arch32 = Add-Architecture '32bit' $Url32 $Hash32
$archArm64 = Add-Architecture 'arm64' $UrlArm64 $HashArm64

if ($arch64) { $architecture['64bit'] = $arch64 }
if ($arch32) { $architecture['32bit'] = $arch32 }
if ($archArm64) { $architecture['arm64'] = $archArm64 }

if ($architecture.Count -gt 0) {
    $manifest['architecture'] = $architecture
}

# Add installation scripts
Add-IfNotNull $manifest 'pre_install' $PreInstall
if ($PostInstall) {
    $manifest['post_install'] = @($PostInstall)
}
if ($Uninstaller) {
    $manifest['uninstaller'] = @{ 'script' = $Uninstaller }
}

# Add other properties
Add-IfNotNull $manifest 'bin' $Bin
if ($EnvAddPath) { $manifest['env_add_path'] = $EnvAddPath }
if ($Persist) { $manifest['persist'] = $Persist }

# Add checkver
if ($CheckverUrl -or $CheckverRegex) {
    $checkver = @{}
    Add-IfNotNull $checkver 'url' $CheckverUrl
    Add-IfNotNull $checkver 'regex' $CheckverRegex
    $manifest['checkver'] = $checkver
}

# Add autoupdate
if (-not $NoAutoupdate) {
    $autoupdate = @{}
    if ($AutoupdateUrl64 -or $AutoupdateUrl32 -or $AutoupdateUrlArm64) {
        $autoupdateArch = @{}
        if ($AutoupdateUrl64) { $autoupdateArch['64bit'] = @{ 'url' = $AutoupdateUrl64 } }
        if ($AutoupdateUrl32) { $autoupdateArch['32bit'] = @{ 'url' = $AutoupdateUrl32 } }
        if ($AutoupdateUrlArm64) { $autoupdateArch['arm64'] = @{ 'url' = $AutoupdateUrlArm64 } }
        $autoupdate['architecture'] = $autoupdateArch
    }
    if ($AutoupdateHashUrl -or $AutoupdateHashRegex) {
        $autoupdateHash = @{}
        Add-IfNotNull $autoupdateHash 'url' $AutoupdateHashUrl
        Add-IfNotNull $autoupdateHash 'regex' $AutoupdateHashRegex
        $autoupdate['hash'] = $autoupdateHash
    }
    if ($autoupdate.Count -gt 0) {
        $manifest['autoupdate'] = $autoupdate
    }
}

# Generate file name
$fileName = "$Name.json"
$filePath = Join-Path $PWD $fileName

# Check if file exists
if ((Test-Path $filePath) -and (-not $Force)) {
    Write-Error "File $fileName already exists. Use -Force to overwrite."
    exit 1
}

# Convert to JSON and save
$manifestJson = $manifest | ConvertTo-Json -Depth 5
try {
    $manifestJson | Set-Content -Path $filePath -Encoding UTF8 -ErrorAction Stop
    Write-Host "Manifest saved to $filePath"
}
catch {
    Write-Error "Failed to save manifest: $_"
    exit 1
}
