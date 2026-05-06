---
name: secrets-audit
description: Hunt for hardcoded secrets, credentials, API keys, tokens, and other sensitive values in source code and config files
allowed-tools: Read, Grep, Glob, Bash(find *), Bash(git log *), Bash(git show *)
argument-hint: [file-or-directory]
---

Scan $ARGUMENTS for hardcoded secrets and sensitive credential exposure.

## Patterns to Search For

**High-signal string patterns** (grep these):
- `password`, `passwd`, `pwd`, `secret`, `api_key`, `apikey`, `access_token`, `auth_token`, `private_key`, `client_secret`
- Assignment patterns: `= "..."`, `= '...'` near the above
- Base64-looking strings 40+ chars in assignments
- Patterns resembling: AWS (`AKIA`), GCP service account JSON, Stripe (`sk_live_`), GitHub PAT (`ghp_`), Slack webhook URLs

**Files to prioritize:**
- `.env`, `.env.*`, `config.*`, `settings.*`, `application.properties`, `*.yml`, `*.yaml`, `*.json`, `*.xml`, `*.ini`, `*.toml`
- Anything in `/config/`, `/secrets/`, `/credentials/`
- Docker-related: `Dockerfile`, `docker-compose.yml`

**Git history check** (if in a git repo):
- Check `git log --all --oneline` for commits mentioning "key", "secret", "token", "password", "credential", "fix leak"
- If any look suspicious, examine with `git show <hash>`

## Output Format

For each finding:
- **File:Line**
- **Type** (e.g., AWS key, database password, JWT secret)
- **Severity**: Critical (live/production credential), High (credential pattern, likely real), Medium (placeholder or test value)
- **The line** (redact the actual secret value in your output with `[REDACTED]`)
- **Remediation**: move to env var / secrets manager, rotate immediately if live

Produce a summary count at the top.
