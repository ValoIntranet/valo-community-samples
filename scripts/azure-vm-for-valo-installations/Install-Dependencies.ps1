Set-ExecutionPolicy Unrestricted -Force

Install-PackageProvider -Name nuget -Force
Install-Module Az -Force -AllowClobber
Install-Module AzureAD -Force -AllowClobber
Install-Module AzureRM -Force -AllowClobber
Install-Module CredentialManager -Force -AllowClobber
Install-Module SharePointPnPPowerShellOnline -Force -AllowClobber
Install-Module Microsoft.Online.SharePoint.PowerShell -Force -AllowClobber
Set-ExecutionPolicy RemoteSigned -Force

Import-Module -Name Az -Force
Import-Module -Name AzureAD -Force
Import-Module -Name AzureRM -Force
Import-Module -Name CredentialManager -Force
Import-Module -Name SharePointPnPPowerShellOnline -Force -DisableNameChecking
Import-Module -Name Microsoft.Online.SharePoint.PowerShell -Force -DisableNameChecking

#works after IE has been initialized.
#Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
