Create a new multi-repo umbrella workspace in the current directory.

If $ARGUMENTS is empty, ask the user for a project name before proceeding. Otherwise use $ARGUMENTS as the project name.

Do the following steps in order:

1. Initialize a git repo in the current directory with `git init`

2. Create `.gitignore` with the following content:
```
# component repos
repos/

# editor artifacts
*~
\#*\#
.#*
.dir-locals.el

# OS artifacts
.DS_Store
```

3. Create `repos.txt` with just a comment line:
```
# Add component repo URLs here, one per line
# git@github.com:you/repo-name.git
```

4. Create `PLAN.md` with the following content:
```markdown
# $ARGUMENTS — Project Plan

## Goal
<!-- What is this project trying to achieve? -->

## Components
<!-- List each repo and its role -->

| Repo | Purpose | Language |
|------|---------|----------|
|      |         |          |

## Architecture
<!-- How do the components relate to each other? -->

## Milestones
<!-- High level phases or milestones -->

## Decisions
<!-- Record significant architectural decisions here (ADR-lite) -->

### [DATE] Decision title
- **Context:**
- **Decision:**
- **Consequences:**
```

5. Create `TODO.md` with the following content:
```markdown
# $ARGUMENTS — Cross-Repo TODO

## In Progress

## Backlog

### [CROSS] Example cross-repo task
- [ ] repo-a: description
- [ ] repo-b: description

## Done
```

6. Create the `repos/` directory with a `.gitkeep` so it exists but is not tracked

7. Do an initial commit with message "Initial umbrella workspace scaffold: $ARGUMENTS"

8. Report what was created.
