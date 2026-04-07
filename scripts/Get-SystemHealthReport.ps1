# Get-SystemHealthReport.ps1
# Collects system health information from the local machine including
# disk usage, memory, uptime, critical services, and OS details.
# Outputs a formatted report to console and saves it to a log file.
# Usage: .\Get-SystemHealthReport.ps1

Import-Module ActiveDirectory

$LogPath  = "C:\scripts\SystemHealth_Report.txt"
$DateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Computer = $env:COMPUTERNAME

function Write-Report {
    param($Message, $Color = "White")
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $LogPath -Value $Message
}

Add-Content -Path $LogPath -Value "`n=== System Health Report: $DateTime ==="
Write-Host "`n=== System Health Report: $DateTime ===" -ForegroundColor Cyan
Write-Host "Computer: $Computer`n" -ForegroundColor Cyan

# --- OS Info ---
Write-Report "--- OS Information ---" "Cyan"
$OS = Get-CimInstance Win32_OperatingSystem
Write-Report "OS Name       : $($OS.Caption)"
Write-Report "Version       : $($OS.Version)"
Write-Report "Architecture  : $($OS.OSArchitecture)"
Write-Report "Last Boot     : $($OS.LastBootUpTime)"
$Uptime = (Get-Date) - $OS.LastBootUpTime
Write-Report "Uptime        : $($Uptime.Days)d $($Uptime.Hours)h $($Uptime.Minutes)m"

# --- Memory ---
Write-Report "`n--- Memory ---" "Cyan"
$TotalRAM = [math]::Round($OS.TotalVisibleMemorySize / 1MB, 2)
$FreeRAM  = [math]::Round($OS.FreePhysicalMemory / 1MB, 2)
$UsedRAM  = [math]::Round($TotalRAM - $FreeRAM, 2)
$RAMPct   = [math]::Round(($UsedRAM / $TotalRAM) * 100, 1)
Write-Report "Total RAM     : $TotalRAM GB"
Write-Report "Used RAM      : $UsedRAM GB ($RAMPct% used)"
Write-Report "Free RAM      : $FreeRAM GB"

if ($RAMPct -gt 85) {
    Write-Report "WARNING: Memory usage is high!" "Red"
}

# --- Disk Usage ---
Write-Report "`n--- Disk Usage ---" "Cyan"
$Disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
foreach ($Disk in $Disks) {
    $TotalGB = [math]::Round($Disk.Size / 1GB, 2)
    $FreeGB  = [math]::Round($Disk.FreeSpace / 1GB, 2)
    $UsedGB  = [math]::Round($TotalGB - $FreeGB, 2)
    $UsedPct = [math]::Round(($UsedGB / $TotalGB) * 100, 1)
    Write-Report "Drive $($Disk.DeviceID)  Total: $TotalGB GB | Used: $UsedGB GB | Free: $FreeGB GB | $UsedPct% used"
    if ($UsedPct -gt 85) {
        Write-Report "WARNING: Drive $($Disk.DeviceID) is running low on space!" "Red"
    }
}

# --- Critical Services ---
Write-Report "`n--- Critical Services ---" "Cyan"
$Services = @(
    "ADWS",       # Active Directory Web Services
    "DNS",        # DNS Server
    "Netlogon",   # Net Logon
    "NTDS",       # AD Domain Services
    "W32Time"     # Windows Time
)
foreach ($Svc in $Services) {
    $Status = Get-Service -Name $Svc -ErrorAction SilentlyContinue
    if ($Status.Status -eq "Running") {
        Write-Report "  [RUNNING] $Svc" "Green"
    } else {
        Write-Report "  [STOPPED] $Svc -- ATTENTION REQUIRED" "Red"
    }
}

# --- AD Summary ---
Write-Report "`n--- Active Directory Summary ---" "Cyan"
$TotalUsers    = (Get-ADUser -Filter *).Count
$EnabledUsers  = (Get-ADUser -Filter {Enabled -eq $true}).Count
$DisabledUsers = (Get-ADUser -Filter {Enabled -eq $false}).Count
$LockedUsers   = (Search-ADAccount -LockedOut | Where-Object {$_.ObjectClass -eq "user"}).Count
$TotalGroups   = (Get-ADGroup -Filter *).Count
$TotalComputers = (Get-ADComputer -Filter *).Count

Write-Report "Total Users   : $TotalUsers"
Write-Report "Enabled       : $EnabledUsers"
Write-Report "Disabled      : $DisabledUsers"
Write-Report "Locked Out    : $LockedUsers"
Write-Report "Total Groups  : $TotalGroups"
Write-Report "Total Computers: $TotalComputers"

Write-Report "`n=== End of Report ===" "Cyan"
Write-Host "`nReport saved to $LogPath`n" -ForegroundColor Cyan
