<#
 .SYNOPSIS
    Provision-DocumentHubSite.ps1

 .DESCRIPTION
    Provisions site pages, content types and other resources in to an existing Communication site created from the Valo Create Content button

 .PARAMETER SiteUrl
    Required, Site Url where to deploy the template 

 .PARAMETER SiteTitle
    Optional, the site will be updated with this Title 

 .PARAMETER PnPPath
    Optional, Where is the site template located. If not defined, uses the default filename ".\ProvisioningTemplates\*" in the execution folder

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
    [Parameter(Mandatory = $true, HelpMessage = "Url of the site where site resources are to be provisioned.")]
    [ValidateNotNullOrEmpty()]
    [String]$SiteUrl,
    
    [Parameter(Mandatory = $false, HelpMessage = "The site will be updated with this Title (if specified)")]
    [ValidateNotNullOrEmpty()]
    [String]$SiteTitle,
    
    [Parameter(Mandatory = $false, HelpMessage = "File path to the Valo Templates pnp template(s) used for this provisioning process")]
    [ValidateNotNullOrEmpty()]
    [String]$ValoTemplatesPnPPath = ".\ValoTemplates\Provisioning\*.xml",

    [Parameter(Mandatory = $false, HelpMessage = "File path to the pnp template(s) used for this provisioning process")]
    [ValidateNotNullOrEmpty()]
    [String]$TemplatesPnPPath = ".\Templates\Provisioning\*.xml",

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

Push-Location $PSScriptRoot

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
    
    Log -Message "Obtaining Valo Templates site url" -Level Info
    
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

function ConvertTo-Hashtable { 
    param ( 
        [Parameter(  
            Position = 0,   
            Mandatory = $true,   
            ValueFromPipeline = $true,  
            ValueFromPipelineByPropertyName = $true  
        )] [object] $psCustomObject 
    );

    $output = @{}; 
    $psCustomObject | Get-Member -MemberType *Property | % {
        $output.($_.name) = $psCustomObject.($_.name); 
    } 
    
    return  $output;
}

function Get-ResourceFileValues { 
    Param (
        $Path
    )

    $Values = $null

    if (Test-Path $Path) {
        $Values = Get-Content -Raw -Path $Path | ConvertFrom-Json | ConvertTo-Hashtable
    }

    return $Values
}

function Deploy-ValoTemplate {
    Param(
        $SiteUrl,
        $TemplatePath
    )

    # Validating the Path and Applying the templates
    if(Test-Path $TemplatePath) {
        # Commence updates to site
        Log -Message "Connecting to site $SiteUrl" -Level Info
        $siteConnected = Ensure-ValoConnection -Url $SiteUrl

        if (!$siteConnected) {
            Log -Message "Something went wrong while connecting to the site $SiteUrl, exiting.." -Level Error 
            Exit
        }

        $LanguageInformation = $global:LanguageTable | Where-Object { $_.LCID -eq (Get-SiteDefaultLanguage -Url $SiteUrl) }
        $LanguageResources = Get-ResourceFileValues -Path ".\Resources\$($LanguageInformation.LanguageTag).json"

        Log -Message "Applying provisioning templates to $SiteUrl" -Level Info -wrapWithLightSeparator
        $PnPTemplates = (Get-ChildItem -Path $TemplatePath | Sort-Object -Property Name)
        
        $PnPTemplates | % { 
            Log -Message $("Applying template {0} to the site {1}" -f @($_.Name, $SiteUrl)) -Level Info
            Apply-PnPProvisioningTemplate -Path $_.FullName -Parameters $LanguageResources -Debug:$ShowDebug
        }
    }
}

#-----------------------------------------------------------------------
# Loading the Framework
#-----------------------------------------------------------------------
. Get-Framework $PartnerPackScriptRoot

#-----------------------------------------------------------------------
# Loading Template Information
#-----------------------------------------------------------------------
$TemplateInformation = (Get-Content template.json) | ConvertFrom-Json
Set-GlobalVariable -parameterName TemplateInformation -value $TemplateInformation

#-----------------------------------------------------------------------
# Getting the Language Reference Table for further use
#-----------------------------------------------------------------------
$LanguageTable = Import-Csv -Path .\Resources\Languages.csv
Set-GlobalVariable -parameterName LanguageTable -value $LanguageTable

#-----------------------------------------------------------------------
# Setuping the Logger
#-----------------------------------------------------------------------
Setup-Logger -debugParam $ShowDebug -logToFileParam $true -logFileName $TemplateInformation.InternalName

#-----------------------------------------------------------------------
# Starting a new Timer
#-----------------------------------------------------------------------
$totalRunTime = [Diagnostics.Stopwatch]::StartNew()
    
Log -Message $("Provisioning $($TemplateInformation.Name) template") -Level Info -wrapWithSeparator

$tenantUrl = Get-TenantUrlFromSiteUrl $SiteUrl
Set-GlobalVariable -parameterName tenantUrl -value $tenantUrl

#-----------------------------------------------------------------------
# Initialize global variables used in the script
#-----------------------------------------------------------------------
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

#-----------------------------------------------------------------------
# Deploy the Valo Templates artefacts
#-----------------------------------------------------------------------
Deploy-ValoTemplate -SiteUrl (Get-ValoTemplatesUrl -SiteUrl $SiteUrl) -TemplatePath $ValoTemplatesPnPPath

#-----------------------------------------------------------------------
# Deploy the Target Site artefacts
#-----------------------------------------------------------------------
Deploy-ValoTemplate -SiteUrl $SiteUrl -TemplatePath $TemplatesPnPPath

$totalRunTime.Stop()
$total = [Math]::Round($totalRunTime.Elapsed.TotalMinutes).ToString()
Log -Message "Valo $($TemplateInformation.Name) template was provisioned in $total minutes" -Level Info -wrapWithSeparator
Setup-Logger -debugParam $false -logToFileParam $false -logFileName ""
Disconnect-PnPOnline
if ($ShowDebug) {
    Set-PnPTraceLog -Off
}

Pop-Location