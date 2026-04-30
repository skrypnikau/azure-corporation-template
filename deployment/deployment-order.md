# Deployment Order — Avoiding Misconfiguration

## Phase 1 — Foundation
1. Create Resource Group: `RG-CORP-DESKTOPS`
2. Create Log Analytics Workspace *(must exist before Firewall and Defender are configured)*
3. Create Virtual Network `VNET-CORP-01` with all subnets (`snet-storage` included)
4. Enable Microsoft Defender for Cloud at subscription level
5. **Create NSGs and ASGs**, then bind NSGs to `snet-admin`, `snet-limited`, `snet-ops`, and `AzureBastionSubnet` before any VMs exist.

## Phase 2 — Perimeter Security
6. Deploy Azure Firewall into `AzureFirewallSubnet`
7. Create Firewall Policy → attach to Firewall (configure DNS Proxy for Private Endpoints)
8. Create Rule Collection Groups (Deny Collections *before* Allow Collections)
9. Enable Firewall diagnostic logs → Log Analytics Workspace
10. Create UDRs: `0.0.0.0/0` → Firewall private IP → associate to workload subnets only (`snet-admin`, `snet-limited`, `snet-ops`).
    > ⚠️ Do not associate to `AzureBastionSubnet` or `AzureFirewallSubnet`.

## Phase 3 — Secure Access
11. Deploy Azure Bastion into `AzureBastionSubnet`
12. Verify Bastion connectivity before deploying VMs

## Phase 4 — Identity & Storage
13. Create groups in Entra ID: `GRP-ADMIN-VM`, `GRP-LIMITED-A`, `GRP-LIMITED-B`, `GRP-OPS`
14. Create Storage Account → disable Public Network Access.
15. Create Private Endpoint for Azure Files in `snet-storage` and link to Azure Private DNS Zone (`privatelink.file.core.windows.net`).
16. Run PowerShell `Set-AzureStorageAccount -ActiveDirectoryProperties` to enable Entra ID Kerberos.
17. Create file shares and assign share-level permissions to groups.
18. Configure NTFS ACLs on directories and files.

## Phase 5 — VM Deployment
19. Deploy VM-PC1–2 → `snet-admin` (no public IPs), attach to `ASG-VM-PC1` / `ASG-VM-PC2`.
20. Deploy VM-PC3–6 → `snet-limited` (no public IPs).
21. Deploy VM-PC7–8 → `snet-ops` (no public IPs).
22. Enable and configure Windows Defender Firewall on each VM.
23. Run client-side registry scripts to enable Entra ID Kerberos for Azure Files.

## Phase 6 — Monitoring & Validation
24. Connect all VMs to Defender for Cloud
25. Enable Defender for Servers
26. Configure Sentinel integration if required
27. Run all validation test cases
