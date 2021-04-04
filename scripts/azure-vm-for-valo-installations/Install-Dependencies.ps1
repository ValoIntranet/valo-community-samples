Set-ExecutionPolicy Unrestricted -Force

Install-PackageProvider -Name nuget -Force
Install-Module AzureAD -Force -AllowClobber #required for all products
Install-Module Az -Force -AllowClobber #required for Intranet and Extranet
#Install-Module AzureRM -Force -AllowClobber #required for Teamwork
#Install-Module SharePointPnPPowerShellOnline -Force -AllowClobber #required for Teamwork, Extranet, Ideas 
Install-Module PnP.PowerShell -Force -AllowClobber #required for Intranet 
Install-Module CredentialManager -Force -AllowClobber #optional if using credential manager
Install-Module Microsoft.Online.SharePoint.PowerShell -Force -AllowClobber
Set-ExecutionPolicy RemoteSigned -Force

Import-Module -Name Az -Force
Import-Module -Name AzureAD -Force
#Import-Module -Name AzureRM -Force
Import-Module -Name CredentialManager -Force
Import-Module -Name SharePointPnPPowerShellOnline -Force -DisableNameChecking
Import-Module PnP.PowerShell -Force -DisableNameChecking
Import-Module -Name Microsoft.Online.SharePoint.PowerShell -Force -DisableNameChecking
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
