param name string
param securityRules array
param region string

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: name
  // location: resourceGroup().location
  location: region
  properties: {
    securityRules: securityRules
  }
}

output id string = nsg.id
output nsgName string = nsg.name
