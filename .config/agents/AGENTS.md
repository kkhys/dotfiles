# AGENTS.md

## Communication
- Always communicate in Japanese
- Do not use emojis unless explicitly instructed
- Do not use bold text (**text**) in responses
- When asking for permission to run a command, provide a brief description in Japanese
- Put a URL on its own line, or end the line right after it. Never follow a URL with text or punctuation on the same line: terminals linkify the trailing characters into the URL

## Code
- Before writing, read the code the change touches and list every place it must reach: callers, tests, fixtures, config, exports. That list is the scope; extra features are not
- Take the first option that fully works, in this order: nothing, because nobody asked for it; a helper or pattern already in the codebase, used the way the surrounding code uses it; the standard library or the platform; an installed dependency; one line a reader gets at a glance; the minimum code that works
- Lazy about the solution, never about the change: finish every caller, test and fixture the change breaks
- Keep the codebase's layers, interfaces and conventions, and the shape the platform already gives a value. An abstraction, option, config or dependency earns its place only when the task needs it now
- Bug fix: grep every caller first, then fix the root cause once in the shared code. Moved or merged code keeps its validation and error handling
- Between options of equal size, take the one that is correct on edge cases
- Mark a deliberate shortcut with a comment in this form: `shortcut: <the limit>, <when to upgrade>`
- Never cut: validation at trust boundaries, error handling that prevents data loss, security, accessibility, anything the user asked for

## Code comments
- Write in English unless the project's instructions say otherwise, and only for what the code cannot express: why, trade-offs, constraints, non-obvious edge cases
- Never restate what the code shows; no banners or narration. Prefer no comment over a redundant one

## Security

### NEVER
- Delete production data without explicit confirmation
- Hardcode secrets
- Commit with test/lint errors

### MUST
- Write tests for new features and bug fixes
- Document breaking changes

## Proactive
- Suggest improvements proactively

## Reporting
- Post to Slack, Notion, or GitHub only on explicit request; otherwise return the text as a draft
- When reporting a change, add one line on the regression risk to existing behaviour
