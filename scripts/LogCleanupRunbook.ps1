param(
    [Parameter(Mandatory = $true)]
    [string]$subscriptionid,
    
    [Parameter(Mandatory = $true)]
    [String]$storagecontainername,
    
    [Parameter(Mandatory = $true)]
    [String]$storagecredentialsname
)

# Access storage account
$storageCredentials = Get-AutomationPSCredentials -Name $storagecredentialsname
$storageName = $storageCredentials.UserName
$storageKey = $storageCredentials.GetNetworkCredential().Password

# Log in with management identity
$connectionResult = Connect-AzAccount -Identity

# Set Azure context to the specified subscription
Set-AzContext -Subscription $subscriptionid

# Authentication for storage account
$storageContext = New-AzStorageContext -StorageAccountName $storageName -StorageAccountKey $storageKey

# Get the blobs stored in the storage container
$blobs = Get-AzStorageBlob -Container $storagecontainername -Context $storageContext | Select-Object Name

# Remove blobs
foreach ($blob in $blobs) {
    Remove-AzStorageBlob -Blob $blob.Name -Container $storagecontainername -Context $storageContext
}
