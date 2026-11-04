# Double Seven frequency (pity system)

Odds live in `lib/core/rules/seven_odds.dart`: a 5% base per own turn, flat for the first 9 dry turns, then a steep ramp; the 12th dry own turn in a row is certain. Card and talisman multipliers scale the chance; Seven Block forces 0.

| Measure (simulator, AI vs AI, all cards) | Value |
| --- | --- |
| 7–7 per game (both players) | 6.6 |
| 7–7 per player per game | **3.3** |
| Longest drought (30-game engine test) | ≤ 11 dry own turns |
| Seven mode: average game length | 71 turns (~36 own turns per player) |

A guarantee on the 12th turn caps every drought at 12, so with ~36 own turns per game the average can't fall below ~3 per player. 3.3 is the closest to the 2–3 target the guarantee allows (an 8% base would give ~5).

## Rebalance under the new frequency

Full forced-pick run: `docs/balance/report.md` (300 games per card). Its one flag, Rallying Cry at +9.5%, is picked only 0.88× per game; re-measured at 1,200 games:

| Card | Picks/game | Lift per pick |
| --- | --- | --- |
| Shackle | 3.63 | +7.7% |
| Rallying Cry | 0.88 | +7.6% |
| Exile | 2.71 | +7.1% |
| Homecoming | 0.64 | +5.2% |

Every card is within +8% per pick; no retune needed.
