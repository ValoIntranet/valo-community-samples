<#
 .SYNOPSIS
    Provision-DocumentHubSite.ps1

 .DESCRIPTION
    Provisions Document Hub site pages, content types and other resources in to an existing Communication site created from the Valo Create Content button

 .PARAMETER SiteUrl
    Required, Site Url where to deploy the document hub template 

 .PARAMETER SiteTitle
    Optional, the document hub site will be updated with this Title 

 .PARAMETER PnPFilePath
    Optional, Where is the Document Hub site template located. If not defined, uses the default filename DocumentHubSite.pnp in the execution folder

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
    [Parameter(Mandatory = $true, HelpMessage = "Url of the site where Document Hub site resources are to be provisioned.")]
    [ValidateNotNullOrEmpty()]
    [String]$SiteUrl,
    
    [Parameter(Mandatory = $false, HelpMessage = "The document hub site will be updated with this Title (if specified)")]
    [ValidateNotNullOrEmpty()]
    [String]$SiteTitle,
    
    [Parameter(Mandatory = $false, HelpMessage = "File path to the pnp template used for this provisioning process")]
    [ValidateNotNullOrEmpty()]
    [String]$PnPFilePath = ".\DocumentHubSite.pnp",

    [Parameter(Mandatory = $false, HelpMessage = "Name of Windows Credentials key used for connecting to Office 365 with a saved account.")]
    [String]$Office365CredentialStoreKey,

    [Parameter(Mandatory = $false, HelpMessage = "SharePoint login userName. Use if Office365CredentialStoreKey is not available.")]
    [String]$SharePointUserName,

    [Parameter(Mandatory = $false, HelpMessage = "SharePoint login password. Use if Office365CredentialStoreKey is not available.")]
    $SharePointPassword,

    [Parameter(Mandatory = $false, HelpMessage = "Full path to the Valo PartnerPack PowerShell script.  Defaults to current path if not provided")]
    $PartnerPackScriptRoot,

    [switch]$ShowDebug,

    [switch]$useMFA
)


function Get-Framework($PartnerPackScriptRoot = $null) {  

    if (-not $PartnerPackScriptRoot) { $PartnerPackScriptRoot = $PSScriptRoot }

    Try {

        #-----------------------------------------------------------------------
        # Loading Every *.ps1 file contained in the \Functions\Log folder
        #-----------------------------------------------------------------------
        Get-ChildItem -Path "$(Join-Path $PartnerPackScriptRoot "\Functions\Log\*.ps1")" -Recurse -ErrorAction Stop | ForEach-Object {
            . $_.FullName 
        }

        #-----------------------------------------------------------------------
        # Loading Every *.ps1 file contained in the \Functions\SampleContent folder
        #-----------------------------------------------------------------------
        Get-ChildItem -Path "$(Join-Path $PartnerPackScriptRoot "\Functions\SampleContent\*.ps1")" -Recurse -ErrorAction Stop | ForEach-Object {
            . $_.FullName 
        }

        #-----------------------------------------------------------------------
        # Loading Every *.ps1 file contained in the \Functions folder
        #-----------------------------------------------------------------------
        Get-ChildItem -Path "$(Join-Path $PartnerPackScriptRoot "\Functions\*.ps1")" -Recurse -ErrorAction Stop | ForEach-Object {
            . $_.FullName 
        }

    }
    Catch {
        Write-Error "Error getting Valo PartnerPack artifacts from path $PartnerPackScriptRoot. Aborting."
        Exit
    }
    
}

function Get-ValoConfigFromHubSite {
    Get-PnPHubSite
}


#-----------------------------------------------------------------------
# Loading the Framework
#-----------------------------------------------------------------------
. Get-Framework $PartnerPackScriptRoot

#-----------------------------------------------------------------------
# Setuping the Logger
#-----------------------------------------------------------------------
Setup-Logger -debugParam $ShowDebug -logToFileParam $true -logFileName "ValoDocumentHubSite"

#-----------------------------------------------------------------------
# Starting a new Timer
#-----------------------------------------------------------------------
$totalRunTime = [Diagnostics.Stopwatch]::StartNew()
    
Log -Message $("Provisioning Valo Document Hub template") -Level Info -wrapWithSeparator

$tenantUrl = Get-TenantUrlFromSiteUrl $SiteUrl

Set-GlobalVariable -parameterName tenantUrl -value $tenantUrl

# Initialize global variables used in the script
Initialize-GenesisVariables -tenantUrl $tenantUrl `
    -Office365CredentialStoreKey $Office365CredentialStoreKey `
    -SharePointUserName $SharePointUserName `
    -SharePointPassword $SharePointPassword `
    -installMode $installMode

Initialize-Credentials `
    -Office365CredentialStoreKey $Office365CredentialStoreKey `
    -SharePointUserName $SharePointUserName `
    -SharePointPassword $SharePointPassword `
    -useMFA:$useMFA

# Execution

$connected = Ensure-ValoConnection -url $SiteUrl

if (!$connected) {
    Log -Message "Something went wrong while connecting to the site $SiteUrl, exiting.." -Level Error 
    Exit
}

