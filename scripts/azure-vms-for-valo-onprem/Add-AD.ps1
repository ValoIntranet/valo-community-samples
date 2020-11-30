param([string]$computerName,[string]$adJoinPWD) 
New-ADComputer -Name $computerName -AccountPassword (ConvertTo-SecureString -String $adJoinPWD -AsPlainText -Force)