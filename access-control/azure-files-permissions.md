# Azure Files — Share Layout and Permissions

## Share Layout

| Share | Assigned To | Permissions |
|---|---|---|
| `azfiles-shared-ro` | `GRP-LIMITED-A`, `GRP-LIMITED-B` | Read |
| `azfiles-ops-work` | `GRP-OPS` | Modify / Delete (ACL level) |
| `azfiles-admin` | `GRP-ADMIN-VM` | Full / Administrative |

## Access Control Model

Azure Files enforces **two separate permission layers:**

1. **Share-level permissions** — coarse gatekeeper (assigned to groups in Entra ID)
2. **NTFS ACLs** — granular control at directory and file level

Both layers must be configured. Configuring only one results in either broken or 
overly permissive access.

## Authentication & Networking

- Protocol: **SMB over Kerberos**
- Identity source: **Entra ID Kerberos** (requires `Set-AzureStorageAccount -ActiveDirectoryProperties` and client registry modifications; it's not a single toggle for cloud-only joined VMs).
- Do **not** use storage account keys for access — this bypasses the ACL model entirely.
- **Networking:** Public Network Access must be **Disabled**. All access must route through a **Private Endpoint** deployed in `snet-storage` to prevent data exfiltration.
