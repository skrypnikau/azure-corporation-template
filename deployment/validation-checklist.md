# Validation Checklist

## Network Access
- [ ] VM-PC1 can reach all resources but **not** VM-PC2 (blocked by ASG)
- [ ] VM-PC2 can reach all resources but **not** VM-PC1 (blocked by ASG)
- [ ] VM-PC3–5 can only reach Azure Files (via Private Endpoint) and the 5 permitted websites
- [ ] VM-PC3–5 cannot reach each other (blocked by ASG/NSG)
- [ ] VM-PC6 has no external internet access
- [ ] VM-PC7–8 cannot reach `ai.com` (verified by App Deny rule); all other internet access works

## Storage Access
- [ ] `GRP-LIMITED-A` / `GRP-LIMITED-B` can read from `azfiles-shared-ro` only
- [ ] `GRP-OPS` can modify/delete in `azfiles-ops-work`
- [ ] `GRP-ADMIN-VM` has full access to `azfiles-admin`
- [ ] Storage Account cannot be accessed via Public Network / Internet (returns 403 Forbidden)
- [ ] `nslookup [storage-account].file.core.windows.net` resolves to a 10.10.40.X private IP

## Secure Access
- [ ] RDP to any VM works **only** via Azure Bastion
- [ ] No VM has a public IP assigned
- [ ] Direct RDP port 3389 is not reachable from internet on any VM

## Monitoring
- [ ] Azure Firewall logs appear in Log Analytics Workspace
- [ ] Defender for Cloud shows no critical unresolved recommendations
