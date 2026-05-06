# TODO

## Future Ideas (not started)

1. ~~**Smoother session startup**~~ — **Done.** `code` and `shell` now auto-init and auto-build on first run; single command for both fresh and existing projects.

2. **Mobile dev environment** — Add an Android app development language/toolchain option (`--lang android` or similar).

3. **Better host tool integration** — Integrate with tmux, emacs, etc. so users don't have to manually set up sessions before starting work (related to item 1).

4. **Switch to native Claude installer** — Blocked by musl 1.2.5 in Alpine 3.23; revert from npm install once musl 1.2.6+ is available.

5. **Improve security** — Possibly move firewall rules to the host instead of inside the container; explore best approach.

6. **Web vulnerability checking commands** — Add skills/commands for auditing web code for security vulnerabilities.

7. **Migrate commands to skills** — Move `.claude/commands/*.md` files to `.claude/skills/<name>/SKILL.md` format. Low priority; existing commands work fine.
