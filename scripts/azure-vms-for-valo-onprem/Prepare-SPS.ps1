param(
    [string]$DCNetBIOS
)
Add-LocalGroupMember -Group Administrators -Member "$($DCNetBIOS)\spsadmin"
Add-LocalGroupMember -Group Administrators -Member "$($DCNetBIOS)\hadmin"
New-Item -ItemType Directory -Path c:\Temp
