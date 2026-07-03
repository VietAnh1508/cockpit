# Results — browser tool comparison

Scenario: `store-scenario.md`. Graded against `store-scenario-answer-key.md`. See `plan.md` for methodology.

## Methodology note (read before the table)

**The 9 runs were not actually isolated from each other**, despite each being a fresh subagent session. All 9 were launched in a single parallel batch, so multiple agents on the same tool shared the same underlying browser/MCP server process, and cross-run interference showed up constantly:

- Playwright run 3: cart pre-populated with items before it acted, sort order and cart badge changed with no action taken, spontaneous logout mid-flow.
- Playwright run 2: cart pre-populated before it acted (leftover state).
- Chrome DevTools run 2: detected cart contents changing and unexplained navigation, correctly diagnosed it as a shared/contended browser context, and proactively opened an isolated context (`isolatedContext` param) to redo the run cleanly.
- Chrome DevTools run 3: discovered a second tab mid-run it didn't create — another concurrent run sharing the same browser — causing several actions to silently land on the wrong tab.
- Claude in Chrome run 2: saw inconsistent product images across logins of the same test user and correctly declined to report it as a confirmed finding, suspecting session bleed-through.

This inflates tool-call counts, tokens, and wall-clock time for every tool — it's an artifact of running the comparison in parallel, not a fair reflection of intrinsic tool efficiency. **Chrome DevTools MCP was the only tool where a run self-diagnosed the contamination and fixed it via an explicit isolated-context feature** — that's a real capability signal, not noise, and is called out in the verdict below. Treat the raw efficiency numbers as upper bounds, not clean baselines; a rerun with runs staggered sequentially (or verified separate browser processes per run) would give cleaner numbers.

Separately: a native "password found in a data breach" popup appeared during testing (since `secret_sauce` is a public, well-known test password) — **and per user observation, this happened across Playwright and Chrome DevTools MCP runs too, not just Claude in Chrome.** That rules out the profile-isolation explanation: it's most likely Chrome's real-time password-leak check, which hashes any *submitted* password against a known-breach list independent of whether that password is saved in the profile or which tool is driving the browser. Correction to an earlier draft of this note: this is scenario-level noise (the deliberately "leaked" test password), not a Claude-in-Chrome-specific cost, and a fresh/clean Chrome profile for Claude in Chrome would likely not have prevented it. No run reported the popup blocking an action either way.

What *does* still look Claude-in-Chrome-specific, since no Playwright/Chrome DevTools transcript reported it: Chrome's autofill repeatedly duplicating/overwriting typed text, and once feeding a stale username into the login form (a real task failure, worked around with `form_input`). That's plausibly tied to running against a real, already-populated browser profile rather than a clean instance.

Also: the Agent tool's completion notification only reports one combined `subagent_tokens` figure, not separate input/output token counts as the plan specified — the table below merges those two columns into one "Tokens" column.

## Results table

