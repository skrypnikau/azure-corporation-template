# Admin Rules — VM-PC1 & VM-PC2 (Group 200)

## Allow Rules
- All outbound internet (Network Rule)
- Management endpoints, internal subnets

## Deny Rules
- East-west traffic between VM-PC1 ↔ VM-PC2

> **Architectural Note:** 
> Azure Firewall does *not* see intra-subnet traffic. This deny is enforced exclusively at two layers:
> 1. Application Security Group (ASG) rules attached to `snet-admin`
> 2. Windows Defender Firewall on each host
