<#
.SYNOPSIS
    Bulk-onboards Active Directory users from an HR CSV file with RBAC group assignment.
.DESCRIPTION
    Generates standardized SamAccountNames (first initial + last name), checks for
    existing duplicates, creates accounts in Corp\Users, forces password reset at
    first logon, and assigns the designated department Security Group.
#>

Import-Module ActiveDirectory

$CsvPath = "C:\Scripts\new_hires.csv"
$TargetOU = "OU=Users,OU=Corp,DC=corp,DC=local"
$NewHires = Import-Csv -Path $CsvPath

foreach ($Hire in $NewHires) {
    $SamAccount = ($Hire.FirstName.Substring(0,1) + $Hire.LastName).ToLower()
    $UPN = "$SamAccount@corp.local"
    $SecurePassword = ConvertTo-SecureString $Hire.InitialPassword -AsPlainText -Force

    if (-not (Get-ADUser -Filter "SamAccountName -eq '$SamAccount'")) {
        New-ADUser `
            -Name "$($Hire.FirstName) $($Hire.LastName)" `
            -GivenName $Hire.FirstName `
            -Surname $Hire.LastName `
            -SamAccountName $SamAccount `
            -UserPrincipalName $UPN `
            -Department $Hire.Department `
            -Title $Hire.JobTitle `
            -Path $TargetOU `
            -AccountPassword $SecurePassword `
            -ChangePasswordAtLogon $true `
            -Enabled $true

        Add-ADGroupMember -Identity $Hire.SecurityGroup -Members $SamAccount
        Write-Host "[SUCCESS] Created $UPN ($($Hire.JobTitle)) -> Added to $($Hire.SecurityGroup)" -ForegroundColor Green
    }
    else {
        Write-Warning "[SKIPPED] Account $SamAccount already exists in Active Directory."
    }
}