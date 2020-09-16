
Import-Module $PSScriptRoot/Log.psm1 -Force
Import-Module $PSScriptRoot/Update-ValoWebParts.psm1 -Force
Import-Module $PSScriptRoot/Get-AllValoSites.psm1 -Force

$global:lastSiteUrl = $null;

<#
 .Synopsis
  Convertes Valo Search web part to Valo Universal web part in all sites of the given Valo hub.

 .Description
  Converts all instances of the Valo Search web part to Valo Universal web part in all sites of the given Valo hub.

 .Parameter HubSiteUrl
  The URL of the Valo hub's root site to process.

 .Parameter HubPrefix
  Valo hub site prefix - defaults to 'default'. This is required for defining the backup location.

 .Parameter BackupOldPages
  If flag is set, script will backup the pages prior to the actual migration.

 .Parameter Analyze
  If flag is set, script will just do a 'dry run' without actually converting the pages.
  This mode is very useful to see which kind of view templates (Handlebar) are used by the pages.

 .Parameter Force
  If flag is set, script will do a 'cancel checkout' on pages currently checked out.  

 .Example
   # Process all sites in the hub
   Update-AllValoSites -HubSiteUrl "https://mytenant.sharepoint.com/sites/sample-hub"

 .Example
   # Process all sites in the hub and define a hub prefix
   Update-AllValoSites -HubSiteUrl "https://mytenant.sharepoint.com/sites/sample-hub" -HubPrefix myhub-prefix

 .Example
   # Process all sites in the hub and backup the pages first
   Update-AllValoSites -HubSiteUrl "https://mytenant.sharepoint.com/sites/sample-hub" -BackupOldPages

 .Example
   # Process all sites in the hub in dry mode (analysis only)
   Update-AllValoSites -HubSiteUrl "https://mytenant.sharepoint.com/sites/sample-hub" -Analyze
#>
function Update-AllValoSites {
    param (
        [parameter(Mandatory=$true)]$HubSiteUrl,
        [parameter(Mandatory=$false)]$HubPrefix = "default",
        [switch] $BackupOldPages,
        [switch] $Analyze,
        [switch] $Force
    )
    try {
        Log "[Update-AllValoSites]: Start" -level Debug

        Log "[Update-AllValoSites]: Retrieving sites for Valo hub $($HubSiteUrl).";
        $siteUrls = Get-AllValoSites -HubSiteUrl $HubSiteUrl;  
        
        $i = 0;
        $total = $siteUrls.Count;
        foreach ($siteUrl in $siteUrls) {
            $i++;
            Log -log "[Update-AllValoSites]: Processing site. Url='$($siteUrl)' ; Progress='$($i)/$($total)'"

            try {
                # Update the site
                Update-ValoSite -SiteUrl $siteUrl -HubPrefix $HubPrefix -BackupOldPages:$BackupOldPages -Analyze:$Analyze -Force:$Force;
            }
            catch {
                Log -log "[Update-AllValoSites]: Something went wrong processing site $siteUrl. Error='$($_.Exception.Message)'" -level Error
            }

            Log -log "[Update-AllValoSites]: Finished processing site. Url='$($siteUrl)' ; Progress='$($i)/$($total)'"
        }
    }
    catch {
        Log -log "[Update-AllValoSites]: Something went wrong. Error='$($_.Exception.Message)'" -level Error
    }
    finally {
        Log -log "[Update-AllValoSites]: Finish" -level Debug
    } 
}

<#
 .Synopsis
  Convertes Valo Search web part to Valo Universal web part.

 .Description
  Converts all instances of the Valo Search web part to Valo Universal web part in the given site.

 .Parameter SiteUrl
  The URL of the site to process.

 .Parameter HubPrefix
  Valo hub site prefix - defaults to 'default'. This is required for defining the backup location.

 .Parameter BackupOldPages
  If flag is set, script will backup the pages prior to the actual migration.

 .Parameter Analyze
  If flag is set, script will just do a 'dry run' without actually converting the pages.
  This mode is very useful to see which kind of view templates (Handlebar) are used by the pages.

 .Parameter Force
  If flag is set, script will do a 'cancel checkout' on pages currently checked out.    

 .Example
   # Process excel file named 'worksheet.xlsx'
   Update-ValoSite -FileName c:\tmp\worksheet.xslx

 .Example
   # Process excel file named 'worksheet.xlsx' and backup the pages first
   Update-ValoSite -FileName c:\tmp\worksheet.xslx -BackupOldPages

 .Example
   # Process excel file named 'worksheet.xlsx' in dry mode (analysis only)
   Update-ValoSite -FileName c:\tmp\worksheet.xslx -Analyze
#>
function Update-ValoSite
{
    param (
        [parameter(Mandatory=$true)]$SiteUrl,
        $HubPrefix = "default",
        [switch] $BackupOldPages,
        [switch] $Analyze,
        [switch] $Force
    )

    # connect to site
    if ($SiteUrl -ne $global:lastSiteUrl)
    {
        Log "Connecting to site $($SiteUrl)." -level Info;
        Connect-PnPOnline $SiteUrl -UseWebLogin;
        $global:lastSiteUrl = $SiteUrl;
    }

    # get page items
    $library = Get-PnPList -Identity "SitePages";
    if ($library)
    {
        $i = 0;
        $total = $library.ItemCount;
        Get-PnPListItem -List $library  | ForEach-Object {
            $i++;
            Log "Processing page. Url='$($_.FieldValues.FileRef)' ; Progress='$($i)/$($total)'" -level Info;  

            $Page = Get-PnPClientSidePage -Identity $_.FieldValues.FileLeafRef

            if ($Page)
            {
                $siteName = $null;
                if ($SiteUrl -match '\/sites\/(.*)')
                {
                    $siteName = $matches[1];
                }

                # process page
                Update-SitePage -Page $Page -HubName $HubPrefix -SiteName $siteName -PageName $_.FieldValues.FileLeafRef -BackupOldPages $BackupOldPages -Analyze $Analyze;
            }
            else 
            {
                Log "Unable to access page '$($_.FieldValues.FileRef)'." -level Error
            }
        }
    }
}

