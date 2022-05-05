param sqlServerName string
param location string = resourceGroup().location
param createNewServer bool = false

param administratorLogin string
@secure()
param administratorLoginPassword string

module newSqlSrv 'modules/sqlSrv-module.bicep' = if (createNewServer) {
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

module fwRulesModule 'modules/sqlSrv-fwRule-module.bicep' = {
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

module database 'modules/db-module.bicep' = {
  name: databaseName
  params: {
    databaseName: databaseName
    collation: collation
    environment: environment
    location: location
    sqlServerName: sqlSrv.name
  }
}
