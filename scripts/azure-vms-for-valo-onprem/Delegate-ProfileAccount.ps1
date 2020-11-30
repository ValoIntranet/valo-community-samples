param(
    [string]$DCNetBIOS
)
$Identity = "$DCNetBIOS\spsprofilesync"
$RootDSE = [ADSI]"LDAP://RootDSE"
$DefaultNamingContext = $RootDse.defaultNamingContext
$ConfigurationNamingContext = $RootDse.configurationNamingContext
$UserPrincipal = New-Object Security.Principal.NTAccount("$Identity")
DSACLS "$DefaultNamingContext" /G "$($UserPrincipal):CA;Replicating Directory Changes"
DSACLS "$ConfigurationNamingContext" /G "$($UserPrincipal):CA;Replicating Directory Changes"
