param sqlServerName string
param location string = resourceGroup().location
param createNewServer bool = false

param administratorLogin string
@secure()
param administratorLoginPassword string

// Update the ACR uri according to your environment before deploying the bicep file
module newSqlSrv 'br:acr84090.azurecr.io/modules/sqlsrv-module:v1' = if (createNewServer) {
  name: sqlServerName
  params: {
    sqlServerName: sqlServerName
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    location: location
  }
}

resource sqlSrv 'Microsoft.Sql/servers@2014-04-01' existing = {
  name: newSqlSrv.name
}

param allowedPublicIpAddresses string
param enableAzSvcs bool

// Update the ACR uri according to your environment before deploying the bicep file
module fwRulesModule 'br:acr84090.azurecr.io/modules/sqlsrv-fwrule-module:v1' = {
  name: 'fwRules'
  params: {
    allowedPublicIpAddresses: allowedPublicIpAddresses
    sqlServerName: sqlSrv.name
    enableAzSvcs:  enableAzSvcs
  }
}

@allowed([
  'TEST'
  'PROD'
])
@description('target environment')
param environment string

param databaseName string
param collation string = 'SQL_Latin1_General_CP1_CI_AS'

// Update the ACR uri according to your environment before deploying the bicep file
module database 'br:acr84090.azurecr.io/modules/db-module:v1' = {
  name: databaseName
  params: {
    databaseName: databaseName
    collation: collation
    environment: environment
    location: location
    sqlServerName: sqlSrv.name
  }
}
