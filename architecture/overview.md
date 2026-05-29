# Architecture Overview

## Core Components

| Component | Role |
|---|---|
| `VM-PC1 … VM-PC8` | Windows VMs replacing physical workstations |
| `Azure Files` | Shared cloud storage replacing on-premises file server |
| `Azure Firewall` | Centralized outbound + east-west traffic control |
| `Azure Bastion` | Secure RDP/SSH over TLS 443 — no public VM ports |
| `Microsoft Defender for Cloud` | Posture management and threat detection |
| `Azure Virtual Desktop` *(optional)* | Full desktop delivery for end users |

## Threat Model

| Risk | Mitigation |
|---|---|
| Exposed RDP on public IPs | Azure Bastion only |
| Lateral movement across VMs | Subnet segmentation + NSGs + Application Security Groups (ASGs) |
| Unrestricted internet access | FQDN application rules per VM group (processed post-Network rules) |
| Storage key abuse / Exfiltration | Identity-based auth (Entra ID Kerberos) + NTFS ACLs + Azure Private Endpoints |
| No threat visibility | Defender for Cloud + Log Analytics |
| Admin-to-admin lateral movement | ASGs isolating VM-PC1 and VM-PC2 at the Azure network fabric layer |
