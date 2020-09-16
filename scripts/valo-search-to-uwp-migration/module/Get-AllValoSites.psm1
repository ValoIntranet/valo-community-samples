Import-Module $PSScriptRoot/Log.psm1 -Force

<#
 .Synopsis
  Gets all sites in the given Valo hub.

 .Description
  Retrieves all sites associated to the given Valo hub.

 .Parameter HubSiteUrl
  The URL of the Valo hub's root site to process.

 .Example
   # Get all sites in the hub
   Get-AllValoSites -HubSiteUrl "https://mytenant.sharepoint.com/sites/sample-hub"
#>
function Get-AllValoSites {
    
    param(
        [parameter(Mandatory=$true)]$HubSiteUrl
    )

    Log "$PSScriptRoot\Get-AllValosites.psm1 has started" -level Debug

    try {
        Log "[Get-AllValoSites]: Start" -level Debug
        Log "Find all the Valo sites from HubSite: $HubsiteUrl." -level "Info"

        # connect to site
        Connect-PnPOnline $HubSiteUrl -UseWebLogin;

        $site = Get-PnPSite -Includes HubSiteId
        $hubsiteId = $site.HubSiteId;

        $sitesUrls = @();
        $metaData = Submit-PnPSearchQuery -Query "contenttype:Valositemetadata DepartmentID:{$hubsiteId}" -SourceId "8413cd39-2156-4e00-b54d-11efd9abdb89" -TrimDuplicates $false
        $metaData.ResultRows | ForEach-Object {  
            if (!$sitesUrls.Contains($_.SPWebUrl)) {
                $sitesUrls += $_.SPWebUrl  
            }
        } 
        return $sitesUrls;
    }
    catch {
        Log "[Get-AllValoSites]: Something went wrong. Error='$($_.Exception.Message)'" -level Error
    }
    finally {
        Log "[Get-AllValoSites]: Finish" -level Debug
    }

    Log "DONE" -level Debug
}

Export-ModuleMember -Function Get-AllValoSites;