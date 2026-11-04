# Progress

_Resume here: read this file and `DECISIONS.md` first._

## Status
Milestones M0–M8 are implemented in code; the endless-improvement loop has begun.
All work lives on branch `claude/vibrant-newton-gzwmx2`.

| Milestone | State |
| --- | --- |
| M0 scaffold, lints, CI (APK + AAB + release on tags), docs | done |
| M1 pure rules engine, seeded RNG, replay log, exhaustive tests | done |
| M2 playable Flame board, human vs human, juice | done |
| M3 AI (5 tiers, 5 personalities) in an isolate | done |
| M4 7–7 system, 24 cards, effect hooks, per-card tests, simulator, balance pass | done (tuning continues) |
| M5 UI shell, settings, fa/en + RTL, tutorials, save/resume | done |
| M6 9 boards, 7 environments, 9 checkers, 7 dice, card backs/frames, victory FX, emotes, store, locker, economy | done |
| M7 Journey: map, bosses, talismans, run shop, daily seed | done |
| M8 progression, achievements, stats, icon, splash, release config | done |

## Verification
* `flutter analyze` — 0 issues.
* `flutter test` — rules, reference move generator (2,500 random positions +
  completeness check), fuzzed games, replay determinism, every card, AI legality,
  match/Crawford, controller (undo/resume), meta/economy/save migration, journey,
  screen smoke tests in en/fa, tap-to-move integration test.
* `test/visual/*` can write screenshots (`--dart-define=SHOT_OUT=dir` / `ART_OUT=dir`).

## Known issues / environment notes
* Pushing from the authoring session failed with HTTP 403 (the Claude GitHub App
  lacked write access to the repository). Commits are local until access is fixed.
* No physical device was available: performance on mid-range Android is designed
  for (cached pictures/images, isolate AI, particle caps) but not profiled on device.

## Next
See `BACKLOG.md`.
