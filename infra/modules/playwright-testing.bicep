param name string
param tags object = {}

// Storage account for reporting artifacts
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: replace('st${take(name, 20)}', '-', '')
  location: 'westeurope'
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

// Blob service with CORS for trace viewer
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

resource playwrightWorkspace 'Microsoft.LoadTestService/playwrightWorkspaces@2026-02-01-preview' = {
  name: name
  location: 'westeurope'
  tags: tags
  properties: {
    regionalAffinity: 'Enabled'
    reporting: 'Enabled'
    storageUri: storageAccount.properties.primaryEndpoints.blob
  }
}

output id string = playwrightWorkspace.id
output name string = playwrightWorkspace.name
output storageAccountName string = storageAccount.name
