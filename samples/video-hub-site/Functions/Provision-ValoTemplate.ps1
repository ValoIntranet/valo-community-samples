<#
 .SYNOPSIS
    Provision-DocumentHubSite.ps1

 .DESCRIPTION
    Provisions site pages, content types and other resources in to an existing Communication site created from the Valo Create Content button

 .PARAMETER SiteUrl
    Required, Site Url where to deploy the template 
    
 .PARAMETER TemplatesSiteUrl
    Required, Valo Templates Site Url

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
function Provision-ValoTemplate() {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "PasswordAuthenticationContext")]
    Param(
        [Parameter(Mandatory = $true, HelpMessage = "Url of the tenant")]
        [ValidateNotNullOrEmpty()]
        [String]$TenantUrl,
    
        [Parameter(Mandatory = $false, HelpMessage = "Parameters to use with the underlying template")]
        [Hashtable]$TemplateParameters,
        
        [Parameter(Mandatory = $false, HelpMessage = "Path to the template")]
        [String]$TemplateName,
        
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

    Set-GlobalVariable -parameterName tenantUrl -value $TenantUrl

    #-----------------------------------------------------------------------
    # Initialize global variables used in the script
    #-----------------------------------------------------------------------
    Initialize-GenesisVariables -tenantUrl $TenantUrl `
        -Office365CredentialStoreKey $Office365CredentialStoreKey `
        -SharePointUserName $SharePointUserName `
        -SharePointPassword $SharePointPassword `
        -installMode $installMode

    Initialize-Credentials `
        -Office365CredentialStoreKey $Office365CredentialStoreKey `
        -SharePointUserName $SharePointUserName `
        -SharePointPassword $SharePointPassword `
        -useMFA:$useMFA

    try {
        #-----------------------------------------------------------------------
        # Creating a temp folder
        #-----------------------------------------------------------------------
        if(!(Test-Path ".temp")) {
            New-Item -ItemType "directory" -Path ".temp" | Out-Null
        }
        
        #-----------------------------------------------------------------------
        # Deploy the tenant template
        #-----------------------------------------------------------------------
        Convert-PnPFolderToProvisioningTemplate -Out ".temp\$TemplateName.pnp" -Folder .\Provisioning\ -Force
        Deploy-ValoTemplate -TenantUrl $TenantUrl -TemplateParameters $TemplateParameters -TemplatePath ".temp\$TemplateName.pnp"

    } catch {
        Log -Message "Something went wrong, exiting.." -Level Error 
    } finally {
        #-----------------------------------------------------------------------
        # Removing the temp folder
        #-----------------------------------------------------------------------
        Remove-Item -Path ".temp" -Recurse 

        #
        Disconnect-PnPOnline
        if ($ShowDebug) {
            Set-PnPTraceLog -Off
        }
    }
}
