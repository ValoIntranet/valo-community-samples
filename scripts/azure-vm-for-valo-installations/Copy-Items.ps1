$container ='valofiles'
$connectionString="connectionStringValue"

$dir = New-Item -Path "c:\" -Name Valo -ItemType Directory -Force

$ctx = New-AzStorageContext -ConnectionString $connectionString
$blobs = Get-AzStorageBlob -Container $container -Blob * -Context $ctx
foreach($blob in $blobs){
    Get-AzStorageBlobContent -Container $container -Blob $blob.Name -Destination $dir.FullName -Context $ctx -Force
}

foreach ($file in Get-Item C:\Valo\*.zip){
    Expand-Archive -LiteralPath $file.FullName -DestinationPath ('C:\Valo\'+$file.BaseName)
}

Get-ChildItem -Recurse -Path c:\valo | Unblock-File

$key = 'InitIE'
$cmd = '%systemroot%\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -file c:\valo\InitIE.ps1'
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name $key -Value $cmd -PropertyType ExpandString




 


