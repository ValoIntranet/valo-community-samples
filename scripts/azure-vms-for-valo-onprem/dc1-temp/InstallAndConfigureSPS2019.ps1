 
$mount = Mount-DiskImage -ImagePath \\dc1\Temp\en_sharepoint_server_2019_x64_dvd_68e34c9e.iso -PassThru
$drive = ($mount | Get-Volume).DriveLetter
Expand-Archive -LiteralPath \\dc1\Temp\AutoSPInstaller-master.zip -DestinationPath C:\Temp
Expand-Archive -LiteralPath \\dc1\Temp\AutoSPSourceBuilder-master.zip -DestinationPath C:\Temp
Get-ChildItem -Path C:\Temp -Recurse | Unblock-File
C:\Temp\AutoSPSourceBuilder-master\Scripts\AutoSPSourceBuilder.ps1 -SharePointVersion 2019 -SourceLocation $drive -Destination C:\Temp\AutoSPInstaller-master\SP\2019 -Languages "de-de","fr-fr","es-es" -LocationForUpdates C:\Temp\AutoSPInstaller-master\SP\2019\Updates -CumulativeUpdate "November 2020" 
Dismount-DiskImage -ImagePath \\dc1\Temp\en_sharepoint_server_2019_x64_dvd_68e34c9e.iso
Copy-Item -Path \\dc1\Temp\sps2019installer.xml -Destination C:\temp\AutoSPInstaller-master\SP\Automation\
C:\Temp\AutoSPInstaller-master\SP\Automation\AutoSPInstallerLaunch.bat C:\Temp\sps2019installer.xml