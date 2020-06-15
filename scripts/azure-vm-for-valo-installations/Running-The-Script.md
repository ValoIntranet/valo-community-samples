# Azure VM for Valo Installations
Guide to run the script

Guide to run the script

1. Download the zip and expand the archive or clone the repo.
    * Copy valo partner pack(s) and other files into the data folder to be copied during the installation into the c:\valo folder in the VM.
2. Open PowerShell and run "Import-Module ./ValoVM.psm1" in the folder where you extracted files.
3. Use the command "New-ValoVM -subcriptionID xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -vmLocation xyz" to start installation. Set the subscription ID where you can create a resource group for the VM and location near the Microsoft 365 tenant to be used for Valo installation. You can also provide the vmSize if you want to change the default size. Current size, Standard_DS1_v2, is optimized for Valo installation.
4. Script will check if Azure PowerShell 4.1 is installed in your machine and if not install it.
5. Authenticate to the target Azure-tenant as prompted where you have access to the subscription by opening https://microsoft.com/devicelogin as requested and add the code from the PowerShell console.
6. Insert VM admin user id and password as prompted (Password must be compliant - min. 12 char, lowercase[a-z], uppercase[A-Z], a number[0-9] and special character included)
7. The resource group with all required VM artifacts will be created in the defined subscription. The naming convention for resource group created is - valo-win10-MMddyy-HHmm
8. Access to VM will be restricted by the network security group only to your public IP when IP can be retrieved for security purposes.
9. Additionally, a storage account will be created where resources from the data folder will be uploaded to be available for VM.
10. The script will also run an additional script in the VM to install required Azure modules, and also, if you have added e.g., Valo partner pack zip file into the data folder, it will be copied into c:\valo folder into the VM and be extracted.
11. After login into your VM, you can run the InitIE.ps1 in the VM to initialize IE and unblock Valo folder scripts.



## Disclaimer
**THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.**
