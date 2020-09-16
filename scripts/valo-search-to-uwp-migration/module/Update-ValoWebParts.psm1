<#
 .Synopsis
  Convertes Valo Search web part to Valo Universal web part on the given client side page.

 .Description
  Converts all instances of the Valo Search web part to Valo Universal web parts on the given client side page.

 .Parameter Page
  The client side page to process.

 .Parameter Analyse
  If set to $true script will just do a 'dry run' without actually converting the pages.
  This mode is very usefull to see which kind of view templates (Handlebar) are used by the pages.

 .Example
   # Perfrom migration of "samplePage"
   Update-ValoWebParts -Page $samplePage

 .Example
   # Perfrom migration of "samplePage" in dry mode (only analysing).
   Update-ValoWebParts -Page $samplePag -Analyze $true
#>
Import-Module $PSScriptRoot/Log.psm1 -Force


$global:valo_search_title = "Valo - Search";
$global:valo_search_id = "0651b316-c8f2-4e27-887a-b7a46b3e94c1";
$global:valo_universal_title = "Valo - Universal";
$global:valo_refiners_title = "Valo - Refiners";
$global:valo_refiners_id = "56858ec9-a7cb-43c6-87c1-6edc8d92ce3a";

function Update-ValoWebParts
{
    param (
        [parameter(Mandatory=$true)]$Page,
        [switch] $Analyze
    )

    $searchWps = Get-PnPClientSideComponent -Page $Page  | where {$_.Title -eq $global:valo_search_title }
    if ($searchWps)
    {
        $searchWps | ForEach-Object {
            if ($_.WebPartId -eq $global:valo_search_id)
            {           
                ConvertWebparts -Page $Page -SearchWP $_ -Analyze:$Analyze;
            }
            else 
            {
                Log "The given 'Valo - Search' web part instance has the wrong Id - skipping." -level Warning;   
            }
        };

        if (!$Analyze)
        {
            # save the page
            $Page.Save();
            $Page.Publish();
        }
    }
    else 
    {
        Log "No 'Valo - Search' web parts found on given page - skipping." -level Warning; 
    }
}

