@description('Log Analytics workspace name.')
param name string

@description('Azure region for the workspace.')
param location string

@description('Workspace SKU name.')
param skuName string = 'PerGB2018'

@description('Retention in days for log data.')
param retentionInDays int = 30

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  sku: {
    name: skuName
  }
  properties: {
    retentionInDays: retentionInDays
  }
}

output workspaceResourceId string = workspace.id
output workspaceName string = workspace.name
