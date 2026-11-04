import 'package:haftnard/core/effects/card_logic.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rng/rng.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/events.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:test/test.dart';

import 'helpers.dart';

const noSeven = GameConfig(p7: 0);

GameState roll(GameState s) => Engine.apply(s, const RollDice()).state;

/// Finds an RNG state for which [pred] holds on the next roll of [s].
GameState withRoll(GameState s, bool Function(GameState) pred) {
  for (var seed = 0; seed < 5000; seed++) {
    final t = s.copyWith(rng: Rng.seeded(seed).state);
    final r = roll(t);
    if (pred(r)) return t;
  }
  throw StateError('no seed found');
}

void main() {
  test('every card has fa + en name and description', () {
    expect(kCards.length, greaterThanOrEqualTo(24));
    for (final c in kCards) {
      expect(c.nameEn, isNotEmpty);
      expect(c.nameFa, isNotEmpty);
      expect(c.descEn.length, greaterThan(10));
      expect(c.descFa.length, greaterThan(10));
      if (c.rarity == Rarity.legendary) {
        expect(c.drawbackEn, isNotNull, reason: '${c.id} needs a drawback');
        expect(c.drawbackFa, isNotNull);
      }
    }
    expect(kCards.map((c) => c.id).toSet().length, kCards.length);
  });

  group('seven event', () {
    test('7-7 never wastes a turn: after picking, a normal roll follows', () {
      const cfg = GameConfig(p7: 1);
      var s = preRollState(Board.initial(), config: cfg);
      s = roll(s);
      expect(s.phase, Phase.sevenPick);
      expect(s.rolled, [7, 7]);
      expect(s.offer.length, 3);
      s = advance(s, (x) => x.phase == Phase.preRoll);
      expect(s.current, Side.white);
      s = roll(s);
      expect(s.phase, anyOf(Phase.moving, Phase.chooseDice));
      expect(s.dice.every((d) => d >= 1 && d <= 6), isTrue);
    });

    test('classic mode never rolls 7-7', () {
      const cfg = GameConfig(mode: GameMode.classic, p7: 1);
      final s = roll(preRollState(Board.initial(), config: cfg));
      expect(s.phase, Phase.moving);
    });

    test('offers never contain duplicates and respect rarity odds', () {
      final counts = {for (final r in Rarity.values) r: 0};
      for (var seed = 0; seed < 1500; seed++) {
        final s = preRollState(
          Board.initial(),
          config: GameConfig(p7: 1, seed: seed),
        );
        final r = roll(s);
        expect(r.offer.toSet().length, r.offer.length);
        for (final c in r.offer) {
          counts[cardById(c).rarity] = counts[cardById(c).rarity]! + 1;
        }
      }
      final total = counts.values.fold<int>(0, (a, b) => a + b);
      expect(counts[Rarity.common]! / total, closeTo(0.6, 0.08));
      expect(counts[Rarity.legendary]! / total, lessThan(0.06));
    });

    test('pity raises the epic chance and resets', () {
      final tx = Tx(preRollState(Board.initial()));
      var sawHigh = false;
      for (var i = 0; i < 40; i++) {
        CardLogic.dealOffer(tx, Side.white);
        final high = tx.offer.any(
          (c) => cardById(c).rarity.index >= Rarity.epic.index,
        );
        if (high) {
          sawHigh = true;
          expect(tx.white.pity, 0);
        }
      }
      expect(sawHigh, isTrue);
    });

    test('card pool restriction is honoured', () {
      const cfg = GameConfig(
        p7: 1,
        cardPool: [CardId.fog, CardId.curse, CardId.brokenDie],
      );
      final s = roll(preRollState(Board.initial(), config: cfg));
      expect(s.offer.toSet(), {CardId.fog, CardId.curse, CardId.brokenDie});
    });
  });

  group('dice control', () {
    test('Loaded Hand: next turn rolls 3 and keeps 2', () {
      var s = pickOnly(
        sevenState(Board.initial(), [CardId.loadedHand], config: noSeven),
      );
      s = roll(s);
      expect(s.phase, Phase.moving, reason: 'not this turn');
      s = finishCurrentTurn(s);
      s = finishCurrentTurn(s);
      expect(s.current, Side.white);
      s = roll(s);
      expect(s.phase, Phase.chooseDice);
      expect(s.choiceDice.length, 3);
      final keep = [s.choiceDice[0], s.choiceDice[2]];
      s = Engine.apply(s, const ChooseDice(0, 2)).state;
      expect(s.phase, Phase.moving);
      expect(s.rolled, keep);
    });

    test('Double Down: two rolls this turn', () {
      var s = pickOnly(
        sevenState(Board.initial(), [CardId.doubleDown], config: noSeven),
      );
      s = roll(s);
      s = advance(
        s,
        (x) => x.phase == Phase.preRoll || x.current != Side.white,
      );
      expect(s.current, Side.white);
      expect(s.rollsThisTurn, 1);
      s = roll(s);
      expect(s.phase, Phase.moving);
      expect(s.rollsThisTurn, 2);
      s = finishCurrentTurn(s);
      expect(s.current, Side.black);
    });

    test("Fate's Edit: set a die next turn", () {
      var s = pickOnly(
        sevenState(Board.initial(), [CardId.fatesEdit], config: noSeven),
      );
      s = roll(s);
      expect(Engine.canSetFate(s), isFalse);
      s = finishCurrentTurn(s);
      s = finishCurrentTurn(s);
      s = withRoll(
        s,
        (r) => r.rolled.length == 2 && r.rolled[0] != r.rolled[1],
      );
      s = roll(s);
      expect(Engine.canSetFate(s), isTrue);
      final other = s.rolled[1];
      s = Engine.apply(s, const SetFate(0, 6)).state;
      expect(s.rolled, [6, other]);
      expect(Engine.canSetFate(s), isFalse);
    });

    test('Second Chance: reroll token', () {
      var s = pickOnly(
        sevenState(Board.initial(), [CardId.secondChance], config: noSeven),
      );
      expect(s.white.rerolls, 1);
      s = roll(s);
      s = Engine.apply(s, const UseReroll()).state;
      expect(s.white.rerolls, 0);
      expect(s.phase, Phase.moving);
      expect(
        () => Engine.apply(s, const UseReroll()),
        throwsA(isA<IllegalActionException>()),
      );
    });

    test('Lucky Charm: +1 to a die', () {
      var s = pickOnly(
        sevenState(Board.initial(), [CardId.luckyCharm], config: noSeven),
      );
      s = withRoll(s, (r) => r.dice.length == 2 && r.dice[0] < 6);
      s = roll(s);
      final before = s.dice[0];
      s = Engine.apply(s, const UseLucky(0)).state;
      expect(s.dice[0], before + 1);
      expect(s.white.lucky, 0);
    });

    test('Seven Magnet doubles p7 from the next turn', () {
      const cfg = GameConfig(p7: 0.5);
      var s = pickOnly(
        sevenState(Board.initial(), [CardId.sevenMagnet], config: cfg),
      );
      expect(s.effects.single.kind, EffectKind.sevenMagnet);
      // Next own turn: 0.5 * 2 = 1.0 so a 7-7 is guaranteed.
      s = roll(s);
      s = finishCurrentTurn(s);
      s = advance(
        s,
        (x) => x.current == Side.white && x.phase == Phase.preRoll,
      );
      s = roll(s);
      expect(s.phase, Phase.sevenPick);
    });
  });

  group('sabotage', () {
    test('Broken Die: opponent rolls one die', () {
      var s = pickOnly(
        sevenState(Board.initial(), [CardId.brokenDie], config: noSeven),
      );
      s = finishCurrentTurn(roll(s));
      expect(s.current, Side.black);
      s = roll(s);
      expect(s.rolled.length, 1);
      expect(s.dice.length, 1);
      s = finishCurrentTurn(s);
      s = finishCurrentTurn(roll(s));
      s = roll(s);
      expect(s.rolled.length, 2, reason: 'only one turn');
    });

    test('Chains: two enemy checkers cannot move for two turns', () {
      final board = Board.fromMaps(
        white: const {13: 15},
        black: const {24: 1, 13: 1, 6: 13},
      );
      // Black relative 24 = abs 1, black relative 13 = abs 12.
      var s = pickOnly(sevenState(board, [CardId.chains], config: noSeven), [
        1,
        12,
      ]);
      expect(s.effectsOf(EffectKind.chains).length, 2);
      s = finishCurrentTurn(roll(s));
      s = roll(s);
      for (final m in Engine.legalMoves(s)) {
        expect(m.from, isNot(anyOf(24, 13)));
      }
      s = finishCurrentTurn(s);
      s = finishCurrentTurn(roll(s));
      s = roll(s);
      for (final m in Engine.legalMoves(s)) {
        expect(m.from, isNot(anyOf(24, 13)));
      }
      s = finishCurrentTurn(s);
      expect(s.effectsOf(EffectKind.chains), isEmpty);
    });

    test('Fog: opponent doubles play as two dice', () {
      var s = pickOnly(
        sevenState(Board.initial(), [CardId.fog], config: noSeven),
      );
      s = finishCurrentTurn(roll(s));
      s = withRoll(
        s,
        (r) => r.rolled.length == 2 && r.rolled[0] == r.rolled[1],
      );
      s = roll(s);
      expect(s.dice.length, 2);
    });

    test('Curse: opponent dice capped at 4', () {
      var s = pickOnly(
        sevenState(Board.initial(), [CardId.curse], config: noSeven),
      );
      s = finishCurrentTurn(roll(s));
      for (var seed = 0; seed < 200; seed++) {
        final r = roll(s.copyWith(rng: Rng.seeded(seed).state));
        expect(r.rolled.every((d) => d <= 4), isTrue);
      }
    });

    test('Mirror: opponent roll becomes my bonus roll', () {
      var s = pickOnly(
        sevenState(Board.initial(), [CardId.mirror], config: noSeven),
      );
      s = finishCurrentTurn(roll(s));
      s = roll(s);
      final copied = List.of(s.rolled);
      s = finishCurrentTurn(s);
      s = roll(s);
      s = advance(s, (x) => x.rollsThisTurn == 2 || x.current != Side.white);
      expect(s.current, Side.white);
      expect(s.rolled, copied);
    });

    test('Thief steals a stored charge, or grants a reroll', () {
      var s = sevenState(Board.initial(), [CardId.thief], config: noSeven);
      s = s.copyWith(black: s.black.copyWith(phoenix: 1));
      final a = pickOnly(s);
      expect(a.white.phoenix, 1);
      expect(a.black.phoenix, 0);
      final b = pickOnly(
        sevenState(Board.initial(), [CardId.thief], config: noSeven),
      );
      expect(b.white.rerolls, 1);
    });
  });

  group('checker powers', () {
    test('Holy Shield: shielded blot cannot be hit', () {
      // White blot abs 20 = black relative 5. Black checker on black rel 8
      // hits it with a 3.
      final board = Board.fromMaps(
        white: const {20: 1, 6: 14},
        black: const {8: 1, 1: 14},
      );
      final control = movingState(board, [3], side: Side.black);
      expect(Engine.legalMoves(control).any((m) => m.to == 5 && m.hit), isTrue);
      var s = pickOnly(
        sevenState(board, [CardId.holyShield], config: noSeven),
        [20],
      );
      expect(s.effectsOf(EffectKind.shield).single.point, 20);
      s = finishCurrentTurn(roll(s));
      expect(s.current, Side.black);
      s = s.copyWith(phase: Phase.moving, dice: [3], rolled: [3]);
      expect(Engine.legalMoves(s).any((m) => m.to == 5), isFalse);
    });

    test('Holy Shield follows its checker and expires', () {
      final board = Board.fromMaps(
        white: const {20: 1, 6: 14},
        black: const {8: 1, 1: 14},
      );
      var s = pickOnly(
        sevenState(board, [CardId.holyShield], config: noSeven),
        [20],
      );
      s = s.copyWith(phase: Phase.moving, dice: [2], rolled: [2]);
      s = Engine.apply(s, const PlayMove(Move(20, 18, 2))).state;
      expect(s.effectsOf(EffectKind.shield).single.point, 18);
    });

    test('Iron Gate: a lone checker blocks', () {
      final board = Board.fromMaps(
        white: const {20: 1, 6: 14},
        black: const {8: 1, 1: 14},
      );
      var s = pickOnly(sevenState(board, [CardId.ironGate], config: noSeven), [
        20,
      ]);
      s = finishCurrentTurn(roll(s));
      s = s.copyWith(phase: Phase.moving, dice: [3], rolled: [3]);
      expect(Engine.legalMoves(s).any((m) => m.to == 5), isFalse);
    });

    test('Ghost Step: a blocked landing glides to the next open point', () {
      final board = Board.fromMaps(
        white: const {10: 1, 1: 14},
        black: const {25 - 7: 2, 25 - 6: 2, 24: 11},
      );
      var s = pickOnly(sevenState(board, [CardId.ghostStep], config: noSeven));
      expect(s.white.ghost, 1);
      s = s.copyWith(phase: Phase.moving, dice: [3], rolled: [3]);
      final ghost = Engine.legalMoves(s).where((m) => m.ghost).toList();
      expect(ghost.single.to, 5);
      s = Engine.apply(s, PlayMove(ghost.single)).state;
      expect(s.board.count(Side.white, 5), 1);
      expect(s.white.ghost, 0);
    });

    test('Phoenix: hit checker re-enters immediately', () {
      // White blot abs 5 = black rel 20; black checker on rel 23 hits with 3.
      final board = Board.fromMaps(
        white: const {5: 1, 6: 14},
        black: const {23: 1, 1: 14},
      );
      var s = pickOnly(sevenState(board, [CardId.phoenix], config: noSeven));
      s = finishCurrentTurn(roll(s));
      s = s.copyWith(phase: Phase.moving, dice: [3], rolled: [3]);
      final hit = Engine.legalMoves(s).firstWhere((m) => m.hit);
      final r = Engine.apply(s, PlayMove(hit));
      expect(r.state.board.onBar(Side.white), 0);
      expect(r.events.whereType<PhoenixRose>(), isNotEmpty);
      expect(r.state.white.phoenix, 0);
      expect(r.state.board.validate(), isNull);
    });

    test('Teleport: move a checker up to 3 pips outside the dice', () {
      var s = sevenState(Board.initial(), [CardId.teleport], config: noSeven);
      s = pickOnly(s, [24, 21]);
      expect(s.board.count(Side.white, 24), 1);
      expect(s.board.count(Side.white, 21), 1);
      expect(s.phase, Phase.preRoll);
    });
  });

  group('traps', () {
    test('Landmine: enemy landing goes to the bar', () {
      final board = Board.fromMaps(
        white: const {6: 15},
        black: const {10: 1, 6: 14},
      );
      // Black relative 7 = abs 18 (empty). Black on rel 10 moving 3 lands there.
      var s = pickOnly(sevenState(board, [CardId.landmine], config: noSeven), [
        18,
      ]);
      s = finishCurrentTurn(roll(s));
      s = s.copyWith(phase: Phase.moving, dice: [3], rolled: [3]);
      final m = Engine.legalMoves(s)
          .firstWhere((m) => m.from == 10 && m.to == 7);
      final r = Engine.apply(s, PlayMove(m));
      expect(r.state.board.onBar(Side.black), 1);
      expect(r.events.whereType<MineTriggered>(), isNotEmpty);
      expect(r.state.effectsOf(EffectKind.landmine), isEmpty);
    });

    test('Quicksand: enemy checkers on the point are stuck one turn', () {
      final board = Board.fromMaps(
        white: const {6: 15},
        black: const {13: 3, 6: 12},
      );
      // Black rel 13 = abs 12.
      var s = pickOnly(sevenState(board, [CardId.quicksand], config: noSeven), [
        12,
      ]);
      s = finishCurrentTurn(roll(s));
      expect(s.effectsOf(EffectKind.quicksandFreeze), isNotEmpty);
      s = roll(s);
      expect(Engine.legalMoves(s).any((m) => m.from == 13), isFalse);
    });

    test('Toll Gate: crossing costs one extra pip', () {
      final board = Board.fromMaps(
        white: const {6: 15},
        black: const {13: 1, 6: 14},
      );
      // Black rel 11 = abs 14. Black moving 13 -> with a 4 crosses 11.
      var s = pickOnly(sevenState(board, [CardId.tollGate], config: noSeven), [
        14,
      ]);
      s = finishCurrentTurn(roll(s));
      s = s.copyWith(phase: Phase.moving, dice: [4], rolled: [4]);
      final m = Engine.legalMoves(s).firstWhere((m) => m.from == 13);
      expect(m.to, 10);
    });
  });

  group('tempo', () {
    test('Time Stop: extra turn, opponent gets an extra pick', () {
      var s = pickOnly(
        sevenState(Board.initial(), [CardId.timeStop], config: noSeven),
      );
      s = finishCurrentTurn(roll(s));
      expect(s.current, Side.white, reason: 'extra turn');
      expect(s.effectsOf(EffectKind.bonusPick).single.affected, Side.black);
      s = finishCurrentTurn(roll(s));
      expect(s.current, Side.black);
      // Force the black 7-7.
      final tx = Tx(s);
      CardLogic.dealOffer(tx, Side.black);
      expect(tx.picksLeft, 2);
    });

    test('Blood Pact bears off two when home', () {
      final board = Board.fromMaps(white: const {6: 5, 5: 5, 1: 5});
      final s = pickOnly(
        sevenState(board, [CardId.bloodPact], config: noSeven),
      );
      expect(s.board.borneOff(Side.white), 2);
      expect(s.board.count(Side.white, 6), 3);
    });

    test('Blood Pact sends a checker to the bar otherwise', () {
      final s = pickOnly(
        sevenState(Board.initial(), [CardId.bloodPact], config: noSeven),
      );
      expect(s.board.onBar(Side.white), 1);
      expect(s.board.count(Side.white, 6), 4);
    });

    test('Blood Pact can win the game', () {
      final board = Board.fromMaps(white: const {2: 1, 1: 1});
      final s = pickOnly(
        sevenState(board, [CardId.bloodPact], config: noSeven),
      );
      expect(s.isOver, isTrue);
      expect(s.result!.winner, Side.white);
    });

    test("Gambler's Coin: someone skips a turn", () {
      for (var seed = 0; seed < 10; seed++) {
        var s = sevenState(Board.initial(), [
          CardId.gamblersCoin,
        ], config: noSeven).copyWith(rng: Rng.seeded(seed).state);
        final r = Engine.apply(s, const PickCard(0));
        final flip = r.events.whereType<CoinFlipped>().single;
        s = finishCurrentTurn(roll(r.state));
        if (flip.ownerWins) {
          expect(s.current, Side.white, reason: 'black skipped');
        } else {
          expect(s.current, Side.black);
          s = finishCurrentTurn(roll(s));
          expect(s.current, Side.black, reason: 'white skipped');
        }
      }
    });

    test('Greed: coins stack, opponent offer grows', () {
      var s = pickOnly(
        sevenState(Board.initial(), [CardId.greed], config: noSeven),
      );
      expect(s.white.greed, 1);
      s = finishCurrentTurn(roll(s));
      final tx = Tx(s);
      CardLogic.dealOffer(tx, Side.black);
      expect(tx.offer.length, 4);
    });
  });

  test('every card can be picked from the opening position without errors', () {
    for (final c in kCards) {
      var s = sevenState(Board.initial(), [c.id], config: noSeven);
      s = Engine.apply(s, const PickCard(0)).state;
      if (s.phase == Phase.cardTarget) {
        final t = Engine.legalActions(s).first;
        s = Engine.apply(s, t).state;
      }
      expect(s.board.validate(), isNull, reason: c.id);
      expect(s.phase, anyOf(Phase.preRoll, Phase.gameOver), reason: c.id);
    }
  });
}
