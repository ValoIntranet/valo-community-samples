New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft" -Name "Internet Explorer"  
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer" -Name "Main" 
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -Value "1" -PropertyType "DWORD"
 
