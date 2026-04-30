# Ops Rules — VM-PC7 & VM-PC8 (Group 400)

## Allow Rules
- Access to VM-PC3–8 on required ports/services (Network Rule)
- Broad outbound internet (Application Rule: `*` FQDN)

## Deny Rules
- `ai.com` — blocked via FQDN application rule in a **Deny Rule Collection**.

> **⚠️ Rule Precedence Warning:** Azure Firewall processes Network Rules *before* Application Rules. If "Broad outbound internet" is created as a Network Rule, the `ai.com` deny rule will be bypassed completely. 
> To function correctly, `ai.com` must be in an Application Deny Collection (processed first), and the broad allow must be an Application Allow Collection (processed second).
