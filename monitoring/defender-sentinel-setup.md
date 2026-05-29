# Security Monitoring Setup

## Microsoft Defender for Cloud
1. Enable at subscription level during Phase 1 (before VMs exist)
2. Enable **Defender for Servers** on all VM-PC1–8
3. Review and resolve all security recommendations post-deployment
4. Configure email alerts for high-severity findings

## Log Analytics Workspace
- All Azure Firewall diagnostic logs → Workspace
- All VM security events → Workspace
- Used as the data source for Sentinel (if enabled)

## Microsoft Sentinel *(optional)*
1. Connect Sentinel to the Log Analytics Workspace
2. Enable data connectors: Azure Firewall, Defender for Cloud, Windows Security Events
3. Configure analytics rules for:
   - Failed RDP attempts via Bastion
   - Denied outbound traffic spikes
   - Unusual Azure Files access patterns
4. Create incident response playbooks (Logic Apps) as needed
