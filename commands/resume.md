Resume the project from saved state.

1. Determine the project identifier:
   - Run `git remote get-url origin`
   - Extract the repository name (e.g., "myproject" from "git@github.com:user/myproject.git")
   - If this fails (not a git repo or no remote), warn that session state
     cannot be loaded from global storage and proceed with local files only.

2. Read LOCAL project files (in current directory) if they exist:
   - CLAUDE.md (project memory and conventions)
   - TODO.md or todo.md (task list)
   - spec.md or SPEC.md (requirements)
   - PLANNING.md or planning.md (architecture)

3. If a valid project identifier was found, read GLOBAL session state:
   - ~/.claude/sessions/<project-name>/session-state.md
   - Optionally scan recent files in ~/.claude/sessions/<project-name>/notes/
     to see what was discussed in the last 1-2 sessions

4. Synthesize and summarize:
   - Current project state
   - What was last worked on (from session-state.md if available)
   - What's next on the task list
   - Any noted blockers

5. Ask if I want to continue with the next task or do something else.
