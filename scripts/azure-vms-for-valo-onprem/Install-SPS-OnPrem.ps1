<#PSScriptInfo      
.VERSION 1.1.1.0                       
.GUID 7bafe56d-60c6-4713-9dd0-73622e13a9f9 
.DESCRIPTION This script will help you to install VMs for Valo on-premises.
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
Valo VM installation script can be used to install SharePoint infrastructure in Azure for full Valo installation.
Feel free to leverage and extends as needed.
.PRIVATEDATA
#> 
function Install-ValoVMInstallationDependecies{

    try{
        $AzInstalled = Get-InstalledModule -Name Az -ErrorAction SilentlyContinue 
        if($null -eq $AzInstalled){
            Write-Host "Installing Azure PowerShell Module"
            Install-Module -Name Az -SkipPublisherCheck -Force -AllowClobber
            
        }
        else {
            $AzVersionInstalled = ($AzInstalled |  Sort-Object -Property Version -Descending | Select-Object -First 1)[0].Version 
            $AzVersionLatest = (Find-Module -Name Az |Sort-Object -Property Version -Descending | Select-Object -First 1)[0].Version
            if($AzVersionInstalled -notlike $AzVersionLatest){
                Write-Host "Updating Azure PowerShell Module to latest version $AzVersionLatest"
                Install-Module -Name Az -SkipPublisherCheck -Force -AllowClobber
            }
        }
        Write-Host "Importing Azure PowerShell Module"
        Import-Module -Name Az -Force
    }
    catch{
        Write-Host "Error with installing or impoerting Azure PowerShell Module: $($_.ErrorDetails)"
    }
    finally{
    }
}
function New-ValoAzureConnection {
    param (
        [Parameter(Mandatory)]
        [string]$SubscriptionID
    )
    Write-Host "Login to target Azure Environment and Initialize Azure Context with $SubscriptionID"
    Connect-AzAccount  -SubscriptionId $SubscriptionID

}
function Edit-ValoLocationName {
    param (
        [Parameter(Mandatory)]
        [string]$Location
    )
    return $Location.ToLower().Replace(" ","")
}
function Test-ValoAzureLocation{
    param (
        [Parameter(Mandatory)]
        [Alias("LOC")]
        [string]$Location
    )
    $LocationName = Get-AzLocation | Select-Object -Property DisplayName,Location | Where-Object -Property Location -EQ (Edit-ValoLocationName -Location $Location)
    if ($null -eq $LocationName){
        Write-Host -ForegroundColor Red "$Location does not exist. Check valid Resource Group location usings command: Get-AzLocation"
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
    $Location = Edit-ValoLocationName -Location $Location
    Test-ValoAzureLocation -Location $Location

    $Size = Get-AzVMSize -Location $Location | Select-Object -Property Name | Where-Object -Property Name -EQ -Value $VMSize
    if($null -eq $Size){
        Write-Host -ForegroundColor Red "$VMSize does not exist. Check valid VM Sizes using command: Get-AzVMSize -Location $Location"
        Break
    }
}
function Test-ValoVMPasswordComplexity{
    param (
        [Parameter(Mandatory)]
        [pscredential]$Cred
    )
    $RegEx="^(.{0,11}|[^0-9]*|[^A-Z]*|[^a-z]*|[a-zA-Z0-9]*)$"

    if($Cred.GetNetworkCredential().Password -cmatch $RegEx){
        Write-Host -ForegroundColor Red "Password must be min. 12 characters long, contain lowercase, uppercase, numeber and special character."
        Break
    }
}
function New-ValoVMResourceGroup {
    param(
        [string]$ResourceGroupName,
        [string]$Location

    )
    Test-ValoAzureLocation -Location $Location
    $Location = Edit-ValoLocationName -Location $Location

    Write-Host "Creating resource group $ResourceGroupName"
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location
    Write-Host "Adding ValoInstaller tag to created Resource group $ResourceGroupName."
    $RG = Get-AzResourceGroup -Name $ResourceGroupName
    [hashtable] $Tags = $RG.Tags
    if ($null -eq $Tags) 
    {
        $Tags = @{ResourcePurpose="ValoInstaller"} 
    }
    else 
    {
        $Tags += @{VMPurpose="ValoInstaller"}
    }
    Set-AzResourceGroup -Id $RG.ResourceId -Tag $Tags


}
function New-ValoVMNetwork{
    param (
        [string]$ResourceGroupName,
        [string[]]$SubnetNames,
        [string]$Location
    )
        $SubNets = @()
        $i = 1
        foreach($SubnetName in $SubnetNames){
            $SubnetName="$SubnetName-subnet"
            $SubnetNetworkSecurityGroupName="$SubnetName-nsg"

            if($i -eq 1){
                #rdp rule below which is open only from the address script is being run
                $MyIP= (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content       
                Write-Host "Your public IP $MyIP used to limit access to VM"
                if($null -ne $MyIP){
                    Write-Host "Creating NSG rule with public IP to limit access to VM"
                    $RdpNsgRule = New-AzNetworkSecurityRuleConfig -Name "Allow-RDP-In" -Description "Allow RDP In from your IP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix $myIP -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
                }
                else{
                    #rdp rule below which is open to all ip addresses
                    Write-Host "Creating NSG rule with public access to VM"
                    $RdpNsgRule = New-AzNetworkSecurityRuleConfig -Name "Allow-RDP-In" -Description "Allow RDP In" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
                }
                Write-Host "Creating NSG $SubnetNetworkSecurityGroupName"
                $Nsg = New-AzNetworkSecurityGroup -Name $SubnetNetworkSecurityGroupName -ResourceGroupName $ResourceGroupName -Location $Location -SecurityRules $RdpNsgRule    
            }
            else {
                Write-Host "Creating NSG $SubnetNetworkSecurityGroupName"
                $Nsg = New-AzNetworkSecurityGroup -Name $SubnetNetworkSecurityGroupName -ResourceGroupName $ResourceGroupName -Location $Location
            }
            Write-Host "Creating subnet $SubnetName"
            $Subnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix 10.11.$i.0/24 -NetworkSecurityGroup $Nsg
            $i+=1
            $SubNets+= $Subnet
        }
        $VnetName="$ResourceGroupName-vnet"
        Write-Host "Creating virtual network $VnetName"
        $Vnet = New-AzVirtualNetwork -Name $VnetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix 10.11.0.0/16 -Subnet $Subnets -DnsServer 10.11.2.4,168.63.129.16
        return $Vnet
}
function New-ValoVMNic{
    param (
        [string]$ResourceGroupName,
        [string]$VmName,
        $VirtualNetwork,
        [string]$SubnetName,
        [switch]$PublicIP,
        [string]$privateIP,
        [string]$Location
    )
        $SubnetName="$SubnetName-subnet"

        $VmNICName= "$VmName-nic1"
        if($PublicIP){
            $VmPublicIPName="$VmName-ip"
            Write-Host "Creating Public IP"
            $VmPublicIP = New-AzPublicIpAddress -Name $VmPublicIPName -ResourceGroupName $ResourceGroupName -AllocationMethod Static -Location $Location
            $VmIPConfig = New-AzNetworkInterfaceIpConfig -Name "VmIPConfig" -Subnet (Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VirtualNetwork) -PrivateIpAddress $privateIP -PublicIpAddress $VmPublicIP -Primary    
        }
        else{
            $VmIPConfig = New-AzNetworkInterfaceIpConfig -Name "VmIPConfig" -Subnet (Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VirtualNetwork)  -PrivateIpAddress $privateIP -Primary    
        }
        Write-Host "Creating NIC for VM"
        New-AzNetworkInterface -Name $VmNicName -ResourceGroupName $ResourceGroupName -Location $Location -IpConfiguration $VmIPConfig | Out-Null
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
        [string]$ResourceGroupName,
        [Parameter(Mandatory)]
        [string]$Location,
        [string]$SubnetName,
        [Parameter(Mandatory)]
        [string]$VmName,
        [string]$VmSize ='Standard_DS1_v2',
        [string]$PrivateIP,
        [switch]$PublicIP,
        [Parameter(Mandatory)]
        [object]$AdminCredentials,
        [string]$ImageString
    )
    $Location = Edit-ValoLocationName -Location $Location
    Test-ValoAzureLocation -Location $Location
    Test-ValoVMSize -Location $Location -VMSize $VMSize
    $ComputerName = $VmName
    $VmName = $VmName.ToLower()

    $image = $ImageString.Split(":")
    if($PublicIP){
        New-ValoVMNic -ResourceGroupName $ResourceGroupName -Location $Location -SubnetName $SubnetName -VmName $VmName -VirtualNetwork (Get-AzVirtualNetwork -Name "$ResourceGroupName-vnet" -ResourceGroup $ResourceGroupName) -PrivateIP $PrivateIP -PublicIP
    }
    else {
        New-ValoVMNic -ResourceGroupName $ResourceGroupName -Location $Location -SubnetName $SubnetName -VmName $VmName -VirtualNetwork (Get-AzVirtualNetwork -Name "$ResourceGroupName-vnet" -ResourceGroup $ResourceGroupName)  -PrivateIP $PrivateIP
    }

    try{
        $Vm = New-AzVMConfig -VMName $VmName -VMSize $VmSize
        $OsDiskName="$VmName-osdisk"
        $Vm = Set-AzVMOSDisk -VM $Vm -Name $OsDiskName -Windows -CreateOption FromImage -DiskSizeInGB 128 -StorageAccountType StandardSSD_LRS
        $Vm = Add-AzVMNetworkInterface -VM $Vm -Id (Get-AzNetworkInterface -Name ("$VmName-nic1") -ResourceGroupName $ResourceGroupName).Id 
        $Vm = Set-AzVMOperatingSystem -VM $Vm -Windows -ComputerName $ComputerName -Credential $AdminCredentials -ProvisionVMAgent -EnableAutoUpdate 
        $Vm = Set-AzVMBootDiagnostic -VM $Vm -Disable
        $VM = Set-AzVMSourceImage -VM $Vm -PublisherName $image[0] -Offer $image[1] -Skus $image[2] -Version $image[3]
        Write-Host "Starting creating virtual machine $vmName"
        $ValoVM = New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $vm     
        if ($null -ne $ValoVM){
            Write-Host "Virtual machine $vmName created in resource group $resourceGroupName."
            return $ValoVM
        }
    }
    catch{
             Write-Host "Error: $($_.Exception.Message) with item $($_.Exception.ItemName)"
             Break

    }
    finally{
    }
}

$SubscriptionID = 'YOUR SUBSCRIPTION ID'
$Location = 'YOUR AZURE LOCATION'
$ResourceGroupName = 'yourdomain-rg-valo-onprem-vm'
$DCPATH="DC=yourdomain,DC=valo,DC=show"
$DCNETBIOS="yourdomain"
$FQDN="yourdomain.valo.show"
$subNetNames = 'client','dc','db','sps'
$IMAGE_CLIENT="MicrosoftWindowsDesktop:windows-10:20h2-ent:latest"
$IMAGE_SERVER2012="MicrosoftWindowsServer:WindowsServer:2012-R2-Datacenter:latest"
$IMAGE_SERVER2016="MicrosoftWindowsServer:windowsServer:2016-Datacenter:latest"
$IMAGE_SERVER2019="MicrosoftWindowsServer:windowsServer:2019-Datacenter:latest"

New-ValoAzureConnection -subscriptionID $SubscriptionID
    
Write-Host "Provide VM admin account username and password"
Write-Host "Password must be compliant - min. 12 char, lowercase[a-z], uppercase[A-Z], number[0-9] and special character included"
# $AdminCredentials = Get-Credential -Message "Provice admin account for the virtual machine. "
Test-ValoVMPasswordComplexity -cred $AdminCredentials
    
try 
{
    $Location = Edit-ValoLocationName -Location $Location
    Test-ValoAzureLocation -Location $Location            
    New-ValoVMResourceGroup -ResourceGroupName $ResourceGroupName -Location $Location 
        
    New-ValoVMNetwork -ResourceGroupName $ResourceGroupName -SubnetNames $subNetNames -Location $Location

    $VMName = "win10"
    $VMSize = "Standard_DS2_v2"
    $valoClientVM = New-ValoVM -VMName $VMName -VMSize $VMSize -Image $IMAGE_CLIENT -Location $Location -ResourceGroupName $ResourceGroupName -AdminCredentials $AdminCredentials -SubNetName $subNetNames[0] -PublicIP
    if ($null -ne $valoClientVM){
        Write-Host 'Virtual machine '$vmName' created in resource group '$resourceGroupName'.'
        # Write-Host 'Executing PowerShell script in the VM'
        # Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VmName -CommandId RunPowerShellScript -ScriptPath 'Install-Dependencies.ps1'                                                
    }

    $VMName = "dc1"
    $VMSize = "Standard_DS1_v2"
    $valoDCVM = New-ValoVM -VMName $VmName -VMSize $VMSize -Image $IMAGE_SERVER2019 -Location $Location -ResourceGroupName $ResourceGroupName -AdminCredentials $AdminCredentials -SubNetName $subNetNames[1] -PrivateIP "10.11.2.4"
     if ($null -ne $valoDCVM){
        Write-Host 'Virtual machine '$vmName' created in resource group '$resourceGroupName'.'
        Write-Host 'Executing PowerShell script in the VM'
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VmName -CommandId RunPowerShellScript -ScriptPath 'Install-AD.ps1'  -Parameter @{ domainName = "na.valo.show"}
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VmName -CommandId RunPowerShellScript -ScriptPath 'Create-Share.ps1'  -Parameter @{ domainName = "na.valo.show";adminAccountName = "guru"}
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VmName -CommandId RunPowerShellScript -ScriptPath 'Add-DNS.ps1'  -Parameter  @{ domainName = "na.valo.show"}
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VmName -CommandId RunPowerShellScript -ScriptPath 'Add-AD.ps1' -Parameter @{ computerName = "sql";adJoinPWD = "VALOINTRANETJ01N"}
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VmName -CommandId RunPowerShellScript -ScriptPath 'Add-AD.ps1' -Parameter @{ computerName = "sps2016";adJoinPWD = "VALOINTRANETJ01N"}
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VmName -CommandId RunPowerShellScript -ScriptPath 'Add-AD.ps1' -Parameter @{ computerName = "sps2019";adJoinPWD = "VALOINTRANETJ01N"}
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VmName -CommandId RunPowerShellScript -ScriptPath 'Add-AD.ps1' -Parameter @{ computerName = "SERVICES";adJoinPWD = "VALOINTRANETJ01N"}

    }

    $VMName = "sql"
    $VMSize = "Standard_D4s_v3"
    $valoDBVM = New-ValoVM -VMName $VmName -VMSize $VMSize -Image $IMAGE_SERVER2019 -Location $Location -ResourceGroupName $ResourceGroupName -AdminCredentials $AdminCredentials -SubNetName $subNetNames[2] -PrivateIP "10.11.3.4"
    $diskConfig = New-AzDiskConfig -SkuName StandardSSD_LRS -Location $Location -CreateOption Empty -DiskSizeGB 256
    $dataDisk1 = New-AzDisk -DiskName "$VMName-datadisk" -Disk $diskConfig -ResourceGroupName $ResourceGroupName
    $Vm = Get-AzVM -Name $VMName -ResourceGroupName $ResourceGroupName 
    $Vm = Add-AzVMDataDisk -VM $Vm -Name "$VMName-datadisk" -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1
    Update-AzVM -VM $Vm -ResourceGroupName $ResourceGroupName
    if ($null -ne $valoDBVM){
        Write-Host 'Virtual machine '$vmName' created in resource group '$resourceGroupName'.'
        Write-Host 'Executing PowerShell script in the VM'
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VmName -CommandId RunPowerShellScript -ScriptPath 'Join-AD.ps1'  -Parameter @{ domainName = "na.valo.show";adJoinPWD = "VALOINTRANETJ01N"}
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VmName -CommandId RunPowerShellScript -ScriptPath 'Initialize-Disk.ps1'
    }

    $VMName = "dc1"
    Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VMName -CommandId RunPowerShellScript -ScriptPath 'Create-ServiceAccounts.ps1'  -Parameter @{ csvPath = "c:\temp\serviceaccounts.csv";DCPath = "DC=na,DC=valo,DC=show"}
    Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VMName -CommandId RunPowerShellScript -ScriptPath 'Create-ValoUsers.ps1'  -Parameter @{ csvPath = "c:\temp\valousers.csv";DCPath = "DC=na,DC=valo,DC=show";DCNetBIOS = "na"}
    Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VMName -CommandId RunPowerShellScript -ScriptPath 'Delegate-ProfileAccount.ps1'  -Parameter @{ DCNetBIOS = "na"}

    $VMName = "sps2016"
    $VMSize = "Standard_D4s_v3"
    $valoSPS2016 = New-ValoVM -VMName $VmName -VMSize $VMSize -Image $IMAGE_SERVER2016 -Location $Location -ResourceGroupName $ResourceGroupName -AdminCredentials $AdminCredentials -SubNetName $subNetNames[3] -PrivateIP "10.11.4.4" -PublicIP
    $diskConfig = New-AzDiskConfig -SkuName StandardSSD_LRS -Location $Location -CreateOption Empty -DiskSizeGB 256
    $dataDisk1 = New-AzDisk -DiskName "$VMName-datadisk" -Disk $diskConfig -ResourceGroupName $ResourceGroupName
    $Vm = Get-AzVM -Name $VMName -ResourceGroupName $ResourceGroupName 
    $Vm = Add-AzVMDataDisk -VM $Vm -Name "$VMName-datadisk" -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1
    Update-AzVM -VM $Vm -ResourceGroupName $ResourceGroupName
    if ($null -ne $valoSPS2016){
        Write-Host 'Virtual machine '$vmName' created in resource group '$resourceGroupName'.'
        Write-Host 'Executing PowerShell script in the VM'
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VmName -CommandId RunPowerShellScript -ScriptPath 'Join-AD.ps1'  -Parameter @{ domainName = "na.valo.show";adJoinPWD = "VALOINTRANETJ01N"}
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VmName -CommandId RunPowerShellScript -ScriptPath 'Initialize-Disk.ps1'
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VmName -CommandId RunPowerShellScript -ScriptPath 'Prepare-SPS.ps1'  -Parameter @{ DCNetBIOS = "na"}
    }

    $VMName = "sps2019"
    $VMSize = "Standard_D4s_v3"
    $valoSPS2019 = New-ValoVM -VMName $VmName -VMSize $VMSize -Image $IMAGE_SERVER2019 -Location $Location -ResourceGroupName $ResourceGroupName -AdminCredentials $AdminCredentials -SubNetName $subNetNames[3] -PrivateIP "10.11.4.5" -PublicIP
    $diskConfig = New-AzDiskConfig -SkuName StandardSSD_LRS -Location $Location -CreateOption Empty -DiskSizeGB 256
    $dataDisk1 = New-AzDisk -DiskName "$VMName-datadisk" -Disk $diskConfig -ResourceGroupName $ResourceGroupName
    $Vm = Get-AzVM -Name $VMName -ResourceGroupName $ResourceGroupName 
    $Vm = Add-AzVMDataDisk -VM $Vm -Name "$VMName-datadisk" -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1
    Update-AzVM -VM $Vm -ResourceGroupName $ResourceGroupName
    if ($null -ne $valoSPS2019){
        Write-Host 'Virtual machine '$vmName' created in resource group '$resourceGroupName'.'
        Write-Host 'Executing PowerShell script in the VM'
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VmName -CommandId RunPowerShellScript -ScriptPath 'Join-AD.ps1'  -Parameter @{ domainName = "na.valo.show";adJoinPWD = "VALOINTRANETJ01N"}
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VmName -CommandId RunPowerShellScript -ScriptPath 'Initialize-Disk.ps1'
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VmName -CommandId RunPowerShellScript -ScriptPath 'Prepare-SPS.ps1'  -Parameter @{ DCNetBIOS = "na"}
    }

    $VMName = "SERVICES"
    $VMSize = "Standard_DS2_v2"
    $valoServices = New-ValoVM -VMName $VmName -VMSize $VMSize -Image $IMAGE_SERVER2019 -Location $Location -ResourceGroupName $ResourceGroupName -AdminCredentials $AdminCredentials -SubNetName $subNetNames[3] -PrivateIP "10.11.4.6" -PublicIP
    if ($null -ne $valoServices){
        Write-Host 'Virtual machine '$vmName' created in resource group '$resourceGroupName'.'
        Write-Host 'Executing PowerShell script in the VM'
        Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VmName -CommandId RunPowerShellScript -ScriptPath 'Join-AD.ps1'  -Parameter @{ domainName = "na.valo.show";adJoinPWD = "VALOINTRANETJ01N"}
    }

    $VMName = "dc1"
    Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VMName -CommandId RunPowerShellScript -ScriptPath 'Create-ServiceAccounts.ps1'  -Parameter @{ csvPath = "c:\temp\serviceaccounts.csv";DCPath = "DC=na,DC=valo,DC=show"}
    Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VMName -CommandId RunPowerShellScript -ScriptPath 'Create-ValoUsers.ps1'  -Parameter @{ csvPath = "c:\temp\valousers.csv";DCPath = "DC=na,DC=valo,DC=show";DCNetBIOS = "na"}
    Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VMName -CommandId RunPowerShellScript -ScriptPath 'Delegate-ProfileAccount.ps1'  -Parameter @{ DCNetBIOS = "na"}

    }

catch
{
    # if (Get-AzResourceGroup -Name $resourceGroupName){ 
    #     Write-Host "Deleting the created resource group $resourceGroupName"        
    #     Remove-AzResourceGroup -Name $resourceGroupName -Force
    # }
    Write-Host "Error: "$_.Exception.Message " with item "$_.Exception.ItemNameß
    
}
finally
{
    # Disconnect-AzAccount
    # Clear-AzContext -Force
}
    