if ($ShowDebug) {
    Set-PnPTraceLog -On -Level:Debug -LogFile ("pnp-debug-log_{0}.txt" -f (Get-Date -Format yyyyMMdd-HHmm))
}

Log -Message "Obtaining Valo Templates site url" -Level Info -wrapWithSeparator

$HubSiteUrl = (Get-PnPHubSite (Get-PnPProperty -ClientObject (Get-PnPSite) -Property HubSiteId).ToString()).SiteUrl
$hubSiteConnected = Ensure-ValoConnection -url $HubSiteurl

if (!$hubSiteConnected) {
    Log -Message "Something went wrong while connecting to the hub site $HubSiteUrl, exiting.." -Level Error 
    Exit
}

$ValoNavigationData = ConvertFrom-Json (Get-PnPFile -Url "$(Get-PnPProperty -ClientObject (Get-PnPSite) -Property ServerRelativeUrl)/config/navigation.json" -AsString -ErrorAction Stop)
$TemplateSiteUrl = $ValoNavigationData.valoHubData.config.ValoPageTemplates

if (!$TemplateSiteUrl) {
    Log -Message "Something went wrong while getting the Valo config from $HubSiteUrl, exiting.." -Level Error 
    Exit
}
$templateSiteConnected = Ensure-ValoConnection -url $TemplateSiteUrl

if (!$templateSiteConnected) {
    Log -Message "Something went wrong while connecting to the template site $TemplateSiteUrl, exiting.." -Level Error 
    Exit
}

Log -Message "Uploading web part templates to Valo Templates Gallery" -Level Info -wrapWithSeparator
Add-PnPFile -Path .\TemplatesGallery\DocumentHub.html -Folder TemplatesGallery -Values @{ "TemplateTitle" = "Document Hub"; "IsFullBleed" = $false } | Out-Null

Log -Message "Uploading page templates to Valo Templates" -Level Info -wrapWithSeparator
Apply-PnPProvisioningTemplate -Path ".\ValoTemplates.pnp" -Debug:$ShowDebug



$connected = Ensure-ValoConnection -url $SiteUrl

if (!$connected) {
    Log -Message "Something went wrong while connecting back to the site $SiteUrl, exiting.." -Level Error 
    Exit
}

Log -Message $("Applying site template to the site {0}" -f $SiteUrl) -Level Info -wrapWithSeparator
Apply-PnPProvisioningTemplate -Path $PnPFilePath -Debug:$ShowDebug

#Possible additional configurations
Log -Message "Executing additional configurations" -Level Info -wrapWithSeparator

if ($SiteTitle) {
    Log -Message "  Setting site title to $SiteTitle" -Level Info -wrapWithSeparator
    Set-PnPWeb -Title $SiteTitle
}

Log -Message "  Removing content types from the Site Pages library" -Level Info

$ContentTypesToRemove = @(
    '0x01010901' # Web Part Page
    '0x0101009D1CB255DA76424F860D91F20E6C4118',  # Site Page
    '0x0101009D1CB255DA76424F860D91F20E6C4118002A50BFCFB7614729B56886FADA02339B', # Repost page
    '0x0101009D1CB255DA76424F860D91F20E6C41180065789619A4EFB44992AF42CEEBB13C9A02' # Valo News Page
)

$ContentTypesToRemove | % {
    Remove-PnPContentTypeFromList -List "Site Pages" -ContentType $_
}

Log -Message "  Renaming content types in the Site Pages library" -Level Info

$ContentTypesToRename = @(
    @{ Id = '0x0101009D1CB255DA76424F860D91F20E6C41180065789619A4EFB44992AF42CEEBB13C9A0301'; Name = 'Policy' }
    @{ Id = '0x0101009D1CB255DA76424F860D91F20E6C41180065789619A4EFB44992AF42CEEBB13C9A0302'; Name = 'Procedure' }
    @{ Id = '0x0101009D1CB255DA76424F860D91F20E6C41180065789619A4EFB44992AF42CEEBB13C9A0303'; Name = 'How to guide' }
)

$SitePagesList = Get-PnPList "Site Pages"
$SitePagesContentTypes = Get-PnPProperty -ClientObject $SitePagesList -Property ContentTypes
(Get-PnPContext).Load($SitePagesContentTypes)

$ContentTypesToRename | % {
    $Id = $_.Id;
    $Name = $_.Name;

    $SitePagesContentTypes | ? { $_.Id -like "$Id*" } | % { 
        $_.Name = $Name; 
        $_.Update($false) 
    }
}

(Get-PnPContext).ExecuteQuery()


$totalRunTime.Stop()
$total = [Math]::Round($totalRunTime.Elapsed.TotalMinutes).ToString()
Log -Message "Valo Document Hub template was provisioned in $total minutes" -Level Info -wrapWithSeparator
Setup-Logger -debugParam $false -logToFileParam $false -logFileName ""
Disconnect-PnPOnline
if ($ShowDebug) {
    Set-PnPTraceLog -Off
}
