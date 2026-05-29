# Known Vulnerabilities & Mitigations

> This document reflects a security analyst's review of the lab architecture.  
> Identifying weaknesses in your own designs is a core part of the security engineering process.  
> All CVEs listed were active at the time of this lab's design.

---

## 🔴 Critical — Active CVEs

### CVE-2025-49752 — Azure Bastion Elevation of Privilege
| Field | Details |
|---|---|
| **CVSS Score** | 10.0 (Critical) |
| **Type** | Authentication Bypass (CWE-294) — Capture-Replay |
| **Affected** | Azure Bastion (all versions prior to Nov 20, 2025) |
| **Attack Vector** | Network — no local access required |
| **Impact** | Full privilege escalation to administrative level on all proxied VMs |

**Why it affects this lab:**  
This lab relies on Azure Bastion as the **sole administrative access point** for all 8 VMs.
A successful exploit against Bastion does not just compromise one VM — it provides 
administrative access to the entire environment in a single network request.

**Mitigations:**
- Confirm Bastion is running the post-Nov 20 2025 patched build (Microsoft patches managed services automatically — verify in the Azure portal under Bastion > Overview)
- Enable **Conditional Access** + **MFA** for all accounts with Bastion access
- Restrict which identities can use Bastion via **Azure RBAC** (role: `Bastion Reader` vs `Bastion Contributor`)
- Monitor Bastion access logs in Log Analytics for replay patterns or unusual authentication attempts
- Enumerate all Bastion deployments and confirm no misconfigured NSGs expose the management plane

