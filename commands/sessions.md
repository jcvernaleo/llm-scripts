List recent session logs across all projects.

1. Scan ~/.claude/sessions/ for all project directories

2. For each project found:
   - Read session-state.md to get last session timestamp
   - Count how many session logs exist in notes/
   - Get the date of the most recent log file

3. Display a table or list showing:
   - Project name
   - Last session date
   - Number of saved sessions
   - Last noted status/phase (one-line summary from session-state.md)

4. Sort by most recently active first.

5. If $ARGUMENTS is provided, treat it as a project name filter:
   - Show detailed session history for that project
   - List all session logs with dates and one-line summaries
   - Example: /sessions myproject

6. Do not ask any follow-up questions. Just display the information.
