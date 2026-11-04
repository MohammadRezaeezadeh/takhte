# Progress

_Resume here: read this file and `DECISIONS.md` first._

## Status
Milestones M0–M8 are complete; the endless-improvement loop is running.
All work lives on branch `claude/vibrant-newton-gzwmx2`.

| Milestone | State |
| --- | --- |
| M0 scaffold, lints, CI (APK + split APKs + AAB, release on tags), docs | done |
| M1 pure rules engine, seeded RNG, replay log, exhaustive tests | done |
| M2 playable Flame board, human vs human, juice | done |
| M3 AI (5 tiers, 5 personalities) in an isolate | done |
| M4 7–7 system, effect hooks, per-card tests, simulator, balance passes | done |
| M5 UI shell, settings, fa/en + RTL, tutorials, save/resume | done |
| M6 9 boards, 7 environments, 9 checkers, 7 dice, backs/frames, victory FX, emotes, store, locker, economy | done |
| M7 Journey: map, 15 bosses, 60 talismans, run shop, daily seed | done |
| M8 progression, achievements, stats, icon, splash, release build | done |

## Content counts
* Cards: **60** (target 60+) · Talismans: **40** (target 40+) · Bosses: 14 + final.
* Boards 9 · Environments 7 · Checkers 9 · Dice 7 · Card backs 4 · Frames 3 ·
  Victory effects 4 · Emotes 8 · Bundles 3 · Achievements 33 · Tips 14 ·
  Music loops 2 · SFX 21.
* Journey shop: talismans, banish, attune (card upgrade), wider offers, luck.

## Verification
* `tool/check.sh` mirrors CI: format gate, `flutter analyze --fatal-infos`, tests.
* `flutter test` — 179 tests (rules, reference movegen, fuzz, every card, AI,
  controller, meta, journey, UI flows, full AI-vs-AI match through the real UI).
* Coverage: rules 95%, core 97%, overall ≈74%.
* Local `flutter build apk --release` succeeds (universal APK ≈55 MB; CI also
  produces per-ABI APKs ≈20 MB).
* Balance: `docs/balance/report.md` (forced-pick methodology with an inert-card
  baseline; every measurable card ≤ +5% win rate per pick, target ≤ +8%).
* Screenshots: `flutter test test/visual/screens_test.dart --dart-define=SHOT_OUT=dir`.

## Known issues / environment notes
* Owner action (optional): set `main` as the default branch on GitHub.
* Branch pushes work; tag pushes from the session get 403, so CI makes releases.
* No physical device was available: performance targets are designed for
  (cached board pictures and checker images, isolate AI, memoised legal moves,
  pooled SFX, particle caps) but not profiled on hardware.

## Next
See `BACKLOG.md`.
