# New-BulkUsers.ps1
# Creates Active Directory user accounts in bulk from a CSV file.
# Each user is placed in the correct OU and added to their security group.
# Usage: .\New-BulkUsers.ps1

Import-Module ActiveDirectory

$CsvPath    = "C:\scripts\users.csv"
$Domain     = "DC=corp,DC=local"
$TempPass   = ConvertTo-SecureString "Welcome@12345" -AsPlainText -Force
$LogPath    = "C:\scripts\BulkUsers_Log.txt"

$Users = Import-Csv -Path $CsvPath
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $LogPath -Value "`n=== Bulk User Creation Run: $Timestamp ==="

foreach ($User in $Users) {

    $FullName = "$($User.FirstName) $($User.LastName)"
    $OUPath   = "OU=$($User.OU),$Domain"
    $UPN      = "$($User.Username)@corp.local"

    # Check if user already exists
    $Sam = $User.Username
    if (Get-ADUser -Filter {SamAccountName -eq $Sam} -ErrorAction SilentlyContinue) {
        $Msg = "SKIPPED  - $($User.Username) already exists"
        Write-Host $Msg -ForegroundColor Yellow
        Add-Content -Path $LogPath -Value $Msg
        continue
    }

    try {
        # Create the user account
        New-ADUser `
            -Name              $FullName `
            -GivenName         $User.FirstName `
            -Surname           $User.LastName `
            -SamAccountName    $User.Username `
            -UserPrincipalName $UPN `
            -Path              $OUPath `
            -AccountPassword   $TempPass `
            -ChangePasswordAtLogon $true `
            -Enabled           $true `
            -Department        $User.Department

        # Add to security group
        Add-ADGroupMember -Identity $User.Group -Members $User.Username

        $Msg = "CREATED  - $($User.Username) in $($User.OU) | Group: $($User.Group)"
        Write-Host $Msg -ForegroundColor Green
        Add-Content -Path $LogPath -Value $Msg

    } catch {
        $Msg = "ERROR    - $($User.Username): $($_.Exception.Message)"
        Write-Host $Msg -ForegroundColor Red
        Add-Content -Path $LogPath -Value $Msg
    }
}

Write-Host "`nDone. Log saved to $LogPath" -ForegroundColor Cyan
