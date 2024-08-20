$ErrorActionPreference = "Stop"

$resourceGroupName = "avd-prod"
$hostpoolResourceGroup = "avd-prod"
$hostPoolName = "AVDProd"
$vmResourceGroup = "avd-prod"
$vmLocation = "japaneast"
$vmImageType = "CustomImage"
$vmCustomImageSourceId = "/subscriptions/01234567-8901-2345-6789-012345678901/resourceGroups/avd/providers/Microsoft.Compute/galleries/AVDImage/images/AVDMaster/versions/1.0.0"
$vmNamePrefix = "AVDProd"
$vmInitialNumber = 0
$vmNumberOfInstances = 1
$availabilityOption = "None"
$vmSize = "Standard_B2ls_v2"
$vmDiskType = "StandardSSD_LRS"
$virtualNetworkResourceGroupName = "avd"
$existingVnetName = "avd-nw"
$existingSubnetName = "prod"
$administratorAccountUsername = "avdadmin@012345678901.onmicrosoft.com"
$administratorAccountPassword = "012345678901"
$vmAdministratorAccountUsername = "avdadmin"
$vmAdministratorAccountPassword = "012345678901"
$domain = "012345678901.onmicrosoft.com"
$shutdownStatus = "Enabled"
$shutdownTime = "20:00"
$shutdownTimezone = "Tokyo Standard Time"

# Connect to Azure
if (-not (Get-AzContext)) {Connect-AzAccount}

try {
    # Get the host pool registration token
    Write-Output "Get the host pool registration token: ${hostPoolName}"
    $expirationTime = (Get-Date).ToString("yyyy-MM-ddT23:59:59Z")
    $hostPool = New-AzWvdRegistrationInfo `
        -ResourceGroupName $hostpoolResourceGroup `
        -HostPoolName $hostPoolName `
        -ExpirationTime $expirationTime
    $secureToken = ConvertTo-SecureString -String $hostPool.Token -AsPlainText -Force
    $administratorAccountPassword = ConvertTo-SecureString -String $administratorAccountPassword -AsPlainText -Force
    $vmAdministratorAccountPassword = ConvertTo-SecureString -String $vmAdministratorAccountPassword -AsPlainText -Force

    # Deploy the host
    $deploymentId = New-Guid
    Write-Output "Add host to hostpool: ${hostPoolName}"
    $deployment = New-AzResourceGroupDeployment `
        -ResourceGroupName $resourceGroupName `
        -TemplateFile "../Common/Add_Host_template.json" `
        -TemplateParameterFile "../Common/Add_Host_parameters.json" `
        -hostpoolResourceGroup $hostpoolResourceGroup `
        -hostPoolName $hostPoolName `
        -hostpoolToken $secureToken `
        -vmResourceGroup $vmResourceGroup `
        -vmLocation $vmLocation `
        -vmImageType $vmImageType `
        -vmCustomImageSourceId $vmCustomImageSourceId `
        -vmNamePrefix $vmNamePrefix `
        -vmInitialNumber $vmInitialNumber `
        -vmNumberOfInstances $vmNumberOfInstances `
        -availabilityOption $availabilityOption `
        -vmSize $vmSize `
        -vmDiskType $vmDiskType `
        -virtualNetworkResourceGroupName $virtualNetworkResourceGroupName `
        -existingVnetName $existingVnetName `
        -existingSubnetName $existingSubnetName `
        -administratorAccountUsername $administratorAccountUsername `
        -administratorAccountPassword $administratorAccountPassword `
        -vmAdministratorAccountUsername $vmAdministratorAccountUsername `
        -vmAdministratorAccountPassword $vmAdministratorAccountPassword `
        -domain $domain `
        -deploymentId $deploymentId
    Write-Output "Successfully added host to hostpool: ${hostPoolName}"

    # Set auto-shutdown for the VMs
    $vms = $deployment.Outputs.rdshVmNamesObject.Value | ForEach-Object {$_.Value.ToString() | ConvertFrom-Json}
    foreach ($vm in $vms) {
        Write-Output "Setting auto-shutdown for VM: $($vm.name)"
        New-AzResourceGroupDeployment `
            -ResourceGroupName $resourceGroupName `
            -TemplateFile "../Common/Set_AutoShutdown_template.json" `
            -TemplateParameterFile "../Common/Set_AutoShutdown_parameters.json" `
            -vmName $vm.name `
            -shutdownStatus $shutdownStatus `
            -shutdownTime $shutdownTime `
            -shutdownTimezone $shutdownTimezone -ErrorAction Stop
    }
    Write-Output "Successfully set auto-shutdown for VMs"

} catch {
    Write-Error "Failed to deploy the host: $_"
}
