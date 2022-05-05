Login-AzAccount

$location = "Sweden Central"

# Create a RG for SQL resources

$rgName = "DataSatPN_2022_Demo"

$rg = Get-AzResourceGroup -ResourceGroupName $rgName -ErrorAction SilentlyContinue

if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

# Create a RG for Bicep Registry and Template Spec

$bcRgName = "DataSatPN_2022_Demo_BicepResources"

$bcRg = Get-AzResourceGroup -ResourceGroupName $bcRgName -ErrorAction SilentlyContinue

if(-not $bcRg) {
    $bcRg = New-AzResourceGroup -Name $bcRgName -Location $location
}

# Create a new Bicep module registry
$reg = New-AzContainerRegistry -Name "acr$(Get-Random -Maximum 99999)" `
            -ResourceGroupName $bcRg.ResourceGroupName `
            -Location $location `
            -Sku "Basic" `
            -EnableAdminUser:$false

$reg.Name

# Create RGs for DEV and PROD env
$devRg = New-AzResourceGroup -Name 'DataSatPN_2022_Demo_DEV' -location $location
$prodRg = New-AzResourceGroup -Name 'DataSatPN_2022_Demo_PROD' -location $location

# Create a role for validating ARM deployment
$role = Get-AzRoleDefinition -Name "Deployment validator" -ErrorAction SilentlyContinue

if (-not $role) {
    $role = Get-AzRoleDefinition | select -First 1

    $role.Id = $null
    $role.Name = "Deployment validator"
    $role.Description = "Can validate an ARM deployment."
    $role.Actions.RemoveRange(0,$role.Actions.Count)
    $role.Actions.Add("Microsoft.Resources/deployments/validate/action")
    $role.NotActions.RemoveRange(0,$role.NotActions.Count)
    $role.AssignableScopes.Add("/subscriptions/$((Get-AzContext).Subscription.Id)")

    New-AzRoleDefinition -Role $role
}

# Create a service principal and grant it contributor access on the DEV rg
$azureContext = Get-AzContext
$servicePrincipal = New-AzADServicePrincipal `
    -DisplayName "DataSatPN-2022-DEV" `
    -Role "Contributor" `
    -Scope $devRg.ResourceId

# Assign also the Contributor role on the RG hosting the bicep registry
New-AzRoleAssignment -ApplicationId $servicePrincipal.AppId `
    -ResourceGroupName $bcRg.ResourceGroupName `
    -RoleDefinitionName "Contributor"

# Assign also the Deployment validator role on PROD RG
New-AzRoleAssignment -ApplicationId $servicePrincipal.AppId `
    -ResourceGroupName $prodRg.ResourceGroupName `
    -RoleDefinitionName "Deployment validator"

$output = @{
   clientId = $($servicePrincipal.AppId)
   clientSecret = $servicePrincipal.PasswordCredentials[0].SecretText
   subscriptionId = $($azureContext.Subscription.Id)
   tenantId = $($azureContext.Tenant.Id)
}

$output | ConvertTo-Json
$output | ConvertTo-Json | Set-Clipboard
# Paste the content of the clipboard in a new GitHub secret called AzCred_DEV

# Create a service principal and grant it access on the PROD rg
$servicePrincipal = New-AzADServicePrincipal `
    -DisplayName "DataSatPN-2022-PROD" `
    -Role "Contributor" `
    -Scope $prodRg.ResourceId

# Assign also the Contributor role on the RG hosting the bicep registry
New-AzRoleAssignment -ApplicationId $servicePrincipal.AppId `
    -ResourceGroupName $bcRg.ResourceGroupName `
    -RoleDefinitionName "Contributor"

$output = @{
   clientId = $($servicePrincipal.AppId)
   clientSecret = $servicePrincipal.PasswordCredentials[0].SecretText
   subscriptionId = $($azureContext.Subscription.Id)
   tenantId = $($azureContext.Tenant.Id)
}

$output | ConvertTo-Json
$output | ConvertTo-Json | Set-Clipboard
# Paste the content of the clipboard in a new GitHub secret called AzCreds_DEV
