# Azure VM for Valo Installations
Guide to run the script

Guide to run the script

1. Download the zip and expand the archive or clone the repo.
    * Copy valo partner pack(s) and other files into the valodata folder to be copied during the installation into the c:\valo folder in the VM.
2. Open PowerShell and run the following command in the folder where you extracted files.
```
Import-Module ./ValoVM.ps1
```
3. Use the following command in Windows or MacOS to start installation. Set the subscription ID to be your Azure subscription or customer subscription where you can create a resource group for the VM and set VMLocation near the Microsoft 365 tenant to be used for Valo installation. You can also provide the VMSize if you want to change the default size. Current size, Standard_DS1_v2, is optimized for Valo installation. ValoFiles can be used to define where are the partner packs to be automatically copied to VM during the installation.
* Windows
```
New-ValoVM -SubscriptionID xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -VMLocation xyz -ValoFiles C:\temp\valopartnerpacks
```
* MacOS
```
New-ValoVM -SubscriptionID xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -VMLocation xyz -ValoFiles /Users/youraccount/Downloads/valopartnerpacks
```
4. Script will check if latest Azure PowerShell version is installed in your machine and if not install it.
5. Authenticate to the target Azure-tenant as prompted. In Windows you will have a web login open to provide Azure subscription user id and password. In MacOS you need to use the code from PowerShell and  access to the subscription by opening https://microsoft.com/devicelogin as requested.
6. Insert VM admin user id e.g. valoinstaller and password as prompted (Password must be compliant - min. 12 char, lowercase[a-z], uppercase[A-Z], a number[0-9] and special character included)
7. The resource group with all required VM artifacts will be created in the defined subscription. The naming convention for resource group created is - 
```
valo-win10-MMddyy-HHmm
```
8. Access to VM will be restricted by the network security group only to your public IP when IP can be retrieved for security purposes.
9. Additionally, a storage account will be created where resources from the data folder will be uploaded to be available for VM.
10. The script will execute an additional script in the VM to install required Azure modules, and also, if you have added e.g., Valo partner pack zip file into the data folder, it will be copied into c:\valo folder into the VM and be extracted.
11. After login into your VM, you can run the InitIE.ps1 in the VM to initialize IE and unblock Valo folder scripts.
12. After Valo installation you can delete the VM by running
```
Remove-ValoVM -SubscriptionID xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx 
```
which will delete the VM using tags set in the installation.

## Disclaimer
**THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.**
