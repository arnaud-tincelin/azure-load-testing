targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the environment used to generate a short unique hash.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

module containerRegistry './modules/container-registry.bicep' = {
  name: 'container-registry'
  params: {
    name: '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    tags: tags
  }
}

module containerAppsEnvironment './modules/container-apps-environment.bicep' = {
  name: 'container-apps-environment'
  params: {
    name: '${abbrs.appManagedEnvironments}${resourceToken}'
    location: location
    tags: tags
  }
}

module albumsApi './modules/albums-api.bicep' = {
  name: 'albums-api'
  params: {
    name: '${abbrs.appContainerApps}albums-api-${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'albums-api' })
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.id
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    containerRegistryName: containerRegistry.outputs.name
  }
}

module albumsFrontend './modules/albums-frontend.bicep' = {
  name: 'albums-frontend'
  params: {
    name: '${abbrs.appContainerApps}albums-frontend-${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'albums-frontend' })
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.id
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    containerRegistryName: containerRegistry.outputs.name
    apiUrl: albumsApi.outputs.uri
  }
}

module loadTesting './modules/load-testing.bicep' = {
  name: 'load-testing'
  params: {
    name: '${abbrs.loadTestingLoadTests}${resourceToken}'
    location: location
    tags: tags
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output SERVICE_ALBUMS_API_ENDPOINT_URL string = albumsApi.outputs.uri
output SERVICE_ALBUMS_FRONTEND_ENDPOINT_URL string = albumsFrontend.outputs.uri
output AZURE_LOAD_TESTING_RESOURCE_NAME string = loadTesting.outputs.name
output AZURE_LOAD_TESTING_RESOURCE_GROUP string = resourceGroup().name
