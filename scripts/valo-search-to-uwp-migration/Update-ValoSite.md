# Update-ValoSite

This command is part of the ["Valo universal web part migration"](./README.md) solution.

It updates all site pages in a site.

The source code is located in the file [Update-ValoSites.psm1](./module/Update-ValoSites.psm1).

## Samples

Migrate all pages in the site, performing a backup of the pages first:

```powershell
Update-AllValoSites -HubSiteUrl Update-ValoSite -SiteUrl "https://mytenant.sharepoint.com/sites/sample-site" -BackupOldPages
```

Migrate all pages in the site, force migration of checked-out pages and performing a backup of the pages first:

```powershell
Update-ValoSite -SiteUrl "https://mytenant.sharepoint.com/sites/sample-site" -BackupOldPages -Force
```

Just analyse all pages in the site:

```powershell
Update-ValoSite -SiteUrl "https://mytenant.sharepoint.com/sites/sample-site" -Analyze
```

## Parameters

### SiteUrl [mandatory]

The URL of the site to process.

### HubPrefix [optional]

Valo hub site prefix - defaults to 'default'. This is required for defining the backup location.

### BackupOldPages [flag]

If flag is set, script will backup the pages prior to the actual migration.

### Analyze [flag]

If flag is set, script will just do a 'dry run' without actually converting the pages. This mode is very useful to see which kind of view templates (Handlebar) are used by the pages.

### Force [flag]

If flag is set, script will do a 'cancel checkout' on pages currently checked out.
