$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$powershell = (Get-Command powershell.exe -ErrorAction Stop).Source

$ws = New-Object -ComObject WScript.Shell
$shortcut = $ws.CreateShortcut("$env:USERPROFILE\Desktop\Mouse Keeper.lnk")
$shortcut.TargetPath = $powershell
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$projectRoot\launch_mouse_keeper.ps1`""
$shortcut.WorkingDirectory = $projectRoot
$shortcut.Description = "Mouse Keeper"
$shortcut.Save()
Write-Host "Shortcut created on Desktop!"
