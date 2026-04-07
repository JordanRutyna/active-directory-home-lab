# Get-LockedAccounts.ps1
# Queries Active Directory for all currently locked user accounts.
# Outputs a formatted report to the console and saves it to a log file.
# Usage: .\Get-LockedAccounts.ps1
# Alternate built-in command: Search-ADAccount -LockedOut

Import-Module ActiveDirectory

$LogPath  = "C:\scripts\LockedAccounts_Report.txt"
$DateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "`n=== Locked Account Audit: $DateTime ===" -ForegroundColor Cyan
Add-Content -Path $LogPath -Value "`n=== Locked Account Audit: $DateTime ==="

$LockedAccounts = Search-ADAccount -LockedOut | Where-Object { $_.ObjectClass -eq "user" }

if ($LockedAccounts.Count -eq 0) {
    $Msg = "No locked accounts found."
    Write-Host $Msg -ForegroundColor Green
    Add-Content -Path $LogPath -Value $Msg

} else {
    Write-Host "Found $($LockedAccounts.Count) locked account(s):`n" -ForegroundColor Yellow

    foreach ($Account in $LockedAccounts) {

        $Details = Get-ADUser -Identity $Account.SamAccountName -Properties `
            LockedOut, BadLogonCount, LastBadPasswordAttempt, PasswordLastSet, Department

        $Report = @"
Username         : $($Details.SamAccountName)
Full Name        : $($Details.Name)
Department       : $($Details.Department)
Bad Logon Count  : $($Details.BadLogonCount)
Last Bad Attempt : $($Details.LastBadPasswordAttempt)
Password Last Set: $($Details.PasswordLastSet)
Locked Out       : $($Details.LockedOut)
"@
        Write-Host $Report -ForegroundColor Yellow
        Add-Content -Path $LogPath -Value $Report
    }
}

Write-Host "Report saved to $LogPath`n" -ForegroundColor Cyan
