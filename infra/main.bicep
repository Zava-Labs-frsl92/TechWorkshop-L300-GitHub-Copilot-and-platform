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

@description('Foundry deployment name for Phi-4.')
param foundryDeploymentName string = 'Phi-4'

@description('Foundry model name to deploy.')
param foundryModelName string = 'Phi-4'

@description('Foundry model version to deploy.')
param foundryModelVersion string = '7'

@description('Foundry deployment SKU name.')
param foundryDeploymentSkuName string = 'GlobalStandard'

@description('Foundry deployment capacity.')
@minValue(1)
param foundryDeploymentCapacity int = 1

@description('Optional Foundry endpoint override. Leave empty to use the resource endpoint.')
param foundryEndpoint string = ''

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
var resolvedFoundryEndpoint = foundryEndpoint == '' ? foundry.outputs.endpoint : foundryEndpoint

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
    foundryEndpoint: resolvedFoundryEndpoint
    foundryDeploymentName: foundryDeploymentName
    foundryResourceId: foundryResource.id
  }
}

module acrPull 'modules/role-assignment.bicep' = {
  name: 'acrPull'
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
    deploymentName: foundryDeploymentName
    modelName: foundryModelName
    modelVersion: foundryModelVersion
    deploymentSkuName: foundryDeploymentSkuName
    deploymentCapacity: foundryDeploymentCapacity
  }
}

resource foundryResource 'Microsoft.CognitiveServices/accounts@2025-09-01' existing = {
  name: foundryName
}

resource foundryUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(foundryResource.id, webAppName, subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908'))
  scope: foundryResource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')
    principalId: webApp.outputs.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    foundry
    webApp
  ]
}

output webAppUrl string = 'https://${webApp.outputs.hostName}'
output acrLoginServer string = acr.outputs.loginServer
output appInsightsConnectionString string = appInsights.outputs.connectionString
output foundryName string = foundry.outputs.name
output foundryEndpoint string = foundry.outputs.endpoint
