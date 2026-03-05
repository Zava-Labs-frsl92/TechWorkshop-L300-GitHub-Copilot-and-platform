@description('Web App name.')
param name string

@description('Azure region for the Web App.')
param location string

@description('App Service plan resource ID.')
param serverFarmId string

@description('ACR login server, for example myregistry.azurecr.io.')
param acrLoginServer string

@description('Container image name in ACR.')
param imageName string

@description('Container image tag in ACR.')
param imageTag string

@description('Optional container port to expose. Leave empty to use the image default.')
param containerPort string = ''

@description('Application Insights connection string.')
param appInsightsConnectionString string

@description('Application Insights instrumentation key.')
param appInsightsInstrumentationKey string

@description('Microsoft Foundry endpoint base URL.')
param foundryEndpoint string

@description('Microsoft Foundry deployment name for Phi-4.')
param foundryDeploymentName string

@description('Foundry resource id for regional endpoint authentication.')
param foundryResourceId string

var linuxFxVersion = 'DOCKER|${acrLoginServer}/${imageName}:${imageTag}'

var baseAppSettings = [
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: appInsightsConnectionString
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: appInsightsInstrumentationKey
  }
  {
    name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
    value: '~3'
  }
  {
    name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
    value: 'false'
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_URL'
    value: 'https://${acrLoginServer}'
  }
  {
    name: 'Foundry__Endpoint'
    value: foundryEndpoint
  }
  {
    name: 'Foundry__DeploymentName'
    value: foundryDeploymentName
  }
  {
    name: 'Foundry__ResourceId'
    value: foundryResourceId
  }
]

var appSettings = containerPort == ''
  ? baseAppSettings
  : concat(baseAppSettings, [
      {
        name: 'WEBSITES_PORT'
        value: containerPort
      }
    ])

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: serverFarmId
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      acrUseManagedIdentityCreds: true
      alwaysOn: true
      ftpsState: 'Disabled'
      appSettings: appSettings
    }
  }
}

output principalId string = webApp.identity.principalId
output hostName string = webApp.properties.defaultHostName
output name string = webApp.name
