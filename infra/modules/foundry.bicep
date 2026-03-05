@description('Azure AI Services (Foundry) resource name.')
param name string

@description('Azure region for the Foundry resource.')
param location string

@description('SKU name for Azure AI Services.')
param skuName string = 'S0'

resource foundry 'Microsoft.CognitiveServices/accounts@2025-09-01' = {
  name: name
  location: location
  kind: 'AIServices'
  sku: {
    name: skuName
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

output name string = foundry.name
output endpoint string = foundry.properties.endpoint
