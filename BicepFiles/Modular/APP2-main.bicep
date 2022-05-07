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

@allowed([
  'TEST'
  'PROD'
])
@description('target environment')
param environment string

param databaseNameList string
param collation string = 'SQL_Latin1_General_CP1_CI_AS'

var dbList = split(databaseNameList, ',')

module database 'modules/db-module.bicep' = [for dbName in dbList: {
  name: dbName
  params: {
    databaseName: dbName
    collation: collation
    environment: environment
    location: location
    sqlServerName: newSqlSrv.name
  }
}]

