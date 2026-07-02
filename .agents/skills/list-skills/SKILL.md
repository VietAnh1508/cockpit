---
name: list-skills
description: "Lists all AI agent skills installed on this machine, across providers: Claude Code user-level skills and commands, Claude Desktop personal skills, Gemini CLI global instructions, and OpenAI Codex CLI skills. Also scans project directories in $PROJECT_DIR for Claude project skills, Cursor rules, and cross-provider AGENTS.md files. Use this whenever the user asks to see their installed skills, list available AI tools, audit what's installed, check their skill inventory, find where a skill lives on disk, or asks things like 'what skills do I have?', 'show me all my AI provider setups', or 'what agent tools are installed'."
---

# List Skills

Run the bundled script and present the results to the user. Works on any machine — project-level scanning requires `PROJECT_DIR` to be set (see below).

## Available scripts

- **`scripts/list_skills.sh`** — discovers and prints all installed skills across providers

## Workflow

```bash
bash scripts/list_skills.sh
```

Present the output as-is — it's already grouped and formatted. If the terminal doesn't render ANSI colors (e.g. inside a tool result), the text is still readable without them.

## What it covers

| Provider | Level | Location |
|---|---|---|
| Claude Code | User skills | `~/.claude/skills/` |
| Claude Code | User commands | `~/.claude/commands/` |
| Claude Code | Project skills & commands | `.claude/skills/` and `.claude/commands/` under `$PROJECT_DIR` |
| Claude Desktop | Personal skills | `~/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/…/skills/` |
| Gemini CLI | Global instructions | `~/.gemini/GEMINI.md` |
| OpenAI Codex CLI | User skills | `~/.codex/skills/` |
| Cursor | Project rules | `.cursor/rules/` under `$PROJECT_DIR` |
| Cross-provider | Project instructions | `AGENTS.md` files under `$PROJECT_DIR` |

**Limitation:** only locally installed, file-based skills can be scanned. Cloud-synced rules and app-database configs (e.g. Cursor User Rules stored in the app DB, OpenAI Assistants) are not enumerable from the filesystem.

Built-in skills bundled with Claude Code (like `/code-review`, `/verify`, `/run`) are not listed — they're part of the Claude Code harness, not installed files.
