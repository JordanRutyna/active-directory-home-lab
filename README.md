# Active Directory Home Lab

A fully functional Windows Server 2022 Active Directory environment built in VirtualBox, simulating a real enterprise IT infrastructure. This lab was built to develop and demonstrate hands-on skills in domain administration, Group Policy management, user account management, and IT security hardening — core competencies for IT support and desktop support roles.

---

## Lab Overview

| Component | Details |
|---|---|
| Hypervisor | VirtualBox (macOS host) |
| Domain Controller | Windows Server 2022 — `DC01` |
| Client Machine | Windows 10 Pro — `CLIENT01` |
| Domain Name | `corp.local` |
| DC IP Address | `192.168.10.10` (static) |
| Client IP Address | `192.168.10.20` (static) |
| Network | Internal NAT — `192.168.10.0/24` |

---

## Network Topology

```
[macOS Host - VirtualBox]
        |
        |-- NAT Adapter (internet access for DC01)
        |
        |-- Internal Network: corp-net (192.168.10.0/24)
               |
               |-- DC01 (Windows Server 2022)
               |    IP: 192.168.10.10
               |    Roles: AD DS, DNS
               |
               |-- CLIENT01 (Windows 10 Pro)
               |    IP: 192.168.10.20
               |    Joined to: corp.local
               |
               |-- CLIENT02 (Windows 10)         [Phase 3 - planned]
                    IP: 192.168.10.21
```

---

## Phase 1 - Domain Controller Setup (Complete)

### What was built
- Deployed Windows Server 2022 in VirtualBox with dual network adapters (NAT + Internal)
- Assigned static IP `192.168.10.10` on the internal adapter
- Installed and configured Active Directory Domain Services (AD DS) and DNS Server roles
- Promoted the server to a Domain Controller for the new forest `corp.local`

### Organizational Unit structure

```
corp.local
├── IT_Department
├── HR_Department
├── Workstations
└── Servers
```

### User accounts

| Username | OU | Role |
|---|---|---|
| jsmith | IT_Department | Standard user |
| alee | IT_Department | Standard user |
| bwilson | HR_Department | Standard user |
| jrutyna-admin | IT_Department | Domain Admin |

### Group Policy - Security Baseline GPO

Linked at the domain level (`corp.local`) with link order 1 (highest precedence). Configured the following Account Policies:

| Policy | Setting |
|---|---|
| Minimum password length | 10 characters |
| Maximum password age | 90 days |
| Account lockout threshold | 5 invalid attempts |

> **Troubleshooting note:** Account lockout policies in Active Directory only apply domain-wide when the GPO is set to link order 1 at the domain root. Resolved a precedence conflict by promoting Security Baseline above Default Domain Policy rather than modifying Default Domain Policy directly, which is the correct enterprise approach.

---

## Phase 2 - Client Machine and Helpdesk Scenarios (Complete)

### What was built
- Deployed Windows 10 Pro VM (`CLIENT01`) with a static IP of `192.168.10.20`
- Pointed CLIENT01's DNS to DC01 (`192.168.10.10`) to enable domain resolution
- Successfully joined CLIENT01 to `corp.local` and moved it into the Workstations OU
- Forced Group Policy application using `gpupdate /force` and verified with `gpresult /r`
- Created and managed security groups following role-based access control (RBAC) principles

### Security groups created

| Group | OU | Type | Scope |
|---|---|---|---|
| IT_Staff | IT_Department | Security | Global |
| HR_Staff | HR_Department | Security | Global |
| FileShare_HR | HR_Department | Security | Global |

> Users are never assigned permissions directly. Permissions are assigned to security groups, and users are added to those groups. This mirrors real enterprise access control practices.

### Helpdesk scenarios practised

**Account lockout and unlock**
- Triggered account lockout on `jsmith` by exceeding the 5-attempt threshold from CLIENT01
- Unlocked the account via Active Directory Users and Computers on DC01 (Properties > Account > Unlock)

**Password reset**
- Reset `alee`s password via ADUC with "User must change password at next logon" enforced
- Logged in as `alee` on CLIENT01 and completed the forced password change workflow end-to-end

**New user onboarding**
- Created new user `nhire` in HR_Department with a temporary password
- Added `nhire` to the `HR_Staff` security group
- Logged in as `nhire` on CLIENT01 to verify end-to-end account provisioning

