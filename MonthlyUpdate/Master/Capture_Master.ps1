$ErrorActionPreference = "Stop"

$vmResourceGroupName = "avd-master"
$vmName = "AVDMaster"
$galleryName = "AVDImage"
$imageDefinition="AVDMaster"
$resourceGroupName = "avd"
$location = "japaneast"
$targetRegion = @{Name = 'japaneast'}
$replicaCount = 1

# Connect to Azure
if (-not (Get-AzContext)) {Connect-AzAccount}

try {
    # Stop the VM and generalize it
    Write-Output "Stop the vm and generalize it: ${vmName}"
    $vm = Get-AzVM -ResourceGroupName $vmResourceGroupName -Name $vmName
    Stop-AzVM -ResourceGroupName $vmResourceGroupName -Name $vmName -Force
    Set-AzVM -ResourceGroupName $vmResourceGroupName -Name $vmName -Generalized

    # Create a new image version
    $imageVersion = (Get-Date).ToString("1.yyyy.MM")
    Write-Output "Create a new image version: ${imageDefinition}/${imageVersion}"
    New-AzGalleryImageVersion `
        -GalleryName $galleryName `
        -GalleryImageDefinitionName $imageDefinition `
        -GalleryImageVersionName $imageVersion `
        -ResourceGroupName $resourceGroupName `
        -Location $location `
        -TargetRegion $targetRegion `
        -SourceImageVMId $vm.Id.ToString() `
        -ReplicaCount $replicaCount

    Write-Output "Successfully captured vm: ${vmName}"
}
catch {
    Write-Error "Failed to capture the vm: $_"
}