@description('ACR name. Must be globally unique, 5-50 alphanumeric characters.')
param name string

@description('Azure region for ACR.')
param location string

@description('ACR SKU name.')
@allowed([
  'Basic'
  'Standard'
])
param skuName string = 'Basic'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  sku: {
    name: skuName
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

output acrId string = acr.id
output loginServer string = acr.properties.loginServer
