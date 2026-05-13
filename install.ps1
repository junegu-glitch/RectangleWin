# RectangleWin one-line installer.
#
# Run from PowerShell:
#   iex (irm https://raw.githubusercontent.com/junegu-glitch/RectangleWin/main/install.ps1)
#
# Installs AutoHotkey v2 (via winget) if missing, downloads RectangleWin.ahk
# to %LOCALAPPDATA%\RectangleWin, registers it for autostart, and launches it.
# No admin required.

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$repo     = 'junegu-glitch/RectangleWin'
$dst      = Join-Path $env:LOCALAPPDATA 'RectangleWin'
$ahkPath  = Join-Path $dst 'RectangleWin.ahk'
$startup  = [Environment]::GetFolderPath('Startup')
$shortcut = Join-Path $startup 'RectangleWin.lnk'

Write-Host ""
Write-Host "==> Installing RectangleWin" -ForegroundColor Cyan

# 1. Find or install AutoHotkey v2
function Find-AutoHotkey {
    $candidates = @(
        (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'),
        (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'AutoHotkey\v2\AutoHotkey64.exe')
    )
    foreach ($p in $candidates) { if ($p -and (Test-Path $p)) { return $p } }
    return $null
}

$ahk = Find-AutoHotkey
if (-not $ahk) {
    Write-Host "    AutoHotkey v2 not found. Installing via winget..."
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw "winget not available. Install AutoHotkey v2 manually from https://www.autohotkey.com/ and re-run this installer."
    }
    & winget install --id AutoHotkey.AutoHotkey -e --accept-package-agreements --accept-source-agreements --silent | Out-Null
    $ahk = Find-AutoHotkey
    if (-not $ahk) { throw "AutoHotkey v2 install did not complete. Try installing manually from https://www.autohotkey.com/" }
}
Write-Host "    AutoHotkey: $ahk"

# 2. Download the latest RectangleWin.ahk
New-Item -ItemType Directory -Force -Path $dst | Out-Null
$url = "https://raw.githubusercontent.com/$repo/main/RectangleWin.ahk"
try {
    Invoke-WebRequest -Uri $url -OutFile $ahkPath -UseBasicParsing
} catch {
    throw "Failed to download $url : $_"
}
Write-Host "    Script:     $ahkPath"

# 3. Register for autostart
$wsh = New-Object -ComObject WScript.Shell
$lnk = $wsh.CreateShortcut($shortcut)
$lnk.TargetPath       = $ahk
$lnk.Arguments        = "`"$ahkPath`""
$lnk.WorkingDirectory = $dst
$lnk.Description      = "RectangleWin - keyboard window snapping"
$lnk.Save()
Write-Host "    Autostart:  $shortcut"

# 4. Kill any existing RectangleWin instance and launch the fresh one
Get-CimInstance Win32_Process -Filter "Name = 'AutoHotkey64.exe' OR Name = 'AutoHotkey.exe'" |
    Where-Object { $_.CommandLine -match 'RectangleWin\.ahk' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Process -FilePath $ahk -ArgumentList "`"$ahkPath`""

Write-Host ""
Write-Host "Done. RectangleWin is running in your system tray." -ForegroundColor Green
Write-Host ""
Write-Host "Shortcuts (all use Ctrl+Win as the base modifier):"
Write-Host "  Enter             Fullscreen"
Write-Host "  Left/Right/Up/Down    Snap to half; press again for 1/3 -> 2/3"
Write-Host "  C                 Smart center (column on landscape, row on portrait)"
Write-Host "  H / V             Force center column / middle row"
Write-Host "  Numpad 7/9/1/3    Quarter corners"
Write-Host "  Shift+Arrows      Move window to monitor in that direction"
Write-Host "  Z                 Undo last snap"
Write-Host "  T                 Toggle Always-on-Top"
Write-Host ""
Write-Host "Tray icon -> 'RectangleWin - shortcuts' shows the same list."
Write-Host "To uninstall: iex (irm https://raw.githubusercontent.com/$repo/main/uninstall.ps1)"
