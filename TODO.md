# TODO

## Future Ideas (not started)

1. ~~**Smoother session startup**~~ — **Done.** `code` and `shell` now auto-init and auto-build on first run; single command for both fresh and existing projects.

2. **Mobile dev environment** — Add an Android app development language/toolchain option (`--lang android` or similar).

3. **Better host tool integration** — Integrate with tmux, emacs, etc. so users don't have to manually set up sessions before starting work (related to item 1).

4a. ~~**Bump base image to Alpine 3.24**~~ — **Done.** Alpine 3.24 released 2026-06-09; ships musl 1.2.6 which unblocks the native Claude installer.

4b. ~~**Switch to native Claude installer**~~ — **Done.** Replaced npm install workaround with `curl -fsSL https://claude.ai/install.sh | bash`. Requires musl 1.2.6+ (Alpine 3.24). Added `downloads.claude.ai` to firewall allowlist for auto-updates.

5. **Improve security** — Possibly move firewall rules to the host instead of inside the container; explore best approach.

5a. ~~**Faster solidity image builds**~~ — **Done.** Switched from `cargo install` (Rust compile from source) to `foundryup` (pre-built binaries). Eliminates 10–20 min compile time and build fragility.

6. ~~**Web vulnerability checking commands**~~ — **Done.** Added five web security skills (`/vuln-scan`, `/sqli-deep`, `/authz-review`, `/secrets-audit`, `/depcheck`) to `skills/`.

7. **Migrate commands to skills** — Move `.claude/commands/*.md` files to `.claude/skills/<name>/SKILL.md` format. Low priority; existing commands work fine.

8. ~~**Pre-audit improvement**~~ — **Done.** `/pre-audit` now detects missing `node_modules` when `package.json` is present and stops with an actionable error.
