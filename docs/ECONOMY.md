# Economy

Offline soft economy. No real money. Purchases go through the
`PurchaseProvider` interface (`lib/meta/purchase.dart`) so Google Play Billing
can be plugged in later without touching the UI.

## Currencies
* **Coins** — earned by playing.
* **Gems** — earned from level-ups (5 per level, 20 every 5th) and achievements (5–30).

## Earning (per game)
| Result | Coins (× difficulty) |
| --- | --- |
| Win | 30 + 12 × points |
| Loss | 10 |
| Match win (length L > 1) | +25 × L |
| Greed card (per stack, on win) | +40 |
| Daily bonus | +100 / day |

Difficulty multipliers: Beginner 0.6, Easy 0.8, Medium 1.0, Hard 1.3,
Master 1.7, Pass & Play 0.5.

XP per game: 40, +40 + 10 × min(points, 6) on a win. Level n → n+1 needs
250 + 150 × (n − 1) XP.

## Prices
| Category | Coins | Gems (premium) |
| --- | --- | --- |
| Boards | 900–1600 | 60–70 |
| Environments | 1200–1800 | 50–55 |
| Checkers | 500–950 | 40–60 |
| Dice | 350–900 | 35 |
| Card backs / frames | 400–700 | 30 |
| Victory effects | 800–1000 | 45 |
| Emotes | 150–250 | 15 |

Bundles are ~20% cheaper than their parts. The **Daily Shop** shows four
affordable, unlocked, unowned items at 25% off, seeded by the date.

## Pacing targets
* A Medium win ≈ 42 coins; ~25 games (≈ 3–4 hours) buys a premium board.
* Level 5 (≈ 1600 XP ≈ 20 games) unlocks most cosmetics and the last cards.

## Journey economy
Run coins: 25 + 10 × points + 5 × stage per win (talismans add more).
Shop: talismans 45–120, banish 30, wider offers 85 (+40 each), luck 60 (+30 each).
On run end you keep 40% of run coins (100% if you complete it) + 20 per stage
reached + 300 for completing the journey.
