Param(
  [string]$Office365CredentialStoreKey,
  [string]$TenantAdminUrl,
  [string]$UserProfileSiteUrl,
  [string]$UserProfileListUrl = "/Lists/ValoUserProfiles"
)

# Getting the credentials
if($Office365CredentialStoreKey) {
  $credential = Get-PnPStoredCredential -Name $Office365CredentialStoreKey -Type PSCredential
} else {
  $credential = Get-Credential
}

Connect-AzureAD -Credential $credential | Out-Null
$tenantConnection = Connect-PnPOnline -Url $TenantAdminUrl -Credentials $credential -ReturnConnection
$userProfileSiteConnection = Connect-PnPOnline -Url $UserProfileSiteUrl -Credentials $credential -ReturnConnection

$users = Get-AzureADUser -All $true
$userProfileList = Get-PnPList -Identity $UserProfileListUrl -Connection $userProfileSiteConnection -ErrorAction SilentlyContinue

if($userProfileList) {
  $users | ForEach-Object {
    $userProperties = Get-PnPUserProfileProperty -Account $_.UserPrincipalName -Connection $tenantConnection -ErrorAction SilentlyContinue
  
    if($userProperties) {
      $existingProfile = Get-PnPListItem -List $userProfileList -Query "<View><Query><Where><Eq><FieldRef Name='ValoProfileAccountName'/><Value Type='Text'>$($userProperties.UserProfileProperties.AccountName)</Value></Eq></Where></Query></View>"

      if(!$existingProfile) {
        Write-Host "Adding $($userProperties.UserProfileProperties.AccountName)"
        Add-PnPListItem -List $userProfileList -Connection $userProfileSiteConnection -Values @{
          "Title" = $userProperties.UserProfileProperties.PreferredName;
          "ValoProfileDisplayName" = $userProperties.UserProfileProperties.PreferredName;
          "ValoProfileFirstName" = $userProperties.UserProfileProperties.FirstName;
          "ValoProfileLastName" = $userProperties.UserProfileProperties.LastName;
          "ValoProfileJobTitle" = $userProperties.UserProfileProperties.Title;
          "ValoProfileDepartment" = $userProperties.UserProfileProperties.Department;
          "ValoProfileWorkPhone" = $userProperties.UserProfileProperties.WorkPhone;
          "ValoProfileMobilePhone" = $userProperties.UserProfileProperties.CellPhone;
          "ValoProfileWorkEmail" = $userProperties.UserProfileProperties.WorkEmail;
          "ValoProfileOfficeNumber" = $userProperties.UserProfileProperties.Office;
          "ValoProfileAccountPictureURL" = $userProperties.UserProfileProperties.PictureURL;
          "ValoProfileAccountName" = $userProperties.UserProfileProperties.AccountName;
          "ValoProfileType" = $_.UserType;
        } | Out-Null
      } else {
        Write-Host "Updating $($userProperties.UserProfileProperties.AccountName)"
        Set-PnPListItem -List $userProfileList -Identity $existingProfile -Connection $userProfileSiteConnection -Values @{
          "Title" = $userProperties.UserProfileProperties.PreferredName;
          "ValoProfileDisplayName" = $userProperties.UserProfileProperties.PreferredName;
          "ValoProfileFirstName" = $userProperties.UserProfileProperties.FirstName;
          "ValoProfileLastName" = $userProperties.UserProfileProperties.LastName;
          "ValoProfileJobTitle" = $userProperties.UserProfileProperties.Title;
          "ValoProfileDepartment" = $userProperties.UserProfileProperties.Department;
          "ValoProfileWorkPhone" = $userProperties.UserProfileProperties.WorkPhone;
          "ValoProfileMobilePhone" = $userProperties.UserProfileProperties.CellPhone;
          "ValoProfileWorkEmail" = $userProperties.UserProfileProperties.WorkEmail;
          "ValoProfileOfficeNumber" = $userProperties.UserProfileProperties.Office;
          "ValoProfileAccountPictureURL" = $userProperties.UserProfileProperties.PictureURL;
          "ValoProfileAccountName" = $userProperties.UserProfileProperties.AccountName;
          "ValoProfileType" = $_.UserType;
        } | Out-Null
      }
    }
  }
} else {
  Write-Error "The User Profile List '$UserProfileListUrl' does not exist"
}
