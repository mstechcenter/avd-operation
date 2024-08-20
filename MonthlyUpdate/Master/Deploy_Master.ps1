$ErrorActionPreference = "Stop"

$resourceGroupName = "avd-master"
$location = "japaneast"
$snapshotName = "AVDMaster_OSDisk_1_19000101"
$storageType="Standard_LRS"
$diskSize = 128
$subnetId = "/subscriptions/01234567-8901-2345-6789-012345678901/resourceGroups/avd/providers/Microsoft.Network/virtualNetworks/avd-nw/subnets/master"
$vmName = "AVDMaster"
$vmSize = "Standard_B2ls_v2"

# Connect to Azure
if (-not (Get-AzContext)) {Connect-AzAccount}

try {
    # Create a new disk from the snapshot
    Write-Output "Get the snapshot: ${snapshotName}"
    $snapshot = Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName

    # Create a new disk
    $osDiskName = "${vmName}_OSDisk_1"
    Write-Output "Deploy the disk: ${osDiskName}"
    $diskConfig = New-AzDiskConfig  `
        -SkuName $storageType `
        -Location $location `
        -CreateOption Copy  `
        -SourceResourceId $snapshot.Id `
        -DiskSizeGB $diskSize
    $osDisk = New-AzDisk `
        -Disk $diskConfig `
        -ResourceGroupName $resourceGroupName `
        -DiskName $osDiskName

    # Create a new NIC
    $nicName = "${vmName}_NetworkInterface"
    Write-Output "Deploy the nic: ${nicName}"
    $nic = New-AzNetworkInterface `
        -Name $nicName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SubnetId $subnetId

    # Create a new VM
    Write-Output "Deploy the vm: ${vmName}"
    $vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize
    $vm = Set-AzVMOSDisk -VM $vm -ManagedDiskId $osDisk.Id -CreateOption Attach -DeleteOption Delete -Windows
    $vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id -DeleteOption Delete
    $vm = Set-AzVMBootDiagnostic -VM $vm -Disable
    New-AzVM `
        -ResourceGroupName $resourceGroupName `
        -Location $location `
        -VM $vm `
        -DisableBginfoExtension

    Write-Output "Successfully deployed the vm: ${vmName}"
}
catch {
    Write-Error "Failed to deploy the vm: $_"
}