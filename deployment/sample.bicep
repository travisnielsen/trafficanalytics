targetScope = 'subscription'
param demoPrefix string
param region1 string = 'centralus'
param region2 string = 'eastus2'
param tags object = {
  project: 'TrafficAnalyticsDemo'
  environment: 'sandbox'
}

resource netrg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${demoPrefix}-network'
  location: region1
  tags: tags
}

/*
resource ingressrg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${demoPrefix}-netops'
  location: region1
  tags: tags
}
*/

resource computerg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${demoPrefix}-compute'
  location: region1
  tags: tags
}

// Central US VNET settings
param region1VnetName string = '${demoPrefix}-${region1}'
param region1AddressSpaces array = [ 
  '10.0.0.0/16'
 ]
param region1SubnetBlockAzFW string = '10.0.0.0/25'           // 123 addresses - 10.0.0.0 - 10.0.0.127
param region1SubnetBlockBastion string = '10.0.0.128/25'      // 123 addresses - 10.0.0.128 - 10.0.0.255
param region1SubnetBlockAppGateway string = '10.0.1.0/25'     // 123 addresses - 10.0.1.0 - 10.0.1.127
param region1SubnetBlockWebServers string = '10.0.1.128/25'     // 123 addresses - 10.0.1.128 - 10.0.1.255


// ------------------------------------------------------------
// Region 1 VNET
// ------------------------------------------------------------

module nsgBastion 'modules/nsg.bicep' = {
  name: '${demoPrefix}-nsg-bastion'
  scope: resourceGroup(netrg.name)
  params: {
    name: '${demoPrefix}-nsg-bastion'
    region: region1
    securityRules: [
        // SEE: https://docs.microsoft.com/en-us/azure/bastion/bastion-nsg#apply
        {
          name: 'bastion-ingress'
          properties: {
            priority: 100
            protocol: 'Tcp'
            access: 'Allow'
            direction: 'Inbound'
            sourceAddressPrefix: 'Internet'
            sourcePortRange: '*'
            destinationAddressPrefix: '*'
            destinationPortRange: '443'
          }
        }
        {
          name: 'bastion-gatewaymgr'
          properties: {
            priority: 120
            protocol: 'Tcp'
            access: 'Allow'
            direction: 'Inbound'
            sourceAddressPrefix: 'GatewayManager'
            sourcePortRange: '*'
            destinationAddressPrefix: '*'
            destinationPortRange: '443'
          }
        }
        {
          name: 'bastion-loadbalancer'
          properties: {
            priority: 140
            protocol: 'Tcp'
            access: 'Allow'
            direction: 'Inbound'
            sourceAddressPrefix: 'AzureLoadBalancer'
            sourcePortRange: '*'
            destinationAddressPrefix: '*'
            destinationPortRange: '443'
          }
        }
        {
          name: 'allow-ssh-rdp-vnet'
          properties: {
            priority: 100
            protocol: '*'
            access: 'Allow'
            direction: 'Outbound'
            sourceAddressPrefix: '*'
            sourcePortRange: '*'
            destinationAddressPrefix: 'VirtualNetwork'
            destinationPortRanges: [
              '22'
              '3389'
            ]
          }
        }
        {
          name: 'allow-azure-dependencies'
          properties: {
            priority: 120
            protocol: '*'
            access: 'Allow'
            direction: 'Outbound'
            sourceAddressPrefix: '*'
            sourcePortRange: '*'
            destinationAddressPrefix: 'AzureCloud'
            destinationPortRange: '443'
          }
        }
        {
          name: 'deny-internet'
          properties: {
            priority: 140
            protocol: '*'
            access: 'Deny'
            direction: 'Outbound'
            sourceAddressPrefix: '*'
            sourcePortRange: '*'
            destinationAddressPrefix: 'Internet'
            destinationPortRange: '*'
          }
        }
    ]
  }
}

module nsgAppGateway 'modules/nsg.bicep' = {
  name: '${demoPrefix}-nsg-appgw'
  scope: resourceGroup(netrg.name)
  params: {
    name: '${demoPrefix}-nsg-appgw'
    region: region1
    securityRules: [
    ]
  }
}

module nsgWebServers 'modules/nsg.bicep' = {
  name: '${demoPrefix}-nsg-webservers'
  scope: resourceGroup(netrg.name)
  params: {
    name: '${demoPrefix}-nsg-webservers'
    region: region1
    securityRules: [
    ]
  }
}

