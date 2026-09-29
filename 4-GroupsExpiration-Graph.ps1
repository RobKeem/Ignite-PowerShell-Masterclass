<#
.SYNOPSIS
    View and manage the Microsoft 365 Groups expiration (lifecycle) policy using Microsoft Graph PowerShell.

.DESCRIPTION
    Modernized version of 4-GroupsExpiration.ps1. The original uses the AzureADPreview module,
    which Microsoft has deprecated. This version uses the Microsoft.Graph.Groups module.

    Read-only by default. Every change supports -WhatIf (preview) and -Confirm (prompt).

    Actions:
      Show      - Display the tenant policy (default, read-only)
      Set       - Create the policy if none exists, otherwise update it
      Renew     - Reset the expiration clock on one group
      AddGroup  - Add one group to the policy (policy must be set to 'Selected')
      Remove    - Delete the tenant policy (turns off group expiration)

.PARAMETER Action
    What to do. Defaults to Show.

.PARAMETER LifetimeInDays
    Days before a group expires. Used with -Action Set. Minimum 30.

.PARAMETER ManagedGroupTypes
    All, Selected, or None. Used with -Action Set.

.PARAMETER NotificationEmail
    Where to send notices for groups with no owners. Separate multiple addresses with ';'.

.PARAMETER GroupId
    Object ID of the group. Used with -Action Renew and AddGroup.

.EXAMPLE
    .\4-GroupsExpiration-Graph.ps1
    Shows the current policy. Changes nothing.

.EXAMPLE
    .\4-GroupsExpiration-Graph.ps1 -Action Set -LifetimeInDays 180 -ManagedGroupTypes All -NotificationEmail 'itadmin@contoso.com' -WhatIf
    Previews creating or updating the policy without changing anything.

.EXAMPLE
    .\4-GroupsExpiration-Graph.ps1 -Action Renew -GroupId '00000000-0000-0000-0000-000000000000'
    Renews one group so its expiration clock restarts today.

.NOTES
    Module:      Microsoft.Graph.Groups   (Install-Module Microsoft.Graph -Scope CurrentUser)
    Permission:  Directory.ReadWrite.All  (Group.Read.All is enough for -Action Show)
    Role:        Groups Administrator or Global Administrator
    Docs:        https://learn.microsoft.com/entra/identity/users/groups-lifecycle
    Test in a lab/dev tenant first. Only one lifecycle policy can exist per tenant.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [ValidateSet('Show', 'Set', 'Renew', 'AddGroup', 'Remove')]
    [string]$Action = 'Show',

    [ValidateRange(30, 36500)]
    [int]$LifetimeInDays = 180,

    [ValidateSet('All', 'Selected', 'None')]
    [string]$ManagedGroupTypes = 'All',

    [string]$NotificationEmail,

    [string]$GroupId
)

# --- Step 1: Check inputs before signing in ---
if ($Action -in 'Renew', 'AddGroup' -and -not $GroupId) {
    throw "-GroupId is required for -Action $Action. Find it with: Get-MgGroup -Filter ""displayName eq 'Name'"""
}
if ($Action -eq 'Set' -and -not $NotificationEmail) {
    throw '-NotificationEmail is required for -Action Set.'
}

# --- Step 2: Connect with only the permission this action needs (least privilege) ---
$scope = if ($Action -eq 'Show') { 'Group.Read.All' } else { 'Directory.ReadWrite.All' }
Import-Module Microsoft.Graph.Groups -ErrorAction Stop
Connect-MgGraph -Scopes $scope -NoWelcome -ErrorAction Stop

# --- Step 3: Look up the current policy (a tenant has zero or one) ---
$policy = Get-MgGroupLifecyclePolicy | Select-Object -First 1

switch ($Action) {

    'Show' {
        if ($policy) {
            $policy | Format-List Id, GroupLifetimeInDays, ManagedGroupTypes, AlternateNotificationEmails
        }
        else {
            Write-Output 'No group expiration policy is configured in this tenant.'
        }
    }

    'Set' {
        $settings = @{
            GroupLifetimeInDays         = $LifetimeInDays
            ManagedGroupTypes           = $ManagedGroupTypes
            AlternateNotificationEmails = $NotificationEmail
        }
        if ($policy) {
            if ($PSCmdlet.ShouldProcess("Policy $($policy.Id)", "Update to $LifetimeInDays days, $ManagedGroupTypes groups")) {
                Update-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $policy.Id @settings
                Write-Output 'Policy updated.'
            }
        }
        elseif ($PSCmdlet.ShouldProcess('Tenant', "Create policy: $LifetimeInDays days, $ManagedGroupTypes groups")) {
            New-MgGroupLifecyclePolicy @settings | Format-List Id, GroupLifetimeInDays, ManagedGroupTypes
        }
    }

    'Renew' {
        if ($PSCmdlet.ShouldProcess("Group $GroupId", 'Renew (restart expiration clock)')) {
            Invoke-MgRenewGroup -GroupId $GroupId
            Write-Output "Group $GroupId renewed."
        }
    }

    'AddGroup' {
        if (-not $policy) { throw 'No policy exists. Run -Action Set first.' }
        if ($policy.ManagedGroupTypes -ne 'Selected') {
            throw "Policy applies to '$($policy.ManagedGroupTypes)' groups. Adding a single group only works when it is 'Selected'."
        }
        if ($PSCmdlet.ShouldProcess("Group $GroupId", "Add to policy $($policy.Id)")) {
            Add-MgGroupToLifecyclePolicy -GroupLifecyclePolicyId $policy.Id -BodyParameter @{ groupId = $GroupId }
            Write-Output "Group $GroupId added to the expiration policy."
        }
    }

    'Remove' {
        if (-not $policy) { Write-Output 'Nothing to remove.'; break }
        if ($PSCmdlet.ShouldProcess("Policy $($policy.Id)", 'DELETE (group expiration turns off for the whole tenant)')) {
            Remove-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $policy.Id
            Write-Output 'Policy removed. Groups no longer expire.'
        }
    }
}
