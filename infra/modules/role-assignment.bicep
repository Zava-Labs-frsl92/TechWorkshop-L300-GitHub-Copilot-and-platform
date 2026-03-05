@description('Principal ID to receive the role assignment.')
param principalId string

@description('Role definition resource ID.')
param roleDefinitionId string

@description('ACR registry name used as the scope for the role assignment.')
param scopeRegistryName string

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: scopeRegistryName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(registry.id, principalId, roleDefinitionId)
  scope: registry
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