module vnetRegion1 'modules/vnet.bicep' = {
  name: region1VnetName
  scope: resourceGroup(netrg.name)
  params: {
    vnetName: region1VnetName
    addressSpaces: region1AddressSpaces
    region: region1
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: region1SubnetBlockAzFW
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: region1SubnetBlockBastion
          networkSecurityGroup: {
            id: nsgBastion.outputs.id
          }
        }
      }
      {
        name: 'ApplicationGateway'
        properties: {
          addressPrefix: region1SubnetBlockAppGateway
          networkSecurityGroup: {
            id: nsgAppGateway.outputs.id
          }
        }
      }
      {
        name: 'WebServers'
        properties: {
          addressPrefix: region1SubnetBlockWebServers
          networkSecurityGroup: {
            id: nsgWebServers.outputs.id
          }
        }
      }
    ]
  }
}


// ------------------------------------------------------------
// Region 2 VNET
// ------------------------------------------------------------

param region2VnetName string = '${demoPrefix}-eastus2'
param region2AddressSpaces array = [
  '11.0.0.0/16'
 ]
param region2SubnetBlockAppServers string = '11.0.0.0/25'  // 123 addresses - 11.0.0.0 - 11.0.0.127


module nsgAppServers 'modules/nsg.bicep' = {
  name: '${demoPrefix}-nsg-appservers'
  scope: resourceGroup(netrg.name)
  params: {
    name: '${demoPrefix}-nsg-appservers'
    region: region2
    securityRules: [
    ]
  }
}

module vnetRegion2 'modules/vnet.bicep' = {
  name: region2VnetName
  scope: resourceGroup(netrg.name)
  params: {
    vnetName: region2VnetName
    addressSpaces: region2AddressSpaces
    region: region2
    subnets: [
      {
        name: 'AppServers'
        properties: {
          addressPrefix: region2SubnetBlockAppServers
          networkSecurityGroup: {
            id: nsgAppServers.outputs.id
          }
        }
      }
    ]
  }
}

// ------------------------------------------------------------
// VNET peering
// ------------------------------------------------------------

module HubToSpokePeering 'modules/peering.bicep' = {
  name: 'region1-to-region2'
  scope: resourceGroup(netrg.name)
  params: {
    localVnetName: vnetRegion1.name
    remoteVnetName: vnetRegion2.name
    remoteVnetId: vnetRegion2.outputs.id
  }
}

module SpokeToHubPeering 'modules/peering.bicep' = {
  name: 'region2-to-region1'
  scope: resourceGroup(netrg.name)
  params: {
    localVnetName: vnetRegion2.name
    remoteVnetName: vnetRegion1.name
    remoteVnetId: vnetRegion1.outputs.id
  }
}

// ------------------------------------------------------------
// Bastion
// ------------------------------------------------------------

module bastion 'modules/bastion.bicep' = {
  name: 'hub-bastion'
  scope: resourceGroup(netrg.name)
  params: {
    name: '${uniqueString(netrg.id)}'
    subnetId: '${vnetRegion1.outputs.id}/subnets/AzureBastionSubnet'
  }
}

// ------------------------------------------------------------
// Virtual Machines
// ------------------------------------------------------------

param vmAdminUserName string = 'vmadmin'

@secure()
param vmAdminPwd string

module webserver 'modules/vm-ubuntu.bicep' = {
  name: 'webserver'
  scope: resourceGroup(computerg.name)
  params: {
    location: region1
    vmName: '${demoPrefix}-web'
    networkResourceGroupName: netrg.name
    vnetName: vnetRegion1.name
    subnetName: 'WebServers'
    adminUserName: vmAdminUserName
    adminPassword: vmAdminPwd
  }
}

module appserver 'modules/vm-ubuntu.bicep' = {
  name: 'appserver'
  scope: resourceGroup(computerg.name)
  params: {
    location: region2
    vmName: '${demoPrefix}-app'
    networkResourceGroupName: netrg.name
    vnetName: vnetRegion2.name
    subnetName: 'AppServers'
    adminUserName: vmAdminUserName
    adminPassword: vmAdminPwd
  }
}

// ------------------------------------------------------------
// Storage
// ------------------------------------------------------------

var prefix = substring(uniqueString(netrg.id), 0, 10)

module storageRegion1 'modules/storage.bicep' = {
  name: 'region1-storage'
  scope: resourceGroup(netrg.name)
  params: {
    accountName: '${prefix}${region1}nsg'
    location: region1
  }
}

module storageRegion2 'modules/storage.bicep' = {
  name: 'region2-storage'
  scope: resourceGroup(netrg.name)
  params: {
    accountName: '${prefix}${region2}nsg'
    location: region2
  }
}

// ------------------------------------------------------------
// Log Analytics
// ------------------------------------------------------------

module logAnalytics 'modules/loganalytics.bicep' = {
  name: 'region1-loganalytics'
  scope: resourceGroup(netrg.name)
  params: {
    appTags: tags
    name: '${uniqueString(netrg.id)}'
  }
}
