function Deploy-ValoTemplate {
  Param(
      $TenantUrl,
      $TemplatePath,
      $TemplateParameters
  )

  # Validating the Path and Applying the templates
  if(Test-Path $TemplatePath) {
      # Commence updates to site
      Log -Message "Connecting to site $TenantUrl" -Level Info
      $siteConnected = Ensure-ValoConnection -Url $TenantUrl

      if (!$siteConnected) {
          Log -Message "Something went wrong while connecting to the site $TenantUrl, exiting.." -Level Error 
          Exit
      }
      Log -Message "Applying provisioning templates to $TenantUrl" -Level Info -wrapWithLightSeparator
      Apply-PnPTenantTemplate -Path $TemplatePath -Parameters $TemplateParameters -Debug:$ShowDebug | Out-Null
  }
}