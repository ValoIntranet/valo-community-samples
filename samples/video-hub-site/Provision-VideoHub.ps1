<#
 .SYNOPSIS
    Provision-DocumentHubSite.ps1

 .DESCRIPTION
    Provisions site pages, content types and other resources in to an existing Communication site created from the Valo Create Content button

 .PARAMETER TenantUrl
    Required, Tenant Url where to deploy the template 
    
 .PARAMETER TemplatesSiteUrl
    Required, Valo Templates Site Url

 .PARAMETER VideoHubSiteUrl
    Required, Video Hub Site Url

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
    [Parameter(Mandatory = $false, HelpMessage = "Url of the tenant")]
    [String]$TenantUrl,

    [Parameter(Mandatory = $false, HelpMessage = "Url of the Valo Templates site")]
    [String]$ValoTemplatesUrl,

    [Parameter(Mandatory = $false, HelpMessage = "Url of the Video Hub site")]
    [String]$VideoHubUrl,
    
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
        # Loading Every *.ps1 file contained in the Partner Pack \Functions\Log folder
        #-----------------------------------------------------------------------
        Get-ChildItem -Path "$(Join-Path $PartnerPackScriptRoot "\Functions\Log\*.ps1")" -Recurse -ErrorAction Stop | ForEach-Object {
            . $_.FullName 
        }

        #-----------------------------------------------------------------------
        # Loading Every *.ps1 file contained in the Partner Pack \Functions\SampleContent folder
        #-----------------------------------------------------------------------
        Get-ChildItem -Path "$(Join-Path $PartnerPackScriptRoot "\Functions\SampleContent\*.ps1")" -Recurse -ErrorAction Stop | ForEach-Object {
            . $_.FullName 
        }

        #-----------------------------------------------------------------------
        # Loading Every *.ps1 file contained in the Partner Pack \Functions folder
        #-----------------------------------------------------------------------
        Get-ChildItem -Path "$(Join-Path $PartnerPackScriptRoot "\Functions\*.ps1")" -Recurse -ErrorAction Stop | ForEach-Object {
            . $_.FullName 
        }

        #-----------------------------------------------------------------------
        # Loading Every *.ps1 file contained in the \Functions folder
        #-----------------------------------------------------------------------
        Get-ChildItem -Path "$PSScriptRoot\Functions\*.ps1" -Recurse -ErrorAction Stop | ForEach-Object {
            . $_.FullName 
        }

    }
    Catch {
        Write-Error "Error getting Valo PartnerPack artifacts from path $PartnerPackScriptRoot. Aborting."
        Exit
    }    
}

#-----------------------------------------------------------------------
# Loading the Framework
#-----------------------------------------------------------------------
. Get-Framework $PartnerPackScriptRoot

#-----------------------------------------------------------------------
# Loading Template Parameters
#-----------------------------------------------------------------------
$TemplateParameters = (Get-Content template.json) | ConvertFrom-Json | ConvertTo-Hashtable

#-----------------------------------------------------------------------
# Setuping the Logger
#-----------------------------------------------------------------------
Setup-Logger -debugParam $ShowDebug -logToFileParam $true -logFileName $TemplateParameters.InternalName
$totalRunTime = [Diagnostics.Stopwatch]::StartNew()
Log -Message $("Provisioning $($TemplateParameters.Name) template") -Level Info -wrapWithSeparator

#-----------------------------------------------------------------------
# Building the Template specific parameters
#-----------------------------------------------------------------------
$TemplateParameters.TenantUrl = if($TenantUrl) { $TenantUrl } else { $TemplateParameters.TenantUrl };
$TemplateParameters.ValoTemplatesUrl = if($ValoTemplatesUrl) { $ValoTemplatesUrl } else { $TemplateParameters.ValoTemplatesUrl };
$TemplateParameters.VideoHubUrl = if($VideoHubUrl) { $VideoHubUrl } else { $TemplateParameters.VideoHubUrl };

if(!($TemplateParameters.TenantUrl) -or !($TemplateParameters.ValoTemplatesUrl) -or !($TemplateParameters.VideoHubUrl)) {
    Log -Message "Please provide TenantUrl, ValoTemplatesUrl and VideoHubUrl..." -Level Error 
    Exit
}

#-----------------------------------------------------------------------
# Provisoning the Template
#-----------------------------------------------------------------------
Provision-ValoTemplate `
    -TenantUrl $TemplateParameters.TenantUrl `
    -TemplateName $TemplateParameters.Name `
    -TemplateParameters $TemplateParameters `
    -Office365CredentialStoreKey $Office365CredentialStoreKey `
    -SharePointUserName $SharePointUserName `
    -SharePointPassword $SharePointPassword `
    -PartnerPackScriptRoot $PartnerPackScriptRoot `
    -ShowDebug:$ShowDebug `
    -useMFA:$useMFA

#-----------------------------------------------------------------------
# Tearing down the Logger
#-----------------------------------------------------------------------
$totalRunTime.Stop()
$total = [Math]::Round($totalRunTime.Elapsed.TotalMinutes).ToString()
Log -Message "Valo $($TemplateParameters.Name) template was provisioned in $total minutes" -Level Info -wrapWithSeparator
Setup-Logger -debugParam $false -logToFileParam $false -logFileName ""

Pop-Location