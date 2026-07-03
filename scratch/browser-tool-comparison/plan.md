# Plan: Compare Playwright MCP vs Claude in Chrome vs Chrome DevTools MCP

## Goal

Same scenario, three tools, one at a time. See which one gets the task right, how many steps it takes, and how many tokens it burns. Output: a table that tells us which tool to reach for by default, and when to switch.

## Test site

**https://www.saucedemo.com** — built for test automation practice, free, no login/account needed, stable (won't change under us), and has *known intentional bugs* baked into specific test users:

- `standard_user` — works normally, our baseline.
- `problem_user` — every product shows the same image (broken image swap). Good for testing whether a tool actually *sees* the page vs. just reads the DOM/accessibility tree.
- `performance_glitch_user` — artificial slow load. Tests whether a tool handles waits/timeouts sensibly.
- `locked_out_user` — login fails with an error message. Tests error handling.
- Password for all: `secret_sauce`

## Scenario file (what we hand to the tool)

Save as `scratch/browser-tool-comparison/store-scenario.md`, given verbatim to each tool/tester as its task list. Keep the answer key (below) in a separate file — `scratch/browser-tool-comparison/store-scenario-answer-key.md` — so it never leaks into the tested session's context.

```
1. Log into saucedemo.com as standard_user.
2. Sort products by price, high to low. Report the name and price of the top 3.
3. Add "Sauce Labs Backpack" and "Sauce Labs Bike Light" to the cart.
4. Open the cart and confirm both items are listed with correct prices.
5. Check out: fill in first name "Test", last name "User", zip "12345".
6. On the checkout overview page, report the item total, tax, and final total.
7. Log out. Log back in as problem_user. Look at the product list and report
   anything visually wrong.
8. Log out. Log back in as performance_glitch_user and note how long login
   takes to settle.
```

### Answer key (do not show to the tested tool)

Confirmed manually (Playwright MCP, 2026-07-03) and locked in `scratch/browser-tool-comparison/store-scenario-answer-key.md`:

- Task 2: Sauce Labs Fleece Jacket ($49.99), Sauce Labs Backpack ($29.99), Sauce Labs Bolt T-Shirt ($15.99).
- Task 6: item total $39.98, tax $3.20, total $43.18.
- Task 7: all product images are identical (the same picture repeated) — this is the bug. Correct answer must mention "images are the same/wrong," not just "looks fine."
- Task 8: login takes noticeably longer (~5s) — correct answer should flag the delay, not just "it worked."

## Metrics

| Metric | How to capture |
|---|---|
| Correctness | Score each of the 8 tasks pass/fail against the answer key. Report X/8 per run. |
| Efficiency | Count of tool calls/actions taken to finish (navigate, click, screenshot, etc. each count as 1). Fewer for the same correctness = better. |
| Token usage | Run `/cost` at the end of each session (or read the transcript's usage totals). Report input + output tokens separately, since screenshot-heavy tools (Claude in Chrome) skew input tokens via vision, while accessibility-tree tools (Playwright MCP) skew via huge text dumps. |
| Wall-clock time | Timestamp first tool call to last tool call. |
| Reliability | Any tool-call errors, retries, or timeouts not caused by the task itself (e.g., MCP server crash, stale element). |

## Procedure

1. **Isolate the tool under test.** Each run should only have access to the one tool being tested (disconnect the other two MCP servers / disable the extension) — otherwise the model might quietly fall back to a tool that isn't the one we're measuring.
2. **Fresh session per run.** No conversation history carried over between tools or between repeats — otherwise later runs get an unfair advantage from cached context.
3. **3 runs per tool** (9 runs total). Agents are non-deterministic; one run isn't enough to trust. Average correctness and tokens across the 3, note variance.
4. **Same prompt every time**: "Here is a scenario file: [contents of store-scenario.md]. Complete each step and report your findings for steps 2, 6, 7, and 8." No extra hints.
5. **Grade immediately after each run** using the answer key, before starting the next run, so grading criteria don't drift.

### Execution mechanism

Run each of the 9 runs as a plain **Agent tool** call (not the Workflow tool — 9 runs is small enough that Agent calls alone are simpler, and Workflow's orchestration overhead isn't needed here).

- Each Agent call gives a fresh, history-free session on its own — satisfies point 2 for free.
- To satisfy point 1 (isolation), a general-purpose subagent can see every connected MCP tool by default, which isn't good enough — the model could quietly reach for a different tool mid-run. Three narrow custom subagent types, one per tool, live in `.claude/agents/browser-tool-comparison/`, each restricted in its frontmatter to only that tool's MCP functions (plus `Read` for loading the scenario file):
  - `playwright-tester` — only `mcp__playwright__*` tools
  - `chrome-devtools-tester` — only `mcp__chrome-devtools__*` tools
  - `claude-in-chrome-tester` — only `mcp__claude-in-chrome__*` tools
- Token usage and wall-clock time come straight from the Agent tool's own completion notification (`subagent_tokens`, `duration_ms`) — no extra instrumentation needed.
- Tool-call count isn't in that notification, so ask each subagent to report how many tool calls it made as part of its final answer.

## Output

A results table in `scratch/browser-tool-comparison/results.md`:

| Tool | Run | Correctness (/8) | Tool calls | Input tokens | Output tokens | Wall-clock | Notes |
|---|---|---|---|---|---|---|---|

Plus a short written verdict at the bottom: which tool to default to, and which situations flip the recommendation (e.g., "Playwright MCP wins on tokens but Claude in Chrome caught the image bug that Playwright missed").

## Open questions — resolved

- Chrome DevTools MCP and Playwright MCP are both installed and confirmed working (smoke-tested against saucedemo.com on 2026-07-03: both navigated, screenshotted, and read console messages correctly).
- Task 7 (visual bug) is scored pass/fail by a human reading the tool's report against the answer key — no separate rubric needed.

## Known flaw in the first 9-run batch (2026-07-03) — fix before trusting efficiency numbers

All 9 runs were launched as a single parallel batch of Agent calls. That satisfies "fresh session per run" but **not** tool isolation from *other runs of the same tool* — concurrent agents on the same MCP server shared the underlying browser/browser context, so runs polluted each other's state (pre-populated carts, unexplained navigation/logout, one run finding an extra tab from another run mid-flight). See `results.md`'s methodology note for the full list of symptoms.

Effect: tool-call counts, tokens, and wall-clock are all inflated by contamination-recovery work, and the one apparent Chrome-DevTools-MCP-vs-Playwright-MCP differentiator (a Chrome DevTools run self-recovering via `isolatedContext`) is circular — that feature only got exercised because the parallel harness created the contention. Correctness (8/8 across all 9) is unaffected and stands as-is.

**Next step: re-run sequentially** — one run fully finishes before the next starts, no shared browser contention — at minimum for Chrome DevTools MCP vs Playwright MCP (Claude in Chrome's cost gap looks robust enough already that it likely doesn't need a re-run, but re-running all 9 sequentially would settle it cleanly too). Not yet scheduled as of 2026-07-03.
