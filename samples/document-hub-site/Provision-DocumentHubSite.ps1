<#
 .SYNOPSIS
    Provision-DocumentHubSite.ps1

 .DESCRIPTION
    Provisions Document Hub site pages, content types and other resources in to an existing Communication site created from the Valo Create Content button

 .PARAMETER SiteUrl
    Required, Site Url where to deploy the document hub template 

 .PARAMETER SiteTitle
    Optional, the document hub site will be updated with this Title 

 .PARAMETER PnPPath
    Optional, Where is the Document Hub site template located. If not defined, uses the default filename ".\ProvisioningTemplates\*" in the execution folder

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
    
    [Parameter(Mandatory = $false, HelpMessage = "File path to the pnp template(s) used for this provisioning process")]
    [ValidateNotNullOrEmpty()]
    [String]$PnPPath = ".\ProvisioningTemplates\*",

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

function Get-ValoTemplatesUrl {
    Param (
        $SiteUrl
    )

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

    return $TemplateSiteUrl

}

function Add-FolderStructure($SourceFolder, $DestinationFolder) {

    $RootFolder = Get-Item $SourceFolder
    
    Get-ChildItem "$($RootFolder.FullName)" -Recurse | % { 
    
        # Check if current item is a folder
        if ($_.PSIsContainer) {
            $FolderToCreateParent = "$DestinationFolder$($_.Parent.FullName.Replace($RootFolder.FullName, '').Replace("\", "/"))"
            if (-not (Get-PnPFolder "$FolderToCreateParent/$($_.Name)" -ErrorAction SilentlyContinue)) {
                Log -Message "Creating folder $($_.Name) in $FolderToCreateParent on template site."
                Add-PnPFolder -Name $_.Name -Folder $FolderToCreateParent | Out-Null
            }
        }
        else {
            $FileToCreateParent = "$DestinationFolder$($_.DirectoryName.Replace($RootFolder.FullName, '').Replace("\", "/"))"
            Log -Message "Uploading file $($_.Name) to $FileToCreateParent on template site."
            Add-PnPFile -Path $_.FullName -Folder $FileToCreateParent | Out-Null
    
        }
    }
    
}

function Get-SiteDefaultLanguage {
    Param (
        $Url
    )

    $connected = Ensure-ValoConnection -url $Url

    if (!$connected) {
        Log -Message "Something went wrong while connecting to the site $Url, exiting.." -Level Error 
        Exit
    }
    
    $LCID = Get-PnPProperty -ClientObject (Get-PnPWeb) -Property Language

    return $LCID

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

## Get target site's default language

$LCID = Get-SiteDefaultLanguage -Url $SiteUrl
$LanguageTable = Import-Csv -Path .\LanguageResources\Languages.csv
$ResourceFile = Get-ChildItem -Path ".\LanguageResources\$($LCID)_*.xml"
if (-not $ResourceFile) { 
    $ResourceFile = Get-ChildItem -Path ".\LanguageResources\1033_*.xml" 
    Log -Message "Default language for site $SiteUrl isn't available in LanguageResources - defaulting to $($ResourceFile.Name)." -Level Warning
}
if ($ResourceFile) {
    $SiteLanguageResource = Import-Clixml $ResourceFile.FullName
}
else {
    $SiteLanguageResource = @{}
}


## Get target site's valo templates site

$TemplateSiteUrl = Get-ValoTemplatesUrl -SiteUrl $SiteUrl


## Commence updates to Valo templates site

Log -Message "Connecting to Valo Templates site $TemplateSiteUrl" -Level Info -wrapWithSeparator
$templateSiteConnected = Ensure-ValoConnection -url $TemplateSiteUrl

if (!$templateSiteConnected) {
    Log -Message "Something went wrong while connecting to the template site $TemplateSiteUrl, exiting.." -Level Error 
    Exit
}

Log -Message "Uploading web part templates to Valo Templates Gallery" -Level Info -wrapWithSeparator
Get-Item .\ValoTemplates\TemplatesGallery\*.html | % {

    # Check if there's a matching .xml file, to use as metadata associated to the upladed html file
    if (Test-Path $_.FullName.Replace(".html", ".xml")) {
        $Values = Import-Clixml $_.FullName.Replace(".html", ".xml")
    }
    else {
        $Values = $null
    }

    # Upload the HTML file and associated metadata to the TemplatesGallery
    Add-PnPFile -Path $_.FullName -Folder TemplatesGallery -Values $Values | Out-Null
}

Log -Message "Ensuring site assets library exists on site $TemplateSiteUrl" -Level Info -wrapWithSeparator
Ensure-SiteAssetsLibrary

Log -Message "Uploading assets to Valo Templates Site Assets folder" -Level Info -wrapWithSeparator
. Add-FolderStructure .\ValoTemplates\SiteAssets SiteAssets

Log -Message "Uploading page templates to Valo Templates" -Level Info -wrapWithSeparator
$PnPTemplates = (Get-ChildItem -Path ".\ValoTemplates\ProvisioningTemplates\*" | Sort-Object -Property Name)

$PnPTemplates | % { 
    Log -Message $("Applying site template {0} to the site {1}" -f @($_.Name, $TemplateSiteUrl)) -Level Info -wrapWithSeparator
    Apply-PnPProvisioningTemplate -Path $_.FullName -Parameters $SiteLanguageResource -Debug:$ShowDebug
    
}

## Commence updates to target site

$connected = Ensure-ValoConnection -url $SiteUrl

if (!$connected) {
    Log -Message "Something went wrong while connecting back to the site $SiteUrl, exiting.." -Level Error 
    Exit
}

$PnPTemplates = (Get-ChildItem -Path $PnPPath | Sort-Object -Property Name)

$PnPTemplates | % { 
    Log -Message $("Applying site template {0} to the site {1}" -f @($_.Name, $SiteUrl)) -Level Info -wrapWithSeparator
    Apply-PnPProvisioningTemplate -Path $_.FullName -Parameters $SiteLanguageResource -Debug:$ShowDebug
    
}

#Possible additional configurations
Log -Message $("Executing additional configurations to {0}" -f $SiteUrl) -Level Info -wrapWithSeparator

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
    @{ Id = '0x0101009D1CB255DA76424F860D91F20E6C41180065789619A4EFB44992AF42CEEBB13C9A0301'; Name = "$($SiteLanguageResource.ValoPageTemplateNamePolicy)" }
    @{ Id = '0x0101009D1CB255DA76424F860D91F20E6C41180065789619A4EFB44992AF42CEEBB13C9A0302'; Name = "$($SiteLanguageResource.ValoPageTemplateNameProcedure)" }
    @{ Id = '0x0101009D1CB255DA76424F860D91F20E6C41180065789619A4EFB44992AF42CEEBB13C9A0303'; Name = "$($SiteLanguageResource.ValoPageTemplateNameHowToGuide)" }
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
