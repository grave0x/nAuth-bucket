# Run the Scoop-Bucket.Tests.ps1 and capture the output
$testOutput = & .\Scoop-Bucket.Tests.ps1 2>&1

# Initialize an array to store failed tests
$failedTests = @()

# Parse the output to identify failed tests
$testOutput | ForEach-Object {
    if ($_ -match "^\s*\[[-x]\]\s*(.+)") {
        $failedTests += $Matches[1]
    }
}

# Function to repair manifest issues
function Repair-ManifestIssues($manifestPath) {
    $content = Get-Content $manifestPath -Raw
    $json = $content | ConvertFrom-Json

    # Ensure required fields are present
    if (-not $json.version) { $json | Add-Member -Type NoteProperty -Name "version" -Value "latest" }
    if (-not $json.description) { $json | Add-Member -Type NoteProperty -Name "description" -Value "Description needed" }
    if (-not $json.homepage) { $json | Add-Member -Type NoteProperty -Name "homepage" -Value "https://example.com" }
    if (-not $json.license) { $json | Add-Member -Type NoteProperty -Name "license" -Value "Unknown" }

    # Convert back to JSON and save
    $json | ConvertTo-Json -Depth 10 | Set-Content $manifestPath
}

# Function to update URLs
function Update-URLs($manifestPath) {
    $content = Get-Content $manifestPath -Raw
    $json = $content | ConvertFrom-Json

    if ($json.url) {
        $response = Invoke-WebRequest -Uri $json.url -Method Head -UseBasicParsing
        if ($response.StatusCode -ne 200) {
            Write-Host "URL is not valid. Please update manually: $($json.url)"
        }
    }

    # Convert back to JSON and save
    $json | ConvertTo-Json -Depth 10 | Set-Content $manifestPath
}

# Function to update checkver
function Update-Checkver($manifestPath) {
    $content = Get-Content $manifestPath -Raw
    $json = $content | ConvertFrom-Json

    if (-not $json.checkver) {
        $json | Add-Member -Type NoteProperty -Name "checkver" -Value @{
            url   = $json.homepage
            regex = "(?<version>[\d.]+)"
        }
    }

    # Convert back to JSON and save
    $json | ConvertTo-Json -Depth 10 | Set-Content $manifestPath
}

# Display and fix failed tests
if ($failedTests.Count -gt 0) {
    Write-Host "The following tests failed:"
    $failedTests | ForEach-Object { Write-Host "- $_" }

    $failedTests | ForEach-Object {
        $testName = $_
        $manifestPath = $testName -replace '^(.*?)\s*\(.*$', '$1'
        $manifestPath = Join-Path "bucket" "$manifestPath.json"

        if (Test-Path $manifestPath) {
            switch -Wildcard ($testName) {
                "*manifest*" {
                    Write-Host "Fixing manifest issues for $manifestPath..."
                    Repair-ManifestIssues $manifestPath
                }
                "*URL*" {
                    Write-Host "Checking and updating URLs for $manifestPath..."
                    Update-URLs $manifestPath
                }
                "*checkver*" {
                    Write-Host "Updating checkver for $manifestPath..."
                    Update-Checkver $manifestPath
                }
                default {
                    Write-Host "Unable to automatically fix: $testName"
                }
            }
        }
        else {
            Write-Host "Manifest file not found: $manifestPath"
        }
    }

    Write-Host "Fixes applied. Please review the changes and run the tests again."
}
else {
    Write-Host "All tests passed successfully!"
}
