# CLAUDE.md

Guidance for Claude Code in this repo.

## What this repo is

- A fork of the atwork-it "Office 365 Groups and Microsoft Teams PowerShell MasterClass" (Nov 2019).
- Used as source material for **internal IT training** (interns and Tier 1 techs).
- **This repo is PUBLIC.** Never add real tenant names, client names, user emails, IPs, passwords, or keys. Use `contoso.com` / `yourlabtenant.onmicrosoft.com` placeholders.

## Layout

- `0-7-*.ps1`, `a1-a4-*.ps1`: original demo scripts. Keep them as-is for "old vs. new" comparisons.
- `*-Graph.ps1`: modernized versions using Microsoft Graph PowerShell.
- `Labs/`: intern lab guides, one per script (`Lab-NN-Topic.md`).

## Script standards (for new or modernized scripts)

- **Modules:** Microsoft Graph PowerShell (`Microsoft.Graph.*`), `ExchangeOnlineManagement` v3, `MicrosoftTeams`. **Never** use AzureAD, AzureADPreview, or MSOnline (deprecated), or basic-auth `New-PSSession` to Exchange (retired).
- **Auth:** interactive/modern auth (`Connect-MgGraph -Scopes ...`). No stored or plain-text credentials, and no `ConvertTo-SecureString -AsPlainText`.
- **Least privilege:** request the smallest Graph scope the action needs.
- **Safety:** any change goes through `[CmdletBinding(SupportsShouldProcess)]`, so `-WhatIf` and `-Confirm` work. Default to read-only.
- **Help:** comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`, `.NOTES` with module, permission, role, and a Microsoft Learn link).
- **Comments:** written for interns. Explain *why*, in plain language. Number the major steps.
- Validate inputs before connecting to anything.
- Verify cmdlet names and parameters against Microsoft Learn (use the Microsoft Learn MCP tools when available). Don't guess syntax.

## Lab guide format (`Labs/`)

Why it matters → objectives → prerequisites table (always "lab/dev tenant only") → numbered steps, each with **Expected** output → cleanup → 5 check-your-understanding questions with a collapsible answer key → instructor notes.

## Checks before committing

- Parse check: `[System.Management.Automation.Language.Parser]::ParseFile(...)` returns 0 errors.
- If available: `Invoke-ScriptAnalyzer -Path <file>`.
- Search the diff for emails, tenant names, and IPs before pushing (public repo).
