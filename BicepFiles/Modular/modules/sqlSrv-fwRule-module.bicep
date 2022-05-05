param sqlServerName string
param allowedPublicIpAddresses string
param enableAzSvcs bool

resource sqlSrv 'Microsoft.Sql/servers@2014-04-01' existing = {
  name: sqlServerName
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

resource fwRuleAzureSvcs 'Microsoft.Sql/servers/firewallrules@2014-04-01' = if (enableAzSvcs) {
  parent: sqlSrv
  name: 'allow_AzureSvcs'
  properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '255.255.255.255'
  }
}
