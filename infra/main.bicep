targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string = 'westus3'

@description('Deployment environment name.')
param environment string = 'dev'

@description('Base application name used for resource naming.')
param appName string = 'zavastorefront'

@description('ACR SKU name.')
@allowed([
  'Basic'
  'Standard'
])
param acrSkuName string = 'Basic'

@description('App Service plan SKU name, for example B1, B2, S1.')
param appServiceSkuName string = 'B1'

@description('App Service plan SKU tier, for example Basic, Standard.')
param appServiceSkuTier string = 'Basic'

@description('App Service plan instance count.')
@minValue(1)
param appServiceSkuCapacity int = 1

@description('Container image name stored in ACR.')
param containerImageName string = 'zavastorefront'

@description('Container image tag stored in ACR.')
param containerImageTag string = 'latest'

@description('Optional container port to expose. Leave empty to use the image default.')
param containerPort string = ''

@description('Azure AI Services (Foundry) SKU name.')
param foundrySkuName string = 'S0'

var uniqueSuffix = uniqueString(resourceGroup().id)
var safeAppName = toLower(replace(appName, '-', ''))
var baseName = toLower('${safeAppName}-${environment}')

var acrNameRaw = toLower('acr${safeAppName}${environment}${uniqueSuffix}')
var acrName = length(acrNameRaw) > 50 ? substring(acrNameRaw, 0, 50) : acrNameRaw

var planName = toLower('asp-${baseName}')
var webAppName = toLower('web-${baseName}-${uniqueSuffix}')
var logAnalyticsName = toLower('log-${baseName}-${uniqueSuffix}')
var appInsightsName = toLower('appi-${baseName}-${uniqueSuffix}')
var foundryName = toLower('ai-${baseName}-${uniqueSuffix}')

module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'logAnalytics'
  params: {
    name: logAnalyticsName
    location: location
  }
}

module appInsights 'modules/app-insights.bicep' = {
  name: 'appInsights'
  params: {
    name: appInsightsName
    location: location
    workspaceResourceId: logAnalytics.outputs.workspaceResourceId
  }
}

module acr 'modules/acr.bicep' = {
  name: 'acr'
  params: {
    name: acrName
    location: location
    skuName: acrSkuName
  }
}

module appServicePlan 'modules/app-service-plan.bicep' = {
  name: 'appServicePlan'
  params: {
    name: planName
    location: location
    skuName: appServiceSkuName
    skuTier: appServiceSkuTier
    capacity: appServiceSkuCapacity
  }
}

module webApp 'modules/webapp-container.bicep' = {
  name: 'webApp'
  params: {
    name: webAppName
    location: location
    serverFarmId: appServicePlan.outputs.planId
    acrLoginServer: acr.outputs.loginServer
    imageName: containerImageName
    imageTag: containerImageTag
    containerPort: containerPort
    appInsightsConnectionString: appInsights.outputs.connectionString
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
  }
}

module acrPull 'modules/role-assignment.bicep' = {
  name: 'acrPull'
  dependsOn: [
    acr
  ]
  params: {
    principalId: webApp.outputs.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    scopeRegistryName: acrName
  }
}

module foundry 'modules/foundry.bicep' = {
  name: 'foundry'
  params: {
    name: foundryName
    location: location
    skuName: foundrySkuName
  }
}

output webAppUrl string = 'https://${webApp.outputs.hostName}'
output acrLoginServer string = acr.outputs.loginServer
output appInsightsConnectionString string = appInsights.outputs.connectionString
output foundryName string = foundry.outputs.name
output foundryEndpoint string = foundry.outputs.endpoint
