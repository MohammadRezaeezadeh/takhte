import 'package:haftnard/core/effects/card_logic.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rng/rng.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:test/test.dart';

import 'helpers.dart';

const noSeven = GameConfig(p7: 0);

GameState roll(GameState s) => Engine.apply(s, const RollDice()).state;

void main() {
  test('Twin Anchors gates two blots', () {
    final board = Board.fromMaps(
      white: const {20: 1, 18: 1, 6: 13},
      black: const {8: 1, 1: 14},
    );
    final s = pickOnly(
      sevenState(board, [CardId.twinAnchors], config: noSeven),
      [20, 18],
    );
    expect(s.effectsOf(EffectKind.ironGate).length, 2);
    final b = finishCurrentTurn(roll(s))
        .copyWith(phase: Phase.moving, dice: [3], rolled: [3]);
    // Black rel 8 -> rel 5 = abs 20 is gated.
    expect(Engine.legalMoves(b).any((m) => m.to == 5), isFalse);
  });

  test('Bazaar Bargain grants reroll and lucky', () {
    final s = pickOnly(
      sevenState(Board.initial(), [CardId.bargain], config: noSeven),
    );
    expect(s.white.rerolls, 1);
    expect(s.white.lucky, 1);
    expect(s.black.lucky, 1, reason: 'the bargain cuts both ways');
  });

  test('Hourglass Sand: capped and no doubles next opponent turn', () {
    var s = pickOnly(
      sevenState(Board.initial(), [CardId.hourglassSand], config: noSeven),
    );
    s = finishCurrentTurn(roll(s));
    for (var seed = 0; seed < 200; seed++) {
      final r = roll(s.copyWith(rng: Rng.seeded(seed).state));
      expect(r.rolled.every((d) => d <= 4), isTrue);
      expect(r.dice.length, 2);
    }
  });

  test("Simorgh's Blessing grants two phoenixes", () {
    final s = pickOnly(
      sevenState(Board.initial(), [CardId.simorgh], config: noSeven),
    );
    expect(s.white.phoenix, 2);
  });

  test('Nightfall blocks opponent sevens', () {
    const cfg = GameConfig(p7: 1);
    var s = pickOnly(
      sevenState(Board.initial(), [CardId.nightfall], config: cfg),
    );
    s = roll(s);
    expect(s.phase, Phase.moving, reason: 'own 7-7 already used this turn');
    s = finishCurrentTurn(s);
    expect(s.current, Side.black);
    s = roll(s);
    expect(s.phase, isNot(Phase.sevenPick));
  });

  test('Lantern of Truth clears enemy traps; unplayable without them', () {
    var s = sevenState(Board.initial(), [CardId.lantern], config: noSeven);
    final tx = Tx(s)
      ..addEffect(
        EffectKind.landmine,
        owner: Side.black,
        affected: Side.white,
        turns: 5,
        point: 15,
      )
      ..addEffect(
        EffectKind.toll,
        owner: Side.black,
        affected: Side.white,
        turns: 4,
        point: 16,
      );
    s = tx.freeze();
    s = pickOnly(s);
    expect(s.effectsOf(EffectKind.landmine), isEmpty);
    expect(s.effectsOf(EffectKind.toll), isEmpty);
    // Without traps the card is never offered.
    final s2 = preRollState(
      Board.initial(),
      config: const GameConfig(p7: 1, cardPool: [CardId.lantern, CardId.fog]),
    );
    expect(roll(s2).offer, [CardId.fog]);
  });

  test('Earthquake breaks chains on your checkers', () {
    var s = sevenState(Board.initial(), [CardId.earthquake], config: noSeven);
    final tx = Tx(s)
      ..addEffect(
        EffectKind.chains,
        owner: Side.black,
        affected: Side.white,
        turns: 2,
        point: 6,
        count: 2,
      );
    s = pickOnly(tx.freeze());
    expect(s.effectsOf(EffectKind.chains), isEmpty);
  });

  test('Lucky Six forces a 6 next turn', () {
    var s = pickOnly(
      sevenState(Board.initial(), [CardId.luckySix], config: noSeven),
    );
    s = finishCurrentTurn(roll(s));
    s = finishCurrentTurn(roll(s));
    expect(s.current, Side.white);
    for (var seed = 0; seed < 30; seed++) {
      final r = roll(s.copyWith(rng: Rng.seeded(seed).state));
      expect(r.rolled.first, 6);
    }
  });

  test('Vortex marks two points; Minefield hides two mines', () {
    final v = pickOnly(
      sevenState(Board.initial(), [CardId.vortex], config: noSeven),
      [15, 16],
    );
    expect(v.effectsOf(EffectKind.quicksand).map((e) => e.point).toSet(), {
      15,
      16,
    });
    final m = pickOnly(
      sevenState(Board.initial(), [CardId.minefield], config: noSeven),
      [16, 15],
    );
    expect(m.effectsOf(EffectKind.landmine).length, 2);
  });

  test('Truce prevents hits for both sides', () {
    final board = Board.fromMaps(
      white: const {20: 1, 10: 1, 6: 13},
      black: const {8: 1, 18: 1, 1: 13},
    );
    var s = pickOnly(sevenState(board, [CardId.truce], config: noSeven));
    // White's own turn: cannot hit black blot at black rel 18 = abs 7 (white rel 7) from 10 with a 3.
    final w = s.copyWith(phase: Phase.moving, dice: [3], rolled: [3]);
    expect(Engine.legalMoves(w).any((m) => m.hit), isFalse);
    s = finishCurrentTurn(roll(s));
    final b = s.copyWith(phase: Phase.moving, dice: [3], rolled: [3]);
    expect(Engine.legalMoves(b).any((m) => m.hit), isFalse);
  });

  test('Tailwind raises and Headwind lowers dice', () {
    var t = pickOnly(
      sevenState(Board.initial(), [CardId.tailwind], config: noSeven),
    );
    t = finishCurrentTurn(roll(t));
    t = finishCurrentTurn(roll(t));
    for (var seed = 0; seed < 100; seed++) {
      final r = roll(t.copyWith(rng: Rng.seeded(seed).state));
      expect(r.rolled.every((d) => d >= 2), isTrue);
    }
    var h = pickOnly(
      sevenState(Board.initial(), [CardId.headwind], config: noSeven),
    );
    h = finishCurrentTurn(roll(h));
    for (var seed = 0; seed < 100; seed++) {
      final r = roll(h.copyWith(rng: Rng.seeded(seed).state));
      expect(r.rolled.every((d) => d <= 5), isTrue);
    }
  });

  test('catalogue has unique cards with art indices', () {
    expect(kCards.length, greaterThanOrEqualTo(37));
    expect(kCards.map((c) => c.glyph).toSet().length, kCards.length);
  });

  test('start cards apply at the opening roll', () {
    var s = GameState.initial(
      const GameConfig(
        seed: 5,
        white: SideMods(startCards: [CardId.bargain, CardId.luckySix]),
        black: SideMods(startCards: [CardId.nightfall]),
      ),
    );
    while (s.phase == Phase.opening) {
      s = Engine.apply(s, const RollOpening()).state;
    }
    expect(s.white.rerolls, 1);
    expect(s.white.lucky, 1);
    expect(s.effectsOf(EffectKind.sixNext).single.owner, Side.white);
    expect(s.effectsOf(EffectKind.sevenBlock).single.affected, Side.white);
  });

  test('pick bonus lets a side take two cards', () {
    final s = preRollState(
      Board.initial(),
      config: const GameConfig(p7: 1, white: SideMods(pickBonus: 1)),
    );
    final r = roll(s);
    expect(r.picksLeft, 2);
  });

  test('Time Stop cannot chain', () {
    var s = pickOnly(
      sevenState(Board.initial(), [CardId.timeStop], config: noSeven),
    );
    s = finishCurrentTurn(roll(s));
    expect(s.current, Side.white, reason: 'extra turn');
    final tx = Tx(s);
    expect(CardLogic.isPlayable(tx, Side.white, CardId.timeStop), isFalse);
  });
}
