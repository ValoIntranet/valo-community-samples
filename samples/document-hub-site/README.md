---
title: Document Hub Site
author: Mark Powney
createdByValo: true
htmlTemplate:
  - DocumentHub.html
pnpTemplate:
  - ValoTemplates.pnp
  - DocumentHubSite.pnp
script:
  - Provision-DocumentHubSite.ps1
sppkg: ""
---

# Document Hub Site

## Summary
This is a sample site template.  The template includes a series of custom content types, page templates, and a custom Universal Web Part template.  

Once provisioned, the site establishes a recommeded pattern for authors to easily create content for a document hub, knowledge base, how-to guides, or similar content. The site is also designed for visitors to find content via a search experience.  The established search experience enables authors to refine the results, based on metadata established in the search content.

This app is developed using below technologies 
* Document Hub PnP template
* Document Hub Universal Web Part template
* Page Templates provisioned to Valo Templates site via PnP template
* Deployment Script

## Used Valo Version 
![Version 1.6](https://img.shields.io/badge/version-1.6-green.svg)

## Prerequisites
 
An existing Valo site must be used to deploy this document hub to.

## PowerShell provisioning command

```powershell
cd .\samples\document-hub-site
.\Provision-DocumentHubSite.ps1 `
    -SiteUrl https://contoso.sharepoint.com/sites/my-document-hub `
    -Office365CredentialStoreKey ValoOffice365Admin
```

## Solution

Solution|Author(s)
--------|---------
document-hub-site | [Mark Powney](https://m.pown.ee/linkedin) ([@mpowney](https://twitter.com/mpowney))

## Version history

Version|Date|Comments
-------|----|--------
1.0 | August 03, 2020 | Initial Release

## Disclaimer
**THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.**