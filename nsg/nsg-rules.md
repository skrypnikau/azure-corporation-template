# NSG Rules & Application Security Groups (ASGs)

## Subnet NSGs

| Subnet | Direction | Rule |
|---|---|---|
| `AzureBastionSubnet` | Inbound | Allow 443 from Internet, Allow 443/4443 from GatewayManager |
| `AzureBastionSubnet` | Outbound | Allow 3389/22 to VirtualNetwork, Allow 443 to AzureCloud |
| `snet-admin` | Inbound | Deny all from internet; allow 3389 from `AzureBastionSubnet` |
| `snet-limited` | Inbound | Deny all from internet; deny from `snet-admin` and `snet-ops` |
| `snet-ops` | Inbound | Deny all from internet; allow from `snet-admin` on management ports |
| Workload Subnets | Outbound | Route via Azure Firewall (UDR 0.0.0.0/0 → Firewall private IP) |

> **⚠️ Routing Warning:** UDRs must *not* be applied to `AzureBastionSubnet` or `AzureFirewallSubnet`.

## Application Security Groups (ASGs)

For intra-subnet isolation (which Azure Firewall cannot see), use ASGs attached to the NICs:
- `ASG-VM-PC1` and `ASG-VM-PC2`: NSG rule denying traffic between these two ASGs.
- `ASG-Limited-Tier`: NSG rule denying peer-to-peer traffic within this ASG.

Windows Defender Firewall must remain **enabled** on all VMs as a defense-in-depth measure, but network isolation must rely on ASGs and NSGs.
