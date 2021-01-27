# Azure VMs for Valo On-premises

## Summary
This script can be used to install VM infrastructure to host Valo On-premises. It will automatically install the Windows 10, AD, SQL, SPS and Office servers. Windows 10 can be used to access all servers. SharePoint server will have port 443 open to Internet. Admin user must copy SQL, SharePoint and Office Online Services medias e.g. from my.visualstudio.com or other sources to a server after VMs have been created. Additionally AutoSPSourceBuilder and AutoSPInstaller are used during the installation and must be downloaded separetely. SQL Management studio will also be installed and needs to be downlaoded. Short video in works how to use the script. Feel free to contact me for any details.

This app is developed using below technologies 
* PowerShell

## Used Valo Version 
Valo Intranet On-prem (Modern)

## Prerequisites
 
It is required that the users have PowerShell on Windows or MacOSX.

## Solution

Solution|Author(s)
--------|---------
azure-vms-for-valo-onprem | [Ilija Lazarov](https://www.linkedin.com/in/ilijalazarov) ([@d3moilija](https://twitter.com/d3moilija))

## Version history

Version|Date|Comments
-------|----|--------
1.0 | November 30, 2020 | Initial Release

## Disclaimer
**THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.**