param connectionMonitorName string
param appTags object
param sourceName string
param sourceResourceId string
param destName string
param destResourceId string
param workspaceResourceId string
param netWatcherName string
param netWatcherLocation string

var testConfigName = '${connectionMonitorName}-http-basic'

resource netWatcher 'Microsoft.Network/networkWatchers@2021-03-01' existing = {
  name: netWatcherName
}

resource connectionMonitorAppServer 'Microsoft.Network/networkWatchers/connectionMonitors@2021-03-01' = {
  name: connectionMonitorName
  parent: netWatcher
  location: netWatcherLocation
  tags: appTags
  properties: {
    endpoints: [
      {
        name: sourceName
        resourceId: sourceResourceId
        type: 'AzureVM'
      }
      {
        name: destName
        resourceId: destResourceId
        type: 'AzureVM'
      }
    ]
    testConfigurations: [
      {
        name: testConfigName
        testFrequencySec: 30
        protocol: 'Http'
        successThreshold: {
          checksFailedPercent: 10
          roundTripTimeMs: 100
        }
        httpConfiguration: {
          port: 80
          method: 'Get'
          path: '/'
          validStatusCodeRanges: [
            '200-202'
          ]
          preferHTTPS: false
        }
      }
    ]
    testGroups: [
      {
        name: '${resourceGroup().name}'
        sources: [
          '${sourceName}'
        ]
        destinations: [
          '${destName}'
        ]
        testConfigurations: [
          '${testConfigName}'
        ]
        disable: false
      }
    ]
    outputs: [
      {
        type: 'Workspace'
        workspaceSettings: {
          workspaceResourceId: workspaceResourceId
        }
      }
    ]
  }
}
