Save the current session state.

1. Determine the project identifier:
   - Run `git remote get-url origin`
   - Extract the repository name (e.g., "myproject" from "git@github.com:user/myproject.git")
   - If this fails (not a git repo or no remote), warn that session notes
     will be saved locally in ./notes/ instead of global storage.

2. Update the local project files (these stay in the repo):
   - Update CLAUDE.md with any new architectural decisions or conventions
   - Update TODO.md - check off completed items, add any new tasks

3. Save session notes:

   If valid project identifier exists:
   - Create ~/.claude/sessions/<project-name>/notes/ if needed
   - Write session log to ~/.claude/sessions/<project-name>/notes/prompts-YYYYMMDD-HHMMSS.md
   - Write state snapshot to ~/.claude/sessions/<project-name>/session-state.md

   If no valid project identifier (fallback):
   - Create ./notes/ in the current directory if needed
   - Write session log to ./notes/prompts-YYYYMMDD-HHMMSS.md
   - Write state snapshot to ./notes/session-state.md
   - Remind user to add notes/ to .gitignore if they don't want it committed

4. Session log should include:
   - Session date/time
   - Git remote URL or "local project"
   - Summary of what was accomplished
   - Key prompts and decisions from this session
   - Any blockers or issues encountered
   - Recommended next steps

5. State snapshot should include:
   - Last session timestamp
   - Current milestone/phase
   - In-progress task
   - Quick context for resumption

6. Confirm what was saved and where.
