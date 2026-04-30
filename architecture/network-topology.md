# Network Topology

**Virtual Network:** `VNET-CORP-01`

| Subnet | CIDR | Hosts |
|---|---|---|
| `snet-admin` | 10.10.10.0/24 | VM-PC1, VM-PC2 |
| `snet-limited` | 10.10.20.0/24 | VM-PC3, VM-PC4, VM-PC5, VM-PC6 |
| `snet-ops` | 10.10.30.0/24 | VM-PC7, VM-PC8 |
| `snet-storage` | 10.10.40.0/24 | Azure Storage Private Endpoints |
| `AzureFirewallSubnet` | 10.10.100.0/24 | Azure Firewall |
| `AzureBastionSubnet` | 10.10.101.0/26 | Azure Bastion |
| `snet-management` | 10.10.110.0/24 | Management / jump host |

All outbound internet traffic from workload subnets (`snet-admin`, `snet-limited`, `snet-ops`) is routed through Azure Firewall via User Defined Routes (UDR): `0.0.0.0/0` → Firewall private IP.
> **⚠️ CRITICAL:** Do *not* apply this UDR to `AzureBastionSubnet` or `AzureFirewallSubnet`, as this will create asymmetric routing and immediately break those services.
