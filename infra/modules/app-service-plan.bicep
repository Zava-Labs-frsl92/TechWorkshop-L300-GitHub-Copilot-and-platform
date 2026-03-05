@description('App Service plan name.')
param name string

@description('Azure region for the App Service plan.')
param location string

@description('App Service plan SKU name, for example B1, S1.')
param skuName string

@description('App Service plan SKU tier, for example Basic, Standard.')
param skuTier string

@description('App Service plan instance count.')
@minValue(1)
param capacity int = 1

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: name
  location: location
  kind: 'linux'
  sku: {
    name: skuName
    tier: skuTier
    capacity: capacity
  }
  properties: {
    reserved: true
  }
}

output planId string = plan.id
output planName string = plan.name
