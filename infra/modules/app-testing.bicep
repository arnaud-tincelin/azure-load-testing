param name string
param tags object = {}
param principalId string = ''

// Playwright Workspaces only supports: eastus, westus3, westeurope, eastasia
var playwrightLocation = 'westeurope'

// --- Storage account for Playwright reporting artifacts ---
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: replace('st${take(name, 20)}', '-', '')
  location: playwrightLocation
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: ['https://trace.playwright.dev']
          allowedMethods: ['GET', 'OPTIONS']
          allowedHeaders: ['*']
          exposedHeaders: ['*']
          maxAgeInSeconds: 3600
        }
      ]
    }
  }
}

// --- Playwright Workspace ---
resource playwrightWorkspace 'Microsoft.LoadTestService/playwrightWorkspaces@2026-02-01-preview' = {
  name: name
  location: playwrightLocation
  tags: tags
  properties: {
    localAuth: 'Enabled'
    regionalAffinity: 'Enabled'
    reporting: 'Enabled'
    storageUri: storageAccount.properties.primaryEndpoints.blob
  }
}

// Playwright Workspace Contributor — required for cloud-hosted browser sessions
resource playwrightRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(playwrightWorkspace.id, principalId, '78cf819f-0969-4ebe-8759-015c6efcd5bf')
  scope: playwrightWorkspace
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '78cf819f-0969-4ebe-8759-015c6efcd5bf')
    principalType: 'User'
  }
}

// Storage Blob Data Contributor — required for report uploads
resource storageBlobRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(storageAccount.id, principalId, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  scope: storageAccount
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalType: 'User'
  }
}

output playwrightWorkspaceName string = playwrightWorkspace.name
output playwrightWorkspaceId string = playwrightWorkspace.id
output dataplaneUri string = playwrightWorkspace.properties.dataplaneUri
output storageAccountName string = storageAccount.name