<#
 .Synopsis
  Convertes Valo Search web part to Valo Universal web part.

 .Description
  Converts all instances of the Valo Search web part on all pages defined in the Excel.

 .Parameter FileName
  The full path to the Excel sheet.

 .Parameter SheetName
  The name of the sheet that contains the relevant data. Defaults to "Update Pages".

 .Parameter BackupOldPages
  If flag is set, script will backup the pages prior to the actual migration.

 .Parameter Analyze
  If flag is set, script will just do a 'dry run' without actually converting the pages.
  This mode is very useful to see which kind of view templates (Handlebar) are used by the pages.

 .Parameter Force
  If flag is set, script will do a 'cancel checkout' on pages currently checked out.    

 .Example
   # Process excel file named 'worksheet.xlsx'
   Update-ValoPages -FileName c:\tmp\worksheet.xslx

 .Example
   # Process excel file named 'worksheet.xlsx' and backup the pages first
   Update-ValoPages -FileName c:\tmp\worksheet.xslx -BackupOldPages

 .Example
   # Process excel file named 'worksheet.xlsx' in dry mode (analysis only)
   Update-ValoPages -FileName c:\tmp\worksheet.xslx -Analyze
#>
function Update-ValoPages 
{
    param (
        [parameter(Mandatory=$true)]$FileName,
        [parameter(Mandatory=$false)]$Sheetname = "Update Pages",
        [switch] $BackupOldPages,
        [switch] $Analyze,
        [switch] $Force
    )
    
    $sheet = $null;
    try {
        $sheet = Import-Excel -Path $FileName -WorksheetName $SheetName -ErrorAction Stop
    }
    catch {
        Log "Unable to import file $FileName." -level Error;
        exit;
    }
    
    if ($sheet)
    {
        $i = 0;
        $total = $sheet.Count;
        $sheet | ForEach-Object {
            $i++;
            Log "[Update-SitePages]: Processing page. Url='$($_.Site)/SitePages/$($_.Name)' ; Progress='$($i)/$($total)'" -level Info;

            # connect to site
            if ($_.Site -ne $global:lastSiteUrl)
            {
                Log "Connecting to site $($_.Site)." -level Info;
                Connect-PnPOnline $_.Site -UseWebLogin;
                $global:lastSiteUrl = $_.Site;
            }

            # get the page list item
            Log "Trying to access page list item $($_.Name) ..." -level Debug
            $Page = Get-PnPListItem -List "SitePages" -Query "<View><Query><Where><Eq><FieldRef Name='FileLeafRef'/><Value Type='Text'>$($_.Name)</Value></Eq></Where></Query></View>";

            if ($Page)
            {
                $siteName = $null;
                if ($_.Site -match '\/sites\/(.*)')
                {
                    $siteName = $matches[1];
                }

                # process page
                Update-SitePage -Page $Page -HubName $_.Hub -SiteName $siteName -PageName $_.Name -BackupOldPages:$BackupOldPages -Analyze:$Analyze -Force:$Force;
            }
            else 
            {
                Log "Unable to access page '$($Page.FieldValues.FileRef)'." -level Error
            }
        }
    }   
}

function Update-SitePage($Page, $HubName, $SiteName, $PageName, $BackupOldPages = $false, $Analyze = $false, $Force = $false)
{
    # undo checkout - if needed
    if ($null -ne $Page.FieldValues.CheckoutUser)
    {
        if ($Force)
        {
            Log "Page $($PageName) is checked-out. We'll have to cancel that ..." -level Warning
            $file = $Page.File;
            $file.UndoCheckOut();
            $file.Context.ExecuteQuery();
        } 
        else 
        {
            Log "Page $($PageName) is checked-out. We cannot handle that. Use -Force parameter to override ..." -level Warning
        }
    }

    # make PnP template export as backup
    if ($BackupOldPages)
    {
        # create hub directory, if necessary
        if (!(Test-Path "$($PSScriptRoot)\..\temp\$($HubName)"))
        {
            $Null = @( 
                mkdir "$($PSScriptRoot)\..\temp\$($HubName)";
            );
        }

        # create site directory, if necessary
        if (!(Test-Path "$($PSScriptRoot)\..\temp\$($HubName)\$($SiteName)"))
        {
            $Null = @( 
                mkdir "$($PSScriptRoot)\..\temp\$($HubName)\$($SiteName)";
            );
        }

        # export page
        Export-PnPClientSidePage -Identity $PageName -Out "$($PSScriptRoot)\..\temp\$($HubName)\$($SiteName)\$($PageName).xml" -Force;
    }

    # proceed operation on ClientSidePage
    $Page = Get-PnPClientSidePage -Identity $PageName;
    if ($Page)
    {
        Update-ValoWebParts -Page $Page -Analyze:$Analyze;
    }
    else {
        Log "File '$($PageName)' not found!" -level Warning;
    }
}

Export-ModuleMember -Function Update-AllValoSites, Update-ValoSite, Update-ValoPages;