function ConvertWebparts($Page, $SearchWP, $Analyze)
{
    Log "Migrating 'Valo Search' web part '$($SearchWP.InstanceId)' on '$($Page.PageTitle)' ..." -level Debug;

    # get generic web part parameters
    $wpSearch_IntanceId = $SearchWP.InstanceId;    
    $wpSearch_section = Get-Section -Page $page -Section $SearchWP.Section;
    $wpSearch_column = Get-Column -Section $SearchWP.Section -Column $SearchWP.Column;
    $wpSearch_order = $SearchWP.Order;
    $wpSearch_Properties = $SearchWP.PropertiesJson | ConvertFrom-Json;

    # determine correct template type
    $type = Get-TemplateType -properties $wpSearch_Properties -Analyze $Analyze;

    if (!$Analyze)
    {
        Log "Removing 'Valo - Search' web part '$($wpSearch_IntanceId)' ..." -level Debug;

        # remove 'Valo - Search' web part instance
        Remove-PnPClientSideComponent -Page $Page -InstanceId $SearchWP.InstanceId -Force
        $SearchWP = $null;

        Log "'Valo - Search' web part '$($wpSearch_IntanceId)' successfully removed." -level Debug;

        Log "Adding new 'Valo - Universal' web part instance ..." -level Debug;

        # add 'Valo - Univeral" web part instance
        $wpUniversal = Add-PnPClientSideWebPart -Page $Page -Component $global:valo_universal_title -Order $wpSearch_order -Section $wpSearch_section -Column $wpSearch_column;

        Log "'Valo - Universal' web part '$($wpUniversal.InstanceId)' successfully added." -level Debug;

        Log "Configuring 'Valo - Universal' web part '$($wpUniversal.InstanceId)' ..." -level Debug;

        

        # read JSON template for web part properties matching the specified template type
        $wpUniversal_Properties_Json =  Get-Content -Raw -Path "$PSScriptRoot\json\wp_valo_universal_$($type).json";

        # get web part properties object from JSON
        $wpUniversal_Properties = $wpUniversal_Properties_Json | ConvertFrom-Json;

        # set web part title
        $wpUniversal_Properties.title = $wpSearch_Properties.wpTitle;

        # set paging option
        if ($wpSearch_Properties.pagingOption)
        {
            $wpUniversal_Properties.selectedPagingOption = $wpSearch_Properties.pagingOption;
        }
        if ($wpSearch_Properties.hidePagingOptions -or $wpSearch_Properties.pagingOption -eq 9999)
        {
            # no paging controls: 1
            $wpUniversal_Properties.templateMetadata.pagingType = 1;
        }
        else {        
            # bottom with page numbers 2
            # top: 3
            # bottom: 4
            $wpUniversal_Properties.templateMetadata.pagingType = $wpSearch_Properties.pagingOption;
        }

        # items per page
        if ($wpSearch_Properties.maxResults)
        {
            $wpUniversal_Properties.searchDataSource.itemsCountPerPage = $wpSearch_Properties.maxResults;
        }

        # skip items
        if ($wpSearch_Properties.skipNr)
        {
            $wpUniversal_Properties.templateMetadata.skipResults = $wpSearch_Properties.skipNr;
        }

        # search scope
        if ($wpSearch_Properties.searchHub)
        {
            # limit to current hub
            $wpUniversal_Properties.searchDataSource.searchScope = 3;
        }
        elseif ($wpSearch_Properties.searchSite)
        {
            # limit to current site
            $wpUniversal_Properties.searchDataSource.searchScope = 2;
        }
        else 
        {
            # search whole tenant
            $wpUniversal_Properties.searchDataSource.searchScope = 1;
        }

        # template params
        if ($wpSearch_Properties.templateParams)
        {
            $wpSearch_Properties.templateParams | ForEach-Object {
                $param = $_;

                # get matching Valo UWP param
                $wpUniversal_param = $wpUniversal_Properties.templateParams | where { $_.name -eq $param.name };
                
                if ($wpUniversal_param)
                {
                    # modifiy default parameter
                    if ($param.value)
                    {
                        $wpUniversal_param.value = $param.value;
                    }
                    if ($param.description)
                    {
                        $wpUniversal_param.description = $param.description;
                    }
                    if ($param.options)
                    {
                        $wpUniversal_param.options = $param.options;
                    }                
                }
                else
                {
                    # add new parameter
                    $wpUniversal_Properties.templateParams += $param;
                }
            }
        }

        # set connections
        $updateRefiners = $false;
        if ($wpSearch_Properties.searchBoxSourceId -ne "")
        {
            $wpUniversal_Properties.searchDataSource.searchBoxSourceId = $wpSearch_Properties.searchBoxSourceId;
        }
        if ($wpSearch_Properties.searchRefinersSourceId -ne "")
        {
            $wpUniversal_Properties.searchDataSource.searchRefinersSourceId = $wpSearch_Properties.searchRefinersSourceId;
            $updateRefiners = $true;
        }

        # set KQL query
        $wpUniversal_Properties.searchDataSource.searchQuerySettings.searchQuery = $wpSearch_Properties.query;

        # sorting (we can only handle simple one parameter sorting like 'LastModifiedTime:ascending')
        if ($wpSearch_Properties.sorting)
        {
            $sort_params = $wpSearch_Properties.sorting.Split(":");
            $sort_property_name = $sort_params[0].trim();

            # map sort direction
            $sort_direction = switch ($sort_params[1].trim())
            {
                "ascending" { 
                    1;
                }  
                "descending" { 
                    2;
                }            
                default { 
                    1; 
                }
            }

            # build new sort object
            $sort_list = @();
            $sort_item = [pscustomobject]@{
                sortField = [pscustomobject]@{
                    name = $sort_property_name;
                    typeInfo = $null;
                }
                sortDirection = $sort_direction;
                sortIdx = 1;
            }
            $sort_list += $sort_item;

            $wpUniversal_Properties.searchDataSource.searchQuerySettings.sortList = $sort_list;
        }

        # configure new web part instance
        Set-PnPClientSideWebPart -Page $Page -Identity $wpUniversal.InstanceId -PropertiesJson ($wpUniversal_Properties | ConvertTo-Json -Depth 100); 

        Log "'Valo - Universal' web part '$($wpUniversal.InstanceId)' successfully configured." -level Debug;

        # update 'Valo - Refiners' web part, if necessary
        if ($updateRefiners)
        {
            Update-RefinersWebpart -Page $Page -OldInstanceId $wpSearch_IntanceId -NewInstanceId $wpUniversal.InstanceId;
        }
    }
}

