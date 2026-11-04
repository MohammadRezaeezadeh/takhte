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

/// Picks [card], then plays until White's next roll and returns that roll for
/// many seeds.
List<GameState> nextOwnRolls(String card) {
  var s = pickOnly(sevenState(Board.initial(), [card], config: noSeven));
  s = finishCurrentTurn(roll(s));
  s = finishCurrentTurn(roll(s));
  expect(s.current, Side.white);
  return [
    for (var seed = 0; seed < 120; seed++)
      roll(s.copyWith(rng: Rng.seeded(seed).state)),
  ];
}

void main() {
  test('Even Odds: all dice even', () {
    for (final r in nextOwnRolls(CardId.evenOdds)) {
      expect(r.rolled.every((d) => d.isEven), isTrue);
    }
  });

  test('Ward of Ones rerolls ones (rarer ones)', () {
    final ones = nextOwnRolls(CardId.wardOnes)
        .expand((r) => r.rolled)
        .where((d) => d == 1)
        .length;
    expect(ones, lessThan(30));
  });

  test('Twin Dice guarantees 6-6', () {
    for (final r in nextOwnRolls(CardId.twinDice)) {
      expect(r.dice.length, 4);
      expect(r.dice.first, 6);
    }
  });

  test('Royal Roll: dice at least 3', () {
    for (final r in nextOwnRolls(CardId.royalRoll)) {
      expect(r.rolled.every((d) => d >= 3), isTrue);
    }
  });

  test('Silk Purse grants two rerolls', () {
    expect(
      pickOnly(sevenState(Board.initial(), [CardId.silkPurse], config: noSeven))
          .white
          .rerolls,
      2,
    );
  });

  test('Leaden Dice caps the opponent at 3', () {
    var s = pickOnly(
      sevenState(Board.initial(), [CardId.leadenDice], config: noSeven),
    );
    s = finishCurrentTurn(roll(s));
    for (var seed = 0; seed < 100; seed++) {
      expect(
        roll(s.copyWith(rng: Rng.seeded(seed).state)).rolled
            .every((d) => d <= 3),
        isTrue,
      );
    }
  });

  test('Shackle chains a single checker', () {
    final s = pickOnly(
      sevenState(Board.initial(), [CardId.shackle], config: noSeven),
      [1],
    );
    final e = s.effectsOf(EffectKind.chains).single;
    expect(e.count, 1);
    expect(e.turnsLeft, 4);
  });

  test('Pickpocket steals all rerolls or grants a lucky charm', () {
    var s = sevenState(Board.initial(), [CardId.pickpocket], config: noSeven);
    s = s.copyWith(black: s.black.copyWith(rerolls: 3));
    final a = pickOnly(s);
    expect(a.white.rerolls, 3);
    expect(a.black.rerolls, 0);
    final b = pickOnly(
      sevenState(Board.initial(), [CardId.pickpocket], config: noSeven),
    );
    expect(b.white.lucky, 1);
  });

  test('Hex of Sevens shrinks the next opponent offer', () {
    var s = pickOnly(
      sevenState(Board.initial(), [CardId.hexSevens], config: noSeven),
    );
    s = finishCurrentTurn(roll(s));
    final tx = Tx(s);
    CardLogic.dealOffer(tx, Side.black);
    expect(tx.offer.length, 2);
  });

  test('Sprint moves a checker exactly 4', () {
    final s = pickOnly(
      sevenState(Board.initial(), [CardId.sprint], config: noSeven),
      [13],
    );
    expect(s.board.count(Side.white, 9), 1);
    expect(s.board.count(Side.white, 13), 4);
  });

  test('Shield Wall protects every blot for one opponent turn', () {
    final board = Board.fromMaps(
      white: const {20: 1, 18: 1, 6: 13},
      black: const {8: 1, 1: 14},
    );
    final s = pickOnly(sevenState(board, [CardId.shieldWall], config: noSeven));
    expect(s.effectsOf(EffectKind.shield).length, 2);
  });

  test('Homecoming bears off one checker only when home', () {
    final home = Board.fromMaps(white: const {6: 5, 5: 5, 4: 5});
    expect(
      pickOnly(sevenState(home, [CardId.homecoming], config: noSeven)).board
          .borneOff(Side.white),
      1,
    );
    final tx = Tx(sevenState(Board.initial(), const [], config: noSeven));
    expect(CardLogic.isPlayable(tx, Side.white, CardId.homecoming), isFalse);
  });

  test('Rallying Cry re-enters all bar checkers', () {
    final board = Board.fromMaps(
      white: const {25: 2, 6: 13},
      black: const {1: 15},
    );
    final s = pickOnly(sevenState(board, [CardId.reentry], config: noSeven));
    expect(s.board.onBar(Side.white), 0);
    expect(s.board.validate(), isNull);
  });

  test(
    'Stone Skin, Caltrops and Bait place two shields, two tolls and a mine',
    () {
      final st = pickOnly(
        sevenState(Board.initial(), [CardId.stoneSkin], config: noSeven),
        [6, 8],
      );
      expect(st.effectsOf(EffectKind.shield).length, 2);
      final ca = pickOnly(
        sevenState(Board.initial(), [CardId.caltrops], config: noSeven),
        [15, 16],
      );
      expect(ca.effectsOf(EffectKind.toll).length, 2);
      final board = Board.fromMaps(
        white: const {20: 1, 6: 14},
        black: const {8: 1, 1: 14},
      );
      final ba = pickOnly(sevenState(board, [CardId.bait], config: noSeven), [
        20,
      ]);
      expect(ba.effectsOf(EffectKind.landmine).single.point, 20);
      // Black hits the bait with a 3 and goes to the bar too.
      final b = ba.copyWith(
        current: Side.black,
        turnNumber: 2,
        phase: Phase.moving,
        dice: [3],
        rolled: [3],
      );
      final hit = Engine.legalMoves(b).firstWhere((m) => m.hit);
      final after = Engine.apply(b, PlayMove(hit)).state;
      expect(after.board.onBar(Side.white), 1);
      expect(after.board.onBar(Side.black), 1);
    },
  );

  test('Rally rolls again when far behind, else a reroll', () {
    final behind = Board.fromMaps(white: const {24: 15}, black: const {6: 15});
    final a = pickOnly(sevenState(behind, [CardId.rally], config: noSeven));
    expect(a.rollQueue.length, 1);
    final b = pickOnly(
      sevenState(Board.initial(), [CardId.rally], config: noSeven),
    );
    expect(b.white.rerolls, 1);
  });

  test('Fortune Teller widens and Destiny doubles your next pick', () {
    final f = pickOnly(
      sevenState(Board.initial(), [CardId.fortuneTeller], config: noSeven),
    );
    final tx = Tx(f);
    CardLogic.dealOffer(tx, Side.white);
    expect(tx.offer.length, 5);
    final d = pickOnly(
      sevenState(Board.initial(), [CardId.destiny], config: noSeven),
    );
    final tx2 = Tx(d);
    CardLogic.dealOffer(tx2, Side.white);
    expect(tx2.picksLeft, 2);
  });

  test('High Stakes doubles the game value', () {
    expect(
      pickOnly(
        sevenState(Board.initial(), [CardId.highStakes], config: noSeven),
      ).cubeValue,
      2,
    );
  });

  test('Exile sends an enemy blot to the bar', () {
    final board = Board.fromMaps(
      white: const {6: 15},
      black: const {10: 1, 1: 14},
    );
    final s = pickOnly(sevenState(board, [CardId.exile], config: noSeven), [
      15,
    ]);
    expect(s.board.onBar(Side.black), 1);
    expect(s.board.validate(), isNull);
  });

  test('Oasis cleanses dice curses', () {
    var s = sevenState(Board.initial(), [CardId.oasis], config: noSeven);
    final tx = Tx(s)
      ..addEffect(
        EffectKind.curse,
        owner: Side.black,
        affected: Side.white,
        turns: 2,
      );
    s = pickOnly(tx.freeze());
    expect(s.effectsOf(EffectKind.curse), isEmpty);
  });

  test('Double Agent copies the opponent’s last untargeted card', () {
    var s = sevenState(Board.initial(), [CardId.doubleAgent], config: noSeven);
    s = s.copyWith(black: s.black.copyWith(cards: [CardId.silkPurse]));
    expect(pickOnly(s).white.rerolls, 2);
    final none = pickOnly(
      sevenState(Board.initial(), [CardId.doubleAgent], config: noSeven),
    );
    expect(none.white.rerolls, 1);
  });

  test('catalogue reaches 70 unique cards with unique art', () {
    expect(kCards.length, 70);
    expect(kCards.map((c) => c.glyph).toSet().length, kCards.length);
    for (final c in kCards) {
      expect(c.descFa, isNotEmpty);
    }
  });

  group('expansion 3', () {
    /// Picks [card] as White, ends White's turn and returns Black's next roll
    /// for many seeds.
    List<GameState> oppRolls(String card) {
      var s = pickOnly(sevenState(Board.initial(), [card], config: noSeven));
      s = finishCurrentTurn(roll(s));
      expect(s.current, Side.black);
      return [
        for (var seed = 0; seed < 120; seed++)
          roll(s.copyWith(rng: Rng.seeded(seed).state)),
      ];
    }

    test('Sandstorm: opponent dice max 4, doubles play as two', () {
      for (final r in oppRolls(CardId.sandstorm)) {
        expect(r.rolled.every((d) => d <= 4), isTrue);
        expect(r.dice.length, 2);
      }
    });

    test('Mountain Pass: opponent rolls one die, minus one', () {
      for (final r in oppRolls(CardId.mountainPass)) {
        expect(r.rolled.length, 1);
        expect(r.rolled.single, lessThanOrEqualTo(5));
      }
    });

    test('Mirage: opponent roll halved', () {
      for (final r in oppRolls(CardId.mirage)) {
        expect(r.rolled.every((d) => d <= 3), isTrue);
      }
    });

    test('Hailstorm: opponent dice minus one, no doubles', () {
      for (final r in oppRolls(CardId.hailstorm)) {
        expect(r.rolled.every((d) => d <= 5), isTrue);
        expect(r.dice.length, 2);
      }
    });

    test('Saffron Thread: next own roll is all even', () {
      for (final r in nextOwnRolls(CardId.saffron)) {
        expect(r.rolled.every((d) => d.isEven), isTrue);
      }
    });

    test('charge cards fill the inventory', () {
      final c = pickOnly(
        sevenState(Board.initial(), [CardId.caravan], config: noSeven),
      );
      expect(c.white.rerolls, 1);
      expect(c.white.lucky, 1);
      final w = pickOnly(
        sevenState(Board.initial(), [CardId.spiritWard], config: noSeven),
      );
      expect(w.white.phoenix, 1);
      expect(w.white.ghost, 1);
      final t = pickOnly(
        sevenState(Board.initial(), [CardId.treasury], config: noSeven),
      );
      expect(t.white.rerolls, 2);
      expect(t.white.phoenix, 1);
    });

    test('Star Reader: next offer is bigger and takes two', () {
      final s = pickOnly(
        sevenState(Board.initial(), [CardId.starReader], config: noSeven),
      );
      final tx = Tx(s);
      CardLogic.dealOffer(tx, Side.white);
      expect(tx.picksLeft, 2);
      expect(tx.offer.length, greaterThanOrEqualTo(4));
    });

    test('Sevenfold: magnet for me, hex on them', () {
      final s = pickOnly(
        sevenState(Board.initial(), [CardId.sevenfold], config: noSeven),
      );
      expect(s.effectsOf(EffectKind.sevenMagnet).single.affected, Side.white);
      expect(s.effectsOf(EffectKind.offerMalus).single.affected, Side.black);
    });
  });
}
