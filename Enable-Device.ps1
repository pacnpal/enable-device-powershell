#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enables a Windows device by its friendly name at boot.

.DESCRIPTION
    Uses Get-PnpDevice to find a device by friendly name and enables it
    if it's currently disabled. Intended to run via Task Scheduler at startup.

.PARAMETER DeviceName
    The friendly name of the device as shown in Device Manager.
    Supports wildcards (e.g. "Realtek*Ethernet*").

.PARAMETER Delay
    Seconds to wait before attempting to enable (default: 10).
    Gives the system time to fully initialize devices after boot.

.PARAMETER Retries
    Number of retry attempts if the device isn't found yet (default: 3).

.PARAMETER RetryInterval
    Seconds between retries (default: 5).

.EXAMPLE
    .\Enable-Device.ps1 -DeviceName "Intel(R) Wi-Fi 6 AX201 160MHz"
.EXAMPLE
    .\Enable-Device.ps1 -DeviceName "Realtek*Ethernet*" -Delay 15 -Retries 5
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$DeviceName,

    [int]$Delay = 10,
    [int]$Retries = 3,
    [int]$RetryInterval = 5
)

# --- Logging ---
$LogDir = "$env:ProgramData\EnableDevice"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
$LogFile = Join-Path $LogDir "enable-device.log"

function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$ts] $Message"
    Write-Output $entry
    Add-Content -Path $LogFile -Value $entry
}

# --- Main ---
Write-Log "Script started. Target device: '$DeviceName'"
Write-Log "Waiting $Delay seconds for system initialization..."
Start-Sleep -Seconds $Delay

$attempt = 0
$device = $null

while ($attempt -lt $Retries) {
    $attempt++
    Write-Log "Attempt $attempt of $Retries - searching for device..."

    $device = Get-PnpDevice -FriendlyName $DeviceName -ErrorAction SilentlyContinue

    if ($device) {
        break
    }

    if ($attempt -lt $Retries) {
        Write-Log "Device not found. Retrying in $RetryInterval seconds..."
        Start-Sleep -Seconds $RetryInterval
    }
}

if (-not $device) {
    Write-Log "ERROR: Device '$DeviceName' not found after $Retries attempts. Exiting."
    exit 1
}

# Handle multiple matches
if (@($device).Count -gt 1) {
    Write-Log "WARNING: Found $(@($device).Count) devices matching '$DeviceName'. Operating on all matches."
}

foreach ($dev in @($device)) {
    $id = $dev.InstanceId
    $name = $dev.FriendlyName
    $status = $dev.Status

    if ($dev.Status -eq 'OK') {
        Write-Log "Device '$name' [$id] is already enabled (Status: $status). Skipping."
        continue
    }

    Write-Log "Enabling device '$name' [$id] (Current status: $status)..."

    try {
        Enable-PnpDevice -InstanceId $id -Confirm:$false -ErrorAction Stop
        Write-Log "SUCCESS: Device '$name' enabled."
    }
    catch {
        Write-Log "ERROR: Failed to enable '$name' - $($_.Exception.Message)"
    }
}

Write-Log "Script finished."
