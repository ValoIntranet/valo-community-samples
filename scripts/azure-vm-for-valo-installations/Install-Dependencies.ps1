Set-ExecutionPolicy Unrestricted -Force

Install-PackageProvider -Name nuget -Force
# removed as does not work with AzureRM at the same time
#Install-Module Az -Force -AllowClobber
Install-Module AzureAD -Force -AllowClobber
Install-Module AzureRM -Force -AllowClobber
Install-Module CredentialManager -Force -AllowClobber
Install-Module SharePointPnPPowerShellOnline -Force -AllowClobber
Install-Module Microsoft.Online.SharePoint.PowerShell -Force -AllowClobber
Set-ExecutionPolicy RemoteSigned -Force

#Import-Module -Name Az -Force
Import-Module -Name AzureAD -Force
Import-Module -Name AzureRM -Force
Import-Module -Name CredentialManager -Force
Import-Module -Name SharePointPnPPowerShellOnline -Force -DisableNameChecking
Import-Module -Name Microsoft.Online.SharePoint.PowerShell -Force -DisableNameChecking

