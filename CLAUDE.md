# Cockpit

A meta-workspace for optimizing AI tooling across projects.

## `configs/` — Observe & Promote

Review AI configurations across all scopes (project CLAUDE.md files, local rules, user-level settings). Identify patterns worth lifting to the global level (`~/.claude/`) so they apply everywhere.

Example: a project-level rule that uses a Haiku sub-agent for commit messages is useful enough to live in `~/.claude/CLAUDE.md` rather than one repo.

## `scratch/` — Draft & Experiment

Capture ideas, try out configurations, and prototype workflows. Write a draft, test it, iterate. Some files get deleted after promoting; others stay as reference.

## Flow

Observe a useful pattern → draft/test in scratch → promote to user-level or target project → clean up if no longer needed.
