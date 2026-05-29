param(
    [switch]$NoUI
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$appScript = Join-Path $projectRoot "mouse_keeper.py"

function Show-MouseKeeperMessage {
    param(
        [string]$Message,
        [string]$Title = "Mouse Keeper"
    )

    if ($NoUI) {
        Write-Host $Message
        return
    }

    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($Message, $Title) | Out-Null
}

function Add-Candidate {
    param(
        [System.Collections.Generic.List[string]]$Candidates,
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    if ($Path -like "$env:LOCALAPPDATA\Microsoft\WindowsApps\*") {
        return
    }

    if (-not $Candidates.Contains($Path)) {
        $Candidates.Add($Path)
    }
}

function Get-PythonLauncher {
    $candidates = New-Object 'System.Collections.Generic.List[string]'

    foreach ($commandName in @("pythonw.exe", "pyw.exe", "python.exe", "py.exe")) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command -and $command.Source) {
            Add-Candidate -Candidates $candidates -Path $command.Source
        }
    }

    foreach ($root in @(
        (Join-Path $env:LOCALAPPDATA "Programs\Python"),
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)}
    )) {
        if ([string]::IsNullOrWhiteSpace($root) -or -not (Test-Path -LiteralPath $root)) {
            continue
        }

        Get-ChildItem -LiteralPath $root -Directory -Filter "Python*" -ErrorAction SilentlyContinue | ForEach-Object {
            Add-Candidate -Candidates $candidates -Path (Join-Path $_.FullName "pythonw.exe")
            Add-Candidate -Candidates $candidates -Path (Join-Path $_.FullName "python.exe")
        }
    }

    foreach ($registryPath in @(
        "HKCU:\Software\Python\PythonCore\*\InstallPath",
        "HKLM:\Software\Python\PythonCore\*\InstallPath",
        "HKLM:\Software\WOW6432Node\Python\PythonCore\*\InstallPath"
    )) {
        Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue | ForEach-Object {
            Add-Candidate -Candidates $candidates -Path $_.ExecutablePath
            Add-Candidate -Candidates $candidates -Path (Join-Path $_."(default)" "pythonw.exe")
            Add-Candidate -Candidates $candidates -Path (Join-Path $_."(default)" "python.exe")
        }
    }

    return $candidates | Select-Object -First 1
}

if (-not (Test-Path -LiteralPath $appScript)) {
    Show-MouseKeeperMessage -Message "Unable to find mouse_keeper.py in $projectRoot."
    exit 1
}

$pythonLauncher = Get-PythonLauncher

if (-not $pythonLauncher) {
    Show-MouseKeeperMessage -Message "Mouse Keeper shortcut is fixed, but Python is not installed yet. Install Python 3, then launch again."
    exit 1
}

Start-Process -FilePath $pythonLauncher `
    -ArgumentList @("`"$appScript`"") `
    -WorkingDirectory $projectRoot `
    -WindowStyle Hidden
