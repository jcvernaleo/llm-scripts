---
name: vuln-scan
description: Audit web application source code for common vulnerability classes (XSS, SQLi, SSRF, path traversal, command injection, insecure deserialization, etc.)
allowed-tools: Read, Grep, Glob, Bash(find *), Bash(wc *)
argument-hint: [file-or-directory]
---

Perform a security-focused source code review of: $ARGUMENTS

Work through the following vulnerability classes systematically. For each finding, report:
- **File and line number**
- **Vulnerability class** (CWE if known)
- **Severity** (Critical / High / Medium / Low)
- **The vulnerable code snippet**
- **Why it's exploitable**
- **Recommended fix**

## Vulnerability Classes to Check

### Injection
- SQL injection: string concatenation into queries, f-string/format() queries, ORM raw() calls
- Command injection: subprocess/exec/eval/system with unsanitized input
- LDAP/XPath/NoSQL injection patterns
- Template injection (Jinja2, Twig, Pebble, Freemarker)

### XSS
- Reflected: user input returned in response without encoding
- Stored: user input persisted and rendered later
- DOM: innerHTML, document.write, eval() with user-controlled data
- Missing Content-Security-Policy headers

### Authentication & Authorization
- Missing authentication decorators/middleware on sensitive routes
- Hardcoded credentials or tokens
- Weak session configuration (no httponly/secure flags, long expiry, predictable IDs)
- JWT: alg:none, weak secret, missing validation

### SSRF
- User-controlled URLs passed to HTTP clients (requests, urllib, curl, fetch)
- Missing allowlists or scheme restrictions

### Path Traversal
- User input used in file open/read/write without normalization
- os.path.join with untrusted components
- Archive extraction (zip slip)

### Insecure Deserialization
- pickle.loads / yaml.load (not safe_load) / PHP unserialize on untrusted data
- Java ObjectInputStream from user-supplied bytes

### Sensitive Data Exposure
- Secrets, API keys, passwords in source or config files
- Verbose error messages exposing stack traces or internal paths
- Logging of sensitive fields

### Dependency Issues
- Note any import of known-dangerous functions (e.g., MD5/SHA1 for passwords, DES, ECB mode)

## Output Format

Produce a structured findings report. Group by severity. Include a summary count table at the top.
If $ARGUMENTS is a directory, use Glob/find to enumerate relevant source files first, then audit them.
