$ie = New-Object -com internetexplorer.application
$ie.visible = $true
$ie.navigate('#')
$wshell = New-Object -ComObject wscript.shell
$wshell.AppActivate('Internet Explorer 11')
Start-Sleep -Seconds 5; 
$wshell.SendKeys('%u')
$wshell.SendKeys('%o')
Stop-Process -Name iexplore

Get-ChildItem -Recurse | Unblock-File
