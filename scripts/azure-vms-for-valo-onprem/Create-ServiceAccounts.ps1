param(
    [string]$csvPath,
    [string]$DCPath
)

$import_users = Import-Csv -Path $csvPath
New-ADOrganizationalUnit -Name ServiceAccounts -Path $DCPath
$import_users | ForEach-Object {
    New-ADUser `
        -Name $_.Name `
        -DisplayName $_.Name `
        -SamAccountName $_.SamAccountName `
        -AccountPassword $(ConvertTo-SecureString $_.Password -AsPlainText -Force) `
        -Enabled $True `
        -PasswordNeverExpires $True `
        -CannotChangePassword $True `
        -ChangePasswordAtLogon $false `
        -Path "ou=serviceaccounts,$($DCPath)"
}

