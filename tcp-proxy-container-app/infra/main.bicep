@description('Primary location for all resources')
param location string = resourceGroup().location

@description('Name of the project')
param projectName string = 'tcp-proxy'

@description('Environment name (dev, test, prod)')
param environmentName string = 'dev'

@description('Web API endpoint URL')
@secure()
param webApiEndpoint string

@description('Web API authentication token')
@secure()
param webApiAuthToken string = ''

@description('Maximum number of concurrent connections')
param maxConnections int = 1000

@description('Connection timeout in seconds')
param connectionTimeout int = 30

@description('Container image')
param containerImage string

// Variables
var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().id, location))
var tags = {
  'azd-env-name': environmentName
  project: projectName
}

// Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: '${projectName}${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${projectName}-logs-${resourceToken}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${projectName}-insights-${resourceToken}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

// Virtual Network for Container Apps
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: '${projectName}-vnet-${resourceToken}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'container-apps-subnet'
        properties: {
          addressPrefix: '10.0.0.0/23'
        }
      }
    ]
  }
}

// User Assigned Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${projectName}-identity-${resourceToken}'
  location: location
  tags: tags
}

// Role assignment for Container Registry
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, managedIdentity.id, 'acrpull')
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    ) // AcrPull
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Container Apps Environment
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: '${projectName}-env-${resourceToken}'
  location: location
  tags: tags
  properties: {
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
      {
        name: 'D4'
        workloadProfileType: 'D4'
        minimumCount: 0
        maximumCount: 10
      }
    ]
    vnetConfiguration: {
      infrastructureSubnetId: vnet.properties.subnets[0].id
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// Container App
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: '${projectName}-app-${resourceToken}'
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    workloadProfileName: 'D4'
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'tcp'
        allowInsecure: false
        corsPolicy: {
          allowedOrigins: ['*']
          allowedMethods: ['*']
          allowedHeaders: ['*']
        }
        additionalPortMappings: [
          {
            external: false
            targetPort: 9090
            exposedPort: 9090
          }
        ]
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentity.id
        }
      ]
      secrets: [
        {
          name: 'web-api-endpoint'
          value: webApiEndpoint
        }
        {
          name: 'web-api-auth-token'
          value: webApiAuthToken
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'tcp-proxy'
          image: containerImage
          env: [
            {
              name: 'TCP_PORT'
              value: '8080'
            }
            {
              name: 'METRICS_PORT'
              value: '9090'
            }
            {
              name: 'WEB_API_ENDPOINT'
              secretRef: 'web-api-endpoint'
            }
            {
              name: 'WEB_API_AUTH_TOKEN'
              secretRef: 'web-api-auth-token'
            }
            {
              name: 'MAX_CONNECTIONS'
              value: string(maxConnections)
            }
            {
              name: 'CONNECTION_TIMEOUT'
              value: string(connectionTimeout)
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationInsights.properties.ConnectionString
            }
          ]
          resources: {
            cpu: json('1.0')
            memory: '2.0Gi'
          }
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 9090
              }
              initialDelaySeconds: 30
              periodSeconds: 10
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/ready'
                port: 9090
              }
              initialDelaySeconds: 5
              periodSeconds: 5
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 50
        rules: [
          {
            name: 'tcp-connections'
            tcp: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
          {
            name: 'http-requests'
            http: {
              metadata: {
                concurrentRequests: '100'
              }
            }
          }
          {
            name: 'cpu-scaling'
            custom: {
              type: 'cpu'
              metadata: {
                type: 'Utilization'
                value: '70'
              }
            }
          }
          {
            name: 'memory-scaling'
            custom: {
              type: 'memory'
              metadata: {
                type: 'Utilization'
                value: '80'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    acrPullRole
  ]
}

// Outputs
output containerRegistryLoginServer string = containerRegistry.properties.loginServer
output containerAppFQDN string = containerApp.properties.configuration.ingress.fqdn
output containerAppURL string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString
output resourceGroupName string = resourceGroup().name
output containerRegistryName string = containerRegistry.name
output containerAppName string = containerApp.name
output managedIdentityClientId string = managedIdentity.properties.clientId
