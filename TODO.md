# TODO

## Future Ideas (not started)

1. **Smoother session startup** — Starting a new session takes too many steps; needs to be more seamless.

2. **Mobile dev environment** — Add an Android app development language/toolchain option (`--lang android` or similar).

3. **Better host tool integration** — Integrate with tmux, emacs, etc. so users don't have to manually set up sessions before starting work (related to item 1).

4. **Switch to native Claude installer** — Blocked by musl 1.2.5 in Alpine 3.23; revert from npm install once musl 1.2.6+ is available.

5. **Improve security** — Possibly move firewall rules to the host instead of inside the container; explore best approach.