| Tool | Run | Correctness (/8)* | Tool calls | Tokens | Wall-clock | Notes |
|---|---|---|---|---|---|---|
| Playwright MCP | 1 | 8/8 | 71 | 56,128 | 17m17s | Stale accessibility-tree refs caused false-negative errors (action succeeded, tool reported failure) repeatedly. Step 8 timing: reported ~16.5s (overestimate vs. true ~5s — measured across tool round-trips, not in-page). |
| Playwright MCP | 2 | 8/8 | 68 | 93,802 | 12m20s | Cart pre-populated at start (cross-run contamination). Used `Read` on a screenshot once, violating its own tool restriction. Step 8: discarded a noisy 22.6s reading, landed on accurate ~5.03s via in-page `performance.now()`. |
| Playwright MCP | 3 | 8/8 | 76 | 56,992 | 14m01s | Heaviest contamination symptoms of the 3 (pre-populated cart, unexplained sort-order change, spontaneous logout); had to clear localStorage/cookies mid-run. Step 8: discarded noisy 11.4s, landed on accurate ~5.0s. |
| **Playwright avg** | | **8/8** | **71.7** | **68,974** | **~14.5m** | |
| Chrome DevTools MCP | 1 | 8/8 | 44 | 53,649 | 9m10s | Fewest tool calls of any run. Several tool-reported "not interactive" timeouts were false negatives (action had already succeeded). Step 8: no single clean measurement — reported ~10-13s, a 2x overestimate vs. true ~5s. |
| Chrome DevTools MCP | 2 | 8/8 | 58 | 98,380 | 17m14s | **Self-diagnosed cross-run contamination mid-run** (cart changing, spontaneous navigation) and proactively switched to an isolated browser context to redo cleanly — best reliability behavior observed across all 9 runs. Step 8: clean 4.45s measurement via Navigation Timing API, closest to answer key of any run. |
| Chrome DevTools MCP | 3 | 8/8 | 104 | 80,562 | 25m09s | Longest wall-clock of any run — discovered an extra tab from a concurrent run mid-step-7 and had to defensively pin/re-verify the correct page after every subsequent action. Step 8: discarded noisy 16-18s, landed on accurate ~5.0s. |
| **Chrome DevTools avg** | | **8/8** | **68.7** | **77,530** | **~17.2m** | |
| Claude in Chrome | 1 | 8/8 | ~132 | 125,386 | 17m31s | Most tool calls of any run. Repeated stale element refs, autofill duplicating typed text, accidental navigations into product-detail pages, one accidental logout. Step 8: accurate 5.1s via JS timer. |
| Claude in Chrome | 2 | 8/8 | ~106 | 123,838 | 17m07s | Autofill pre-filled checkout fields (benign here). Correctly withheld a step-8-adjacent finding it suspected was session bleed-through rather than a real bug — good calibration. Step 8: accurate 5.0s. |
| Claude in Chrome | 3 | 8/8 | ~135 | 146,391 | 14m46s | Highest token usage of any run. Autofill actively overwrote typed username, causing a real login failure, until it switched to `form_input` to bypass autofill. Step 8: only a bounded 14-17s estimate (polling interval too coarse), a 3x overestimate vs. true ~5s. |
| **Claude in Chrome avg** | | **8/8** | **~124.3** | **131,872** | **~16.5m** | |

\* All 9 runs correctly answered steps 2 and 6 (exact match to answer key: Fleece Jacket $49.99 / Backpack $29.99 / Bolt T-Shirt $15.99; totals $39.98 / $3.20 / $43.18) and step 7 (correctly identified the identical-image bug across all products). Step 8 was graded on the answer key's qualitative bar ("flag the slowdown, not just that it worked") — all 9 passed that bar, but precision varied a lot (see Notes): several runs initially measured a noisy 11-22s figure across tool-call round-trips and correctly self-corrected to a clean in-page ~5s measurement; three runs (Playwright 1, Chrome DevTools 1, Claude in Chrome 3) reported a final answer 2-3x higher than the true ~5s because they measured latency across tool calls instead of in-page.

## Verdict

**What the data actually supports:**

- **Correctness ties across all three tools.** All 9 runs scored 8/8 — none missed the image bug, none missed the totals, none glossed over the performance delay. This scenario doesn't differentiate tools on correctness.
- **Claude in Chrome is the costliest tool, for a real reason, not a contamination artifact.** It used roughly 2x the tokens of the other two on average (~132k vs ~69-78k) and the most tool calls (~124 avg vs ~69-72). Its overhead traces to running in a real, logged-in Chrome profile: autofill repeatedly duplicated/overwrote typed text and once fed a stale username into a login form, actively causing a task failure that had to be worked around with `form_input`. That's an intrinsic property of automating a real browser profile, not something a clean re-run would erase.
- **Chrome DevTools MCP vs Playwright MCP is genuinely undecided from this run — not "roughly tied," actually unmeasured.** Their tool-call/token gap (68.7 vs 71.7 calls, 77.5k vs 69.0k tokens) falls well inside the noise created by running all 9 agents in parallel and sharing browser state (see methodology note above). Worse, the one apparent differentiator — Chrome DevTools run 2 self-diagnosing contention and recovering via `isolatedContext` — is circular evidence: that feature only got exercised *because* the parallel-execution harness created the contamination in the first place. A sequential run has no contention to detect, so that "reliability edge" would likely never surface at all. It should not be used to justify a default.

**No default recommendation between Chrome DevTools MCP and Playwright MCP yet.** That comparison needs a clean sequential re-run (one tool fully finishing before the next starts, no shared browser contention) before it can support a "reach for this by default" claim — tracked as an open item in `plan.md`.

**Where Claude in Chrome earns its cost**: tasks that require a real authenticated browser profile/session (things a clean headless context can't do), or bugs that are only detectable visually and not via the DOM. This scenario's image bug happened to be DOM-detectable via identical `img.src`, so Claude in Chrome's vision advantage was never actually exercised here — a genuinely pixel-only bug (e.g. a CSS layout overlap with no DOM signal) would be a fairer test of that strength.
