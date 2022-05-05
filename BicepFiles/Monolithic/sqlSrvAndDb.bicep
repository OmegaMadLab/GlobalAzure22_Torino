param location string = resourceGroup().location

param sqlServerName string
param createNewServer bool = false

param allowedPublicIpAddresses string

param administratorLogin string
@secure()
param administratorLoginPassword string

resource newSqlSrv 'Microsoft.Sql/servers@2014-04-01' = if(createNewServer) {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
}

resource sqlSrv 'Microsoft.Sql/servers@2014-04-01' existing = {
  name: newSqlSrv.name
}

var ipAddressList = split(allowedPublicIpAddresses, ',')

resource fwRule 'Microsoft.Sql/servers/firewallRules@2014-04-01' = [for ipAddress in ipAddressList: {
  parent: sqlSrv
  name: 'allow_${ipAddress}'
  properties: {
      startIpAddress: ipAddress
      endIpAddress: ipAddress
  }
}]

resource fwRuleAzureSvcs 'Microsoft.Sql/servers/firewallrules@2014-04-01' = {
  parent: sqlSrv
  name: 'allow_AzureSvcs'
  properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '255.255.255.255'
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
