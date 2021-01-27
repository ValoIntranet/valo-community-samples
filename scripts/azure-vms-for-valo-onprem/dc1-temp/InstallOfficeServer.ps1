Add-WindowsFeature Web-Server,Web-Mgmt-Tools,Web-Mgmt-Console,Web-WebServer,Web-Common-Http,Web-Default-Doc,Web-Static-Content,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Security,Web-Filtering,Web-Windows-Auth,Web-App-Dev,Web-Net-Ext45,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Includes,NET-Framework-Features,NET-Framework-45-Features,NET-Framework-Core,NET-Framework-45-Core,NET-HTTP-Activation,NET-Non-HTTP-Activ,NET-WCF-HTTP-Activation45,Windows-Identity-Foundation,Server-Media-Foundation
Mount-DiskImage -ImagePath \\dc1\Temp\en_office_online_server_last_updated_november_2018_x64_dvd_1b5ae10d.iso
Start-Process "f:\setup.exe" -ArgumentList "/config \\dc\Temp\office-online.xml" -Wait
Import-Module "C:\Program Files\Microsoft Office Web Apps\AdminModule\OfficeWebApps\officewebapps.psd1"


New-OfficeWebAppsFarm -InternalURL "https://office.YOURDOMAIN.valo.show"  -EditingEnabled -CertificateName "*.valo.show"

Invoke-WebRequest https://office.YOURDOMAIN.valo.show/hosting/discovery

#if http
#Set-OfficeWebAppsFarm -AllowHttpSecureStoreConnections:$true

#in SharePoint Server

#New-SPWOPIBinding -ServerName office.YOURDOMAIN.valo.show -AllowHTTP #if http
 
#by default https -> convert to http
Get-SPWOPIZone
Set-SPWOPIZone -zone "internal-http"

#by default blocked for https
(Get-SPSecurityTokenServiceConfig).AllowOAuthOverHttp
$config = (Get-SPSecurityTokenServiceConfig)
$config.AllowOAuthOverHttp = $true
$config.Update()

#enable Excel Services
$Farm = Get-SPFarm
$Farm.Properties.Add("WopiLegacySoapSupport", "https://office.YOURDOMAIN.valo.show/x/_vti_bin/ExcelServiceInternal.asmx");
$Farm.Update();