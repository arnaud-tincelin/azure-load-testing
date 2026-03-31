param name string
param location string
param tags object = {}

resource loadTesting 'Microsoft.LoadTestService/loadTests@2022-12-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

output id string = loadTesting.id
output name string = loadTesting.name
