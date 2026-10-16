[CmdletBinding()]
param([string]$InstallDirectory = (Join-Path $env:TEMP 'factory-game-godot'))

$ErrorActionPreference = 'Stop'
$version = (Get-Content (Join-Path $PSScriptRoot '../.godot-version') -Raw).Trim()
$baseUrl = "https://github.com/godotengine/godot-builds/releases/download/$version-stable"
$destination = Join-Path $InstallDirectory $version
$templateDirectory = Join-Path $env:APPDATA "Godot/export_templates/$version.stable"
New-Item -ItemType Directory -Path $destination -Force | Out-Null

function Get-VerifiedDownload([string]$Name, [string[]]$Checksums) {
    $path = Join-Path $destination $Name
    $line = @($Checksums | Where-Object { ($_ -split '\s+')[-1].TrimStart('*') -eq $Name })
    if ($line.Count -ne 1) { throw "No unique official checksum for $Name" }
    $expected = ($line[0] -split '\s+')[0]
    if (!(Test-Path -LiteralPath $path) -or (Get-FileHash -LiteralPath $path -Algorithm SHA512).Hash -ne $expected) {
        Write-Host "Downloading $Name"
        & curl.exe --fail --location --retry 3 --silent --show-error "$baseUrl/$Name" --output $path
        if ($LASTEXITCODE -ne 0) { throw "Download failed: $Name" }
    }
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA512).Hash -ne $expected) {
        throw "Checksum mismatch: $Name"
    }
    return $path
}

$checksumsPath = Join-Path $destination 'SHA512-SUMS.txt'
& curl.exe --fail --location --retry 3 --silent --show-error "$baseUrl/SHA512-SUMS.txt" --output $checksumsPath
if ($LASTEXITCODE -ne 0) { throw 'Could not download official checksums' }
$checksums = Get-Content -LiteralPath $checksumsPath
$editorArchive = Get-VerifiedDownload "Godot_v$version-stable_win64.exe.zip" $checksums
Expand-Archive -LiteralPath $editorArchive -DestinationPath $destination -Force

# Reuse a completed installation: the official template archive is large.
if (!(Test-Path -LiteralPath (Join-Path $templateDirectory '.factory-game-installed'))) {
    $templatesArchive = Get-VerifiedDownload "Godot_v$version-stable_export_templates.tpz" $checksums
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($templatesArchive)
    try {
        New-Item -ItemType Directory -Path $templateDirectory -Force | Out-Null
        foreach ($entry in $archive.Entries) {
            if ($entry.FullName -notmatch '^templates/(windows_[^/]+|d3d12/.*|angle/.*)$' -or !$entry.Name) { continue }
            $relativePath = $entry.FullName.Substring('templates/'.Length)
            $target = Join-Path $templateDirectory $relativePath
            New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $target, $true)
        }
    } finally { $archive.Dispose() }
    if (!(Test-Path -LiteralPath (Join-Path $templateDirectory 'windows_release_x86_64.exe'))) {
        throw 'Windows release template is missing after extraction'
    }
    Set-Content -LiteralPath (Join-Path $templateDirectory '.factory-game-installed') -Value $version
}

$executable = Join-Path $destination "Godot_v$version-stable_win64_console.exe"
if (!(Test-Path -LiteralPath $executable)) { throw "Godot executable missing: $executable" }
Write-Host "Godot installed: $executable"
if ($env:GITHUB_ENV) { "GODOT_BIN=$executable" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append }