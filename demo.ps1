# Execute environmentPreparation.ps1 to deploy the target environment

$rgName = "GlobalAzure2022_TO_Demo"
$rg = Get-AzResourceGroup -ResourceGroupName $rgName -ErrorAction SilentlyContinue

#region Monolithic approach

# Deploy the monolithic bicep file
New-AzResourceGroupDeployment -Name "MonolithicDeployment" `
    -ResourceGroupName $rg.ResourceGroupName `
    -TemplateFile ".\BicepFiles\Monolithic\sqlSrvAndDb.bicep" `
    -TemplateParameterFile ".\BicepFiles\Monolithic\sqlSrvAndDb.parameters.json"

# Cleanup
Get-AzResource -ResourceGroupName $rg.ResourceGroupName | Remove-AzResource -force

#endregion

#region Modular approach

#region with local files
# APP1
New-AzResourceGroupDeployment -Name "Modular-Local-Deployment-APP1" `
    -ResourceGroupName $rg.ResourceGroupName `
    -TemplateFile ".\BicepFiles\Modular\APP1-main.bicep" `
    -TemplateParameterFile ".\BicepFiles\Modular\APP1-main.parameters.json"

# APP2
New-AzResourceGroupDeployment -Name "Modular-Local-Deployment-APP2" `
    -ResourceGroupName $rg.ResourceGroupName `
    -TemplateFile ".\BicepFiles\Modular\APP2-main.bicep" `
    -TemplateParameterFile ".\BicepFiles\Modular\APP2-main.parameters.json"

# Cleanup
Get-AzResource -ResourceGroupName $rg.ResourceGroupName | Remove-AzResource -force

#endregion

#region with bicep registry

# Push modules to the bicep registry
$registry = Get-AzContainerRegistry -ResourceGroupName "GlobalAzure2022_TO_Demo_BicepResources"

bicep publish ".\BicepFiles\Modular\modules\db-module.bicep" --target "br:$($registry.LoginServer)/modules/db-module:v1"
bicep publish ".\BicepFiles\Modular\modules\sqlSrv-module.bicep" --target "br:$($registry.LoginServer)/modules/sqlsrv-module:v1"
bicep publish ".\BicepFiles\Modular\modules\sqlSrv-fwRule-module.bicep" --target "br:$($registry.LoginServer)/modules/sqlsrv-fwrule-module:v1"

# Define an alias for the registry in bicepConfig.json
[PsCustomObject]$bicepConfig = Get-Content ".\BicepFiles\Modular_BicepRegistry\bicepConfig.json" -Encoding UTF8 | ConvertFrom-Json 
$bicepConfig.moduleAliases.br.DataSatPN.registry = $registry.LoginServer

$bicepConfig

$bicepConfig | ConvertTo-Json -Depth 5 |  Out-File ".\BicepFiles\Modular_BicepRegistry\bicepConfig.json"

# APP1
New-AzResourceGroupDeployment -Name "Modular-BicepRegistry-Deployment-APP1" `
    -ResourceGroupName $rg.ResourceGroupName `
    -TemplateFile ".\BicepFiles\Modular_BicepRegistry\APP1-main.bicep" `
    -TemplateParameterFile ".\BicepFiles\Modular_BicepRegistry\APP1-main.parameters.json"

# Cleanup
Get-AzResource -ResourceGroupName $rg.ResourceGroupName | Remove-AzResource -force

#endregion

#endregion

#region Template Spec

# Create a template spec for APP1-main.bicep
New-AzTemplateSpec -ResourceGroupName "GlobalAzure2022_TO_Demo_BicepResources" `
                -Name "APP1" `
                -Version "v1.0" `
                -Description "APP1 Template" `
                -DisplayName "APP1" `
                -Location "Sweden Central" `
                -TemplateFile ".\BicepFiles\Modular_BicepRegistry\APP1-main.bicep"

#endregion