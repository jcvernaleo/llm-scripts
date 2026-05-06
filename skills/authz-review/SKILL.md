---
name: authz-review
description: Review web application route/endpoint definitions and business logic for broken access control, privilege escalation, and IDOR vulnerabilities
allowed-tools: Read, Grep, Glob, Bash(find *)
argument-hint: [file-or-directory]
---

Perform a focused broken access control review of: $ARGUMENTS

## What to Enumerate First

1. Identify the routing framework in use (Flask, Django, Express, Rails, Spring, Laravel, FastAPI, etc.)
2. Enumerate all route/endpoint definitions
3. Map which routes have authentication and authorization middleware/decorators applied

## What to Look For

### Missing Authentication
- Routes accessible without login that should require it
- Auth middleware applied inconsistently (some routes decorated, others not)
- Admin/internal routes without auth

### Broken Object-Level Authorization (IDOR)
- Routes that fetch objects by ID without verifying the requesting user owns or has access to that object
- Pattern: `GET /invoice/<id>` where `id` comes from user input and is queried directly
- Look for: direct DB lookups by user-supplied ID with no ownership check

### Broken Function-Level Authorization
- Admin functions accessible to non-admin users
- Role checks that are client-side only (e.g., hidden UI elements vs. server enforcement)
- Privilege escalation: can a regular user modify their own role/group?

### Mass Assignment
- ORM create/update from request body without field allowlisting (Rails `permit`, Django form `fields`, etc.)
- Direct `model.update(request.json)` patterns

### JWT / Session Abuse
- Role or permission claims stored in JWT that the server trusts without re-checking against DB
- Missing token revocation on logout

## Output Format

- List all routes found with their auth status (Authenticated / Unauthenticated / Unknown)
- Flag findings with file:line, vulnerability class, and recommended fix
- Note any routes that could not be fully analyzed due to dynamic registration
