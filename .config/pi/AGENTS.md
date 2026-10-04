# AGENTS.md

## Communication
- Always communicate in Japanese
- Do not use emojis unless explicitly instructed
- Do not use bold text (**text**) in responses
- When asking for permission to run a command, provide a brief description in Japanese

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

## Git
- End every commit message with the trailer `Co-authored-by: Codex <noreply@openai.com>`. Keep existing trailers and never duplicate it

## Proactive
- Suggest improvements proactively

## Reporting
- Post to Slack, Notion, or GitHub only on explicit request; otherwise return the text as a draft
- When reporting a change, add one line on the regression risk to existing behaviour

## Claude Code compatibility
The skills under `~/.agents/skills` and the `CLAUDE.md` files in repositories are written for Claude Code. Apply them by translating, never by skipping:

- Tools: `Bash` is `bash`; `Read` is `read`; `Edit` and `Write` are `edit` and `write`; `Grep` and `Glob` are `rg` and `find` through `bash`; `Agent` and `Task` are `subagent`; `AskUserQuestion` is `ask_user_question`; `WebSearch` is `web_search`; `WebFetch` is `fetch_content`
- `Skill(<name>)`, or an instruction to invoke the `<name>` skill: read that skill's `SKILL.md` and follow it. A name written `<plugin>:<name>` is the skill listed under that name, or under `<name>` when only that is listed
- `${CLAUDE_SKILL_DIR}` is the directory holding the `SKILL.md` being followed
- `$ARGUMENTS` is the request text that came with the skill
- `` !`command` `` stands for that command's output: run the command and read the result before going on
- `mcp__plugin_<plugin>_<server>__<tool>` is `mcp__<server>__<tool>`, called through `codemode`
- `subagent_type`: `general-purpose` is `delegate`, `Explore` is `scout`, and `<plugin>:<name>` is the agent `<name>`. For a type `subagent` does not list, use `delegate` and state the role in the task
- A tool with no counterpart here (`Monitor`, `ScheduleWakeup`, `TaskCreate`): do the step directly, or say that it cannot be done
