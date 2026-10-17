[CmdletBinding()]
param(
    [string]$Godot = 'godot',
    [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?$')]
    [string]$Version = '0.1.0-dev'
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedVersion = (Get-Content (Join-Path $projectRoot '.godot-version') -Raw).Trim()
$actualVersion = (& $Godot --version | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or !$actualVersion.StartsWith("$expectedVersion.stable.")) {
    throw "Expected Godot $expectedVersion stable; got $actualVersion"
}

function Invoke-GodotChecked([string[]]$Arguments, [string]$LogName) {
    $log = Join-Path $outputDirectory $LogName
    & $Godot @Arguments 2>&1 | Tee-Object -FilePath $log | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "Godot failed; see $log" }
    if (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|ERROR:|Parse Error:' -Quiet) {
        throw "Godot reported errors; see $log"
    }
}

$outputDirectory = Join-Path $projectRoot "exports/$Version"
$packageName = "Ironworks-$Version-windows-x86_64"
$packageDirectory = Join-Path $outputDirectory $packageName
# A fresh staging directory avoids stale files without deleting earlier builds.
if (Test-Path -LiteralPath $packageDirectory) {
    throw "Build already exists: $packageDirectory. Choose a new version or move the previous build."
}
New-Item -ItemType Directory -Path $packageDirectory -Force | Out-Null
Set-Content -LiteralPath (Join-Path $projectRoot 'exports/.gdignore') -Value ''
Invoke-GodotChecked @('--headless', '--path', $projectRoot, '--editor', '--import') 'import.log'
Invoke-GodotChecked @('--headless', '--path', $projectRoot, '--script', 'res://verify_factory.gd') 'verification.log'
if (!(Select-String -LiteralPath (Join-Path $outputDirectory 'verification.log') -Pattern 'Factory verification: \d+ checks, 0 failures' -Quiet)) {
    throw 'Integration checks did not finish successfully'
}
$executable = Join-Path $packageDirectory 'Ironworks.exe'
Invoke-GodotChecked @('--headless', '--path', $projectRoot, '--export-release', 'Windows Desktop', $executable) 'export.log'
if (!(Test-Path -LiteralPath $executable) -or !(Test-Path -LiteralPath (Join-Path $packageDirectory 'Ironworks.pck'))) {
    throw 'Export did not produce the executable and game pack'
}
Push-Location $packageDirectory
try {
    $runtimeLog = Join-Path $outputDirectory 'runtime-smoke.log'
    $process = Start-Process -FilePath $executable -ArgumentList '--headless', '--quit-after', '30', '--log-file', ("`"" + $runtimeLog + "`"") -PassThru -WindowStyle Hidden
    if (!$process.WaitForExit(60000)) { $process.Kill(); throw 'Exported game smoke check timed out' }
    if ($process.ExitCode -ne 0) { throw "Exported game exited with code $($process.ExitCode)" }
    if (!(Test-Path -LiteralPath $runtimeLog)) { throw 'Exported runtime did not write its startup log' }
    if (Select-String -LiteralPath $runtimeLog -Pattern 'SCRIPT ERROR:|ERROR:|Parse Error:' -Quiet) { throw 'Exported runtime reported errors' }
} finally { Pop-Location }
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/PLAYER-README.txt') -Destination (Join-Path $packageDirectory 'README.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'MUSIC-CREDITS.txt') -Destination (Join-Path $packageDirectory 'MUSIC-CREDITS.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/audio/licensed/CC0-1.0.txt') -Destination (Join-Path $packageDirectory 'CC0-1.0.txt')
$commit = (& git -C $projectRoot rev-parse HEAD | Out-String).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Could not resolve source commit' }
@{ version = $Version; godot = $actualVersion; commit = $commit; platform = 'windows-x86_64' } |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $packageDirectory 'build-info.json') -Encoding utf8
$zipPath = Join-Path $outputDirectory "$packageName.zip"
Add-Type -AssemblyName System.IO.Compression.FileSystem
# Windows security scanning can briefly retain a lock after executable startup.
for ($attempt = 1; $attempt -le 5; $attempt++) {
    try {
        if (Test-Path -LiteralPath $zipPath) { [IO.File]::Delete($zipPath) }
        [IO.Compression.ZipFile]::CreateFromDirectory($packageDirectory, $zipPath, [IO.Compression.CompressionLevel]::Optimal, $true)
        break
    } catch [IO.IOException] {
        if ($attempt -eq 5) { throw }
        Start-Sleep -Seconds 2
    }
}
$hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  $packageName.zip" | Set-Content -LiteralPath (Join-Path $outputDirectory 'SHA256SUMS.txt') -Encoding ascii
Write-Host "Release package: $zipPath"