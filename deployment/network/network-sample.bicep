param demoPrefix string
param vnetName string
param addressSpaces array = [ 
  '10.0.0.0/16'
 ]

param subnetAddressBlock1 string = '10.0.0.0/25'  // 123 addresses - 10.0.0.0 - 10.0.0.127
param subnetAddressBlock2 string = '10.0.0.128/25'    // 123 addresses - 10.0.1.128 - 10.0.0.255

resource subnet1Nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: '${demoPrefix}-nsg-subnet1'
  location: resourceGroup().location
  properties: {
    securityRules: [

    ]
  }
}

resource subnet2Nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: '${demoPrefix}-nsg-subnet2'
  location: resourceGroup().location
  properties: {
    securityRules: [

    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: addressSpaces
    }
    subnets: [
      {
        name: 'subnet1'
        properties: {
          addressPrefix: subnetAddressBlock1
          networkSecurityGroup: subnet1Nsg
        }
      }
      {
        name: 'subnet2'
        properties: {
          addressPrefix: subnetAddressBlock2
          networkSecurityGroup: subnet2Nsg
        }
      }
    ]
  }
}
