param vnetName string
param addressSpaces array
param subnets array
param region string

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: region
  properties: {
    addressSpace: {
      addressPrefixes: addressSpaces
    }
    subnets: subnets
  }
}

output name string = vnet.name
output id string = vnet.id
