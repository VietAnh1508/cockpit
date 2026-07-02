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

Save as `scratch/store-scenario.md`, given verbatim to each tool/tester as its task list. Keep the answer key (below) in a separate file — `scratch/store-scenario-answer-key.md` — so it never leaks into the tested session's context.

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

- Task 2: Sauce Labs Fleece Jacket ($49.99), Sauce Labs Backpack ($29.99), Sauce Labs Bike Light ($9.99) — exact order depends on current catalog prices, confirm once against a manual run before scoring.
- Task 6: item total = 29.99 + 9.99 = 39.98; tax and final total depend on saucedemo's current tax rate — confirm once manually, then lock the expected numbers.
- Task 7: all product images are identical (the same picture repeated) — this is the bug. Correct answer must mention "images are the same/wrong," not just "looks fine."
- Task 8: login takes noticeably longer (~5s) — correct answer should flag the delay, not just "it worked."

Run the scenario manually once yourself first to pin exact numbers/prices before using this as a grading key — saucedemo's catalog is stable but don't hardcode assumptions from memory.

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

## Output

A results table in `scratch/store-scenario-results.md`:

| Tool | Run | Correctness (/8) | Tool calls | Input tokens | Output tokens | Wall-clock | Notes |
|---|---|---|---|---|---|---|---|

Plus a short written verdict at the bottom: which tool to default to, and which situations flip the recommendation (e.g., "Playwright MCP wins on tokens but Claude in Chrome caught the image bug that Playwright missed").

## Open questions before running this

- Is Chrome DevTools MCP actually installed/configured yet, or does that need setup first?
- Is Playwright MCP installed, or does it need `npx @playwright/mcp` set up first?
- Do we score task 7 (visual bug) as pass/fail by a human reading the tool's report, or do we need a stricter rubric?
