---
applyTo: "**"
excludeAgent: ["coding-agent"]
description: "Code review standards - applies only to Copilot code review, not coding agent"
---

# Code Review Standards

Instructions for GitHub Copilot code review on pull requests.

## Review Focus Areas

### Security (Critical)

- Flag hardcoded credentials, API keys, tokens, passwords
- Check for missing input validation on user-provided data
- Verify authentication/authorization checks on protected endpoints
- Flag use of deprecated or insecure cryptographic functions

### Code Quality

- Identify functions exceeding 50 lines (suggest extraction)
- Flag code duplication (DRY violations)
- Check for proper error handling (no bare except, meaningful messages)
- Verify logging exists for significant operations
- Ensure consistent naming conventions (snake_case for Python/Terraform)

### Terraform-Specific

- Verify provider versions are locked (`~>` constraints)
- Check that sensitive variables use `sensitive = true`
- Flag hardcoded IDs (should use data sources)
- Ensure resources have descriptive names with provider prefix
- Verify `description` on all variables and outputs

### Testing

- Flag missing tests for new functionality
- Check test coverage for edge cases and error conditions
- Verify mocks are used for external dependencies
- Ensure test names describe what is being tested

## Review Behavior

### ALWAYS

- Provide specific file and line references
- Suggest concrete fixes, not just problem identification
- Prioritize security issues over style issues
- Consider existing codebase patterns when suggesting changes

### NEVER

- Suggest changes that contradict existing patterns without justification
- Flag auto-generated or vendored code
- Recommend technologies not in the project's stack
- Provide generic feedback without actionable guidance

## Severity Classification

| Severity | Criteria | Action |
|----------|----------|--------|
| **Blocking** | Security vulnerabilities, data loss risk | Must fix before merge |
| **Major** | Logic errors, missing error handling | Should fix before merge |
| **Minor** | Style, naming, documentation | Fix in this PR or follow-up |
| **Suggestion** | Optimization, alternative approaches | Consider for future |
