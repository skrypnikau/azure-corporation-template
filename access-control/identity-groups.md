# Identity Groups

| Group | Members | Purpose |
|---|---|---|
| `GRP-ADMIN-VM` | VM-PC1, VM-PC2 users | Admin-level access |
| `GRP-LIMITED-A` | VM-PC3, VM-PC4, VM-PC5 users | Restricted internet + read-only files |
| `GRP-LIMITED-B` | VM-PC6 user | No internet, internal resources only |
| `GRP-OPS` | VM-PC7, VM-PC8 users | Ops access + broad internet |

Groups are created in **Azure AD / Entra ID**.  
Share-level permissions and NTFS ACLs are assigned at the group level.
