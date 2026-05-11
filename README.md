# Active Directory Home Lab

A fully functional Windows Server 2022 Active Directory environment built in VirtualBox, simulating a real enterprise IT infrastructure. This lab was built to develop and demonstrate hands-on skills in domain administration, Group Policy management, PowerShell automation, user account management, and IT security hardening, core competencies for IT support and desktop support roles.

---

## Lab Overview

| Component | Details |
|---|---|
| Hypervisor | VirtualBox (macOS host) |
| Domain Controller | Windows Server 2022 (`DC01`) |
| Client Machine | Windows 10 Pro (`CLIENT01`) |
| Domain Name | `corp.local` |
| DC IP Address | `192.168.10.10` (static) |
| Client IP Address | `192.168.10.20` (static) |
| Network | Internal NAT (`192.168.10.0/24`) |

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
                    IP: 192.168.10.20
                    Joined to: corp.local
```

---

## Phase 1: Domain Controller Setup (Complete)

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

| Username | OU | Role | Created via |
|---|---|---|---|
| jsmith | IT_Department | Standard user | Manual |
| alee | IT_Department | Standard user | Manual |
| bwilson | HR_Department | Standard user | Manual |
| lpark | HR_Department | Standard user | Manual |
| dchen | IT_Department | Standard user | Manual |
| sconnor | HR_Department | Standard user | Bulk (CSV) |
| mtorres | IT_Department | Standard user | Bulk (CSV) |
| tbaker | HR_Department | Standard user | Bulk (CSV) |
| jrutyna-admin | IT_Department | Domain Admin | Manual |

### Group Policy - Security Baseline GPO

Linked at the domain level (`corp.local`) with link order 1 (highest precedence). Configured the following Account Policies:

| Policy | Setting |
|---|---|
| Minimum password length | 10 characters |
| Maximum password age | 90 days |
| Account lockout threshold | 5 invalid attempts |

> **Troubleshooting note:** Account lockout policies in Active Directory only apply domain-wide when the GPO is set to link order 1 at the domain root. Resolved a precedence conflict by promoting Security Baseline above Default Domain Policy rather than modifying Default Domain Policy directly, which is the correct enterprise approach.

---

## Phase 2: Client Machine and Helpdesk Scenarios (Complete)

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
- Unlocked the account via Active Directory Users and Computers (Properties > Account > Unlock)

**Password reset**
- Reset `alee`s password via ADUC with "User must change password at next logon" enforced
- Logged in as `alee` on CLIENT01 and completed the forced password change workflow end-to-end

**New user onboarding**
- Created new user `nhire` in HR_Department with a temporary password
- Added `nhire` to the `HR_Staff` security group
- Logged in as `nhire` on CLIENT01 to verify end-to-end account provisioning

---

## Phase 3: Security, GPOs, and PowerShell Automation (Complete)

### Group Policy Objects

Four GPOs were created and linked across the domain:

| GPO | Linked To | Purpose |
|---|---|---|
| Security Baseline | `corp.local` (link order 1) | Password policy, account lockout |
| Corporate Wallpaper | `corp.local` | Enforces a standard desktop wallpaper |
| USB Storage Restriction | Workstations OU | Blocks USB mass storage device driver |
| HR Mapped Drive | HR_Department OU | Maps `H:` to `\\DC01\HR_Share` at logon |

### Shared folder and NTFS permissions

Created `HR_Share` on DC01 and configured permissions following the principle of least privilege:

| Permission Type | Principal | Access |
|---|---|---|
| Share | FileShare_HR | Change |
| NTFS | FileShare_HR | Modify |

- Verified `H:` drive maps correctly for HR users logged in from CLIENT01
- Confirmed IT users are denied access to `HR_Share` as expected

### PowerShell automation scripts

Three scripts are located in the `/scripts` folder:

**`New-BulkUsers.ps1`**
Creates multiple Active Directory users from a CSV file. Includes duplicate checking before creation and structured error handling to report failed accounts without halting the full import.

**`Get-LockedAccounts.ps1`**
Performs a domain-wide audit of locked user accounts. Returns locked account details and timestamps to support helpdesk triage.

**`Get-SystemHealthReport.ps1`**
Generates a system health summary covering OS information, RAM usage, disk space, critical service status, and a basic Active Directory user and computer count.

### Event log review and auditing

- Reviewed Security event logs on DC01 for Event ID `4740` (account lockout) and `4624` (successful logon)
- Enabled advanced auditing with `auditpol` to capture Event ID `4625` (failed logon) and `5136` (directory service object modification)

All scripts are located in the `/scripts` folder. Each script writes a timestamped log file to `C:\scripts\` on DC01.

## Troubleshooting Log

| Issue | Cause | Resolution |
|---|---|---|
| GPO not applying to CLIENT01 after domain join | Policy not yet pulled by the client | Ran `gpupdate /force`, verified with `gpresult /r` |
| Account lockout policy not triggering | GPO link order conflict with Default Domain Policy | Promoted Security Baseline to link order 1 at domain root |
| `Get-ADUser` filter returning no results | Variable expansion fails inside single-quoted LDAP filter strings | Replaced single-quoted filter with a plain variable reference |
| Bulk-created users left in disabled state | Passwords in CSV did not meet domain complexity requirements | Re-set passwords using `Set-ADAccountPassword` and enabled accounts |
| HR_Share inaccessible immediately after adding user to FileShare_HR | New group membership not reflected in active security token | Required full log off and re-login to obtain updated Kerberos token |
| USB GPO appeared not to block in VirtualBox | VirtualBox passes USB through at the driver level before Windows mounts | Confirmed correct behaviour; the driver-level block prevents mounting as expected |

---

## Skills Demonstrated

- Windows Server 2022 installation and configuration
- Active Directory Domain Services (AD DS) setup and administration
- DNS Server configuration and domain name resolution
- Organizational Unit (OU) design and user account management
- Security group creation and role-based access control (RBAC)
- Group Policy Object (GPO) creation, linking, and precedence management
- GPO troubleshooting using `gpupdate /force` and `gpresult /r`
- Windows 10 Pro domain join and client configuration
- Shared folder creation with layered share and NTFS permissions
- PowerShell scripting for bulk user provisioning and domain auditing
- Windows event log review and audit policy configuration with `auditpol`
- Helpdesk workflows: account lockout, password reset, new user onboarding
- Network adapter configuration and static IP assignment
- Virtual machine provisioning and network isolation in VirtualBox
- IT security fundamentals: least privilege, password policy, account lockout, access control

---

## Certifications and Context

This lab was built to complement preparation for IT support roles and supports skills covered in:

- **CompTIA Security+** (SY0-701), earned May 2025
- **CompTIA Network+** (N10-009), in progress

---

*This lab is complete across all three phases. See the `/scripts` folder for PowerShell automation and the troubleshooting log above for real issues encountered and resolved during the build.*
