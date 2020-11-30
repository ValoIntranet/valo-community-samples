param(
    [string]$domainName,
    [string]$adJoinPWD
)
$joinCred = New-Object pscredential -ArgumentList ([pscustomobject]@{
    UserName = $null 
    Password = (ConvertTo-SecureString -String $adJoinPWD -AsPlainText -Force)[0]})
Add-Computer -Domain $domainName -Options UnsecuredJoin,PasswordPass -Credential $joinCred