# Architecture

```
lib/
  core/            Pure Dart. No Flutter imports. Deterministic.
    rng/           xoshiro128** seeded RNG (32-bit math, golden-tested)
    rules/         Board, MoveGen, GameState, actions, events, Engine, records, match
    effects/       Card catalogue, card logic (targets/apply/offers), effect hooks
    ai/            Evaluator, expectiminimax AiBrain, personalities
    opponent.dart  Opponent interface (AiOpponent, LocalHumanOpponent)
  game/            Flame scene + match flow
    match_controller.dart   Applies actions, runs AI (isolate), undo, autosave hooks
    scene/                  BoardGame (FlameGame + MatchPresenter), fx, environments
    themes/                 Board themes, checker/dice art (all procedural)
    audio.dart              SFX/ambient/haptics (best effort)
  meta/            Profile, stats, achievements, economy, cosmetics, journey, save
  ui/              Flutter screens, HUD, overlays, widgets
  net/             RemoteOpponent placeholder (online seam)
tool/              simulate.dart (balance), gen_sfx.dart (audio synthesis)
```

## Rules engine
* `GameState` is immutable; `Engine.apply(state, action) → StepResult(state, events)`.
* A game is fully described by `GameConfig` (incl. seed) + `List<GameAction>`
  (`GameRecord`). Replays, autosave/resume and the future server all rely on this.
* `MoveGen` works on a mutable `TurnSim` (two 26-slot arrays in the mover's frame).
  It enforces "use as many dice as possible; otherwise the larger die" via a
  memoised DFS, and `allPlays` enumerates distinct full plays for the AI.
* Tested against an independent brute-force generator on thousands of random
  positions, plus fuzzed random games with invariant checks and JSON round-trips.

## Effects
Hooks per `EffectKind` (`onTurnStart`, `onBeforeRoll`, `onRoll`,
`onGenerateMoves` → `MoveContext`, `onMoveApplied`, `onHit`) with priorities.
Durations tick at the end of the *affected* side's turns. Non-immediate effects
activate on the turn after they were created. Stored charges (reroll, lucky,
ghost, phoenix) live in `SideInv`.

## Presentation
`MatchController` awaits `MatchPresenter.present(before, after, events)` so the
Flame scene can animate each event (arc moves, hits, dice tumble, 7–7 cinematic)
before the AI continues. After the event animations the scene reconciles to the
authoritative state (`resync`), so visuals can never drift from the rules.

## State management
Riverpod `NotifierProvider` (`metaProvider`) holds settings + profile snapshots;
the `SaveService` persists a versioned JSON file atomically. Per-match state is a
`ChangeNotifier` (`MatchController`) owned by the game screen.
