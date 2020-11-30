param(
    [string]$csvPath,
    [string]$DCPath,
    [string]$DCNetBIOS
)

$import_users = Import-Csv -Path $csvPath
New-ADOrganizationalUnit -Name ValoUsers -Path $DCPath
New-ADGroup -Name ValoOwners -Path "ou=valousers,$($DCPath)" -GroupScope Universal
New-ADGroup -Name ValoMembers -Path "ou=valousers,$($DCPath)" -GroupScope Universal
New-ADGroup -Name ValoVisitors -Path "ou=valousers,$($DCPath)" -GroupScope Universal
$import_users | ForEach-Object {
    New-ADUser `
        -Name $_.Name `
        -DisplayName $_.Name `
        -SamAccountName $_.SamAccountName `
        -AccountPassword $(ConvertTo-SecureString $_.Password -AsPlainText -Force) `
        -Enabled $True `
        -PasswordNeverExpires $True `
        -ChangePasswordAtLogon $false `
        -Path "ou=valousers,$($DCPath)"
}

Grant-SmbShareAccess -Name "temp" -AccountName "$($DCNetBIOS)\spsadmin" -AccessRight Change -Force
Grant-SmbShareAccess -Name "temp" -AccountName "$($DCNetBIOS)\hadmin" -AccessRight Change -Force
