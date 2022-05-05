param administratorLogin string = 'strongLogin'

@secure()
param administratorLoginPassword string

param location string = resourceGroup().location

param sqlServerName string

resource sqlSrv 'Microsoft.Sql/servers@2014-04-01' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
}

output SqlParameters object = {
    SqlUri: sqlSrv.properties.fullyQualifiedDomainName
    SqlServerName: sqlSrv.name
}
