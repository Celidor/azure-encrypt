<#
Title:       azure-encrypt
AUTHOR:      PAUL SCHWARZENBERGER
DATE:        15/04/2019
DESCRIPTION: Creates Azure Key Vault and encrypts virtual machines
Version:     1.0
Usage:       azure-encrypt.ps1
#>

    # Log in to Azure
    Login-AzureRmAccount
    # Get resource group - this will only work if the user has rights to a single resource group
    $ResourceGroup = Get-AzureRmResourceGroup
    $ResourceGroupName = $ResourceGroup.ResourceGroupName
    $location = $ResourceGroup.Location

    Write-Output "Encrypting virtual machines in the $ResourceGroupName resource group in $location"
    
    # Create Azure Key Vault for resource group disk encryption if needed
    $KeyVaultName = $ResourceGroupName + "-vault"
    $KeyVault = Get-AzureRmKeyVault -ResourceGroupName $ResourceGroupName -VaultName $KeyVaultName

    if ($KeyVault.VaultName -eq $KeyVaultName) {
        Write-Output "Azure Key Vault named $KeyVaultName already exists."

    } else {

    Write-Output "Creating new Azure Key Vault named $KeyVaultName ..."
    # Create new Azure Key Vault for resource group disk encryption
    New-AzureRmKeyVault -Location $location -ResourceGroupName $ResourceGroupName -VaultName $KeyVaultName -EnabledForDiskEncryption
    }

    # Create Azure Key Vault Key for disk encryption if needed
    $KeyVaultKeyName = $ResourceGroupName + "-key"
    $KeyVaultKey = Get-AzureKeyVaultKey -VaultName $KeyVaultName

    if ($KeyVaultKey.Name -eq $KeyVaultKeyName) {
        Write-Output "Azure Key Vault Key named $KeyVaultKeyName already exists."

        } else {

        Write-Output "Creating new Azure Key Vault Key named $KeyVaultKeyName ..."
        # Create new Azure Key Vault for resource group disk encryption
        Add-AzureKeyVaultKey -VaultName $KeyVaultName -Name $KeyVaultKeyName -Destination Software
    }

    # Define required information for our Key Vault and keys
    $KeyVault = Get-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourceGroupName;
    $DiskEncryptionKeyVaultUrl = $KeyVault.VaultUri;
    $KeyVaultResourceId = $KeyVault.ResourceId;
    $KeyEncryptionKeyUrl = (Get-AzureKeyVaultKey -VaultName $KeyVaultName -Name $KeyVaultKeyName).Key.kid;

    # Encrypt virtual machines where needed
    Get-AzureRmResource | Where {$_.ResourceGroupName -eq $ResourceGroupName -and $_.ResourceType -eq "Microsoft.Compute/virtualMachines"} | ForEach-Object { 
        $VmName = $_.Name
        $VmDiskEncryptionStatus = Get-AzureRmVmDiskEncryptionStatus -ResourceGroupName $ResourceGroupName -VMName $VmName

        if ($VmDiskEncryptionStatus.OsVolumeEncrypted -ne "Encrypted" -or $VmDiskEncryptionStatus.DataVolumesEncrypted -ne "Encrypted"){
            Set-AzureRmVMDiskEncryptionExtension `
              -ResourceGroupName $ResourceGroupName `
              -VMName $VmName `
              -DiskEncryptionKeyVaultUrl $DiskEncryptionKeyVaultUrl `
              -DiskEncryptionKeyVaultId $KeyVaultResourceId `
              -KeyEncryptionKeyUrl $KeyEncryptionKeyUrl `
              -KeyEncryptionKeyVaultId $KeyVaultResourceId `
              -VolumeType "All"
        }
    }    

    # Report encryption status
    Get-AzureRmResource | Where {$_.ResourceGroupName -eq $ResourceGroupName -and $_.ResourceType -eq "Microsoft.Compute/virtualMachines"} | ForEach-Object {
        $VmName = $_.Name
        Get-AzureRmVmDiskEncryptionStatus -ResourceGroupName $ResourceGroupName -VMName $VmName
        }
