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

11. ~~**Audit skill fixes**~~ — **Done.**  Merged 2026-10-09 (PR #1, `39d104c`).  The final PDF was hard to read and much too long (e.g. a 57-page report with only a few Informational findings).

    **Phase 1 — Reorder the PDF (`skills/audit-report/SKILL.md`)** — Done, signed off 2026-10-09 (`2295675`).
    - New order for the combined document:
      1. Report header (generated): Date, Auditor, Repository, Commit, Scope, taken from the per-file reports.  If the reports disagree on a value (e.g. commit), list every distinct value.
      2. Findings summary (generated): a severity count table from the checklist's `**Total:**` line, followed by one combined findings table across all reports (ID, Severity, Title, Contract).  Include the report filename in the ID, or renumber findings, so IDs don't collide (every per-file report starts at F-01).
      3. Round-over-round comparison (only if `audit/round-*/` exists), same as now.
      4. Detailed findings: each `audit-*.md`, with its repeated Date/Auditor/Repository/Commit header block removed in the combined document only (source files untouched).
      5. Appendices: ToB maturity, ToB prep, then prior rounds.
    - Drop `AUDIT-CHECKLIST.md` from the PDF entirely, both for the current round and in prior-round appendices.  It is still read for the completeness check and the totals.
    - Update the Rules section ("checklist first" no longer applies).

    **Phase 2 — Make reports shorter (`skills/audit/SKILL.md`, `skills/audit-report/SKILL.md`)** — Done, signed off 2026-10-09.
    - Sample: Safe-gaurd rerun (2026-10-08, 9 reports, 2 Low + 8 Informational).  The `audit-*.md` files total 64 KB, and the ToB appendices add another 27 KB.  Where the 64 KB goes:
      - Executive Summary: 38%.  Mostly per-file "what was verified ✓" tables, plus descriptions of what each contract does.
      - Informational findings: 29%.  Each has a full description, PoC, fix and Foundry regression test (even "delete this unused file" got a test).
      - Low findings: 18%.
      - Per-file `## Summary` with "Top 3 recommendations": 8%.  It pads to three even with a single Informational finding.
    - Changes:
      - Scale detail to severity:
        - Critical/High: full detail, same as now (description, step-by-step PoC, fix with code, Foundry regression test).
        - Medium: description, short PoC, fix with code.  Foundry test only if the PoC is not obvious.
        - Low: description, a short fix (code only if a few lines), PoC only as brief numbered steps when needed to show the issue is real.  No regression test.
        - Informational: only a row in an `## Informational` table (ID, location, issue, suggestion).  No separate section.
      - Executive summary: overall risk plus 2–4 sentences, then a short "Areas verified" list (a few one-line bullets) instead of the per-check verification table.  No description of what the contract does.
      - Drop the per-file `## Summary` section (totals and Top 3 recommendations).  It repeats the Findings Summary table.
      - Files with no findings, or declarations only (interfaces): header, one-line result, done.
      - Keep the `## Findings Summary` table format unchanged so `/audit-report` and the checklist update keep working.
    - ToB output (`skills/audit-report/SKILL.md`): the rerun (2026-10-09) cut the reports to 22.6 KB (−65%), but the ToB plugin output grew from 27 KB to 67 KB, so the PDF stayed about the same size.  The plugins' length and headings vary between runs.  `/audit-report` now includes only keyword-matched excerpts: maturity executive summary, scorecard and roadmap; prep static analysis, checklist and unavailable tools.  Prior rounds get only the maturity scorecard.  The full files stay in `audit/`.  On the rerun this is 15 KB of 67 KB, so about 40 KB total goes into the PDF, down from 90 KB.

    **Phase 3 — Docs**
    - Update README.md and CLAUDE.md wherever they describe the audit report layout.
    - Reinstall the skills (`cp -r skills/audit skills/audit-report ~/.claude/skills/`) and test on a real audit directory if one is available.

12. ~~**Install Slither in the `solidity` lang**~~ — **Done.**  Slither 0.11.6 with all transitive dependencies pinned, installed via `pipx install --global`; regenerate pins with `misc/slither-constraints.sh`.  Slither is useful for contract analysis, and `/pre-audit`'s ToB prep step already looks for it (in the Safe-gaurd sample, `tob-prep.md` had to substitute `forge lint`).  Install `slither-analyzer` at a pinned version (probably via pip/pipx, which needs `python3`/`py3-pip` added to `lang_packages_solidity`).  Check that it works with the static `solc` binary already installed, and add any PyPI domains it needs to the solidity firewall allowlist.  `all` picks it up through solidity.

    **Findings**
    - Latest release is `slither-analyzer` 0.11.6 (2026-07-28).  Requires Python >= 3.10 and supports 3.14.
    - Dependencies: crytic-compile (`<0.5`), web3 7.x, eth-abi/eth-typing/eth-utils, pycryptodome, prettytable.  crytic-compile pulls in `solc-select`, which installs its own `solc` shim.
    - Alpine's Python is externally managed (PEP 668), so a plain `pip install` fails.  Install into an isolated environment instead.
    - The image is built without the firewall (it is applied at `start`), so PyPI only has to be reachable at build time.  At runtime Slither calls `forge`/`solc` locally.  It only goes online if `solc-select` downloads a compiler, and that uses `binaries.soliditylang.org`, which is already allowed.  So no new firewall domains are expected.

    **Decision (2026-10-12):** pin Slither *and* all its transitive dependencies (reproducibility over convenience; regenerating on each bump is acceptable).

    **Phase 1 — Install (`ai-devcontainer.sh`, `misc/`)**
    - Add `pipx` (pulls in `python3`) to `lang_packages_solidity`.
    - The build context is the project's `.devcontainer/`, not this repo, so a constraints file next to the script won't reach the build.  Instead, keep the pinned list (`pip freeze` output, `name==version` per line) in a `SLITHER_CONSTRAINTS` variable in `ai-devcontainer.sh`, with the Slither version at the top.  The generated Dockerfile writes it to `/tmp/slither-constraints.txt` and runs `PIP_CONSTRAINT=/tmp/slither-constraints.txt pipx install slither-analyzer==<ver>`.  The pins are also visible in the committed Dockerfile.
    - Add `misc/slither-constraints.sh <version>` to regenerate the list.  It runs a throwaway `alpine:3.24` container with `$AI_DEVCONTAINER_ENGINE` (default podman), installs Slither via pipx, and prints the venv's `pip freeze`.  Run it on the host (this dev container has no engine or PyPI access) and paste the output into the script.  Same Alpine release and Python as the image, so the pins resolve to the same wheels/builds.
    - Add a `_lang_postinstall_slither` step and add it to `lang_postinstall_solidity` so `all` gets it too.
    - Not doing hash pinning (`--require-hashes`): musl/source builds make per-file hashes brittle.  Version pins only.
    - Make sure the static `/usr/local/bin/solc` wins over `solc-select`'s shim in `~/.local/bin` (check PATH order).  Otherwise `solc` would start pointing at a solc-select-managed version with no compiler installed.  (Resolved: not exposed by pipx, see status below.)
    - Some transitive dependencies may have no musl wheels and need a C build (e.g. `ckzg`, `bitarray`).  If the build fails, add `build-base python3-dev` only for the install step, or permanently if that's simpler.
    - Test (on the host): run `misc/slither-constraints.sh 0.11.6` and paste the result in, then `build --lang solidity` on a scratch project, then inside the container run `slither --version`, `solc --version` (still the static binary), and `slither .` on a small Foundry project.

    **Phase 1 status (2026-10-12)** — Done, signed off 2026-10-12.
    - Pins generated in this container (Alpine 3.24.2, Python 3.14.8): 47 packages, all with musl wheels, so no `build-base`/`python3-dev` is needed.
    - Changed from the plan: install with `pipx install --global` (venv in `/opt/pipx`, commands in `/usr/local/bin`) instead of per-user `~/.local/bin`.  The opencode backend's PATH doesn't include `~/.local/bin`.
    - The `solc` shim is a non-issue.  pipx only exposes Slither's own commands, so `solc-select`'s `solc` stays inside the venv.
    - Verified here: the generated RUN step installs cleanly, `slither --version` prints 0.11.6, the installed venv's `pip freeze` matches the pins exactly, and the temp constraints file is removed.  `slither` on a real contract could not be tested here (no `solc`, and the solc download hosts aren't allowlisted in a `base` container).
    - Host test (2026-10-12): `--lang solidity` image builds; `slither --version` = 0.11.6; `which solc` = `/usr/local/bin/solc` (0.8.37); `slither .` on a fresh `forge init` project compiles through forge and reports 1 result (solc-version), as expected.

    **Phase 2 — Docs** — Done, signed off 2026-10-12.
    - README language table and `langs`/usage text: mention Slither under `solidity`.
    - README: how to bump Slither (run `misc/slither-constraints.sh`, paste output, rebuild).
    - CLAUDE.md if needed.  Mark this item done (and fold in the item 11 TODO update).

