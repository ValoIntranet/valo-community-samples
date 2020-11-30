  param(
      [string]$domainName
  )
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName $domainName -SafeModeAdministratorPassword (Convertto-SecureString -AsPlainText "V4L0D1r3ct0ry" -Force) -Confirm:$false
