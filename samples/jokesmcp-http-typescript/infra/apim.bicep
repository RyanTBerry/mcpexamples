@description('Name of the existing API Management service')
param apimServiceName string

@description('Base URL of the MCP server, without the /mcp path suffix')
param backendMcpServerBaseUrl string

@description('API path suffix for the MCP API; the gateway endpoint becomes https://<apim>/<path>/mcp')
param mcpApiPath string = 'jokes'

resource apiManagement 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apimServiceName
}

// APIM appends the MCP endpoint path to this backend, so the URL must be the server root.
resource jokesMcpBackend 'Microsoft.ApiManagement/service/backends@2025-09-01-preview' = {
  parent: apiManagement
  name: 'jokes-mcp-backend'
  properties: {
    description: 'Jokes MCP server hosted on Azure Container Apps'
    protocol: 'http'
    url: backendMcpServerBaseUrl
  }
}

resource jokesMcpApi 'Microsoft.ApiManagement/service/apis@2025-09-01-preview' = {
  parent: apiManagement
  name: 'jokes-mcp'
  properties: {
    displayName: 'Jokes MCP Server'
    description: 'Native MCP pass-through API for the Jokes demo server.'
    type: 'mcp'
    path: mcpApiPath
    protocols: [
      'https'
    ]
    subscriptionRequired: false
    backendId: jokesMcpBackend.name
    mcpProperties: {
      transportType: 'streamable'
    }
  }
}

output mcpGatewayUrl string = 'https://${apimServiceName}.azure-api.net/${mcpApiPath}/mcp'
