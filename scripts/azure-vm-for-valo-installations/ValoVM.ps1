<#PSScriptInfo      
.VERSION 1.1.0.0                       
.GUID 7bafe56d-60c6-4713-9dd0-73622e13a9f9 
.DESCRIPTION This script will help you to install VM for Valo installations.
.AUTHOR ilija@valointranet.com      
.COMPANYNAME Valo Solutions              
.COPYRIGHT 2020 Valo Solutions.                      
.TAGS Valo VM
.LICENSEURI https://valointranet.com/
.PROJECTURI https://valointranet.com/
.ICONURI https://valointranet.com/
.EXTERNALMODULEDEPENDENCIES Az 
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
Valo VM installation script can be used to install Windows 10 VM.
Feel free to leverage and extends as needed.
.PRIVATEDATA
#>
function Install-ValoVMInstallationDependecies{

    try{
        $azInstalled = Get-InstalledModule -Name Az -ErrorAction SilentlyContinue 
        if($null -eq $azInstalled){
            Write-Host 'Installing Azure PowerShell Module'
            Install-Module -Name Az -SkipPublisherCheck -Force -AllowClobber
            
        }
        else {
            $azVersionInstalled = ($azInstalled |  Sort-Object -Property Version -Descending | Select-Object -First 1)[0].Version 
            $azVersionLatest = (Find-Module -Name Az |Sort-Object -Property Version -Descending | Select-Object -First 1)[0].Version
            if($azVersionInstalled -notlike $azVersionLatest){
                Write-Host 'Installing latest Azure PowerShell Module'
                Install-Module -Name Az -SkipPublisherCheck -Force -AllowClobber
            }
        }
        Write-Host 'Importing Azure PowerShell Module'
        Import-Module -Name Az -Force
    }
    catch{
        Write-Host 'Error with installing or impoerting Azure PowerShell Module: ' $_.ErrorDetails
    }
    finally{
    }
}
function New-ValoAzureConnection {
    param (
        [Parameter(Mandatory)]
        [string]$subscriptionID
    )
    Write-Host 'Login to target Azure Environment'
    Connect-AzAccount
    Write-Host 'Initialize Azure Context with ' $subscriptionID
    Set-AzContext -SubscriptionId $subscriptionID

}
function Test-ValoVMResourceGroupLocation{
    param (
        [Parameter(Mandatory)]
        [Alias("LOC")]
        [string]$Location
    )
    $locationName = Get-AzLocation | Select-Object -Property DisplayName,Location | Where-Object -Property Location -EQ $Location
    if ($null -eq $locationName){
        Write-Host -ForegroundColor Red 'Check valid Resource Group location usings command: Get-AzLocation'
        Break
    }
}
function Test-ValoVMSize{
    param (
        [Parameter(Mandatory)]
        [Alias("LOC")]
        [string]$Location,
        [Parameter(Mandatory)]
        [Alias("SIZE")]
        [string]$VMSize
    )

    $size = Get-AzVMSize -Location $Location | Select-Object -Property Name | Where-Object -Property Name -EQ -Value $VMSize
    if($null -eq $size){
        Write-Host -ForegroundColor Red 'Check valid VM Sizes using command: Get-AzVMSize -Location $Location'
        Break
    }
}
function Test-ValoVMPasswordComplexity{
    param (
        [Parameter(Mandatory)]
        [pscredential]$cred
    )
    $regex="^(.{0,11}|[^0-9]*|[^A-Z]*|[^a-z]*|[a-zA-Z0-9]*)$"

    if($cred.GetNetworkCredential().Password -cmatch $regex){
        Write-Host -ForegroundColor Red 'Password must be min. 12 characters long, contain lowercase, uppercase, numeber and special character.'
        Break
    }
}
function New-ValoVMResourceGroup {
    param(
        [string]$resourceGroupName,
        [string]$location

    )
    Write-Host 'Creating resource group '$resourceGroupName
    New-AzResourceGroup -Name $resourceGroupName -Location $location
    Write-Host 'Adding ValoInstaller tag to created Resource group '$resourceGroupName'.'
    $rg = Get-AzResourceGroup -Name $resourceGroupName
    [hashtable] $tags = $rg.Tags
    if ($null -eq $tags) 
    {
        [hashtable] $tags = @{ResourcePurpose="ValoInstaller"} 
    }
    else 
    {
        $Tags += @{VMPurpose="ValoInstaller"}
    }
    Set-AzResourceGroup -Id $rg.ResourceId -Tag $tags


}
function New-ValoVMStorageAccount{
    param (
        [string]$ValoFiles,
        [string]$resourceGroupName,
        [string]$location,
        [string]$timeStamp
    )
    $storageAccountName = ('temp-'+$timeStamp).Replace('-','')
    $storageContainer = 'valofiles'
    $vmScript ='Copy-Items.ps1'
    $vmScriptModified = $timeStamp+"-Copy-Items.ps1" 

    Write-Host 'Creating storage account '$storageAccountName
    $sa = New-AzStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroupName -Location $location -SkuName  Standard_LRS -AccessTier Cool -EnableHttpsTrafficOnly $true
    New-AzStorageContainer -Name $storageContainer -Context $sa.Context -Permission Off
    Set-AzStorageBlobContent -File '.\InitIE.ps1' -Container $storageContainer -Blob 'InitIE.ps1' -Context $sa.Context |Out-Null
    $key = ((Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName)| Where-Object {$_.KeyName -eq "key1"})[0].Value
    $connectionString="DefaultEndpointsProtocol=https;AccountName="+$storageAccountName+";AccountKey="+$key+";EndpointSuffix=core.windows.net"
    $outfile = $((Get-Content -path $vmScript -Raw) -replace 'connectionStringValue',$connectionString) | Set-Content -Path $vmScriptModified  | Out-Null   
    Write-Host 'Adding resources to container' 
    if ($ValoFiles) {
        $files = Get-ChildItem $ValoFiles
        foreach ($file in $files){
            Set-AzStorageBlobContent -File $file.FullName -Container $storageContainer -Blob $file.Name -Context $sa.Context  | Out-Null
        }
    }

}
function New-ValoVMNetwork{
    param (
        [string]$resourceGroupName,
        [string]$vmName,
        [string]$location
    )
        $vnetName=$resourceGroupName+'-vnet'
        $subnetName=$vmName+'-subnet'
        $vmNICName= $vmName+"-nic1"
        $subnetNetworkSecurityGroupName=$subnetName+"-nsg"
        $vmPublicIPName=$vmName+'-ip'
        #network creation
        #rdp rule below which is open only from the address script is being run
        $myIP= (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content       
        Write-Host 'Your public IP '$myIP' used to limit access to VM'
        if($null -ne $myIP){
            Write-Host 'Creating NSG rule with public IP to limit access to VM'
            $rdpNSGRule = New-AzNetworkSecurityRuleConfig -Name 'Allow-RDP-In' -Description "Allow RDP In from your IP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix $myIP -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
        }
        else{
            #rdp rule below which is open to all ip addresses
            Write-Host 'Creating NSG rule with public access to VM'
            $rdpNSGRule = New-AzNetworkSecurityRuleConfig -Name 'Allow-RDP-In' -Description "Allow RDP In" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
        }
        Write-Host 'Creating NSG ' $subnetNetworkSecurityGroupName
        $NSG = New-AzNetworkSecurityGroup -Name $subnetNetworkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $rdpNSGRule
        Write-Host 'Creating subnet '$subnetName
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24 -NetworkSecurityGroup $NSG
        Write-Host 'Creating virtual network '$vnetName
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        Write-Host 'Creating Public IP '$vmPublicIP.IpAddress
        $vmPublicIP = New-AzPublicIpAddress -Name $vmPublicIPName -ResourceGroupName $resourceGroupName -AllocationMethod Static -Location $location
        $vmIPConfig = New-AzNetworkInterfaceIpConfig -Name "VMIPConfig" -Subnet $vnet.Subnets[0] -PublicIpAddress $vmPublicIP -Primary
        Write-Host 'Creating NIC for VM '
        $vmNIC = New-AzNetworkInterface -Name $vmNICName -ResourceGroupName $resourceGroupName -Location $location -IpConfiguration $vmIPConfig
        return $vmNIC

}
function New-ValoVM {
<# 
.SYNOPSIS
This function install a new VM for Valo installations.
.DESCRIPTION 
This function install a new VM for Valo installations. 
#>
    param (
        [Parameter(Mandatory)]
        [Alias("SUBID")]
        [string]$SubscriptionID,
        [Parameter(Mandatory)]
        [Alias("LOC")]
        [string]$VMLocation,
        [Alias("SIZE")]
        [string]$VMSize ='Standard_DS1_v2',
        [Alias("DIR")]
        [string]$ValoFiles
    )

    Install-ValoVMInstallationDependecies

    New-ValoAzureConnection -subscriptionID $SubscriptionID

    Write-Host 'Provide VM admin account username and password'
    Write-Host 'Password must be compliant - min. 12 char, lowercase[a-z], uppercase[A-Z], number[0-9] and special character included'
    $adminCredentials = Get-Credential -Message "Provice admin account for the virtual machine. "
    Test-ValoVMPasswordComplexity -cred $adminCredentials

    try{
        Test-ValoVMResourceGroupLocation -location $VMLocation
        Test-ValoVMSize -location $VMLocation -VMSize $VMSize
        
        #Get-AzVMSize -Location $VMLocation
        #Get-AzVMImagePublisher -Location $VMLocation
        $publisher='MicrosoftWindowsDesktop'
        #Get-AzVMImageOffer -Location $VMLocation -PublisherName $publisher
        $offer='windows-10'
        #Get-AzVMImageSku -Location $VMLocation -PublisherName $publisher -Offer $offer
        $sku='20h1-ent'
        $version='latest'
    
        #generic contatenated parameters
        $timeStamp = (Get-Date -Format "MMddyy-HHmm")
        $resourceGroupName='valo-win10-'+$timeStamp
        $vmName='win10'
        $osDiskName=$vmName+"-osdisk"

        New-ValoVMResourceGroup -resourceGroupName $resourceGroupName -location $VMLocation 

        New-ValoVMStorageAccount -ValoFiles $ValoFiles -storageAccountName $storageAccountName -storageContainer $storageContainer `
        -resourceGroupName $resourceGroupName -location $VMLocation -timestamp $timeStamp 
        $vmScriptModified = $timeStamp+"-Copy-Items.ps1" 


        $vmNIC = New-ValoVMNetwork -resourceGroupName $resourceGroupName -location $VMLocation -vmName $vmName 

        #vm creation
        $vm = New-AzVMConfig -VMName $vmName -VMSize $VMSize
        $vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $adminCredentials -ProvisionVMAgent -EnableAutoUpdate 
        $vm = Add-AzVMNetworkInterface -VM $vm -Id $vmNIC.Id
        $vm = Set-AzVMSourceImage -VM $vm -PublisherName $publisher -Offer $offer -Skus $sku -Version $version  
        $vm = Set-AzVMOSDisk -VM $vm -Name $osDiskName -Windows -CreateOption FromImage -DiskSizeInGB 128 -StorageAccountType StandardSSD_LRS
        $vm = Set-AzVMBootDiagnostic -VM $vm -Disable
        Write-Host 'Starting creating virtual machine '$vmName
        $valoVM = New-AzVM -ResourceGroupName $resourceGroupName -Location $vmLocation -VM $vm
        if ($null -ne $valoVM){
            Write-Host 'Virtual machine '$vmName' created in resource group '$resourceGroupName'.'
            Write-Host 'Executing PowerShell script in the VM'
            Write-Host 'Executing PowerShell script Install-Dependencies'
            Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -VMName $vmName -CommandId RunPowerShellScript -ScriptPath 'Install-Dependencies.ps1'                                                

            Write-Host 'Executing PowerShell script Copy-Items using ' $vmScriptModified
            Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -VMName $vmName -CommandId RunPowerShellScript -ScriptPath $vmScriptModified                                              

            Write-Host 'Connect to the VM in Windows using command: mstsc /v:'$vmPublicIP.IpAddress
        }
    }
    catch{
#         Remove-AzResourceGroup -Name $resourceGroupName -Force
         Write-Host "Error: "$_.Exception.Message " with item "$_.Exception.ItemNameß

    }
    finally{
        Remove-Item $vmScriptModified
        Disconnect-AzAccount
    }
}
function Remove-ValoVM {
<# 
.SYNOPSIS
This function removes a VM used for Valo installations using the tag.
.DESCRIPTION 
This function removes a VM used for Valo installations using the tag.
#>
    param (
    [Parameter(Mandatory)]
    [Alias("SUBID")]
    [string]$SubscriptionID
    )
    Install-Dependecies
    Write-Host 'Login to target Azure Environment'
    Connect-AzAccount
    Set-AzContext -SubscriptionId $SubscriptionID

    $rg = Get-AzResourceGroup -Tag @{ResourcePurpose="ValoInstaller"} 

    try {
        Write-Host 'Deleting resource group '$rg.ResourceGroupName'.'
        Remove-AzResourceGroup -Id $rg.ResourceId -Force       
        Write-Host 'Resource group '$rg.ResourceGroupName' deleted.'

    }
    catch {
        Write-Host "Error: "$_.Exception.Message " with item "$_.Exception.ItemNameß        
    }
    finally{
        
        Disconnect-AzAccount

    }
 
}
