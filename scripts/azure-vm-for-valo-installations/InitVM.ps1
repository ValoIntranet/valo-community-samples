$container ='data'
$connectionString="connectionStringValue"

Install-PackageProvider -Name nuget -Force
Install-Module AzureAD -Force -AllowClobber
Install-Module AzureRM -Force -AllowClobber
Install-Module CredentialManager -Force -AllowClobber
Install-Module SharePointPnPPowerShellOnline -Force -AllowClobber
Install-Module Microsoft.Online.SharePoint.PowerShell -Force -AllowClobber

Set-ExecutionPolicy RemoteSigned -Force
Import-Module -Name AzureAD -Force
Import-Module -Name AzureRM -Force
Import-Module -Name CredentialManager -Force
Import-Module -Name SharePointPnPPowerShellOnline -Force -DisableNameChecking
Import-Module -Name Microsoft.Online.SharePoint.PowerShell -Force -DisableNameChecking


$dir = New-Item -Path "c:\" -Name Valo -ItemType Directory -Force

$ctx = New-AzureStorageContext -ConnectionString $connectionString
$blobs = Get-AzureStorageBlob -Container $container -Blob * -Context $ctx
foreach($blob in $blobs){
    Get-AzureStorageBlobContent -Container $container -Blob $blob.Name -Destination $dir.FullName -Context $ctx -Force
}




 

