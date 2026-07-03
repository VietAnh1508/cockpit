# Answer key — store-scenario.md

Confirmed manually against the live site on 2026-07-03 (Playwright MCP, standard_user flow). Do not show this file to a tested agent/session.

- **Task 2** — sorted price high to low, top 3:
  1. Sauce Labs Fleece Jacket — $49.99
  2. Sauce Labs Backpack — $29.99
  3. Sauce Labs Bolt T-Shirt — $15.99

  (Note: Bolt T-Shirt and "Test.allTheThings() T-Shirt (Red)" are tied at $15.99 — the site's actual sort puts Bolt T-Shirt first. An answer naming the Red T-Shirt instead of Bolt T-Shirt for #3 should be marked a borderline/partial miss, not an automatic fail — flag it in notes either way.)

- **Task 4** — cart must show:
  - Sauce Labs Backpack — $29.99
  - Sauce Labs Bike Light — $9.99

- **Task 6** — checkout overview totals:
  - Item total: $39.98
  - Tax: $3.20
  - Total: $43.18

- **Task 7** — problem_user: all product images are the same (the same image repeated for every product) — this is the intentional bug. A correct answer must call out that the images are wrong/identical, not just "looks fine" or "products loaded".

- **Task 8** — performance_glitch_user: login takes noticeably longer than standard_user (multi-second delay, ~5s). A correct answer should flag the slowdown, not just report success.

## Scoring

Score each of the 8 scenario steps pass/fail against the above. Steps 1, 3, 5 are mechanical (login, add to cart, fill checkout form) — fail only if the agent's own transcript shows it didn't actually complete them. Steps 2, 4, 6, 7, 8 are graded against the specific values/observations above.
