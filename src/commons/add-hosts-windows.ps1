<#
Adds host entries to the Windows hosts file (`C:\Windows\System32\drivers\etc\hosts`).

Features:
- Runs elevated (relaunches with Admin privileges when needed).
- Accepts `-Entries` (string[]) or `-FromFile` (one entry per line, '#' ignored).
- Makes a timestamped backup before modifying the hosts file.
- Idempotent: compares normalized lines (collapses whitespace) and avoids duplicates.
- Supports `-WhatIf` dry-run.

Notes:
- Some systems don't have PowerShell Core (`pwsh`) installed — use the Windows PowerShell `powershell` executable instead. The script will attempt to detect `pwsh` first, then fall back to `powershell`.
- For convenience a batch wrapper `scripts\run-add-hosts-windows.bat` is provided to launch this script elevated via `powershell`.

Examples:
    # Add entries directly (use powershell.exe when pwsh isn't available)
    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\add-hosts-windows.ps1 -Entries '127.0.0.1 example.local','127.0.0.1 author.local'

    # Read entries from a file
    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\add-hosts-windows.ps1 -FromFile .\hosts-to-add.txt

    # Dry run
    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\add-hosts-windows.ps1 -FromFile .\hosts-to-add.txt -WhatIf
#>

param(
    [Parameter(ValueFromPipeline=$false,Position=0)]
    [string[]] $Entries = @(),

    [string] $FromFile,

    [switch] $WhatIf
)

function Get-PSExePath {
    $cmd = Get-Command -Name pwsh -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Path) { return $cmd.Path }
    $cmd2 = Get-Command -Name powershell -ErrorAction SilentlyContinue
    if ($cmd2 -and $cmd2.Path) { return $cmd2.Path }
    return $null
}

function Relaunch-Elevated {
    $psExe = Get-PSExePath
    if (-not $psExe) { Write-Error 'Cannot find pwsh or powershell to re-launch elevated.'; exit 1 }

    $argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$PSCommandPath)

    foreach ($k in $PSBoundParameters.Keys) {
        $v = $PSBoundParameters[$k]
        if ($v -is [System.Management.Automation.SwitchParameter]) {
            if ($v) { $argList += "-$k" }
        }
        elseif ($v -is [System.Array]) {
            foreach ($item in $v) { $argList += "-$k"; $argList += $item }
        }
        else {
            $argList += "-$k"; $argList += $v
        }
    }

    Write-Host 'Not running as Administrator — relaunching elevated...'
    Start-Process -FilePath $psExe -ArgumentList $argList -Verb RunAs -WindowStyle Normal
    exit
}

function Ensure-RunningAsAdmin {
    $current = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Relaunch-Elevated
    }
}

function Backup-HostsFile($path) {
    try {
        $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
        $bak = "$path.$ts.bak"
        Copy-Item -Path $path -Destination $bak -Force -ErrorAction Stop
        return $bak
    }
    catch {
        Write-Warning "Could not create backup of hosts file: $_"
        return $null
    }
}

function Normalize-Line($line) {
    if ($null -eq $line) { return '' }
    # Remove leading/trailing whitespace and collapse internal whitespace to single spaces
    $s = $line -replace '\s+', ' '
    return $s.Trim()
}

try {
    $hostsPath = Join-Path $env:WinDir 'System32\drivers\etc\hosts'
    if (-not (Test-Path -Path $hostsPath)) {
        Write-Error "Windows hosts file not found at expected path: $hostsPath"
        exit 2
    }

    # Collect entries
    if ($FromFile) {
        if (-not (Test-Path -Path $FromFile)) { Write-Error "FromFile '$FromFile' not found."; exit 3 }
        $raw = Get-Content -Path $FromFile -ErrorAction Stop
        $fileEntries = $raw | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not ($_ -match '^#') }
        $Entries = @($Entries + $fileEntries) | Where-Object { $_ -ne $null -and $_.Trim() -ne '' }
    }

    if (-not $Entries -or $Entries.Count -eq 0) {
        Write-Host 'No entries provided. Nothing to do.'
        exit 0
    }

    # Ensure elevated
    Ensure-RunningAsAdmin

    # Backup
    if (-not $WhatIf) {
        $bak = Backup-HostsFile $hostsPath
        if ($bak) { Write-Host "Created backup: $bak" }
    }
    else {
        Write-Host "WhatIf: would create backup of $hostsPath"
    }

    # Read existing hosts lines and build a normalized set for quick lookup
    $existing = Get-Content -Path $hostsPath -ErrorAction Stop | ForEach-Object { Normalize-Line $_ } | Where-Object { $_ -ne '' }
    $existingSet = @{}
    foreach ($l in $existing) { $existingSet[$l] = $true }

    foreach ($entry in $Entries) {
        $norm = Normalize-Line $entry
        if ($norm -eq '') { continue }
        if ($existingSet.ContainsKey($norm)) {
            Write-Host "Exists: $norm"
            continue
        }
        if ($WhatIf) {
            Write-Host "Would add: $norm"
        }
        else {
            # Append as ASCII to avoid BOM issues
            # Add-Content -Path $hostsPath -Value $norm -Encoding ascii
            [System.IO.File]::AppendAllText($hostsPath,$norm + [System.Environment]::NewLine,[System.Text.Encoding]::ASCII)
            Write-Host "Added: $norm"
            $existingSet[$norm] = $true
        }
    }

    Write-Host 'Done.'
}
catch {
    Write-Error "Error: $_"
    exit 1
}
