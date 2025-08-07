@description('Bicep template for Azure Load Balancer forwarding to Container Apps TCP service')
param location string = resourceGroup().location
param projectName string = 'tcp-proxy'
param environmentName string = 'prod'
param containerAppFQDN string

// Variables
var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().id, location))
var tags = {
  'azd-env-name': environmentName
  project: projectName
}

// Public IP for Load Balancer
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${projectName}-lb-ip-${resourceToken}'
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
      domainNameLabel: '${projectName}-lb-${resourceToken}'
    }
  }
}

// Load Balancer
resource loadBalancer 'Microsoft.Network/loadBalancers@2023-09-01' = {
  name: '${projectName}-lb-${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'frontend-config'
        properties: {
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'container-apps-backend'
        properties: {
          // Note: For Container Apps with external ingress, we'll use Application Gateway instead
          // This is a placeholder - Load Balancer works best with VMs in the same VNet
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'tcp-forwarding-rule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/loadBalancers/frontendIPConfigurations',
              '${projectName}-lb-${resourceToken}',
              'frontend-config'
            )
          }
          backendAddressPool: {
            id: resourceId(
              'Microsoft.Network/loadBalancers/backendAddressPools',
              '${projectName}-lb-${resourceToken}',
              'container-apps-backend'
            )
          }
          protocol: 'Tcp'
          frontendPort: 8080
          backendPort: 8080
          enableFloatingIP: false
          idleTimeoutInMinutes: 15
          loadDistribution: 'Default'
          disableOutboundSnat: false
          probe: {
            id: resourceId(
              'Microsoft.Network/loadBalancers/probes',
              '${projectName}-lb-${resourceToken}',
              'tcp-health-probe'
            )
          }
        }
      }
    ]
    probes: [
      {
        name: 'tcp-health-probe'
        properties: {
          protocol: 'Http'
          port: 9090
          requestPath: '/health'
          intervalInSeconds: 30
          numberOfProbes: 3
        }
      }
    ]
    outboundRules: []
  }
}

// Network Security Group for VM
resource vmNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: '${projectName}-vm-nsg-${resourceToken}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowTCPToLoadBalancer'
        properties: {
          description: 'Allow TCP traffic from VM to Load Balancer'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: publicIP.properties.ipAddress
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowSSHInbound'
        properties: {
          description: 'Allow SSH'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowRDPInbound'
        properties: {
          description: 'Allow RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 210
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Route Table for VM to Load Balancer
resource routeTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: '${projectName}-vm-routes-${resourceToken}'
  location: location
  tags: tags
  properties: {
    routes: [
      {
        name: 'ToLoadBalancer'
        properties: {
          addressPrefix: '${publicIP.properties.ipAddress}/32'
          nextHopType: 'Internet'
        }
      }
    ]
  }
}

// Outputs
output loadBalancerPublicIP string = publicIP.properties.ipAddress
output loadBalancerFQDN string = publicIP.properties.dnsSettings.fqdn
output loadBalancerResourceId string = loadBalancer.id
output vmNetworkSecurityGroupId string = vmNetworkSecurityGroup.id
output routeTableId string = routeTable.id
