<#
 .Synopsis
  Module to resuse PnPContext.

 .Description
  Reuses PnPContext to limit actual re-connects to the minium.

 .Parameter SiteUrl
  The site URL to connnect to.

 .Example
   # connect to a site
   Get-Context -SiteUrl "https://my-tenant.sharepoint.com/sites/my-site-to-connect-to"
#>
function Get-Context
{
    param(
        [parameter(Mandatory=$true)][string]$SiteUrl
    )

    $currentCtx = $null;

    $Null = @(
        try {
            # try to reuse context
            $currentCtx = Get-PnPContext -ErrorAction SilentlyContinue;
        }
        catch 
        {
            # do nothing
        }
        
        # if we have a current context we will clone the new one.
        if ($currentCtx)
        {
            # make sure, the new url get propagated
            Set-PnPNewUrl -NewUrl $SiteUrl

            $newCtx = [Microsoft.SharePoint.Client.ClientContextExtensions]::Clone($currentCtx, $SiteUrl);
            if ($newCtx)
            {
                Set-PnPContext -Context $newCtx -ErrorAction Stop;

                $currentCtx = Get-PnPContext -ErrorAction SilentlyContinue;
            }
            else 
            {
                Disconnect-PnPOnline -ErrorAction SilentlyContinue;
                $currentCtx = $null;
            }
        }
        
        # if we don't have a current context, we will just connect.
        if (!$currentCtx) 
        {
            Connect-PnPOnline $SiteUrl -UseWebLogin -ErrorAction Stop;
            $currentCtx = Get-PnPContext -ErrorAction SilentlyContinue;
        }
    );

    return $currentCtx;
}

function Set-PnPNewUrl($NewUrl)
{
    # works with SharePointPnPPowerShellOnline version 3.22.2006.2 
    # $connection = [SharePointPnP.PowerShell.Commands.Base.PnPConnection](Get-PnPConnection);

    # works with latest version of SharePointPnPPowerShellOnline
    $connection = [PnP.PowerShell.Commands.Base.PnPConnection](Get-PnPConnection);

    $connection.GetType().GetProperty("Url").SetValue($connection, $NewUrl);
}

Export-ModuleMember -Function Get-Context;