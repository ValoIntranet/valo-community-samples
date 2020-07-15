$container ='valofiles'
$connectionString="connectionStringValue"

$dir = New-Item -Path "c:\" -Name Valo -ItemType Directory -Force

$ctx = New-AzureStorageContext -ConnectionString $connectionString
$blobs = Get-AzureStorageBlob -Container $container -Blob * -Context $ctx
foreach($blob in $blobs){
    Get-AzureStorageBlobContent -Container $container -Blob $blob.Name -Destination $dir.FullName -Context $ctx -Force
}
#reverted using AzureRM above
# $ctx = New-AzStorageContext -ConnectionString $connectionString
# $blobs = Get-AzStorageBlob -Container $container -Blob * -Context $ctx
# foreach($blob in $blobs){
#     Get-AzStorageBlobContent -Container $container -Blob $blob.Name -Destination $dir.FullName -Context $ctx -Force
# }

foreach ($file in Get-Item C:\Valo\*.zip){
    Expand-Archive -LiteralPath $file.FullName -DestinationPath ('C:\Valo\'+$file.BaseName)
}

Get-ChildItem -Recurse -Path c:\valo | Unblock-File

#Init IE
reg import c:\valo\InitIE.reg
#Install Azure CLI dependency for Valo Ideas
#works after IE has been initialized.
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi




 


