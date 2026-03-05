@description('Azure AI Services (Foundry) resource name.')
param name string

@description('Azure region for the Foundry resource.')
param location string

@description('SKU name for Azure AI Services.')
param skuName string = 'S0'

@description('Model deployment name for Phi-4.')
param deploymentName string = 'Phi-4'

@description('Model name to deploy in Foundry.')
param modelName string = 'Phi-4'

@description('Model version to deploy in Foundry.')
param modelVersion string = '7'

@description('Deployment SKU name for model inference.')
param deploymentSkuName string = 'GlobalStandard'

@description('Deployment capacity for model inference.')
@minValue(1)
param deploymentCapacity int = 1

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

resource phi4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  name: deploymentName
  parent: foundry
  sku: {
    name: deploymentSkuName
    capacity: deploymentCapacity
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: modelName
      version: modelVersion
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    currentCapacity: deploymentCapacity
    raiPolicyName: 'Microsoft.DefaultV2'
  }
}

output name string = foundry.name
output endpoint string = foundry.properties.endpoint
output deploymentName string = deploymentName
