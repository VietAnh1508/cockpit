# Results — browser tool comparison (run: FILL IN DATE/LABEL)

Scenario: `store-scenario.md`. Graded against `store-scenario-answer-key.md`. See `plan.md` for methodology.

## Pre-run checklist (fill in before starting, based on lessons from the 2026-07-03 batch)

- [ ] **Sequential, not parallel**: launch one run, wait for it to fully finish, then launch the next. Do not batch multiple runs of the *same* tool concurrently — concurrent agents on the same MCP server share the underlying browser/context and pollute each other's state (pre-populated carts, unexplained navigation, stray tabs from other runs). This was the main flaw in the 2026-07-03 batch.
- [ ] **Verify isolation directly**, don't just trust "fresh session": before trusting a run's numbers, check its transcript for any of last time's contamination symptoms (state present before the agent acted, navigation/logout the agent didn't trigger, an extra tab/page it didn't create). If present, the run is contaminated — discard or re-run rather than averaging it in.
- [ ] **Token split**: the Agent tool's completion notification only gives one combined `subagent_tokens` figure. If input/output split is actually needed, pull it from the `agent-*.jsonl` transcript's usage records instead (grep/jq for totals — don't load the whole file).
- [ ] **Wall-clock caveat**: `duration_ms` from the Agent completion notification is total agent time (includes model thinking), not strictly first-tool-call-to-last-tool-call. If a run needed a manual permission approval mid-flight, note it — that adds human-reaction-time noise that has nothing to do with the tool.
- [ ] **Real-profile side effects** (Claude in Chrome only): note any autofill behavior (duplicated/overwritten typed text, stale saved credentials) and whether it visibly interfered with an action. This looked genuinely tool-specific in the 2026-07-03 run.
- [ ] **Password-breach popup is not profile-specific — don't re-litigate this.** In the 2026-07-03 run it appeared across Playwright, Chrome DevTools MCP, *and* Claude in Chrome, so it's not a Claude-in-Chrome/real-profile artifact — it's Chrome's real-time password-leak check, which hashes any *submitted* password against a known-breach list regardless of profile or tool. `secret_sauce` is a public, well-known test password, so this will very likely recur next time too. If it's a distraction, disable Chrome's "Warn you if passwords are exposed in a data breach" setting globally before testing, rather than trying to fix it via profile isolation.

## Results table

| Tool | Run | Correctness (/8)* | Tool calls | Tokens | Wall-clock | Notes |
|---|---|---|---|---|---|---|
| Playwright MCP | 1 | | | | | |
| Playwright MCP | 2 | | | | | |
| Playwright MCP | 3 | | | | | |
| **Playwright avg** | | | | | | |
| Chrome DevTools MCP | 1 | | | | | |
| Chrome DevTools MCP | 2 | | | | | |
| Chrome DevTools MCP | 3 | | | | | |
| **Chrome DevTools avg** | | | | | | |
| Claude in Chrome | 1 | | | | | |
| Claude in Chrome | 2 | | | | | |
| Claude in Chrome | 3 | | | | | |
| **Claude in Chrome avg** | | | | | | |

\* Grade steps 2, 6, 7 as exact matches against the answer key. Grade step 8 on the answer key's qualitative bar (flag the slowdown, not just "it worked") — but also record the *specific number reported* in Notes, since precision varied a lot last time (some runs measured latency across tool-call round-trips and got 2-3x the true value; only in-page timing, e.g. `performance.now()` bracketing the action within one script, was reliably accurate).

## Verdict

State only what the data actually supports. Before writing a "default to X" line, check:
- Is the gap between the top two tools bigger than the noise you'd expect from any contamination or measurement issues you flagged above? If not, say the comparison is undecided rather than picking a winner.
- Is a claimed differentiator (e.g. a tool recovering from some failure) something that would still happen in a clean run, or did your test setup create the very problem the tool then got credit for solving? If the latter, don't count it.

Call `advisor()` before finalizing the verdict — the 2026-07-03 run shipped an overclaimed "default to Chrome DevTools MCP" recommendation on its first draft that didn't survive scrutiny (the efficiency gap was self-described as "within noise," and the one differentiator was circular). Catch that before writing it down, not after.
