<#PSScriptInfo      
.VERSION 1.0.0.0                       
.GUID 7bafe56d-60c6-4713-9dd0-73622e13a9f9 
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
<# remove this to inform Az is needed.
#Requires -Module Az
#>
<# 
.SYNOPSIS
This script will help you to install VM for Valo installations.
.DESCRIPTION 
 Script to install Virtual Machine for Valo Installations.
 Script will install default Windows 10 machine and enable AzureAD, AzureRM, Credential Manager, SharePointPnP and SPO Management shell. 
 The script uses Azure PowerShell and will install it during the process.
#> 
function Install-Dependecies{

    try{
        $azInstalled = Get-InstalledModule -Name Az -ErrorAction SilentlyContinue 
        if($null -eq $azInstalled){
            Install-Module -Name Az -SkipPublisherCheck -Force -AllowClobber
            Write-Host 'Installed Azure PowerShell Module'
        }
        else {
            $azVersion = ($azInstalled |  Sort-Object -Property Version -Descending | Select-Object -First 1)[0].Version 
            if($azVersion -notlike '*4.1*'){
                Install-Module -Name Az -SkipPublisherCheck -Force -AllowClobber
                Write-Host 'Installed Azure PowerShell Module'
            }
        }
        Import-Module -Name Az -Force
        Write-Host 'Imported Azure PowerShell Module'
    }
    catch{
    }
    finally{
    }
}
function Test-ResourceGroupLocation{
    param (
        [Parameter(Mandatory)]
        [Alias("LOC")]
        [string]$location
    )
    $locationName = Get-AzLocation | Select-Object -Property DisplayName,Location | Where-Object -Property Location -EQ $location
    if ($null -eq $locationName){
        Write-Host -ForegroundColor Red 'Check valid Resource Group location usings command: Get-AzLocation'
        Break
    }
}
function Test-VMSize{
    param (
        [Parameter(Mandatory)]
        [Alias("LOC")]
        [string]$location,
        [Parameter(Mandatory)]
        [Alias("SIZE")]
        [string]$vmSize
    )

    $size = Get-AzVMSize -Location $location | Select-Object -Property Name | Where-Object -Property Name -EQ -Value $vmSize
    if($null -eq $size){
        Write-Host -ForegroundColor Red 'Check valid VM Sizes using command: Get-AzVMSize -Location $location'
        Break
    }
}
function Test-PasswordComplexity{
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
function New-ValoVM {
    param (
        [Parameter(Mandatory)]
        [Alias("SUBID")]
        [string]$SubcriptionID,
        [Parameter(Mandatory)]
        [Alias("LOC")]
        [string]$vmLocation,
        [Alias("SIZE")]
        [string]$vmSize ='Standard_DS1_v2',
        [Alias("DIR")]
        [string]$dataDirectory = '.\data'
    )

    Install-Dependecies
    Write-Host 'Login to target Azure Environment'
    Connect-AzAccount
    Set-AzContext -SubscriptionId $subcriptionID

    Test-ResourceGroupLocation -location $vmLocation
    Test-VMSize -location $vmLocation -vmSize $vmSize

    Write-Host 'Provide VM admin account username and password'
    Write-Host 'Password must be compliant - min. 12 char, lowercase[a-z], uppercase[A-Z], number[0-9] and special character included'
    $adminCredentials = Get-Credential -Message "Provice admin account for the virtual machine. "
    Test-PasswordComplexity -cred $adminCredentials

    #Get-AzVMSize -Location $location
    $location =$vmLocation
    #Get-AzVMImagePublisher -Location $location
    $publisher='MicrosoftWindowsDesktop'
    #Get-AzVMImageOffer -Location $location -PublisherName $publisher
    $offer='windows-10'
    #Get-AzVMImageSku -Location $location -PublisherName $publisher -Offer $offer
    $sku='19h2-ent'
    $version='latest'
    
    #generic contatenated parameters
    $timeStamp = (Get-Date -Format "MMddyy-HHmm")
    $resourceGroupName='valo-win10-'+$timeStamp
    $storageAccountName = ('temp-'+$timeStamp).Replace('-','')
    $vmScript ='InitVM.ps1'
    $vmName='win10'
    $vnetName=$resourceGroupName+'-vnet'
    $subnetName=$vmName+'-subnet'
    $vmNICName= $vmName+"-nic1"
    $subnetNetworkSecurityGroupName=$subnetName+"-nsg"
    $osDiskName=$vmName+"-osdisk"
    $vmPublicIPName=$vmName+'-ip'

    try{
        New-AzResourceGroup -Name $resourceGroupName -Location $location
        Write-Host 'Resource group created '$resourceGroupName

        $sa = New-AzStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroupName -Location $location -SkuName  Standard_LRS -AccessTier Cool -EnableHttpsTrafficOnly $true
        Write-Host 'Storage account created '$storageAccountName

        $key = ((Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName)| Where-Object {$_.KeyName -eq "key1"})[0].Value
        $connectionString="DefaultEndpointsProtocol=https;AccountName="+$storageAccountName+";AccountKey="+$key+";EndpointSuffix=core.windows.net"
        ((Get-Content -path $vmScript -Raw) -replace 'connectionStringValue',$connectionString) | Set-Content -Path $timeStamp"-"$vmScript 
        New-AzStorageContainer -Name 'data' -Context $sa.Context -Permission Off
        New-AzStorageContainer -Name 'scripts' -Context $sa.Context -Permission Off
        $files = Get-ChildItem $dataDirectory
        foreach ($file in $files){
            Set-AzStorageBlobContent -File $file.FullName -Container 'data' -Blob $file.Name -Context $sa.Context 
        }
        Set-AzStorageBlobContent -File $timeStamp"-"$vmScript -Container 'scripts' -Blob $vmScript -Context $sa.Context
        Write-Host 'Resources added to containers' 

        #network creation
        #rdp rule below which is open only from the address script is being run
        $myIP= (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content       
        Write-Host 'Your public IP '$myIP' used to limit access to VM'
        if($null -ne $myIP){
        $rdpNSGRule = New-AzNetworkSecurityRuleConfig -Name 'Allow-RDP-In' -Description "Allow RDP In from your IP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix $myIP -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
        }
        else{
        #rdp rule below which is open to all ip addresses
        $rdpNSGRule = New-AzNetworkSecurityRuleConfig -Name 'Allow-RDP-In' -Description "Allow RDP In" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
        }
        $NSG = New-AzNetworkSecurityGroup -Name $subnetNetworkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $rdpNSGRule
        Write-Host 'Network security group created '$subnetNetworkSecurityGroupName
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24 -NetworkSecurityGroup $NSG
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        Write-Host 'Virtual network created '$vnetName
        $vmPublicIP = New-AzPublicIpAddress -Name $vmPublicIPName -ResourceGroupName $resourceGroupName -AllocationMethod Static -Location $location
        Write-Host 'Public IP created '$vmPublicIP.IpAddress
        $vmIPConfig = New-AzNetworkInterfaceIpConfig -Name "VMIPConfig" -Subnet $vnet.Subnets[0] -PublicIpAddress $vmPublicIP -Primary
        $vmNIC = New-AzNetworkInterface -Name $vmNICName -ResourceGroupName $resourceGroupName -Location $location -IpConfiguration $vmIPConfig
        Write-Host 'NIC for VM created'
        #vm creation
        $vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize
        $vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $adminCredentials -ProvisionVMAgent -EnableAutoUpdate 
        $vm = Add-AzVMNetworkInterface -VM $vm -Id $vmNIC.Id
        $vm = Set-AzVMSourceImage -VM $vm -PublisherName $publisher -Offer $offer -Skus $sku -Version $version  
        $vm = Set-AzVMOSDisk -VM $vm -Name $osDiskName -Windows -CreateOption FromImage -DiskSizeInGB 128 -StorageAccountType StandardSSD_LRS
        $vm = Set-AzVMBootDiagnostic -VM $vm -Disable
        Write-Host 'Starting creating virtual machine '$vmName
        $valoVM = New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vm
        if ($null -ne $valoVM){
            Write-Host 'Virtual machine '$vmName' created in resource group '$resourceGroupName'.'
            Set-AzVMExtension -ResourceGroupName $resourceGroupName -Location $location -VMName  $vmName -Name "CustomScriptExtension" -Publisher "Microsoft.Compute" -Type "CustomScriptExtension" -TypeHandlerVersion "1.1" -SettingString '{"commandToExecute":"powershell Set-ExecutionPolicy Unrestricted"}'
            $SettingsString = '{"fileUris": ["https://'+$storageAccountName+'.blob.core.windows.net/scripts/'+$vmScript+'"], "commandToExecute":"powershell -File '+$vmScript+'"}'
            $ProtectedSettingsString = '{"storageAccountName":"' + $storageAccountName + '","storageAccountKey":"' + $key + '"}'
            Set-AzVMExtension -ResourceGroupName $resourceGroupName -Location $location -VMName  $vmName -Name "CustomScriptExtension" -Publisher "Microsoft.Compute" -Type "CustomScriptExtension" -TypeHandlerVersion "1.1" -SettingString $SettingsString -ProtectedSettingString $ProtectedSettingsString
            Write-Host 'PowerShell script run in the VM'
            Write-Host 'Connect to the VM in Windows using command: mstsc /v:'$vmPublicIP.IpAddress

        }
    }
    catch{
         Remove-AzResourceGroup -Name $resourceGroupName -Force
         Write-Host "Error: "$_.Exception.Message " with item "$_.Exception.ItemNameß

    }
    finally{
        Remove-Item $timeStamp"-"$vmScript
        Disconnect-AzAccount
    }
}
Export-ModuleMember -Function New-ValoVM
