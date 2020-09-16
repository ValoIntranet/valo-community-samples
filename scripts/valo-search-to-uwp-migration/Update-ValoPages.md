# Update-ValoPages

This command is part of the ["Valo universal web part migration"](./README.md) solution.

It updates all pages defined in an Excel worksheet. The pages can be located in different hubs and different sites. It is recommended in that case to sort the sheet first by hub and then by site. This way the script will process the sheet site-wise, thus preventing unnecessary site connections to happen during the migration run.

The source code is located in the file [Update-ValoSites.psm1](./module/Update-ValoSites.psm1).

## Samples

Migrate all pages in the [Excel](./input/migrate-pages.xlsx) file's worksheet with the default name *'Update Pages'*, performing a backup of the pages first:

```powershell
Update-ValoPages -FileName "$global:dir\input\migrate-pages.xlsx" -BackupOldPages
```

Migrate all pages in the [Excel](./input/migrate-pages.xlsx) file's worksheet named *'My Pages'*,  performing a backup of the pages first:

```powershell
Update-ValoPages -FileName "$global:dir\input\migrate-pages.xlsx" -SheetName "My Pages" -BackupOldPages
```

Migrate all pages in the [Excel](./input/migrate-pages.xlsx) file's worksheet with the default name *'Update Pages'*, force migration of checked-out pages and performing a backup of the pages first:

```powershell
Update-ValoPages -FileName "$global:dir\input\migrate-pages.xlsx" -BackupOldPages -Force
```

Just analyze all pages in the [Excel](./input/migrate-pages.xlsx) file's worksheet with the default name *'Update Pages'*:

```powershell
Update-ValoPages -FileName "$PSScriptRoot\input\migrate-pages.xlsx" -Analyse
```

## Parameters

### FileName [mandatory]

The full path to the Excel sheet.

### SheetName [optional]

The name of the sheet that contains the relevant data. Defaults to "Update Pages".

### BackupOldPages [flag]

If flag is set, script will backup the pages prior to the actual migration.

### Analyze [flag]

If flag is set, script will just do a 'dry run' without actually converting the pages. This mode is very useful to see which kind of view templates (Handlebar) are used by the pages.

### Force [flag]

If flag is set, script will do a 'cancel checkout' on pages currently checked out. 

## Excel File

The Excel worksheet as input for this command needs to define the following columns. A [sample Excel file](./input/migrate-pages.xlsx) is included in the solution.

### Hub

The prefix or synonym of the hub. The parameter is used for separating the exported pages in hub-based folders, if the *-BackupOldPages* flag has been set. So it technically doesn't need to be your Valo hub prefix, but at least in multi hub setups I would strongly recommend to use that value for better clearance.

### Site

This is the full site URL of the page you want to be migrated.

### Name

This is the file name of the page to migrate.