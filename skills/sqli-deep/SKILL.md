---
name: sqli-deep
description: Deep-dive SQL injection  trace user input from entry points to all database query sinks
allowed-tools: Read, Grep, Glob, Bash(find *)
argument-hint: [file-or-directory]
---

Perform a taint-analysis-style SQL injection review of: $ARGUMENTS

## Step  Identify Input Sources
Find all locations where user-controlled data enters the application:
- HTTP request parameters, body, headers, cookies
- URL path parameters
- File uploads, form fields
- External API responses used in queries

## Step  Identify Query Sinks
Find all locations where SQL is constructed or executed:
- Raw query strings: `query(`, `execute(`, `cursor.execute(`, `db.query(`, `connection.query(`
- String formatting into queries: f-strings, `.format()`, `%` interpolation, `+` concatenation
- ORM escape hatches: `.raw(`, `RawSQL(`, `extra(`, `execute_sql(`, `text(` (SQLAlchemy), `query_builder->whereRaw(`

## Step  Trace Data Flow
For each sink, trace backwards: does unsanitized user input reach it?
- Direct path: `query = "SELECT * FROM users WHERE id = " + request.args['id']`
- Indirect path: input stored in variable, passed through functions, reaches sink
- Second-order: input stored in DB, later retrieved and used in another query

## Step  Classify Findings
- **Confirmed**: clear unsanitized user input to query sink
- **Probable**: input reaches sink through code path that appears unsanitized but requires confirmation
- **False positive risk**: parameterized but worth noting for review

## Output
For each finding: file:line, input source, sink, data flow path, exploitation scenario, parameterization fix.4 3 2 1 review 
