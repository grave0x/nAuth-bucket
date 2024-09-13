if (!$env:SCOOP_HOME) { $env:SCOOP_HOME = Convert-Path (scoop prefix scoop) }
$checkhashes = "$env:SCOOP_HOME/bin/checkhashes.ps1"
$dir = Resolve-Path "$PSScriptRoot/../bucket"
if (Test-Path $dir) {
    & $checkhashes -Dir $dir @Args
}
else {
    Write-Error "Directory not found: $dir"
}
