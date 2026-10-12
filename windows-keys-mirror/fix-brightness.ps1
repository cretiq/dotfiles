<#
.SYNOPSIS
    Restart DisplayEnhancementService (workaround for stuck-after-wake brightness).

.DESCRIPTION
    Mirrors the proven manual flow: taskkill /F /PID, then Start-Service.
    No graceful stop -- handler cleanup can preserve the broken state.
    Transcript at $env:TEMP\fixbright.log.
    -Install registers a scheduled task to do the same on every wake.
#>

[CmdletBinding(DefaultParameterSetName = 'Fix')]
param(
    [Parameter(ParameterSetName = 'Install')]   [switch]$Install,
    [Parameter(ParameterSetName = 'Uninstall')] [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
$ServiceName = 'DisplayEnhancementService'
$TaskName    = 'Fix Brightness After Wake'
$LogPath     = Join-Path $env:TEMP 'fixbright.log'

try { Start-Transcript -Path $LogPath -Append | Out-Null } catch { }
function Log { param([string]$m) Write-Host ("[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss.fff'), $m) }

Log "==== fixbright | user=$env:USERNAME PSVer=$($PSVersionTable.PSVersion) set=$($PSCmdlet.ParameterSetName) ===="

$id = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not ([Security.Principal.WindowsPrincipal]::new($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Log "ERR not admin"
    try { Stop-Transcript | Out-Null } catch { }
    exit 1
}

function Restart-Svc {
    $pre = Get-CimInstance Win32_Service -Filter "Name='$ServiceName'"
    Log "PRE  state=$($pre.State) pid=$($pre.ProcessId)"
    if ($pre.ProcessId -gt 0) {
        & taskkill /F /PID $pre.ProcessId | ForEach-Object { Log "  $_" }
    } else {
        Log "  no pid -- service already stopped"
    }
    Start-Service $ServiceName
    Start-Sleep -Milliseconds 500
    $post = Get-CimInstance Win32_Service -Filter "Name='$ServiceName'"
    Log "POST state=$($post.State) pid=$($post.ProcessId)"
}

function Install-Task {
    # Wake task uses same taskkill flow.
    $cmd = "`$p=(Get-CimInstance Win32_Service -Filter \`"Name='$ServiceName'\`").ProcessId; if (`$p -gt 0) { taskkill /F /PID `$p }; Start-Service $ServiceName"
    $tr  = "powershell.exe -NoProfile -WindowStyle Hidden -Command `"$cmd`""
    $f   = "*[System[Provider[@Name='Microsoft-Windows-Power-Troubleshooter'] and EventID=1]]"
    schtasks /Create /TN $TaskName /TR $tr /SC ONEVENT /EC System /MO $f /RU SYSTEM /RL HIGHEST /F | Out-Null
    if ($LASTEXITCODE -eq 0) { Log "task installed" } else { Log "ERR schtasks /Create exit=$LASTEXITCODE" }
}

function Uninstall-Task {
    schtasks /Delete /TN $TaskName /F | Out-Null
    Log "task removed (exit=$LASTEXITCODE)"
}

try {
    switch ($PSCmdlet.ParameterSetName) {
        'Install'   { Install-Task }
        'Uninstall' { Uninstall-Task }
        default     { Restart-Svc }
    }
} catch {
    Log "EXC $($_.Exception.Message)"
    Log "    $($_.ScriptStackTrace)"
} finally {
    Log "==== end | log=$LogPath ===="
    try { Stop-Transcript | Out-Null } catch { }
}
