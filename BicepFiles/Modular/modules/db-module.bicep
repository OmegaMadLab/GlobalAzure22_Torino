param sqlServerName string
param location string

resource sqlSrv 'Microsoft.Sql/servers@2014-04-01' existing = {
  name: sqlServerName
}

@allowed([
  'TEST'
  'PROD'
])
@description('target environment')
param environment string

param databaseName string
param collation string = 'SQL_Latin1_General_CP1_CI_AS'

resource db 'Microsoft.Sql/servers/databases@2019-06-01-preview' = {
  parent: sqlSrv
  name: databaseName
  location: location
  sku: {
    name: environment == 'TEST' ? 'S0' : 'S3'
  }
  properties:{
    collation: collation
  }
}
