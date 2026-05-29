# Limited Rules — VM-PC3–6 (Group 300)

## VM-PC3, VM-PC4, VM-PC5

**Allow:**
- SMB / Kerberos / DNS to Azure Files and identity services
- HTTP/HTTPS to: `youtube.com`, `study.com`, `gmail.com`, `outlook.com`, `pizza.com`

**Deny:**
- All other outbound internet
- Peer-to-peer traffic between VM-PC3, VM-PC4, VM-PC5

## VM-PC6

**Allow:**
- Azure Files share access
- Internal services only

**Deny:**
- All external internet
