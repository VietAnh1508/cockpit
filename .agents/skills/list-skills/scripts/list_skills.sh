#!/usr/bin/env bash
# Lists AI agent skills installed on this machine, across providers

BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

header() { echo -e "\n${BOLD}$1${RESET}  ${DIM}$2${RESET}"; }
item()   { echo "  • $1"; }
none()   { echo -e "  ${DIM}(none)${RESET}"; }

# ── CLAUDE CODE — USER SKILLS ───────────────────────────────────────────────
header "CLAUDE CODE — USER SKILLS" "~/.claude/skills/"
USER_DIR="$HOME/.claude/skills"
if [ -d "$USER_DIR" ]; then
  found=0
  for entry in "$USER_DIR"/*/; do
    [ -d "$entry" ] && item "$(basename "$entry")" && found=1
  done
  for entry in "$USER_DIR"/*.md; do
    [ -f "$entry" ] && item "$(basename "$entry" .md)  [standalone .md]" && found=1
  done
  [ $found -eq 0 ] && none
else
  none
fi

# ── CLAUDE CODE — USER COMMANDS ─────────────────────────────────────────────
header "CLAUDE CODE — USER COMMANDS" "~/.claude/commands/"
CMD_DIR="$HOME/.claude/commands"
if [ -d "$CMD_DIR" ]; then
  found=0
  for entry in "$CMD_DIR"/*.md; do
    [ -f "$entry" ] && item "$(basename "$entry" .md)" && found=1
  done
  [ $found -eq 0 ] && none
else
  none
fi

# ── GEMINI CLI ───────────────────────────────────────────────────────────────
header "GEMINI CLI — GLOBAL INSTRUCTIONS" "~/.gemini/GEMINI.md"
GEMINI_FILE="$HOME/.gemini/GEMINI.md"
if [ -f "$GEMINI_FILE" ]; then
  size=$(wc -c < "$GEMINI_FILE" | tr -d ' ')
  if [ "$size" -gt 0 ]; then
    lines=$(wc -l < "$GEMINI_FILE" | tr -d ' ')
    item "GEMINI.md  ($lines lines)"
  else
    echo -e "  ${DIM}GEMINI.md exists but is empty${RESET}"
  fi
else
  echo -e "  ${DIM}(not found — Gemini CLI not installed or not configured)${RESET}"
fi

# ── OPENAI CODEX CLI ─────────────────────────────────────────────────────────
header "OPENAI CODEX CLI — USER SKILLS" "~/.codex/skills/"
CODEX_DIR="$HOME/.codex/skills"
if [ -d "$CODEX_DIR" ]; then
  found=0
  for entry in "$CODEX_DIR"/*/; do
    name=$(basename "$entry")
    [[ "$name" == .* ]] && continue   # skip internal .system dir
    [ -d "$entry" ] && item "$name" && found=1
  done
  [ $found -eq 0 ] && none
else
  echo -e "  ${DIM}(not found — Codex CLI not installed)${RESET}"
fi

# ── PROJECT-LEVEL ──────────────────────────────────────────────────────────
header "PROJECT-LEVEL" "\$PROJECT_DIR"
if [ -z "$PROJECT_DIR" ]; then
  echo -e "  ${DIM}(set PROJECT_DIR to scan project-level skills)${RESET}"
else
  PROJECT_ROOTS=()
  IFS=: read -ra _raw_roots <<< "$PROJECT_DIR"
  for r in "${_raw_roots[@]}"; do
    expanded="${r/#\~/$HOME}"
    [ -d "$expanded" ] && PROJECT_ROOTS+=("$expanded")
  done

  if [ ${#PROJECT_ROOTS[@]} -eq 0 ]; then
    echo -e "  ${DIM}(no valid directories found in PROJECT_DIR=\"$PROJECT_DIR\")${RESET}"
  else
    any_project=0
    for CODING_DIR in "${PROJECT_ROOTS[@]}"; do
      # Claude Code: .claude/skills/
      while IFS= read -r -d '' skills_dir; do
        skills=$(find -L "$skills_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort | tr '\n' '  ')
        if [ -n "$skills" ]; then
          project=$(dirname "$(dirname "$skills_dir")")
          echo "  ${BOLD}$(basename "$project")${RESET}  [claude] skills: $skills"
          any_project=1
        fi
      done < <(find "$CODING_DIR" -maxdepth 4 -type d -name "skills" -path "*/.claude/skills" -print0 2>/dev/null)

      # Claude Code: .claude/commands/
      while IFS= read -r -d '' cmds_dir; do
        cmds=$(find "$cmds_dir" -mindepth 1 -maxdepth 1 -name "*.md" -exec basename {} .md \; 2>/dev/null | sort | tr '\n' '  ')
        if [ -n "$cmds" ]; then
          project=$(dirname "$(dirname "$cmds_dir")")
          echo "  ${BOLD}$(basename "$project")${RESET}  [claude] commands: $cmds"
          any_project=1
        fi
      done < <(find "$CODING_DIR" -maxdepth 4 -type d -name "commands" -path "*/.claude/commands" -print0 2>/dev/null)

      # Cursor: .cursor/rules/
      while IFS= read -r -d '' rules_dir; do
        rules=$(find -L "$rules_dir" -mindepth 1 -maxdepth 1 \( -name "*.mdc" -o -name "*.md" \) -exec basename {} \; 2>/dev/null | sort | tr '\n' '  ')
        if [ -n "$rules" ]; then
          project=$(dirname "$(dirname "$rules_dir")")
          echo "  ${BOLD}$(basename "$project")${RESET}  [cursor] rules: $rules"
          any_project=1
        fi
      done < <(find "$CODING_DIR" -maxdepth 4 -type d -name "rules" -path "*/.cursor/rules" -print0 2>/dev/null)

      # Cross-provider: AGENTS.md
      while IFS= read -r -d '' agents_file; do
        relpath="${agents_file#$CODING_DIR/}"
        echo "  ${BOLD}$relpath${RESET}"
        any_project=1
      done < <(find "$CODING_DIR" -maxdepth 3 -name "AGENTS.md" -print0 2>/dev/null)
    done
    [ $any_project -eq 0 ] && echo -e "  ${DIM}(nothing found under \"$PROJECT_DIR\")${RESET}"
  fi
fi

# ── CLAUDE DESKTOP ─────────────────────────────────────────────────────────
header "CLAUDE DESKTOP — PERSONAL SKILLS" "~/Library/Application Support/Claude/…/skills/"
DESKTOP_BASE="$HOME/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin"
if [ -d "$DESKTOP_BASE" ]; then
  SEEN=""
  found=0
  while IFS= read -r -d '' skills_dir; do
    while IFS= read -r -d '' skill; do
      name=$(basename "$skill")
      # Deduplicate without associative arrays (compatible with bash 3.2)
      if [[ " $SEEN " != *" $name "* ]]; then
        item "$name"
        SEEN="$SEEN $name"
        found=1
      fi
    done < <(find "$skills_dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort -z)
  done < <(find "$DESKTOP_BASE" -maxdepth 3 -type d -name "skills" -print0 2>/dev/null)
  [ $found -eq 0 ] && none
else
  echo -e "  ${DIM}(Claude Desktop not found)${RESET}"
fi

echo ""
