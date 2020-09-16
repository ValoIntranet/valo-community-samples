$global:dir = $PSScriptRoot;

Import-Module $global:dir/module/Update-ValoSites.psm1 -Force

# define log file location
$global:logFileName = "$($global:dir)/logs/site-update_$([DateTime]::Now.ToString("yyyMMddhhmm")).log";

# migrate pages in the given hub, backup pages first
# Update-AllValoSites -HubSiteUrl "https://mytenant.sharepoint.com/sites/sample-hub" -BackupOldPages;

# migrate pages in the given hub - only 'dry mode'
# Update-AllValoSites -HubSiteUrl "https://mytenant.sharepoint.com/sites/sample-hub" -Analyze;

# migrate pages in the given site, backup pages first
Update-ValoSite -SiteUrl "https://mytenant.sharepoint.com/sites/sample-site" -BackupOldPages;

# migrate pages in the given site - only 'dry mode'
# Update-ValoSite -SiteUrl "https://mytenant.sharepoint.com/sites/sample-site" -Analyze;

# migrate pages defined in Excel sheet, backup pages first
# Update-ValoPages -FileName "$global:dir\input\migrate-pages.xlsx" -BackupOldPages;

# migrate pages defined in Excel sheet - only 'dry mode'
# Update-ValoPages -FileName "$PSScriptRoot\input\migrate-pages.xlsx" -Analyze;
