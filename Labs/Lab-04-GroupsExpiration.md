# Lab 04: Microsoft 365 Group Expiration Policy

**Time:** 45 minutes | **Level:** Intern / Tier 1 | **Script:** `4-GroupsExpiration-Graph.ps1`

## Why this matters

Teams and Microsoft 365 Groups pile up. Old, unused groups clutter the tenant, keep data around longer than needed, and confuse users. An **expiration policy** asks group owners to renew their group every X days. If nobody renews it, the group is soft-deleted and can be restored for 30 days.

## Learning objectives

By the end you can:

1. Explain what a group expiration policy does, in one sentence, to a non-technical user.
2. Connect to Microsoft Graph with the least permission needed.
3. Read the current policy without changing anything.
4. Use `-WhatIf` to preview a change before making it.
5. Renew a single group.

## Before you start

| Need | Check |
|---|---|
| PowerShell 7 | `$PSVersionTable.PSVersion` shows 7.x |
| Graph module | `Get-Module Microsoft.Graph.Groups -ListAvailable` returns a result. If not: `Install-Module Microsoft.Graph -Scope CurrentUser` |
| **Lab/dev tenant** | Never do this lab in a client or production tenant |
| Role | Groups Administrator or Global Administrator in the lab tenant |

> **Rule:** Only one expiration policy can exist per tenant. Changes affect **every** group it covers.

## Steps

### Step 1: Read the current policy (read-only)

```powershell
.\4-GroupsExpiration-Graph.ps1
```

A sign-in window opens. Consent asks only for `Group.Read.All`, which is read-only.

**Expected:** Either a policy (Id, GroupLifetimeInDays, ManagedGroupTypes, AlternateNotificationEmails) or `No group expiration policy is configured in this tenant.`

Write down what you see. You'll compare it at the end.

### Step 2: Preview a change with -WhatIf

```powershell
.\4-GroupsExpiration-Graph.ps1 -Action Set -LifetimeInDays 180 -ManagedGroupTypes All -NotificationEmail 'you@yourlabtenant.onmicrosoft.com' -WhatIf
```

**Expected:** A line starting with `What if: Performing the operation...`. **Nothing changed.** Run Step 1 again to prove it.

### Step 3: Make the change

Run the same command **without** `-WhatIf`. You'll get a confirmation prompt, because the script marks changes as high impact. Type `Y`.

**Expected:** `Policy updated.` or the new policy details. Run Step 1 to verify.

### Step 4: Renew one group

Find a group ID:

```powershell
Get-MgGroup -Filter "groupTypes/any(g:g eq 'Unified')" -Top 5 | Select-Object DisplayName, Id
```

Renew it:

```powershell
.\4-GroupsExpiration-Graph.ps1 -Action Renew -GroupId '<paste-Id-here>'
```

**Expected:** `Group <Id> renewed.`

### Step 5: Clean up

Put the policy back the way you found it in Step 1, using `-Action Set` with the original values. If there was no policy at the start, use `-Action Remove`.

## Check your understanding

1. In plain English, what happens to a group nobody renews?
2. Why does Step 1 ask for `Group.Read.All` but Step 3 asks for `Directory.ReadWrite.All`?
3. What does `-WhatIf` do, and when should you use it?
4. A client says, "My Team disappeared!" What's the first thing you'd check, and how long do you have to restore it?
5. Why does `-Action AddGroup` fail when the policy is set to `All`?

<details>
<summary>Answer key (instructor)</summary>

1. The owners get email reminders. If nobody renews it, the group (and its Team, SharePoint site, mailbox) is soft-deleted and can be restored for 30 days.
2. Least privilege: reading needs less access than changing. Only ask for what the task needs.
3. It shows what *would* happen without changing anything. Use it before any change in a real tenant.
4. Check whether it expired or was deleted (Entra admin center > Groups > Deleted groups). You have 30 days to restore it.
5. `All` already covers every group. Adding single groups only makes sense when the policy is `Selected`.
</details>

## Instructor notes

- Old vs. new: have interns open `4-GroupsExpiration.ps1` (AzureADPreview) side by side with the Graph version. Good talking point: modules get retired, and scripts need maintenance.
- Common snag: consent prompt blocked, which means the lab account lacks the admin role.
- Reference: https://learn.microsoft.com/entra/identity/users/groups-lifecycle
