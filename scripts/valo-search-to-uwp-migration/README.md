# Migration solution for "Valo Search" to "Valo Universal" web parts

## Summary

This solution has been developed to ease the pain of migrating the "Valo Search" web part on hundreds of pages in each and every Valo intallation at your customer's tenants.

The idea behind the solution was of course to automate the migration process as far as possible. As both web parts have lots of parameters the overall task has some complexity. This said - don't expect this solution to be an out-of-the-box setup for all your migration tasks!

The effort you still need to invest before running the script on a specific tenant depends really on the handlebar templates you've currently in use. We've already prepared most of the Valo standard templates (at least the ones we use at the moment). These templates are included here - feel free to add more!

Of course we had a couple more templates that are plain customer specific. These are not included here, as they are not relevant for a generic solution.

I'll describe the migration process and the required steps under "Procedure" further below.

This app is developed using below technologies

* PowerShell 5.1
* SharePointPnPPowerShellOnline 3.25.2009.1

## Used Valo Version

* Tested with Valo Modern 1.6 and 1.7

## Prerequisites

It is required that the users have PowerShell 5.1 on Windows. As the solution makes full use of PnP library PowerShell Core is not sufficient.

[PnP PowerShell](https://docs.microsoft.com/en-us/powershell/sharepoint/sharepoint-pnp/sharepoint-pnp-cmdlets) must be installed on the client. We usually are working with the latest release as stated above, but feel free to test another one ...

## Procedure

### Operation Modes

This script solution has three general operation modes:

* Migrate specific pages defined in an [Excel sheet](./input/migrate-pages.xlsx).
* Migrate all pages in a specific site.
* Migrate all pages in all sites of a Valo hub.

You'll find a [sample bootstrap script](./valo-uwp-migration.ps1) that showcases most of the relevant operation modes.

### Required Steps

Before you can actually think about using one of the above methods you should check that you've all your preparations in place. So - what needs to be done first?

* Try to find out which handlebar templates are in use in your pages! For each handlebar template in use we will need a matching JSON template. How you get that I will tell you in a minute ...
* For Valo standard handlebars I've already included some required templates (but not all). If you need more, you'll have to generate them. The same is true of course for further custom templates you might have in use.
* You're unsure which kind of templates are in use? You're lucky - this solution will help you find out. Just start it in one of the above operation modes with the flag -Analyse set. Plese see the [sample bootstrap script](./valo-uwp-migration.ps1) for more details. Running the analysis will give you warning outputs for all handlebar templates the our solution currently cannot match.
![analysis output](./images/template-analysis.png)
* You've identified the template you need to add, by running the analysis first. To extend the template mapping you will have to add some code in the file [UpdateValoWebParts.psm1](./module/Update-ValoWebParts.psm1). The mappings in the following screenshot correlate with the JSON templates included [here](./module/json). New handlebar templates have to be added in the PowerShell file and the JSON file has to be added to the JSON folder. Please have a look at the naming-convention used here.
![template mapping](./images/template-mapping.png)
Extending the code to add another template mapping will look like this:
![extended mapping](./images/extend-template-types.png)
Staying in this scenario - to add the corresponding JSON file you'll have to add a JSON named "wp_valo_universal_hub-selection.json" to the [folder](./module/json).
* Ok - fine. Now you now, what needs to be mapped, but how to get that JSON template? That's actually easy - all you'll need is a Valo Universal webpart on a site page running the desired target handlebar template. You can easily export the JSON from there - it's exactly the PropertyJson Data of the web part. Open a PowerShell window and type the following commands (without comments, of course ...):

```powershell

# Connect to site
Connect-PnPOnline https://mytenant.sharepoint.com/sites/sample-site

# Get page
$page = Get-PnPClientSidePage -Identity sample-page.aspx

# Show page components
Get-PnPClientSideComponent -Page $page

# You will get output with all components on the page. 
# Search for Title "Valo - Search" and copy the "IntanceId" value

# Get Valo Search web part
$wp = Get-PnPClientSideComponent -Page $page -InstanceId some-guid

# Display the JSON data
$wp.PropertiesJson

# Copy the whole JSON from opening to closing curly bracket.
# Past the whole string to the new JSON file.
# You can "pretty print" it using e. g. VS Code to optimize readabilty.

```

* Oops, you don't have a handlebar that's Valo Universal web part compatible? Yes, that's some point. There is some template migration work to be done first, if you're using custom templates. Further details on that might be found in Valo documentation.
* Once you've done the above steps you might want to repeat the analysis done before. It should now look like this:
![successfull analysis](./images/template-analysis-success.png)
If that's the case, you're ready to roll. If not make sure to map all templates that still produce a waring first.

### Troubeshooting

The nasty thing with the PropertyJson data used for our JSON templates is, that not all properties will get exported in any case. So we need to make sure everything is in place that we might need for customizing.

## Setup

First you have to checkout the whole solution folder somewhere to your local harddisk. Now make sure that PnP PowerShell is installed on your machine.

For starting the solution, please customise and use the [sample bootstrap script](./valo-uwp-migration.ps1).

If you want to use an Excel sheet as input, you can use the [provided file](./input/migrate-pages.xlsx). Of course you'll have to add your own entries there. A sample entry is included to give you some clue of what is needed by our script.

## Solution

Solution|Author(s)
--------|---------
valo-search-to-uwp-migration | [Ole Rühaak](https://www.linkedin.com/in/ole-ruehaak/), [GIS AG](https://gis-ag.com)

## Version history

Version|Date|Comments
-------|----|--------
1.0 | September 15, 2020 | Initial Release

## Disclaimer

**THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.**
