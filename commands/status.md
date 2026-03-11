Show current project state without taking action.

1. Determine the project identifier:
   - Run `git remote get-url origin`
   - Extract the repository name
   - Note if this fails (no global session data available)

2. Read LOCAL project files (in current directory) if they exist:
   - CLAUDE.md (project memory and conventions)
   - TODO.md or todo.md (task list)
   - spec.md or SPEC.md (requirements)
   - PLANNING.md or planning.md (architecture)

3. If a valid project identifier was found, read GLOBAL session state:
   - ~/.claude/sessions/<project-name>/session-state.md

4. Display a concise summary:
   - Project name and git remote
   - Current milestone/phase
   - Last session date (if available)
   - Completed tasks (recent)
   - In-progress task
   - Next up on TODO
   - Any noted blockers

5. Do not ask any follow-up questions. Just display the status and wait for my next instruction.
