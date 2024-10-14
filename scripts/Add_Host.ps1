$ErrorActionPreference = "Stop"

# Load parameter
.$args[0]

# Connect to Azure
if (-not (Get-AzContext)) {Connect-AzAccount}
Get-AzSubscription -SubscriptionName $subscriptionName | Set-AzContext

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
        -TemplateFile "./templates/Add_Host_template.json" `
        -TemplateParameterFile "./parameters/Add_Host_parameters.json" `
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
            -TemplateFile "./templates/Set_AutoShutdown_template.json" `
            -TemplateParameterFile "./parameters/Set_AutoShutdown_parameters.json" `
            -vmName $vm.name `
            -shutdownStatus $shutdownStatus `
            -shutdownTime $shutdownTime `
            -shutdownTimezone $shutdownTimezone -ErrorAction Stop
    }
    Write-Output "Successfully set auto-shutdown for VMs"

} catch {
    Write-Error "Failed to deploy the host: $_"
}
