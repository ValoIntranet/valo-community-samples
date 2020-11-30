param(
    [string]$domainName,
    [string]$adminAccountName
)
New-Item -ItemType Directory -Path c:\Temp
New-SmbShare -Name "temp" -Path "C:\Temp" -FullAccess "$domainName\$adminAccountName"
