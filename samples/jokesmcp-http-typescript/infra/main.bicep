targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param jokesmcpHttpTypescriptExists bool

@description('Id of the user or app to assign application roles')
param principalId string

@description('Resource group containing the existing API Management service')
param apimResourceGroupName string

@description('Name of the existing API Management service')
param apimServiceName string

// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
}

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module resources 'resources.bicep' = {
  scope: rg
  name: 'resources'
  params: {
    location: location
    tags: tags
    principalId: principalId
    jokesmcpHttpTypescriptExists: jokesmcpHttpTypescriptExists
  }
}

module apiManagement 'apim.bicep' = {
  name: 'jokes-mcp-api'
  scope: resourceGroup(apimResourceGroupName)
  params: {
    apimServiceName: apimServiceName
    backendMcpServerBaseUrl: resources.outputs.JOKES_MCP_SERVER_BASE_URL
  }
}

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = resources.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output AZURE_RESOURCE_JOKESMCP_HTTP_TYPESCRIPT_ID string = resources.outputs.AZURE_RESOURCE_JOKESMCP_HTTP_TYPESCRIPT_ID
output JOKES_MCP_BACKEND_URL string = '${resources.outputs.JOKES_MCP_SERVER_BASE_URL}/mcp'
output JOKES_MCP_GATEWAY_URL string = apiManagement.outputs.mcpGatewayUrl
