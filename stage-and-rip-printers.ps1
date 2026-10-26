
$ErrorActionPreference = "Stop"

$root = "C:\temp"
$install = "$root\SpoolSmith"
$archive = "$root\SpoolSmith-download.zip"
$output = "$root\Printers-$($env:COMPUTERNAME)-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"

New-Item -ItemType Directory -Force -Path $root, $install | Out-Null

# Download latest release
$release = Invoke-RestMethod "https://api.github.com/repos/spilloid/spoolsmith/releases/latest"
$asset = $release.assets | Where-Object {
    $_.name -match '^spoolsmith-v.*-windows-amd64\.zip$'
} | Select-Object -First 1

if (-not $asset) { throw "Portable Windows release not found." }

Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $archive
Expand-Archive -Path $archive -DestinationPath $install -Force

# Locate CLI
$exe = Get-ChildItem $install -Filter "spoolsmith.exe" -Recurse |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $exe) { throw "SpoolSmith executable not found." }

# Verify signature
$sig = Get-AuthenticodeSignature $exe
if ($sig.Status -ne "Valid") {
    throw "Invalid executable signature: $($sig.Status)"
}

# Export all supported printers, including drivers where possible
& $exe copy --all $output

if ($LASTEXITCODE -ne 0 -or -not (Test-Path $output)) {
    throw "Printer export failed."
}

Write-Host "Export complete: $output" -ForegroundColor Green
Get-Item $output | Select-Object FullName, Length
