param name string
param location string = resourceGroup().location
param tags object = {}

param containerAppsEnvironmentName string = ''
param containerName string = 'main'
param containerRegistryName string = ''
param env array = []
param imageName string
param keyVaultName string = ''
param managedIdentityEnabled bool = !empty(keyVaultName)

@description('The name of the user-assigned identity')
param managedIdentityName string = ''

param daprEnabled bool = false
param daprApp string = containerName
param daprAppProtocol string = 'http'

@description('The type of identity for the resource')
@allowed([ 'None', 'SystemAssigned', 'UserAssigned' ])
param identityType string = 'None'

// Private registry support requires both an ACR name and a User Assigned managed identity
var usePrivateRegistry = !empty(managedIdentityName) && !empty(containerRegistryName)

// Automatically set to `UserAssigned` when an `identityName` has been set
var normalizedIdentityType = !empty(managedIdentityName) ? 'UserAssigned' : identityType


@description('CPU cores allocated to a single container instance, e.g. 0.5')
param containerCpuCoreCount string = '0.5'

@description('Memory allocated to a single container instance, e.g. 1Gi')
param containerMemory string = '1.0Gi'

resource containerRegistryAccess 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: '${deployment().name}-registry-access'
}

resource app 'Microsoft.App/containerApps@2023-05-02-preview' = {
  name: name
  location: location
  tags: tags
  // It is critical that the identity is granted ACR pull access before the app is created
  // otherwise the container app will throw a provision error
  // This also forces us to use an user assigned managed identity since there would no way to 
  // provide the system assigned identity with the ACR pull access before the app is created
  dependsOn: usePrivateRegistry ? [ containerRegistryAccess ] : []
  identity: {
    type: normalizedIdentityType
    userAssignedIdentities: !empty(managedIdentityName) && normalizedIdentityType == 'UserAssigned' ? { '${managedIdentity.id}': {} } : null
  } 
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      // secrets: [
      //   {
      //     name: 'registry-password'
      //     value: containerRegistry.listCredentials().passwords[0].value
      //   }
      // ]
      dapr: {
        enabled: daprEnabled
        appId: daprApp
        appProtocol: daprAppProtocol
      }
      registries: [
        {
          server: '${containerRegistry.name}.azurecr.io'
          // username: containerRegistry.name
          identity: managedIdentity.id
          // passwordSecretRef: 'registry-password'
        }
      ]
    }
    template: {
      containers: [
        {
          image: imageName
          name: containerName
          env: env
          resources: {
            cpu: json(containerCpuCoreCount)
            memory: containerMemory
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: containerAppsEnvironmentName
}

// 2022-02-01-preview needed for anonymousPullEnabled
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: containerRegistryName
}

// user assigned managed identity to use throughout
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: managedIdentityName
}

//output identityPrincipalId string = managedIdentityEnabled ? app.identity.principalId : ''
output identityPrincipalId string = normalizedIdentityType == 'None' ? '' : (empty(managedIdentityName) ? app.identity.principalId : managedIdentity.properties.principalId)
output imageName string = imageName
output name string = app.name
