param (
    [Parameter(Mandatory)]
    [Alias("SUBID")]
    [string]$SubscriptionID,
    [Parameter(Mandatory)]
    [Alias("LOC")]
    [string]$VMLocation,
    [Alias("SIZE")]
    [string]$VMSize ='Standard_DS1_v2',
    [Alias("RG")]
    [string]$VMResourceGroupName
)
. .\ValoVM-Helpers.ps1
#PSScriptInfo      
#VERSION 1.1.1.0                       
#GUID 7bafe56d-60c6-4713-9dd0-73622e13a9f9 
#DESCRIPTION This script will help you to install VM for Valo installations.
#AUTHOR ilija@valointranet.com      
#COMPANYNAME Valo Solutions              
#COPYRIGHT 2020 Valo Solutions.                      
#TAGS Valo VM
#LICENSEURI https://valointranet.com/
#PROJECTURI https://valointranet.com/
#ICONURI https://valointranet.com/
#EXTERNALMODULEDEPENDENCIES Az 
#REQUIREDSCRIPTS
#EXTERNALSCRIPTDEPENDENCIES
#RELEASENOTES
#Valo VM installation script can be used to install Windows 10 VM.
#Feel free to leverage and extends as needed.
#PRIVATEDATA

Install-ValoVMInstallationDependecies

New-ValoAzureConnection -subscriptionID $SubscriptionID

Write-Host 'Provide VM admin account username and password'
Write-Host 'Password must be compliant - min. 12 char, lowercase[a-z], uppercase[A-Z], number[0-9] and special character included'
$adminCredentials = Get-Credential -Message "Provice admin account for the virtual machine. "
Test-ValoVMPasswordComplexity -cred $adminCredentials

try{
    $VMLocation = Test-ValoVMResourceGroupLocation -location $VMLocation
    Test-ValoVMSize -location $VMLocation -VMSize $VMSize
    
    #Get-AzVMSize -Location $VMLocation
    #Get-AzVMImagePublisher -Location $VMLocation
    $publisher='MicrosoftWindowsDesktop'
    #Get-AzVMImageOffer -Location $VMLocation -PublisherName $publisher
    $offer='windows-10'
    #Get-AzVMImageSku -Location $VMLocation -PublisherName $publisher -Offer $offer
    $sku='20h2-ent'
    $version='latest'

    #generic contatenated parameters
    $timeStamp = (Get-Date -Format "MMddyy-HHmm")
    if ($VMResourceGroupName){
        $resourceGroupName = $VMResourceGroupName
    }
    else {
        $resourceGroupName='valo-win10-'+$timeStamp
    }
    $vmName='win10'
    $osDiskName=$vmName+"-osdisk"

    New-ValoVMResourceGroup -resourceGroupName $resourceGroupName -location $VMLocation 

    $vmPublicIP = New-ValoVMNetwork -resourceGroupName $resourceGroupName -location $VMLocation -vmName $vmName 

    $vm = New-AzVMConfig -VMName $vmName -VMSize $VMSize
    $vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $adminCredentials -ProvisionVMAgent -EnableAutoUpdate 
    $vm = Add-AzVMNetworkInterface -VM $vm  -Id (Get-AzNetworkInterface -Name ("$vmName-nic1") -ResourceGroupName $resourceGroupName).Id 
    $vm = Set-AzVMSourceImage -VM $vm -PublisherName $publisher -Offer $offer -Skus $sku -Version $version  
    $vm = Set-AzVMOSDisk -VM $vm -Name $osDiskName -Windows -CreateOption FromImage -DiskSizeInGB 128 -StorageAccountType StandardSSD_LRS
    $vm = Set-AzVMBootDiagnostic -VM $vm -Disable
    Write-Host 'Starting creating virtual machine '$vmName
    $valoVM = New-AzVM -ResourceGroupName $resourceGroupName -Location $vmLocation -VM $vm
    if ($null -ne $valoVM){
        Write-Host 'Virtual machine '$vmName' created in resource group '$resourceGroupName'.'
        Write-Host 'Executing PowerShell script InitIE.ps1 to initialize IE. Verify by opening IE when logging in.'
        Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -VMName $vmName -CommandId RunPowerShellScript -ScriptPath 'InitIE.ps1'                                                
        Write-Host 'Connect to the VM in Windows using command: mstsc /v:'$vmPublicIP.IpAddress
    }
}
catch{
    Write-Host "Error: "$_.Exception.Message " with item "$_.Exception.ItemNameß

}
finally{
    Disconnect-AzAccount
}
