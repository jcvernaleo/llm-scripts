# TODO

## Future Ideas (not started)

0. ~~**GitHub CLI access in containers**~~ — **Done.** `~/.config/gh` is mounted from the host at start time (when present), same pattern as SSH agent and git config. `gh` was already in the base image and all required GitHub domains were already in the base firewall allowlist.

1. ~~**Smoother session startup**~~ — **Done.** `code` and `shell` now auto-init and auto-build on first run; single command for both fresh and existing projects.

2. ~~**Mobile dev environment**~~ — **Done.** Added `--lang android`: OpenJDK 21 + Android SDK cmdline-tools + platform-tools + build-tools 35 + API 35 platform.

3. **Better host tool integration** — Integrate with tmux, emacs, etc. so users don't have to manually set up sessions before starting work (related to item 1).

4a. ~~**Bump base image to Alpine 3.24**~~ — **Done.** Alpine 3.24 released 2026-06-09; ships musl 1.2.6 which unblocks the native Claude installer.

4b. ~~**Switch to native Claude installer**~~ — **Done.** Replaced npm install workaround with `curl -fsSL https://claude.ai/install.sh | bash`. Requires musl 1.2.6+ (Alpine 3.24). Added `downloads.claude.ai` to firewall allowlist for auto-updates.

5. **Improve security** — Possibly move firewall rules to the host instead of inside the container; explore best approach.

5a. ~~**Faster solidity image builds**~~ — **Done.** Switched from `cargo install` (Rust compile from source) to `foundryup` (pre-built binaries). Eliminates 10–20 min compile time and build fragility.

6. ~~**Web vulnerability checking commands**~~ — **Done.** Added five web security skills (`/vuln-scan`, `/sqli-deep`, `/authz-review`, `/secrets-audit`, `/depcheck`) to `skills/`.

7. ~~**Migrate commands to skills**~~ — **Done.** Moved all commands to `skills/<name>/SKILL.md` format; removed `commands/` directory; updated README and CLAUDE.md.

8. ~~**Pre-audit improvement**~~ — **Done.** `/pre-audit` now detects missing `node_modules` when `package.json` is present and stops with an actionable error.

9. ~~**Trim base image packages**~~ — **Done.** Moved packages only needed by specific languages out of the shared base image and into the relevant `lang_packages_*`/postinstall entries: `jq` moved to `solidity` and `terraform` (both need it for `wget | jq -r` version lookups); `unzip` moved to `terraform` and `android` (both unzip downloaded archives); `nodejs`/`npm` moved to `lang_packages_node` (already duplicated there, base copy was redundant) — note left in script that they may need to move back to base if we start relying on MCP servers (commonly launched via `npx` regardless of `--lang`). Dropped entirely as pure convenience tools (not required by any build/git/firewall operation, or by Claude Code itself — confirmed `fd`/`fzf` aren't shelled out to internally, unlike ripgrep which has a `USE_BUILTIN_RIPGREP` override): `bash-completion`, `mandoc`, `man-pages`, `less`, `htop`, `tree`, `procps`, `fd`, `fzf`. Can be added back with a one-off `apk add` inside the container if needed interactively. Not pursuing backend-specific package scoping (e.g. `gcompat`/`libgcc`/`libstdc++` only needed by the `claude` backend) — no interest in backend-specific containers right now.

10. ~~**Opt out of nonessential Claude Code traffic/auto-update**~~ — **Done.** Added `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` and `DISABLE_AUTOUPDATER=1` to the generated Dockerfile, per official devcontainer guidance (code.claude.com/docs/en/devcontainer). Containers are rebuilt regularly, so updates happening at image-build time (rather than via background checks) is intended; manual `claude update` inside a running container still works. Note: disabling nonessential traffic also disables feature-flag evaluation, so Remote Control and other flag-gated features are unavailable in-container — accepted tradeoff. Considered but declined: pinning the Claude Code CLI version itself (native installer always grabs latest; would require switching back to npm install to pin) and `/etc/claude-code/managed-settings.json` for org policy — both left as-is, not worth pursuing currently.

11. **Audit skill fixes** — In progress on branch `jcv_audit-skill-fixes`.  The final PDF is hard to read and much too long (e.g. a 57-page report with only a few Informational findings).

    **Phase 1 — Reorder the PDF (`skills/audit-report/SKILL.md`)** — Done, awaiting user test and signoff.
    - New order for the combined document:
      1. Report header (generated): Date, Auditor, Repository, Commit, Scope, taken from the per-file reports.  If the reports disagree on a value (e.g. commit), list every distinct value.
      2. Findings summary (generated): a severity count table from the checklist's `**Total:**` line, followed by one combined findings table across all reports (ID, Severity, Title, Contract).  Include the report filename in the ID, or renumber findings, so IDs don't collide (every per-file report starts at F-01).
      3. Round-over-round comparison (only if `audit/round-*/` exists), same as now.
      4. Detailed findings: each `audit-*.md`, with its repeated Date/Auditor/Repository/Commit header block removed in the combined document only (source files untouched).
      5. Appendices: ToB maturity, ToB prep, then prior rounds.
    - Drop `AUDIT-CHECKLIST.md` from the PDF entirely, both for the current round and in prior-round appendices.  It is still read for the completeness check and the totals.
    - Update the Rules section ("checklist first" no longer applies).

    **Phase 2 — Make reports shorter (`skills/audit/SKILL.md`, possibly `skills/audit-report/SKILL.md`)**
    - Scale detail to severity:
      - Critical/High: full detail, same as now (description, step-by-step PoC, fix with code, Foundry regression test).
      - Medium: description, short PoC, fix with code.  Foundry test only if the PoC is not obvious.
      - Low: description and a one or two sentence fix.  No PoC, no test.
      - Informational: only a row in an "Informational" table (location, issue, suggestion).  No separate section.
    - When a report has no findings, keep it short: the header, a one-line result, and the checks performed.  No executive summary or Summary/Top 3 recommendations.
    - Cut repeated per-file text: make the executive summary 2–3 sentences, and drop "Top 3 recommendations" unless there are Medium or higher findings.
    - Don't describe what each contract does, and don't restate the vulnerability checklist item by item.  Only list checklist items with findings or Needs Manual Review status.
    - ToB output: moving it to appendices (Phase 1) is enough for now; revisit only if the rerun report is still too long.
    - Start from the rerun audit directory the user provides after Phase 1, to see where the pages actually go.
    - Check that `/audit` updating the checklist (Checklist Update section) still works with the new format.

    **Phase 3 — Docs**
    - Update README.md and CLAUDE.md wherever they describe the audit report layout.
    - Reinstall the skills (`cp -r skills/audit skills/audit-report ~/.claude/skills/`) and test on a real audit directory if one is available.
