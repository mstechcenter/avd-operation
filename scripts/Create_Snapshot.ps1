$ErrorActionPreference = "Stop"

# Load parameter
.$args[0]

# Connect to Azure
if (-not (Get-AzContext)) {Connect-AzAccount}
Get-AzSubscription -SubscriptionName $subscriptionName | Set-AzContext

try {
    # Get the VM
    Write-Output "Get the vm: ${vmName}"
    $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName

    # Create a snapshot
    $osDiskId = $vm.StorageProfile.OsDisk.ManagedDisk.Id
    $osDiskName = $vm.StorageProfile.OsDisk.Name
    $date = Get-Date -Format "yyyyMMdd"
    $snapshotName = "${osDiskName}_${date}"
    Write-Output "Create the snapshot: ${snapshotName}"
    $snapshot =  New-AzSnapshotConfig `
        -SourceUri $osDiskId `
        -Location $location `
        -CreateOption copy
    New-AzSnapshot `
        -Snapshot $snapshot `
        -SnapshotName $snapshotName `
        -ResourceGroupName $resourceGroupName

    Write-Output "Successfully created the snapshot: ${snapshotName}"
}
catch {
    Write-Error "Failed to create the snapshot: $_"
}