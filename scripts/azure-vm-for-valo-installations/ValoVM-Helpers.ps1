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
    $location = $location.replace(" ","")
    $locationName = Get-AzLocation | Select-Object -Property DisplayName,Location | Where-Object -Property Location -EQ $Location
    if ($null -eq $locationName){
        Write-Host -ForegroundColor Red 'Check valid Resource Group location usings command: Get-AzLocation'
        Break
    }
    return $location
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
        New-AzNetworkInterface -Name $vmNICName -ResourceGroupName $resourceGroupName -Location $location -IpConfiguration $vmIPConfig | Out-Null
        return $vmPublicIP

}
    