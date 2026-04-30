# Access Matrix

| VM | Role | Internet | Internal Access |
|---|---|---|---|
| VM-PC1 | Admin | Unrestricted | All resources except VM-PC2 |
| VM-PC2 | Admin | Unrestricted | All resources except VM-PC1 |
| VM-PC3 | Limited | `youtube.com`, `study.com`, `gmail.com`, `outlook.com`, `pizza.com` | Azure Files (read-only) |
| VM-PC4 | Limited | Same as VM-PC3 | Azure Files (read-only) |
| VM-PC5 | Limited | Same as VM-PC3 | Azure Files (read-only) |
| VM-PC6 | Highly Restricted | None | Azure Files (read-only) + internal only |
| VM-PC7 | Ops | Full except `ai.com` | VM-PC3–8, working files |
| VM-PC8 | Ops | Full except `ai.com` | VM-PC3–8, working files |

> All policy is enforced at the **network layer** — not the application layer.
