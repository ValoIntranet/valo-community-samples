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

    $Null = @(
        $currentCtx = $null;
        
        try {
            # try to reuse context
            $currentCtx = Get-PnPContext;
        }
        catch 
        {
            # do nothing
        }
        
        if ($currentCtx)
        {
            # if we have a current context we will clone the new one.
            SetPnPNewUrl -NewUrl $SiteUrl

            $newCtx = [Microsoft.SharePoint.Client.ClientContextExtensions]::Clone($currentCtx, $SiteUrl);
            if ($newCtx)
            {
                Set-PnPContext -Context $newCtx -ErrorAction Stop;
            }
            else 
            {
                Disconnect-PnPOnline
            }
        }
        else 
        {
            # if we don't have a current context, we will just connect.
            Connect-PnPOnline $SiteUrl -UseWebLogin -ErrorAction Stop;
        }
    );
}

function SetPnPNewUrl($NewUrl)
{
    # works with SharePointPnPPowerShellOnline version 3.22.2006.2 
    # $connection = [SharePointPnP.PowerShell.Commands.Base.PnPConnection](Get-PnPConnection);

    # works with latest version of SharePointPnPPowerShellOnline
    $connection = [PnP.PowerShell.Commands.Base.PnPConnection](Get-PnPConnection);

    $connection.GetType().GetProperty("Url").SetValue($connection, $NewUrl);
}

Export-ModuleMember -Function Get-Context;