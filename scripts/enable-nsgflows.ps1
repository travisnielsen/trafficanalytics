<#
.SYNOPSIS
    This script enables Network Flow Logs and Traffic Analytics for each NSG for a given region in the current subscription
.DESCRIPTION
    TBD 
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)][string]$region,
    [Parameter(Mandatory)][string]$networkWatcherRG,
    [Parameter(Mandatory)][string]$storageAcctRG,
    [Parameter(Mandatory)][string]$storageAcctName,
    [Parameter(Mandatory)][string]$logWorkspaceRG,
    [Parameter(Mandatory)][string]$logWorkspaceName
)

$networkWatcherName = "NetworkWatcher_${region}"
$networkWatcher = Get-AzNetworkWatcher -Name $networkWatcherName -ResourceGroupName $networkWatcherRG
$flowLogEnabledNsgs = Get-AzNetworkWatcherFlowLog -NetworkWatcher $networkWatcher | ForEach-Object {$_.TargetResourceId}

# Storage Account
$storage = Get-AzStorageAccount -ResourceGroupName $storageAcctRG -Name $storageAcctName

# Log Analytics Workspace
$logAnalytics = Get-AzOperationalInsightsWorkspace -ResourceGroupName $logWorkspaceRG -Name $logWorkspaceName

# NSGs
$nsgs = Get-AzNetworkSecurityGroup

foreach ($nsg in $nsgs) {

    # Only look at NSGs within the specified region
    if ($nsg.Location -eq $region) {

        # Only update NSGs that don't have flow logs  
        if ($flowLogEnabledNsgs -notcontains $nsg.Id) {
            Set-AzNetworkWatcherConfigFlowLog -NetworkWatcher $networkWatcher `
            -TargetResourceId $nsg.Id `
            -EnableFlowLog $true `
            -StorageAccountId $storage.Id `
            -EnableRetention $true `
            -RetentionInDays 14 `
            -FormatType Json `
            -FormatVersion 2 `
            -EnableTrafficAnalytics `
            -WorkspaceResourceId $logAnalytics.ResourceId `
            -WorkspaceGUID $logAnalytics.CustomerId `
            -WorkspaceLocation $region `
            -TrafficAnalyticsInterval 10
        }
    }
}