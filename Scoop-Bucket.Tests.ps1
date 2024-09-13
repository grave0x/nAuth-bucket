# Ensure SCOOP_HOME is set
if (!$env:SCOOP_HOME) {
    $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop)
}

# Import the Bucket-Tests script
. "$env:SCOOP_HOME\test\Import-Bucket-Tests.ps1"

# Add custom tests for your bucket
Describe "nAuth-bucket" {
    It "Contains valid manifests" {
        $manifestFiles = Get-ChildItem "$PSScriptRoot\bucket" -Filter '*.json'
        $manifestFiles | Should -Not -BeNullOrEmpty

        foreach ($file in $manifestFiles) {
            $content = Get-Content $file.FullName -Raw
            { ConvertFrom-Json $content -ErrorAction Stop } | Should -Not -Throw
        }
    }

    # Add more custom tests as needed
}
