/*
==================================================================================
Azure Infrastructure-as-Code (IaC) - Corporate Network & Security Baseline
Author: Yauheni Skrypnikau
Description: Hardened Enterprise Azure Architecture with VNet Segmentation, 
             strict Network Security Groups (NSGs), User Defined Routes (UDRs), 
             Azure Bastion secure ingress, and Azure Firewall egress filtration.
==================================================================================
*/

@description('The location where all resources will be deployed.')
param location string = resourceGroup().location

@description('Corporate Virtual Network IP Prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('IP Addresses for each subnet segment')
param workloadSubnetPrefix string = '10.0.1.0/24'
param databaseSubnetPrefix string = '10.0.2.0/24'
param bastionSubnetPrefix string = '10.0.3.0/26'
param firewallSubnetPrefix string = '10.0.4.0/26'

// ===============================================================================
// NETWORK SECURITY GROUPS (NSGs) - Strict Access Control Policies
// ===============================================================================

// NSG for Workload Segment (Web/App Tier)
resource workloadNSG 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-corp-workload'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP-Inbound'
        properties: {
          description: 'Allow web traffic to workload segment'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-HTTPS-Inbound'
        properties: {
          description: 'Allow secure web traffic to workload segment'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Block-Direct-Management-Inbound'
        properties: {
          description: 'Explicitly deny direct internet management access (RDP/SSH)'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 120
          direction: 'Inbound'
        }
      }
    ]
  }
}

// NSG for Database Segment (Data Tier - Tight Isolation)
resource databaseNSG 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-corp-database'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-SQL-From-Workload'
        properties: {
          description: 'Restrict database access strictly to workload application layer'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: workloadSubnetPrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Deny-All-Inbound-Default'
        properties: {
          description: 'Block all other traffic entering database subnet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 999
          direction: 'Inbound'
        }
      }
      {
        name: 'Deny-Direct-Internet-Outbound'
        properties: {
          description: 'Prevent database nodes from accessing the internet directly to prevent exfiltration'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Deny'
          priority: 100
          direction: 'Outbound'
        }
      }
    ]
  }
}

// ===============================================================================
// ROUTE TABLES (UDR) - Force Tunneling through Firewall
// ===============================================================================

resource routeTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: 'rt-corp-spoke-egress'
  location: location
  properties: {
    routes: [
      {
        name: 'route-to-egress-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.0.4.4' // Static internal IP assigned to Azure Firewall
        }
      }
    ]
  }
}

// ===============================================================================
// VIRTUAL NETWORK & SUBNET SEGMENTATION
// ===============================================================================

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-corp-prod'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-workload-prod'
        properties: {
          addressPrefix: workloadSubnetPrefix
          networkSecurityGroup: {
            id: workloadNSG.id
          }
          routeTable: {
            id: routeTable.id
          }
        }
      }
      {
        name: 'snet-database-prod'
        properties: {
          addressPrefix: databaseSubnetPrefix
          networkSecurityGroup: {
            id: databaseNSG.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet' // Required naming convention for Azure Bastion
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
      {
        name: 'AzureFirewallSubnet' // Required naming convention for Azure Firewall
        properties: {
          addressPrefix: firewallSubnetPrefix
        }
      }
    ]
  }
}

// ===============================================================================
// SECURE INGRESS (Azure Bastion Host)
// ===============================================================================

resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-bastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2023-09-01' = {
  name: 'bas-corp-ingress'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: bastionPublicIP.id
          }
        }
      }
    ]
  }
}

// ===============================================================================
// SECURE EGRESS (Azure Firewall)
// ===============================================================================

resource firewallPublicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-firewall'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource azureFirewall 'Microsoft.Network/azureFirewalls@2023-09-01' = {
  name: 'fw-corp-egress'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'AzureFirewallSubnet')
          }
          publicIPAddress: {
            id: firewallPublicIP.id
          }
        }
      }
    ]
    applicationRuleCollections: [
      {
        name: 'Allow-Core-Updates'
        properties: {
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'Allow-Microsoft-Updates'
              sourceAddresses: [
                workloadSubnetPrefix
              ]
              protocols: [
                {
                  port: 443
                  protocolType: 'Https'
                }
              ]
              targetFqdns: [
                '*.microsoft.com'
                '*.windowsupdate.com'
              ]
            }
            {
              name: 'Allow-GitHub-Detections'
              sourceAddresses: [
                workloadSubnetPrefix
              ]
              protocols: [
                {
                  port: 443
                  protocolType: 'Https'
                }
              ]
              targetFqdns: [
                'github.com'
                '*.githubusercontent.com'
              ]
            }
          ]
        }
      }
    ]
  }
}

// ===============================================================================
// TEMPLATE OUTPUTS
// ===============================================================================
output vnetId string = virtualNetwork.id
output bastionPublicIP string = bastionPublicIP.properties.ipAddress
output firewallPublicIP string = firewallPublicIP.properties.ipAddress