function Get-TemplateType($Properties, $Analyze)
{
    $Null = @(  
        $value = $null;

        # 'internal' or 'external' template?
        if (($null -eq $Properties.intTemplate) -or ($Properties.intTemplate -eq "NO-TEMPLATE"))
        {
            $Properties.external -match '.+\/(.+)$';
            $value = $matches[1];
        }
        else {            
            $value = $Properties.intTemplate;
        }

        Log "Try to get mapping for old view template '$($value)' ... " -level Debug;

        $type = switch ($value)
        {
            "Documents.html" { 
                "documents";
            }
            "news.async.html" { 
                "news";
            }
            "news.compact.html" {
                "news-compact";
            }
            "People.html" { 
                "people";
            }
            "banner.quicklinks.html" {
                "banner";
            }
            "events.html" {
                "events"
            }            
            default { 
                $message = "Unknown view template type: '$($value)'";
                if ($Analyze)
                {
                    Log $message -level Warning;
                }
                else 
                {
                    throw $message; 
                }
            }
        }

        if ($type)
        {
            Log "Found '$($type)' as replacment for old template type '$($value)'." -level Debug;
        }
        else {
            Log "No matching view template found for old template type '$($value)'." -level Warning;
        }
    );

    return $type;
}

function Update-RefinersWebpart($Page, $OldInstanceId, $NewInstanceId)
{
    Log "Updating 'Valo Refiner' web part on '$($Page.PageTitle)' ..." -level Debug;

    $refinersWps = Get-PnPClientSideComponent -Page $page | where {$_.Title -eq $global:valo_refiners_title }
    $refinersWps | ForEach-Object {
        if ($_.WebPartId -eq $global:valo_refiners_id)
        {
            $Properties = $_.PropertiesJson | ConvertFrom-Json;
            if ($Properties.searchResultsSourceId -eq $OldInstanceId)
            {
                # set new id
                $Properties.searchResultsSourceId = $NewInstanceId;

                # re-configure 'ValoLanguage' refiner
                $refiner = $Properties.refiners | where { $_.name -eq "ValoLanguage" };
                if ($refiner)
                {
                    $refiner.name = "owstaxIdValoLanguage";
                    $refiner.type = "taxonomy";
                    $refiner.termsetId = "f29df4ec-6d48-43e7-ae9d-f4d40738df59";
                }

                # update web part
                Set-PnPClientSideWebPart -Page $Page -Identity $_.InstanceId -PropertiesJson ($Properties | ConvertTo-Json -Depth 100); 

                Log "'Valo Refiner' web part on '$($Page.PageTitle)' successfully updated." -level Debug;
            }
            else 
            {            
                Log "The given 'Valo - Refiners' web part instance has no binding to the id of the former 'Valo - Search' web part - skipping." -level Warning;
            }
        }
        else 
        {
            Log "The given 'Valo - Refiners' web part instance has the wrong Id - skipping." -level Warning;   
        }
    };
}

function Get-Section($Page, $Section)
{
    $Null = @(  
        $index = 1;
        foreach ($tmp_Section in $Page.Sections) {
            if ($Section -eq $tmp_Section)
            {
                break;
            }    
            $index++;         
        }
    );

    return $index;
}

function Get-Column($Section, $Column)
{
    $Null = @(  
        $index = 1;
        foreach ($tmp_Column in $Section.Columns) {
            if ($Column -eq $tmp_Column)
            {
                break;
            }    
            $index++;         
        }
    );

    return $index;
}

Export-ModuleMember -Function Update-ValoWebParts;