# Firewall Policy — Rule Collection Groups

## Structure

| Priority | Group | Applies To |
|---|---|---|
| 100 | `100-Global` | DNS, NTP, Azure platform services |
| 200 | `200-Admin` | VM-PC1, VM-PC2 |
| 300 | `300-Limited` | VM-PC3, VM-PC4, VM-PC5, VM-PC6 |
| 400 | `400-Ops` | VM-PC7, VM-PC8 |

Rules are processed in priority order. Lower number = higher priority.  
See individual files for rules per group.
