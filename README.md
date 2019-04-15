# azure-encrypt

* creates Azure Key Vault and key in an existing resource group
* encrypts virtual machines in Azure

## usage

* Azure AD user running the script must only have read access to a single resource group
* Azure AD user requires Contributor rights to that resource group
* Import AzureRM PowerShell modules if needed

```
./azure-encrypt.ps1
```
* Log in to Azure when prompted
* Confirm encryption of virtual machines when prompted
* Encryption can take up to 15 minutes per virtual machine