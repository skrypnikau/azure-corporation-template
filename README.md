# 🏢 Azure Corporation Security Template: 8-Workstation Infrastructure

> **Role:** Security Analyst  
> **Type:** Cloud Security Lab  
> **Platform:** Microsoft Azure  
> **Scenario:** Secure cloud migration of a small incorporation - 8 physical PCs replaced by Azure VMs, on-premises file server replaced by Azure Files.

---

## 🎯 Objective

Design and implement a **segmented, policy-driven cloud environment** that enforces:
- ✅ Least-privilege access per workstation role
- ✅ Centralized traffic control via Azure Firewall (FQDN filtering)
- ✅ Identity-based file storage - no storage account keys
- ✅ Zero exposed RDP ports - Bastion only
- ✅ Full security visibility via Defender for Cloud

---

## 🗺️ Architecture at a Glance

```
                        ┌─────────────────────────────────────────┐
                        │           VNET-CORP-01                  │
                        │                                         │
  Internet ──── [Azure Firewall] ──── snet-admin  (10.10.10.0/24)│
                    (FQDN rules)  │    ├── VM-PC1  [Admin]        │
                        │         │    └── VM-PC2  [Admin]        │
                        │         │                               │
                        │         ├── snet-limited (10.10.20.0/24)│
                        │         │    ├── VM-PC3  [Limited]      │
                        │         │    ├── VM-PC4  [Limited]      │
                        │         │    ├── VM-PC5  [Limited]      │
                        │         │    └── VM-PC6  [Restricted]   │
                        │         │                               │
                        │         └── snet-ops    (10.10.30.0/24) │
                        │              ├── VM-PC7  [Ops]          │
                        │              └── VM-PC8  [Ops]          │
                        │                                         │
  Admin Access ── [Azure Bastion] ─────────────────► All VMs      │
                  (TLS 443 only)  │                               │
                        │         └── [Azure Files] ◄── All VMs  │
                        │              (Kerberos/SMB)             │
                        │                                         │
                        │    [Defender for Cloud + Log Analytics] │
                        └─────────────────────────────────────────┘
```

---

## 👥 VM Roles & Access

| VM | Role | Internet | File Access |
|---|---|---|---|
| VM-PC1 | Admin | Unrestricted | Full (`azfiles-admin`) |
| VM-PC2 | Admin | Unrestricted | Full (`azfiles-admin`) |
| VM-PC3 | Limited | 5 sites only* | Read (`azfiles-shared-ro`) |
| VM-PC4 | Limited | 5 sites only* | Read (`azfiles-shared-ro`) |
| VM-PC5 | Limited | 5 sites only* | Read (`azfiles-shared-ro`) |
| VM-PC6 | Highly Restricted | ❌ None | Read (`azfiles-shared-ro`) |
| VM-PC7 | Ops | Full except `ai.com` | Modify (`azfiles-ops-work`) |
| VM-PC8 | Ops | Full except `ai.com` | Modify (`azfiles-ops-work`) |

*Permitted sites for VM-PC3–5: `youtube.com`, `study.com`, `gmail.com`, `outlook.com`, `pizza.com`

> All access enforced at the **network layer** via Azure Firewall + NSG. Application-level bypass is not possible.

---

## 🔒 Security Controls

| Control | Implementation |
|---|---|
| No public RDP | Azure Bastion — RDP/SSH over TLS 443 only |
| Network segmentation | 6 subnets + Azure Firewall east-west rules |
| Internet filtering | FQDN application rules per VM group |
| Storage security | Kerberos/SMB auth + NTFS ACLs (two layers) |
| Admin isolation | VM-PC1 ↔ VM-PC2 blocked at Firewall + NSG + Windows Firewall |
| Threat detection | Microsoft Defender for Cloud + Log Analytics |

---

## 📁 Repository Structure

```
azure-corporation-template/
│
├── 📄 README.md                          ← You are here
│
├── 📂 architecture/
│   ├── overview.md                       ← Components & threat model
│   └── network-topology.md              ← VNet, subnets, CIDR table
│
├── 📂 access-control/
│   ├── access-matrix.md                  ← VM → Role → Access table
│   ├── identity-groups.md               ← Entra ID groups (GRP-*)
│   └── azure-files-permissions.md       ← Shares + NTFS ACL model
│
├── 📂 firewall-policy/
│   ├── rule-collection-groups.md        ← Priority structure 100–400
│   ├── admin-rules.md                   ← VM-PC1, VM-PC2
│   ├── limited-rules.md                 ← VM-PC3–6
│   └── ops-rules.md                     ← VM-PC7–8
│
├── 📂 nsg/
│   └── nsg-rules.md                     ← NSG per subnet
│
├── 📂 deployment/
│   ├── deployment-order.md              ← 6-phase deployment + why order matters
│   └── validation-checklist.md         ← Test cases post-deployment
│
└── 📂 monitoring/
    └── defender-sentinel-setup.md      ← Defender for Cloud + Sentinel
```

---

## ⚡ Deployment Order (TL;DR)

```
Phase 1 → Foundation        (Resource Group, Log Analytics, VNet, Defender)
Phase 2 → Perimeter         (Firewall + Policy + UDRs — BEFORE any VM)
Phase 3 → Secure Access     (Bastion)
Phase 4 → Identity/Storage  (Entra ID groups + Azure Files + ACLs)
Phase 5 → VMs               (Deploy with no public IPs, apply NSGs)
Phase 6 → Monitor/Validate  (Defender for Servers, test all cases)
```

> See [`deployment/deployment-order.md`](./deployment/deployment-order.md) for full detail and misconfiguration warnings.

---

## 🛠️ Tech Stack

![Azure](https://img.shields.io/badge/Azure-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Windows](https://img.shields.io/badge/Windows_VM-0078D4?style=flat&logo=windows&logoColor=white)
![Defender](https://img.shields.io/badge/Defender_for_Cloud-00B4D8?style=flat&logo=microsoft&logoColor=white)


---

## 🔍 Security Review

This lab includes a post-design vulnerability assessment — identifying weaknesses 
in the architecture before production deployment.

| | |
|---|---|
| 🔴 Critical CVEs | 2 (CVE-2025-49752, CVE-2025-58726) |
| 🟠 High findings | 2 |
| 🟡 Medium findings | 4 |

→ See [`security-review/vulnerabilities-and-mitigations.md`](./security-review/vulnerabilities-and-mitigations.md)
