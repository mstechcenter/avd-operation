$ErrorActionPreference = "Stop"

# Load parameter
.$args[0]

# Connect to Azure
if (-not (Get-AzContext)) {Connect-AzAccount}
Get-AzSubscription -SubscriptionName $subscriptionName | Set-AzContext

# AVDMaster
Write-Output "Remove the AVDMaster"
# VM
Get-AzVM -ResourceGroupName $masterResourceGroupName -Name $masterVMName | Remove-AzVm -ForceDeletion $true -Force
# Snapshot
Get-AzSnapshot -ResourceGroupName $masterResourceGroupName | `
    Where-Object { $_.Name -like "${masterVMName}*" } | `
    Sort-Object { $_.TimeCreated } | `
    Select-Object -First 1 | `
    Remove-AzSnapshot -Force
# Image
Get-AzGalleryImageVersion -ResourceGroupName $imageResourceGroupName -GalleryName $galleryName -GalleryImageDefinitionName $imageDefinitionName | `
    Sort-Object { $_.PublishingProfile.PublishedDate } | `
    Select-Object -First 1 | `
    Remove-AzGalleryImageVersion -Force

# AVDTest
Write-Output "Remove the AVDTest"
# SessionHost
Remove-AzWvdSessionHost -ResourceGroupName $testResourceGroupName -HostPoolName $testHostPoolName -Name $testAVDName -Force
# VM
$vmConfig = Get-AzVM -ResourceGroupName $testResourceGroupName -Name $testVMName
$vmConfig.StorageProfile.OsDisk.DeleteOption = 'Delete'
$vmConfig.StorageProfile.DataDisks | ForEach-Object { $_.DeleteOption = 'Delete' }
$vmConfig.NetworkProfile.NetworkInterfaces | ForEach-Object { $_.DeleteOption = 'Delete' }
$vmConfig | Update-AzVM
$vmConfig | Remove-AzVm -ForceDeletion $true -Force

#AVDPartner
Write-Output "Remove the AVDPartner"
# SessionHost
Get-AzWvdSessionHost -ResourceGroupName $partnerResourceGroupName -HostPoolName $partnerHostPoolName | `
    Where-Object { $_.Name -like "*${partnerAVDNameSuffix}*" } | `
    Remove-AzWvdSessionHost -Force
# VM
Get-AzVM -ResourceGroupName $partnerResourceGroupName | `
    Where-Object { $_.Name -like "${partnerVMNameSuffix}*" } | `
    ForEach-Object{
        $_.StorageProfile.OsDisk.DeleteOption = 'Delete'
        $_.StorageProfile.DataDisks | ForEach-Object { $_.DeleteOption = 'Delete' }
        $_.NetworkProfile.NetworkInterfaces | ForEach-Object { $_.DeleteOption = 'Delete' }
        $_ | Update-AzVM
        $_ | Remove-AzVm -ForceDeletion $true -Force
    }

#AVDProper
Write-Output "Remove the AVDProper"
# SessionHost
Get-AzWvdSessionHost -ResourceGroupName $properResourceGroupName -HostPoolName $properHostPoolName | `
    Where-Object { $_.Name -like "*${properAVDNameSuffix}*" } | `
    Remove-AzWvdSessionHost -Force
# VM
Get-AzVM -ResourceGroupName $properResourceGroupName | `
    Where-Object { $_.Name -like "${properVMNameSuffix}*" } | `
    ForEach-Object{
        $_.StorageProfile.OsDisk.DeleteOption = 'Delete'
        $_.StorageProfile.DataDisks | ForEach-Object { $_.DeleteOption = 'Delete' }
        $_.NetworkProfile.NetworkInterfaces | ForEach-Object { $_.DeleteOption = 'Delete' }
        $_ | Update-AzVM
        $_ | Remove-AzVm -ForceDeletion $true -Force
    }