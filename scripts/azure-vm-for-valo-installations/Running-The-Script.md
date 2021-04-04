# Azure VM for Valo Installations
Guide to run the script

1. Download the zip and expand the archive or clone the repo.
2. Open PowerShell and navigate to the folder where you extracted files.
3. Use the following command in Windows or MacOS to start installation. Set the subscription ID to be your Azure subscription or customer subscription where you can create a resource group for the VM and set VMLocation near the Microsoft 365 tenant to be used for Valo installation. You can also provide the VMSize if you want to change the default size. Current size, Standard_DS1_v2, is optimized for cost. 
* Windows
```
.\ValoVM -SubscriptionID xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -VMLocation xyz
```
* MacOS
```
./ValoVM -SubscriptionID xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -VMLocation xyz
```
4. Script will check if latest Azure PowerShell version is installed in your machine and if not install it.
5. Authenticate to the target Azure-tenant as prompted. 
6. Insert VM admin user id e.g. valoinstaller and password as prompted (Password must be compliant - min. 12 char, lowercase[a-z], uppercase[A-Z], a number[0-9] and special character included)
7. The resource group with all required VM artifacts will be created in the defined subscription. The naming convention for resource group created is - 
```
valo-win10-MMddyy-HHmm
```
8. Access to VM will be restricted by the network security group only to your public IP when IP can be retrieved for security purposes.
9. Delete the VM by deleting the resource group after Valo Installation to minize cost impact.
## Disclaimer
**THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.**