13. ~~**Audit PDF content overflows the page**~~ — **Done.**  Fixed 2026-10-12.  Some content in the `/audit-report` PDF runs past the page margins.  Likely causes in the stylesheet (`skills/audit-report/SKILL.md` Step 3): `pre { overflow-x: auto; }` scrolls on screen but just clips in print, so long code lines run off the page.  Also, long unbroken inline `code` (paths, hashes, selectors) and wide tables (e.g. the 4-column Informational table) don't wrap.  Possible fixes: `pre { white-space: pre-wrap; overflow-wrap: anywhere; }`, `code { overflow-wrap: anywhere; }`, `table { table-layout: fixed; }` with `td { overflow-wrap: anywhere; }`, and an explicit `@page` size/margin.  Find the overflowing pages in a real PDF first to confirm which of these it is.

    **Findings (2026-10-12)**, from `audit/audit-report-20261012.pdf`, a real 11-file report.  No poppler in the container, so the page streams were inflated by hand and their drawing coordinates checked.
    - The page is 794px wide (A4).  With weasyprint's default 75px margin and the body's `2em` padding, the content box runs from x=104 to x=689 (585px).
    - On 9 pages, *tables* are drawn 652–885px wide.  The worst reaches x=990, past the page edge, so its right-hand column is lost, not just clipped at the margin.
    - Cause: unbreakable inline `code` in cells (e.g. `PermissionedLendingPool.sol:406-425,494-518` in the Informational tables' Location column).  Auto table layout won't shrink a column below its longest unbreakable word, so the whole table grows past the page.
    - `pre` is not a problem in this PDF.  Highlighted blocks (e.g. ```` ```solidity ````) already wrap in print because of pandoc's highlighting CSS.  An unlabelled ```` ``` ```` block with long lines would still clip, though.

    **Phase 1 — Stylesheet fix (`skills/audit-report/SKILL.md` Step 3)**
    - `code { overflow-wrap: anywhere; }`, and the same on `th, td`.  Unlike `break-word`, `anywhere` lowers the min-content width, so auto-layout tables can fit the page.  Keep auto layout (not `table-layout: fixed`), so the narrow ID/Severity columns stay narrow.
    - `pre`: replace `overflow-x: auto` with `white-space: pre-wrap; overflow-wrap: anywhere;` (and the same on `pre code`), so unlabelled code blocks wrap rather than clip.
    - Add an explicit `@page { size: A4; margin: 2cm; }`, and drop the screen-oriented `max-width: 900px; margin: 0 auto; padding: 2em` from `body`.  This gives back about 60px of width and makes the layout explicit rather than relying on weasyprint defaults.
    - Test (needs weasyprint: the host or a `solidity` container, since this container can't install it): regenerate the PDF from the same `audit/` files and confirm no table runs past the margin, and that the Informational tables are still readable.  The stream-coordinate check used above can be repeated to verify: no `re`/`Tm` x beyond the right content edge.

    **Phase 1 status (2026-10-12)** — Done, signed off 2026-10-12.  Host test: the PDF was regenerated from the same `audit/` files and looks fine by eye.  The stream-coordinate check finds nothing past the content box (x 83.6–710.1, about 627px wide, up from 585px) on any of the 45 page streams, and nothing below the page bottom.  Before the fix, tables reached x=990.

    **Phase 2 — Docs** — Done, signed off 2026-10-12.
    - README `/audit-report` section: notes the A4 layout and wrapping.  CLAUDE.md needed no change (it doesn't describe the stylesheet).  Item marked done.
