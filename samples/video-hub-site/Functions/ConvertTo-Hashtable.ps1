function ConvertTo-Hashtable { 
  param ( 
      [Parameter(  
          Position = 0,   
          Mandatory = $true,   
          ValueFromPipeline = $true,  
          ValueFromPipelineByPropertyName = $true  
      )] [object] $psCustomObject 
  );

  $output = @{}; 
  $psCustomObject | Get-Member -MemberType *Property | % {
      $output.($_.name) = $psCustomObject.($_.name); 
  } 
  
  return  $output;
}