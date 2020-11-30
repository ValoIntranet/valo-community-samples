$domainName = "YOURDOMAIN"
$serverName = "sql"

$mount = Mount-DiskImage -ImagePath \\dc1\temp\en_sql_server_2019_developer_x64_dvd_baea4195.iso -PassThru
$drive = ($mount | Get-Volume).DriveLetter
$sqlConfig = "/ConfigurationFile=\\dc1\Temp\SQL2019ConfigurationFile.ini"
Start-Process ($drive+":\setup.exe") $sqlConfig -Wait
Dismount-DiskImage -ImagePath \\dc1\Temp\en_sql_server_2019_developer_x64_dvd_baea4195.iso

Install-PackageProvider -Name NuGet  -Force
Install-Module -Name SQLServer -AllowClobber -Force
Add-SqlLogin -LoginType WindowsUser -LoginName "$domainName\spsadmin" -Enable -GrantConnectSql -ServerInstance $serverName
$sqlServer = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $serverName
$sqlServerRole = $sqlServer.Roles | where {$_.Name -eq 'dbcreator'}
$sqlServerRole.AddMember("$domainName\spsadmin")
$sqlServerRole = $sqlServer.Roles | where {$_.Name -eq 'securityadmin'}
$sqlServerRole.AddMember("$domainName\spsadmin")

$conn = new-object System.Data.SqlClient.SqlConnection 
$connectionString = "Server=$serverName;Database=master;Integrated Security=True;" 
$conn.ConnectionString = $connectionString 
$conn.Open() 
$cmd = new-object System.Data.SqlClient.SqlCommand 
$cmd.Connection = $conn 
$commandText = "sp_configure 'show advanced options', 1;RECONFIGURE WITH OVERRIDE;"         
$cmd.CommandText = $commandText 
$r = $cmd.ExecuteNonQuery() 
$commandText = "sp_configure 'max degree of parallelism', 1;RECONFIGURE WITH OVERRIDE"         
$cmd.CommandText = $commandText 
$r = $cmd.ExecuteNonQuery() 

$smo = 'Microsoft.SqlServer.Management.Smo.'  
$wmi = new-object ($smo + 'Wmi.ManagedComputer').  

# List the object properties, including the instance names.  
$Wmi  

# Enable the TCP protocol on the default instance.  
$uri = "ManagedComputer[@Name='$serverName']/ ServerInstance[@Name='MSSQLSERVER']/ServerProtocol[@Name='Tcp']"  
$Tcp = $wmi.GetSmoObject($uri)  
$Tcp.IsEnabled = $true  
$Tcp.Alter()  
$Tcp  

Restart-Service MSSQLSERVER -Force

New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action allow

\\dc1\Temp\SSMS-Setup-ENU.exe /passive
 Set-ExecutionPolicy RemoteSigned
 
