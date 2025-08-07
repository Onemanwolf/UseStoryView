@description('Application Gateway for VM to Container Apps TCP forwarding')
param location string = resourceGroup().location
param projectName string = 'tcp-proxy'
param environmentName string = 'prod'
param containerAppFQDN string
param virtualNetworkName string
param subnetAddressPrefix string = '10.0.2.0/24'

// Variables
var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().id, location))
var tags = {
  'azd-env-name': environmentName
  project: projectName
}

// Application Gateway Public IP
resource appGatewayPublicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${projectName}-appgw-ip-${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: '${projectName}-appgw-${resourceToken}'
    }
  }
}

// Application Gateway Subnet
resource appGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  name: '${virtualNetworkName}/appgateway-subnet'
  properties: {
    addressPrefix: subnetAddressPrefix
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

// Application Gateway
resource applicationGateway 'Microsoft.Network/applicationGateways@2023-09-01' = {
  name: '${projectName}-appgw-${resourceToken}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 1
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: appGatewaySubnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: appGatewayPublicIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_8080'
        properties: {
          port: 8080
        }
      }
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'container-apps-backend'
        properties: {
          backendAddresses: [
            {
              fqdn: containerAppFQDN
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'tcp-proxy-http-settings'
        properties: {
          port: 8080
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 30
          probe: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/probes',
              '${projectName}-appgw-${resourceToken}',
              'tcp-proxy-health-probe'
            )
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'tcp-proxy-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              '${projectName}-appgw-${resourceToken}',
              'appGwPublicFrontendIp'
            )
          }
          frontendPort: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendPorts',
              '${projectName}-appgw-${resourceToken}',
              'port_8080'
            )
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'tcp-proxy-routing-rule'
        properties: {
          ruleType: 'Basic'
          priority: 1
          httpListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              '${projectName}-appgw-${resourceToken}',
              'tcp-proxy-listener'
            )
          }
          backendAddressPool: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendAddressPools',
              '${projectName}-appgw-${resourceToken}',
              'container-apps-backend'
            )
          }
          backendHttpSettings: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
              '${projectName}-appgw-${resourceToken}',
              'tcp-proxy-http-settings'
            )
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcp-proxy-health-probe'
        properties: {
          protocol: 'Http'
          host: containerAppFQDN
          path: '/health'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {
            statusCodes: [
              '200'
            ]
          }
        }
      }
    ]
    enableHttp2: false
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 10
    }
  }
}

// Network Security Group for Application Gateway
resource appGwNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: '${projectName}-appgw-nsg-${resourceToken}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowGatewayManager'
        properties: {
          description: 'Allow Gateway Manager'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTPInbound'
        properties: {
          description: 'Allow HTTP traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAzureLoadBalancer'
        properties: {
          description: 'Allow Azure Load Balancer'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Outputs
output applicationGatewayPublicIP string = appGatewayPublicIP.properties.ipAddress
output applicationGatewayFQDN string = appGatewayPublicIP.properties.dnsSettings.fqdn
output applicationGatewayResourceId string = applicationGateway.id
output appGatewaySubnetId string = appGatewaySubnet.id
output appGwNetworkSecurityGroupId string = appGwNetworkSecurityGroup.id
