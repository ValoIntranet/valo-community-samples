### Get valo templates pnp provisioning template (including all client side pages)
$ValoTemplatePages = Get-PnPProvisioningTemplate -OutputInstance -IncludeAllClientSidePages
$ValoTemplatePages = Read-PnPProvisioningTemplate -OutputInstance ..\ValoTemplates.pnp


### Remove pages from a Valo templates pnp template that aren't related to the document hub

$ValoTemplatePages = Get-PnPProvisioningTemplate -OutputInstance -IncludeAllClientSidePages
$FilesToRemove = $ValoTemplatePages.ClientSidePages | ? { $_.PageName -notlike 'Document-*' }
$FilesToRemove | % { $ValoTemplatePages.ClientSidePages.Remove($_) }
$ValoTemplatePages.ClientSidePages | % { $_.PageName }


### Remove all Site Fields from pnp template
for ($x=0; $x -le $ValoTemplatePages.SiteFields.Count; $x++) { $ValoTemplatePages.SiteFields.RemoveAt(0); }


### Remove custom actions scoped to the web
for ($x=0; $x -le $ValoTemplatePages.CustomActions.WebCustomActions.Count; $x++) { $ValoTemplatePages.CustomActions.WebCustomActions.RemoveAt(0); }

### Remove navigation elements
for ($x=0; $x -le $ValoTemplatePages.Navigation.CurrentNavigation.StructuralNavigation.NavigationNodes.Count; $x++) { $ValoTemplatePages.Navigation.CurrentNavigation.StructuralNavigation.NavigationNodes.RemoveAt(0); }


### Remove additional admins, owners, members
$ValoTemplatePages.Security.AdditionalAdministrators.Clear()
$ValoTemplatePages.Security.AdditionalOwners.Clear()
$ValoTemplatePages.Security.AdditionalMembers.Clear()
$ValoTemplatePages.Security.AdditionalVisitors.Clear()


### Remove property bag entries
for ($x=0; $x -le $ValoTemplatePages.PropertyBagEntries.Count; $x++) { $ValoTemplatePages.PropertyBagEntries.RemoveAt(0); }


### Remove site features
for ($x=0; $x -le $ValoTemplatePages.Features.SiteFeatures.Count; $x++) { $ValoTemplatePages.Features.SiteFeatures.RemoveAt(0); }


### Remove Header and Footer, site settings and web settings
$ValoTemplatePages.Footer = $null
$ValoTemplatePages.Header = $null
$ValoTemplatePages.SiteSettings = $null
$ValoTemplatePages.WebSettings = $null
$ValoTemplatePages.ComposedLook = $null
$ValoTemplatePages.RegionalSettings = $null

