# Security Policy

## Supported versions

Only the latest `main` commit is supported. Update before reporting.

## Reporting a vulnerability

Use **GitHub Security Advisories** (Report a vulnerability on the repo
page). Reports stay private until a fix ships. Include:

- What is affected (file, command, agent, MCP server)
- Steps to reproduce with impact (what an attacker gains)
- Anything you already tried toward a fix

Expect an initial response within 7 days. No bug bounties are offered;
credit is given in the fix notes unless you ask otherwise.

## Scope and rules

In scope: this repository's agents, skills, scripts, bot, installer,
and documented configurations. Out of scope: third-party MCP servers,
upstream skill libraries, model providers, Telegram/Drive/Notion
themselves. Never test against anyone else's machines, accounts, or
workspaces. Do not exfiltrate, persist, or pivot during testing.
Social engineering of any person is out of scope, always.

## Safe harbor

Good-faith research that follows this policy will not be treated as
abuse. Stop and report immediately if you reach live credentials,
another person's data, or unintended access.