**References:** [NVD](https://nvd.nist.gov/vuln/detail/CVE-2025-49752) · [MSRC](https://msrc.microsoft.com/update-guide/vulnerability/CVE-2025-49752)

---

### CVE-2025-58726 — Kerberos Reflection / Ghost SPN — SMB Privilege Escalation
| Field | Details |
|---|---|
| **CVSS Score** | 8.8 (High) |
| **Type** | SMB relay via Ghost SPN + Kerberos reflection |
| **Affected** | Windows hosts using Kerberos/SMB without enforced signing |
| **Attack Vector** | Network (lateral — within same subnet) |
| **Impact** | SYSTEM-level privilege escalation via SMB relay |

**Why it affects this lab:**  
Azure Files uses Kerberos over SMB for identity-based authentication — the exact attack surface.
VM-PC3, VM-PC4, VM-PC5 share `snet-limited`. Peer-to-peer is blocked at the **firewall level**,
but SMB signing enforcement at the **host level** is not explicitly configured in this lab.
A compromised VM-PC3 can relay Kerberos tickets to escalate privileges on VM-PC4 or VM-PC5.

**Mitigations:**  
Apply on all VM-PC1 through VM-PC8 via PowerShell or GPO:
```powershell
# Enforce SMB signing on server side
Set-SmbServerConfiguration -RequireSecuritySignature $true -Force

# Enforce SMB signing on client side
Set-SmbClientConfiguration -RequireSecuritySignature $true -Force
```
- Apply October 2025 Patch Tuesday updates to all VMs
- Validate SMB signing status post-deployment:
```powershell
Get-SmbServerConfiguration | Select RequireSecuritySignature
Get-SmbClientConfiguration | Select RequireSecuritySignature
```

**References:** [Semperis Research](https://www.semperis.com/blog/exploiting-ghost-spns-and-kerberos-reflection-for-smb-server-privilege-elevation/)

---

## 🟠 High — Architectural Weaknesses

### FQDN Filtering DNS Window Bypass
**Issue:**  
Azure Firewall resolves FQDN rules via DNS and caches results for up to **15 minutes**.
During this window, a previously resolved IP remains permitted even if the domain mapping changes.
An attacker on VM-PC3 can use DNS pinning or direct IP access to bypass FQDN-based blocks
within this window — including the `ai.com` block on VM-PC7/8.

**Mitigation:**
- Duplicate critical deny rules as explicit **IP-based network rules** alongside FQDN application rules
- Use **Azure Firewall Premium** with TLS inspection for content-layer enforcement
- Enable **Azure Firewall Threat Intelligence** mode: `Alert and Deny`

---

### Storage Account Keys Not Explicitly Disabled
**Issue:**  
The lab design specifies identity-based access only — but storage account keys are **active by default**
unless explicitly disabled. Any user or process with access to the storage account can use the key
to bypass Kerberos auth and NTFS ACLs entirely.

**Mitigation:**  
Run immediately after storage account creation:
```bash
az storage account update \
  --name <storage-account-name> \
  --resource-group RG-CORP-DESKTOPS \
  --allow-shared-key-access false
```
Verify:
```bash
az storage account show \
  --name <storage-account-name> \
  --query allowSharedKeyAccess
```
Expected output: `false`

---

## 🟡 Medium — Design Gaps

### Single Point of Failure — Azure Bastion
**Issue:**  
Bastion is the only administrative entry point. An outage, misconfiguration, or active exploit
against Bastion means **zero administrative access** to all 8 VMs simultaneously.

**Mitigation:**
- Configure **JIT (Just-in-Time) VM Access** via Defender for Cloud as a break-glass fallback
- Document a break-glass runbook: which account, which method, how to activate
- JIT should be disabled by default and only activatable by a separate privileged identity

---

### No Privileged Identity Management (PIM)
**Issue:**  
VM-PC1 and VM-PC2 admin accounts hold elevated permissions **24/7**.
If either account is compromised (phishing, credential stuffing, session hijack),
the attacker immediately has full administrative access — no time limit, no approval required.

**Mitigation:**
- Enable **Azure PIM (Privileged Identity Management)** for admin roles
- Admin rights are activated on-demand for a fixed duration (e.g., 2 hours) with MFA confirmation
- All activation events are logged and reviewable

---

### No TLS Inspection — Content-Layer Bypass
**Issue:**  
Azure Firewall Standard filters HTTPS traffic by **SNI hostname only** — it does not inspect
payload content. A permitted domain (`youtube.com`, `study.com`) can be used to deliver
malware, exfiltrate data, or tunnel C2 traffic through an allowed FQDN.

**Mitigation:**
- Upgrade to **Azure Firewall Premium** and enable TLS inspection with an internal CA certificate
- Alternatively, deploy **Microsoft Defender for Endpoint** on all VMs for host-level content inspection
- Add **Web Content Filtering** policy in Defender for Endpoint as a compensating control

---

### Ops Group Insider Threat Surface (VM-PC7/8)
**Issue:**  
`GRP-OPS` has broad internet access and visibility into VM-PC3–8.
If an Ops-role user is compromised or malicious, they can observe Limited user activity
and have a wide outbound channel — only `ai.com` is blocked.

**Mitigation:**
- Enable **UEBA (User and Entity Behavior Analytics)** in Microsoft Sentinel for `GRP-OPS`
- Create Sentinel analytics rule: alert on anomalous outbound data volume from `snet-ops`
- Apply **session recording** in Bastion (Bastion Premium tier) for all Ops sessions

---

## Summary Risk Table

| Finding | Severity | CVE / Type | Status in Lab | Priority Fix |
|---|---|---|---|---|
| Azure Bastion auth bypass | 🔴 Critical | CVE-2025-49752 | Not explicitly mitigated | Immediate |
| SMB relay via Kerberos reflection | 🟠 High | CVE-2025-58726 | Not mitigated | High |
| FQDN DNS window bypass | 🟠 High | Design gap | Partial | High |
| Storage account keys active | 🟠 High | Misconfiguration | Not mitigated | High |
| Bastion single point of failure | 🟡 Medium | Design gap | Not mitigated | Medium |
| No PIM for admin accounts | 🟡 Medium | Design gap | Not mitigated | Medium |
| No TLS inspection | 🟡 Medium | Design gap | Not mitigated | Medium |
| Ops insider threat surface | 🟡 Medium | Design gap | Not mitigated | Medium |

---

> **Note:** This lab is a design and documentation exercise.  
> The vulnerabilities listed above are identified as part of a post-design security review —  
> a standard step in any real-world security architecture process.  
> Addressing them in a production deployment would require additional licensing (Firewall Premium, Bastion Premium, PIM) and operational procedures beyond the scope of this lab.