---

## Phase 3 - Security and Automation (In Progress)

### PowerShell automation scripts (Complete)

All scripts are located in the `/scripts` folder. Each script writes a timestamped log file to `C:\scripts\` on DC01.

**`New-BulkUsers.ps1`**
Creates multiple AD user accounts from a CSV file. Handles OU placement, security group assignment, password setting, and forced password change on first logon. Includes duplicate detection and per-user error handling so a single bad row does not abort the entire run.

Sample CSV format:
```csv
FirstName,LastName,Username,Department,OU,Group
Sarah,Connor,sconnor,IT_Department,IT_Department,IT_Staff
Lisa,Park,lpark,HR_Department,HR_Department,HR_Staff
```

**`Get-LockedAccounts.ps1`**
Queries the domain for all currently locked user accounts using `Search-ADAccount -LockedOut`. For each locked account, reports the username, department, bad logon count, last bad password attempt timestamp, and password last set date. Useful as a morning helpdesk audit to catch lockouts before users call in.

**`Get-SystemHealthReport.ps1`**
Collects a health snapshot of DC01 including OS version and uptime, RAM usage with a warning threshold at 85%, disk usage per drive, status of five critical AD services (ADWS, DNS, Netlogon, NTDS, W32Time), and an Active Directory summary showing total, enabled, disabled, and locked user counts alongside total groups and computers.

Sample output from DC01:
```
--- Active Directory Summary ---
Total Users    : 13
Enabled        : 11
Disabled       : 2
Locked Out     : 0
Total Groups   : 51
Total Computers: 2
```
### Additional GPOs (In Progress)
**`Corporate Wallpaper`** GPO (Complete)

- Created a shared folder `C:\Wallpaper` on DC01 and shared it as `\\DC01\Wallpaper` with read access for Domain Users
- Configured the GPO under User Configuration > Policies > Administrative Templates > Desktop > Desktop Wallpaper, pointing to `\\DC01\Wallpaper\wallpaper.jpg`
- Linked at the domain level and verified on CLIENT01 using `gpupdate /force`

### Remaining Phase 3 items (Planned)
- [ ] Corporate wallpaper GPO
- [ ] USB storage restriction GPO
- [ ] Mapped network drive GPO for HR users
- [ ] HR_Share network folder with NTFS and share permissions tied to FileShare_HR group
- [ ] Event log review (Event IDs 4624, 4625, 4740, 5136)

---

## Key troubleshooting performed

| Issue | Cause | Resolution |
|---|---|---|
| GPO not applying to CLIENT01 | Policy not yet pulled after domain join | Ran `gpupdate /force`, verified with `gpresult /r` |
| Account lockout policy not triggering | GPO link order conflict with Default Domain Policy | Promoted Security Baseline to link order 1 at domain root |
| `Get-ADUser` filter error in script | Variables do not expand inside AD filter blocks | Assigned variable to a plain string before passing to `-Filter {}` |
| Bulk users created but disabled | `New-ADUser` creates the account before applying the password, so a complexity failure leaves a disabled account | Fixed with `Set-ADAccountPassword` and `Enable-ADAccount` after correcting the password |

---

## Skills demonstrated

- Windows Server 2022 installation and configuration
- Active Directory Domain Services (AD DS) setup and administration
- DNS Server configuration and domain name resolution
- Organizational Unit (OU) design and user account management
- Security group creation and role-based access control (RBAC)
- Group Policy Object (GPO) creation, linking, and precedence management
- GPO troubleshooting using `gpupdate /force` and `gpresult /r`
- Windows 10 Pro domain join and client configuration
- Helpdesk workflows: account lockout, password reset, new user onboarding
- PowerShell scripting for AD automation, auditing, and system health reporting
- Network adapter configuration and static IP assignment
- Virtual machine provisioning and network isolation (VirtualBox)
- IT security fundamentals: least privilege, password policy, account lockout, RBAC

---

## Certifications and context

This lab was built to complement preparation for IT support roles and supports skills covered in:
- **CompTIA Security+** (SY0-701) — earned May 2025
- **CompTIA Network+** (N10-009) — in progress

---

*This lab is actively being expanded. See Phase 3 above for upcoming additions.*
