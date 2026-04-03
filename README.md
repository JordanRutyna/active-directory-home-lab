# Active Directory Home Lab

A fully functional Windows Server 2022 Active Directory environment built in VirtualBox, simulating a real enterprise IT infrastructure. This lab was built to develop and demonstrate hands-on skills in domain administration, Group Policy management, user account management, and IT security hardening — core competencies for IT support and desktop support roles.

---

## Lab Overview

| Component | Details |
|---|---|
| Hypervisor | VirtualBox (macOS host) |
| Domain Controller | Windows Server 2022 — `DC01` |
| Domain Name | `corp.local` |
| DC IP Address | `192.168.10.10` (static) |
| Network | Internal NAT — `192.168.10.0/24` |
| Client VMs | Windows 10 (Phase 2) |

---

## Network Topology

```
[macOS Host — VirtualBox]
        |
        |— NAT Adapter (internet access)
        |
        |— Internal Network: corp-net (192.168.10.0/24)
               |
               |— DC01 (Windows Server 2022)
               |    IP: 192.168.10.10
               |    Roles: AD DS, DNS
               |
               |— CLIENT01 (Windows 10)         [Phase 2]
               |    IP: 192.168.10.20
               |
               |— CLIENT02 (Windows 10)         [Phase 2]
                    IP: 192.168.10.21
```

---

## Phase 1 — Domain Controller Setup (Complete)

### What was built
- Deployed Windows Server 2022 in VirtualBox with dual network adapters (NAT + Internal)
- Assigned static IP `192.168.10.10` on the internal adapter
- Installed and configured Active Directory Domain Services (AD DS) and DNS Server roles
- Promoted the server to a Domain Controller for the new forest `corp.local`

### Organizational Unit Structure

```
corp.local
├── IT_Department
├── HR_Department
├── Workstations
└── Servers
```

### User Accounts Created

| Username | OU | Role |
|---|---|---|
| jsmith | IT_Department | Standard user |
| alee | IT_Department | Standard user |
| bwilson | HR_Department | Standard user |
| jrutyna-admin | IT_Department | Domain Admin |

### Group Policy — Security Baseline GPO

Applied at the domain level (`corp.local`). Configured the following Account Policies:

| Policy | Setting |
|---|---|
| Minimum password length | 10 characters |
| Maximum password age | 90 days |
| Account lockout threshold | 5 invalid attempts |

---

## Phase 2 — Client Machines & Helpdesk Scenarios (In Progress)

- [ ] Deploy Windows 10 VM (`CLIENT01`) and join to `corp.local`
- [ ] Deploy second Windows 10 VM (`CLIENT02`) — optional
- [ ] Simulate helpdesk tickets (password resets, account lockouts, permission issues, new user onboarding)
- [ ] Configure Remote Desktop and test remote support workflow
- [ ] Document runbook for common helpdesk tasks

---

## Phase 3 — Security & Automation (Planned)

- [ ] Add Kali Linux VM for basic security testing
- [ ] Configure PowerShell remoting across the domain
- [ ] Write PowerShell scripts for bulk user creation and account auditing (see `/scripts`)
- [ ] Harden DNS settings and review event logs for suspicious activity
- [ ] Implement additional GPOs (drive mapping, software restriction, wallpaper enforcement)

---

## Scripts

PowerShell automation scripts will be added to the `/scripts` folder in Phase 2 and 3. Planned scripts:

- `New-BulkUsers.ps1` — Create multiple AD users from a CSV file
- `Get-LockedAccounts.ps1` — Audit and report locked user accounts
- `Reset-UserPassword.ps1` — Safely reset a domain user's password
- `Get-SystemHealthReport.ps1` — Generate a basic system health report

---

## Skills Demonstrated

- Windows Server 2022 installation and configuration
- Active Directory Domain Services (AD DS) setup and administration
- DNS Server configuration
- Organizational Unit (OU) design and user account management
- Group Policy Object (GPO) creation and application
- Network adapter configuration and static IP assignment
- Virtual machine provisioning and network isolation (VirtualBox)
- IT security fundamentals — password policy, account lockout, least privilege

---

## Certifications & Context

This lab was built to complement preparation for IT support roles and supports skills covered in:
- **CompTIA Security+** (SY0-701) — earned May 2025
- **CompTIA Network+** (N10-009) — in progress

---

*This lab is actively being expanded. See phases above for upcoming additions.*
