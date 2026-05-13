# RectangleWin uninstaller.
#
# Run from PowerShell:
#   iex (irm https://raw.githubusercontent.com/junegu-glitch/RectangleWin/main/uninstall.ps1)
#
# Stops the running script, removes the autostart shortcut, and deletes the
# install folder. Does NOT uninstall AutoHotkey (you may want to keep it for
# other scripts).

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$dst      = Join-Path $env:LOCALAPPDATA 'RectangleWin'
$startup  = [Environment]::GetFolderPath('Startup')
$shortcut = Join-Path $startup 'RectangleWin.lnk'

Write-Host "==> Uninstalling RectangleWin" -ForegroundColor Cyan

Get-CimInstance Win32_Process -Filter "Name = 'AutoHotkey64.exe' OR Name = 'AutoHotkey.exe'" |
    Where-Object { $_.CommandLine -match 'RectangleWin\.ahk' } |
    ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
        Write-Host "    Stopped: PID $($_.ProcessId)"
    }

if (Test-Path $shortcut) {
    Remove-Item $shortcut -Force
    Write-Host "    Removed: $shortcut"
}

if (Test-Path $dst) {
    Remove-Item $dst -Recurse -Force
    Write-Host "    Removed: $dst"
}

Write-Host ""
Write-Host "Done. AutoHotkey is left installed (it may be used by other scripts)." -ForegroundColor Green
