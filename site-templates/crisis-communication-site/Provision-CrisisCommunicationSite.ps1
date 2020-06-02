<#
 .SYNOPSIS
    Provision-CrisisCommunicationSite.ps1

 .DESCRIPTION
    Provisions Crisis Communication site pages, news, images and other resources in to an existing Communication site

 .PARAMETER HubUrl
    Optional, If not included, important message won't be added

 .PARAMETER SiteUrl
    Required, Site Url where to deploy the crisis communication template 

 .PARAMETER PnPFilePath
    Optional, Where is the Crisis Communication site template located. If not defined, uses the default filename CrisisCommunicationSite.pnp in the execution folder

 .PARAMETER Office365CredentialStoreKey
    Optional, If credentials to O365 are stored in Credential Manager, give the store key

 .PARAMETER SharePointUserName
    Optional, If Office365CredentialStoreKey or this parameter not given, prompts for credentials

 .PARAMETER SharePointPassword
    Optional, If Office365CredentialStoreKey or this parameter not given, prompts for credentials

 .PARAMETER ShowDebug
    Optional, Show debug information in the output

 .PARAMETER useMFA
    Optional, If MFA is enforced for the account, use this switch parameter to use web login

#>
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "PasswordAuthenticationContext")]
Param(
    [Parameter(Mandatory = $false, HelpMessage = "Url of the hub site")]
    [ValidateNotNullOrEmpty()]
    [String]$HubUrl,
    
    [Parameter(Mandatory = $true, HelpMessage = "Url of the site where Crisis Communication site resources are provisioned.")]
    [ValidateNotNullOrEmpty()]
    [String]$SiteUrl,
    
    [Parameter(Mandatory = $false, HelpMessage = "File path to the pnp template")]
    [ValidateNotNullOrEmpty()]
    [String]$PnPFilePath = ".\CrisisCommunicationSite.pnp",

    [Parameter(Mandatory = $false, HelpMessage = "Name of Windows Credentials key used for connecting to Office 365 with a saved account.")]
    [String]$Office365CredentialStoreKey,

    [Parameter(Mandatory = $false, HelpMessage = "SharePoint login userName. Use if Office365CredentialStoreKey is not available.")]
    [String]$SharePointUserName,

    [Parameter(Mandatory = $false, HelpMessage = "SharePoint login password. Use if Office365CredentialStoreKey is not available.")]
    $SharePointPassword,

    [switch]$ShowDebug,

    [switch]$useMFA
)


function Get-Framework {  
    #-----------------------------------------------------------------------
    # Loading Every *.ps1 file contained in the \Functions\Log folder
    #-----------------------------------------------------------------------
    Get-ChildItem -Path "$PSScriptRoot\Functions\Log\*.ps1" -Recurse | ForEach-Object {
        . $_.FullName 
    }

    #-----------------------------------------------------------------------
    # Loading Every *.ps1 file contained in the \Functions\SampleContent folder
    #-----------------------------------------------------------------------
    Get-ChildItem -Path "$PSScriptRoot\Functions\SampleContent\*.ps1" -Recurse | ForEach-Object {
        . $_.FullName 
    }

    #-----------------------------------------------------------------------
    # Loading Every *.ps1 file contained in the \Functions folder
    #-----------------------------------------------------------------------
    Get-ChildItem -Path "$PSScriptRoot\Functions\*.ps1" -Recurse | ForEach-Object {
        . $_.FullName 
    }
}

function Connect-SPOnline {
    Param (
        [String]$SiteUrl
    )
    # Connecting to the SharePoint Site
    if ($Global:Office365CredentialStoreKey) {
        Connect-PnPOnline -Url $SiteUrl -Credentials $Global:Office365CredentialStoreKey
        return $true
    } 
    elseif ($Global:SharePointUserName -and $Global:SharePointPassword) {
        $cred = New-Object System.Management.Automation.PsCredential($global:SharePointUserName,$global:SharePointPassword)
        Connect-PnPOnline -Url $SiteUrl -Credentials $cred 
        return $true
    }
    return $false
}

function Add-ImportantMessageToHub {
    Log -Message "Adding list item to Important Messages in the Hub site" -Level Info -wrapWithSeparator
    $infoMessagesList = Get-PnPList -Identity "InformationMessages"
    if($infoMessagesList) 
    {
        $startDate = [DateTime]::UtcNow
        $title = "Crisis Communication site is up and running"
        $body = "For all important communication in this Covid-19 crisis please refer to our crisis communication site. We encourage everyone to follow this site."
        $type = "1. Alert"
        $link = $("{0}, Crisis communication site" -f $SiteUrl)
        Add-PnPListItem -List $infoMessagesList -ContentType "ValoInformationMessages" -Values @{
            "Title" = $title;
            "ValoMessageStartDate" = $startDate;
            "ValoMessageDescription" = $body;
            "ValoMessageType" = $type;
            "ValoMessageLink" = $link;
        } | Out-Null
    }
}

#-----------------------------------------------------------------------
# Loading the Framework
#-----------------------------------------------------------------------
. Get-Framework

#-----------------------------------------------------------------------
# Setuping the Logger
#-----------------------------------------------------------------------
Setup-Logger -debugParam $ShowDebug -logToFileParam $true -logFileName "ValoCrisisCommunicationSite"

#-----------------------------------------------------------------------
# Starting a new Timer
#-----------------------------------------------------------------------
$totalRunTime = [Diagnostics.Stopwatch]::StartNew()
    
Log -Message $("Provisioning Valo Crisis Communication template to site {0}" -f $SiteUrl) -Level Info -wrapWithSeparator

$tenantUrl = Get-TenantUrlFromSiteUrl $SiteUrl

Set-GlobalVariable -parameterName tenantUrl -value $tenantUrl

# Initialize global variables used in the script
Initialize-GenesisVariables -tenantUrl $tenantUrl `
    -installMode $installMode

Initialize-Credentials -Office365CredentialStoreKey $Office365CredentialStoreKey `
    -SharePointUserName $SharePointUserName `
    -SharePointPassword $SharePointPassword `
    -useMFA:$useMFA

# Execution
$connected = Connect-SPOnline $SiteUrl

if (!$connected) {
    Log -Message "Missing CredentialStoreKey or Username/Passoword, exiting.." -Level Error 
    Exit
}

if ($ShowDebug) {
    Set-PnPTraceLog -On -Level:Debug -LogFile ("pnp-debug-log_{0}.txt" -f (Get-Date -Format yyyyMMdd-HHmm))
}

Log -Message "Applying site template to the site" -Level Info -wrapWithSeparator
Apply-PnPProvisioningTemplate -Path $PnPFilePath -Debug:$ShowDebug

#Possible additional configurations
Log -Message "Executing additional configurations" -Level Info -wrapWithSeparator

if ($HubUrl)
{
    $connected = Connect-SPOnline $HubUrl

    Add-ImportantMessageToHub
}

$totalRunTime.Stop()
$total = [Math]::Round($totalRunTime.Elapsed.TotalMinutes).ToString()
Log -Message "Valo Crisis Communication template was provisioned in $total minutes" -Level Info -wrapWithSeparator
Setup-Logger -debugParam $false -logToFileParam $false -logFileName ""
Disconnect-PnPOnline
if ($ShowDebug) {
    Set-PnPTraceLog -Off
}