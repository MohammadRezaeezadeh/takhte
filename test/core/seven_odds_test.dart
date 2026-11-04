import 'package:haftnard/core/ai/ai.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/rng/rng.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/seven_odds.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:test/test.dart';

import 'helpers.dart';

GameState roll(GameState s) => Engine.apply(s, const RollDice()).state;

void main() {
  test('odds curve: flat base, rising ramp, certain on the 12th dry turn', () {
    for (var d = 0; d < SevenOdds.rampStart; d++) {
      expect(SevenOdds.chance(d), SevenOdds.base);
    }
    var prev = 0.0;
    for (var d = 0; d < SevenOdds.guaranteeTurn; d++) {
      final c = SevenOdds.chance(d);
      expect(c, greaterThanOrEqualTo(prev));
      prev = c;
    }
    expect(SevenOdds.chance(SevenOdds.guaranteeTurn - 1), 1);
    expect(SevenOdds.chance(0, base: 0), 0);
  });

  test('a dry streak is guaranteed to end by the 12th own turn', () {
    var s = preRollState(Board.initial());
    s = s.copyWith(white: s.white.copyWith(dry: SevenOdds.guaranteeTurn - 1));
    for (var seed = 0; seed < 50; seed++) {
      final r = roll(s.copyWith(rng: Rng.seeded(seed).state));
      expect(r.rolled, [7, 7]);
      expect(r.white.dry, 0);
      expect(r.white.sevens, 1);
    }
  });

  test('a dry turn grows the streak; bonus rolls do not count', () {
    final s = preRollState(Board.initial(), config: const GameConfig(p7: 0));
    final r = roll(s);
    expect(r.white.dry, 1);
  });

  test('Seven Block still wins over the guarantee', () {
    var s = preRollState(Board.initial());
    s = s.copyWith(
      white: s.white.copyWith(dry: 20),
      effects: [
        const ActiveEffect(
          id: 1,
          kind: EffectKind.sevenBlock,
          owner: Side.black,
          affected: Side.white,
          turnsLeft: 2,
          createdTurn: 0,
        ),
      ],
    );
    for (var seed = 0; seed < 50; seed++) {
      final r = roll(s.copyWith(rng: Rng.seeded(seed).state));
      expect(r.rolled, isNot([7, 7]));
    }
  });

  test('talisman multipliers still scale the chance', () {
    int sevens(double mult) {
      var n = 0;
      for (var seed = 0; seed < 4000; seed++) {
        final s = preRollState(
          Board.initial(),
          config: GameConfig(white: SideMods(p7Multiplier: mult)),
        ).copyWith(rng: Rng.seeded(seed).state);
        if (roll(s).rolled.first == 7) n++;
      }
      return n;
    }

    final plain = sevens(1);
    expect(plain / 4000, closeTo(SevenOdds.base, 0.015));
    expect(sevens(2), greaterThan(plain * 1.6));
    expect(sevens(0.5), lessThan(plain * 0.7));
  });

  test('classic mode never rolls 7-7, even after long droughts', () {
    var s = preRollState(
      Board.initial(),
      config: const GameConfig(mode: GameMode.classic),
    );
    s = s.copyWith(white: s.white.copyWith(dry: 30));
    for (var seed = 0; seed < 30; seed++) {
      expect(
        roll(s.copyWith(rng: Rng.seeded(seed).state)).rolled.first,
        isNot(7),
      );
    }
  });

  test('legacy saves keep their original odds (no pity)', () {
    final legacy = GameConfig.fromJson({'mode': 'seven', 'seed': 3});
    expect(legacy.sevenPity, isFalse);
    expect(legacy.p7, closeTo(1 / 36, 1e-12));
    final now = GameConfig.fromJson(const GameConfig(seed: 3).toJson());
    expect(now.sevenPity, isTrue);
    expect(now.p7, SevenOdds.base);
    final m = MatchConfig.fromJson({'mode': 'seven', 'length': 1, 'seed': 1});
    expect(m.sevenPity, isFalse);
    expect(
      MatchConfig.fromJson(const MatchConfig().toJson()).sevenPity,
      isTrue,
    );
  });

  test('in real games nobody waits more than 11 own turns', () {
    var maxDry = 0;
    var sevens = 0;
    for (var g = 0; g < 30; g++) {
      var s = GameState.initial(GameConfig(seed: 500 + g, cardPool: const []));
      final brains = {
        for (final side in Side.values)
          side: AiBrain(AiConfig(difficulty: Difficulty.easy, seed: g)),
      };
      var guard = 0;
      while (!s.isOver && guard++ < 3000) {
        for (final a in brains[Engine.actor(s)]!.decide(s)) {
          if (s.isOver) break;
          if (a is PlayMove && !Engine.legalMoves(s).contains(a.move)) break;
          if (a is EndTurn && !Engine.canEndTurn(s)) break;
          s = Engine.apply(s, a).state;
          for (final inv in [s.white, s.black]) {
            if (inv.dry > maxDry) maxDry = inv.dry;
          }
        }
      }
      sevens += s.white.sevens + s.black.sevens;
    }
    expect(maxDry, lessThan(SevenOdds.guaranteeTurn));
    expect(sevens / 60, inInclusiveRange(2.0, 4.5));
  });
}
