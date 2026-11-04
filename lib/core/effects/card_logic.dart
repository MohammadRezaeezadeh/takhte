import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/effects/effect_system.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/events.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';

/// Card behaviour: playability, targeting, application and offer dealing.
abstract final class CardLogic {
  /// Whether [card] can do something for [side] right now.
  static bool isPlayable(Tx tx, Side side, String card) {
    final def = cardById(card);
    if (def.target != TargetKind.none) {
      return allTargets(tx, side, card).isNotEmpty;
    }
    switch (card) {
      case CardId.timeStop:
        // No chaining: unavailable during the extra turn and while the
        // opponent's compensation from a previous Time Stop is pending.
        return !tx.extraTurn &&
            !tx.effects.any(
              (e) =>
                  e.kind == EffectKind.bonusPick && e.affected == side.opponent,
            );
      case CardId.lantern:
        return tx.effects.any(
          (e) =>
              e.owner == side.opponent &&
              (e.kind == EffectKind.landmine ||
                  e.kind == EffectKind.quicksand ||
                  e.kind == EffectKind.toll),
        );
      case CardId.earthquake:
        return tx.effects.any(
          (e) =>
              (e.affected == side &&
                  (e.kind == EffectKind.chains ||
                      e.kind == EffectKind.quicksandFreeze)) ||
              (e.owner == side.opponent &&
                  (e.kind == EffectKind.shield ||
                      e.kind == EffectKind.ironGate)),
        );
      case CardId.homecoming:
        return tx.board.allHome(side) && tx.board.borneOff(side) < Pos.checkers;
      case CardId.reentry:
        return tx.board.onBar(side) > 0;
      case CardId.oasis:
        return tx.effects.any((e) => e.affected == side && _isDiceCurse(e));
      default:
        return true;
    }
  }

  static bool _isDiceCurse(ActiveEffect e) =>
      e.owner != e.affected &&
      const {
        EffectKind.brokenDie,
        EffectKind.fog,
        EffectKind.curse,
        EffectKind.headwind,
        EffectKind.sevenBlock,
        EffectKind.skipTurn,
        EffectKind.mirrorWatch,
      }.contains(e.kind);

  /// All complete target lists for [card] (absolute points; 0 = bar).
  static List<List<int>> allTargets(Tx tx, Side side, String card) {
    final def = cardById(card);
    final opp = side.opponent;
    final board = tx.board;
    switch (def.target) {
      case TargetKind.none:
        return const [];
      case TargetKind.enemyCheckers2:
        final pts = <int, int>{};
        for (var abs = 1; abs <= 24; abs++) {
          final n = board.count(opp, toRelative(opp, abs));
          if (n > 0) pts[abs] = n;
        }
        final keys = pts.keys.toList();
        final out = <List<int>>[];
        for (var i = 0; i < keys.length; i++) {
          if (pts[keys[i]]! >= 2) out.add([keys[i], keys[i]]);
          for (var j = i + 1; j < keys.length; j++) {
            out.add([keys[i], keys[j]]);
          }
        }
        if (out.isEmpty && keys.length == 1) out.add([keys.first]);
        return out;
      case TargetKind.ownChecker:
        return [
          for (var abs = 1; abs <= 24; abs++)
            if (board.count(side, toRelative(side, abs)) > 0) [abs],
        ];
      case TargetKind.ownBlot:
        return [
          for (var abs = 1; abs <= 24; abs++)
            if (board.count(side, toRelative(side, abs)) == 1) [abs],
        ];
      case TargetKind.emptyPoint:
        final mined = {
          for (final e in tx.effects)
            if (e.kind == EffectKind.landmine) e.point,
        };
        return [
          for (var abs = 1; abs <= 24; abs++)
            if (board.atAbsolute(abs).$1 == null && !mined.contains(abs)) [abs],
        ];
      case TargetKind.enemyOrEmpty:
        return [
          for (var abs = 1; abs <= 24; abs++)
            if (board.atAbsolute(abs).$1 != side) [abs],
        ];
      case TargetKind.ownBlot2:
        return _pairs([
          for (var abs = 1; abs <= 24; abs++)
            if (board.count(side, toRelative(side, abs)) == 1) abs,
        ]);
      case TargetKind.emptyPoint2:
        final mined = {
          for (final e in tx.effects)
            if (e.kind == EffectKind.landmine) e.point,
        };
        return _pairs([
          for (var abs = 1; abs <= 24; abs++)
            if (board.atAbsolute(abs).$1 == null && !mined.contains(abs)) abs,
        ]);
      case TargetKind.enemyOrEmpty2:
        return _pairs([
          for (var abs = 1; abs <= 24; abs++)
            if (board.atAbsolute(abs).$1 != side) abs,
        ]);
      case TargetKind.enemyChecker:
        return [
          for (var abs = 1; abs <= 24; abs++)
            if (board.count(opp, toRelative(opp, abs)) > 0) [abs],
        ];
      case TargetKind.enemyBlot:
        return [
          for (var abs = 1; abs <= 24; abs++)
            if (board.count(opp, toRelative(opp, abs)) == 1) [abs],
        ];
      case TargetKind.ownPoint2:
        return _pairs([
          for (var abs = 1; abs <= 24; abs++)
            if (board.count(side, toRelative(side, abs)) > 0) abs,
        ]);
      case TargetKind.sprint:
        final ctx = EffectSystem.moveContext(tx, side);
        final mine = board.of(side);
        final theirs = board.of(opp);
        return [
          for (var from = 25; from >= 5; from--)
            if (mine[from] - (from <= 24 ? (ctx.frozen[from] ?? 0) : 0) > 0 &&
                !(theirs[25 - (from - 4)] >= 2 ||
                    (theirs[25 - (from - 4)] == 1 &&
                        (ctx.protectedMask & (1 << (from - 4))) != 0)))
              [if (from == Pos.bar) 0 else toAbsolute(side, from)],
        ];
      case TargetKind.teleport:
        final ctx = EffectSystem.moveContext(tx, side);
        final mine = board.of(side);
        final theirs = board.of(opp);
        final out = <List<int>>[];
        for (var from = 25; from >= 1; from--) {
          if (mine[from] == 0) continue;
          final frozen = ctx.frozen[from] ?? 0;
          if (from <= 24 && mine[from] - frozen <= 0) continue;
          for (var k = 1; k <= 3; k++) {
            final to = from - k;
            if (to < 1) break;
            final o = theirs[25 - to];
            final blocked =
                o >= 2 || (o == 1 && (ctx.protectedMask & (1 << to)) != 0);
            if (blocked) continue;
            out.add([
              if (from == Pos.bar) 0 else toAbsolute(side, from),
              toAbsolute(side, to),
            ]);
          }
        }
        return out;
    }
  }

  /// Unordered distinct pairs; a single option if only one point exists.
  static List<List<int>> _pairs(List<int> pts) {
    if (pts.length == 1) return [pts];
    return [
      for (var i = 0; i < pts.length; i++)
        for (var j = i + 1; j < pts.length; j++) [pts[i], pts[j]],
    ];
  }

  static bool validTargets(Tx tx, Side side, String card, List<int> t) {
    final all = allTargets(tx, side, card);
    bool same(List<int> a, List<int> b) {
      if (a.length != b.length) return false;
      if (isUnorderedTarget(cardById(card).target)) {
        final x = List.of(a)..sort();
        final y = List.of(b)..sort();
        for (var i = 0; i < x.length; i++) {
          if (x[i] != y[i]) return false;
        }
        return true;
      }
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }

    return all.any((x) => same(x, t));
  }

  /// Applies [card] for [side] with validated [targets].
  static void apply(Tx tx, Side side, String card, List<int> targets) {
    final opp = side.opponent;
    SideInv inv() => tx.inv(side);
    switch (card) {
      case CardId.loadedHand:
        tx.addEffect(
          EffectKind.loadedHand,
          owner: side,
          affected: side,
          turns: 1,
          immediate: false,
        );
      case CardId.doubleDown:
        tx.rollQueue.add(<int>[]);
      case CardId.fatesEdit:
        tx.addEffect(
          EffectKind.fateEdit,
          owner: side,
          affected: side,
          turns: 1,
          immediate: false,
        );
      case CardId.secondChance:
        tx.setInv(side, inv().copyWith(rerolls: inv().rerolls + 1));
      case CardId.luckyCharm:
        tx.setInv(side, inv().copyWith(lucky: inv().lucky + 1));
      case CardId.sevenMagnet:
        tx.addEffect(
          EffectKind.sevenMagnet,
          owner: side,
          affected: side,
          turns: 5,
          immediate: false,
        );
      case CardId.brokenDie:
        tx.addEffect(
          EffectKind.brokenDie,
          owner: side,
          affected: opp,
          turns: 2,
        );
      case CardId.fog:
        tx
          ..addEffect(EffectKind.fog, owner: side, affected: opp, turns: 3)
          ..addEffect(
            EffectKind.sevenBlock,
            owner: side,
            affected: opp,
            turns: 3,
          )
          ..addEffect(
            EffectKind.curse,
            owner: side,
            affected: opp,
            turns: 3,
            count: 5,
          );
      case CardId.curse:
        tx.addEffect(
          EffectKind.halveDice,
          owner: side,
          affected: opp,
          turns: 2,
        );
      case CardId.mirror:
        tx.addEffect(
          EffectKind.mirrorWatch,
          owner: side,
          affected: opp,
          turns: 1,
        );
      case CardId.chains:
        final counts = <int, int>{};
        for (final p in targets) {
          counts[p] = (counts[p] ?? 0) + 1;
        }
        counts.forEach((p, n) {
          tx.addEffect(
            EffectKind.chains,
            owner: side,
            affected: opp,
            turns: 2,
            point: p,
            count: n,
          );
        });
      case CardId.thief:
        _steal(tx, side);
      case CardId.holyShield:
        tx.addEffect(
          EffectKind.shield,
          owner: side,
          affected: opp,
          turns: 3,
          point: targets.first,
        );
      case CardId.ironGate:
        tx.addEffect(
          EffectKind.ironGate,
          owner: side,
          affected: opp,
          turns: 2,
          point: targets.first,
        );
      case CardId.ghostStep:
        tx.setInv(side, inv().copyWith(ghost: inv().ghost + 1));
      case CardId.phoenix:
        tx.setInv(side, inv().copyWith(phoenix: inv().phoenix + 1));
      case CardId.teleport:
        final fromAbs = targets[0];
        final toAbs = targets[1];
        final from = fromAbs == 0 ? Pos.bar : toRelative(side, fromAbs);
        final to = toRelative(side, toAbs);
        final hit = tx.board.count(opp, 25 - to) == 1;
        tx.events.add(Teleported(side, fromAbs, toAbs));
        Engine.applyBoardMove(tx, side, Move(from, to, 0, hit: hit));
      case CardId.landmine:
        tx.addEffect(
          EffectKind.landmine,
          owner: side,
          affected: opp,
          turns: 8,
          point: targets.first,
        );
      case CardId.quicksand:
        tx.addEffect(
          EffectKind.quicksand,
          owner: side,
          affected: opp,
          turns: 6,
          point: targets.first,
        );
      case CardId.tollGate:
        tx.addEffect(
          EffectKind.toll,
          owner: side,
          affected: opp,
          turns: 8,
          point: targets.first,
        );
      case CardId.timeStop:
        tx.extraTurn = true;
        tx.addEffect(
          EffectKind.bonusPick,
          owner: opp,
          affected: opp,
          turns: 9999,
        );
      case CardId.bloodPact:
        _bloodPact(tx, side);
      case CardId.gamblersCoin:
        final heads = tx.rng.nextInt(2) == 0;
        tx.events.add(CoinFlipped(side, ownerWins: heads));
        tx.addEffect(
          EffectKind.skipTurn,
          owner: side,
          affected: heads ? opp : side,
          turns: 1,
          immediate: false,
        );
      case CardId.greed:
        tx.setInv(side, inv().copyWith(greed: inv().greed + 1));
        tx.addEffect(
          EffectKind.bonusOffer,
          owner: opp,
          affected: opp,
          turns: 9999,
        );
      case CardId.twinAnchors:
        for (final p in targets) {
          tx.addEffect(
            EffectKind.ironGate,
            owner: side,
            affected: opp,
            turns: 2,
            point: p,
          );
        }
      case CardId.bargain:
        tx.setInv(
          side,
          inv().copyWith(rerolls: inv().rerolls + 1, lucky: inv().lucky + 1),
        );
        final o = tx.inv(opp);
        tx.setInv(opp, o.copyWith(lucky: o.lucky + 1));
      case CardId.hourglassSand:
        tx
          ..addEffect(EffectKind.fog, owner: side, affected: opp, turns: 1)
          ..addEffect(EffectKind.curse, owner: side, affected: opp, turns: 1);
      case CardId.simorgh:
        tx.setInv(side, inv().copyWith(phoenix: inv().phoenix + 2));
      case CardId.nightfall:
        tx.addEffect(
          EffectKind.sevenBlock,
          owner: side,
          affected: opp,
          turns: 6,
        );
      case CardId.lantern:
        final removed = tx.effects
            .where(
              (e) =>
                  e.owner == opp &&
                  (e.kind == EffectKind.landmine ||
                      e.kind == EffectKind.quicksand ||
                      e.kind == EffectKind.toll),
            )
            .map((e) => e.id)
            .toSet();
        tx.effects.removeWhere((e) => removed.contains(e.id));
      case CardId.earthquake:
        tx.effects.removeWhere(
          (e) =>
              (e.affected == side &&
                  (e.kind == EffectKind.chains ||
                      e.kind == EffectKind.quicksandFreeze)) ||
              (e.owner == opp &&
                  (e.kind == EffectKind.shield ||
                      e.kind == EffectKind.ironGate)),
        );
      case CardId.luckySix:
        tx.addEffect(
          EffectKind.sixNext,
          owner: side,
          affected: side,
          turns: 1,
          immediate: false,
        );
      case CardId.vortex:
        for (final p in targets) {
          tx.addEffect(
            EffectKind.quicksand,
            owner: side,
            affected: opp,
            turns: 6,
            point: p,
          );
        }
      case CardId.minefield:
        for (final p in targets) {
          tx.addEffect(
            EffectKind.landmine,
            owner: side,
            affected: opp,
            turns: 8,
            point: p,
          );
        }
      case CardId.truce:
        tx.addEffect(EffectKind.truce, owner: side, affected: opp, turns: 2);
      case CardId.tailwind:
        tx.addEffect(
          EffectKind.tailwind,
          owner: side,
          affected: side,
          turns: 1,
          immediate: false,
        );
      case CardId.headwind:
        tx.addEffect(EffectKind.headwind, owner: side, affected: opp, turns: 2);
      case CardId.evenOdds:
        _nextTurn(tx, side, EffectKind.evenUp);
      case CardId.wardOnes:
        _nextTurn(tx, side, EffectKind.wardOnes);
      case CardId.twinDice:
        _nextTurn(tx, side, EffectKind.twinDice);
      case CardId.royalRoll:
        _nextTurn(tx, side, EffectKind.minThree);
      case CardId.silkPurse:
        tx.setInv(side, inv().copyWith(rerolls: inv().rerolls + 2));
      case CardId.leadenDice:
        tx.addEffect(
          EffectKind.curse,
          owner: side,
          affected: opp,
          turns: 2,
          count: 3,
        );
      case CardId.shackle:
        tx.addEffect(
          EffectKind.chains,
          owner: side,
          affected: opp,
          turns: 4,
          point: targets.first,
          count: 1,
        );
      case CardId.pickpocket:
        final o = tx.inv(opp);
        if (o.rerolls > 0) {
          tx
            ..setInv(opp, o.copyWith(rerolls: 0))
            ..setInv(side, inv().copyWith(rerolls: inv().rerolls + o.rerolls));
          tx.events.add(ItemStolen(side, 'reroll'));
        } else {
          tx.setInv(side, inv().copyWith(lucky: inv().lucky + 1));
          tx.events.add(TokenGranted(side, 'lucky'));
        }
      case CardId.hexSevens:
        tx.addEffect(
          EffectKind.offerMalus,
          owner: side,
          affected: opp,
          turns: 9999,
        );
      case CardId.sprint:
        final fromAbs = targets.first;
        final from = fromAbs == 0 ? Pos.bar : toRelative(side, fromAbs);
        final to = from - 4;
        final hit = tx.board.count(opp, 25 - to) == 1;
        tx.events.add(Teleported(side, fromAbs, toAbsolute(side, to)));
        Engine.applyBoardMove(tx, side, Move(from, to, 0, hit: hit));
      case CardId.shieldWall:
        for (var rel = 1; rel <= 24; rel++) {
          if (tx.board.count(side, rel) == 1) {
            tx.addEffect(
              EffectKind.shield,
              owner: side,
              affected: opp,
              turns: 1,
              point: toAbsolute(side, rel),
            );
          }
        }
      case CardId.homecoming:
        final mine = List<int>.of(tx.board.of(side));
        for (var p = 6; p >= 1; p--) {
          if (mine[p] > 0) {
            mine[p]--;
            mine[Pos.off]++;
            tx.events.add(CheckerBorneOff(side, toAbsolute(side, p)));
            break;
          }
        }
        tx.board = tx.board.withSide(side, mine);
        EffectSystem.cleanup(tx);
        if (tx.board.borneOff(side) == Pos.checkers) {
          Engine.endGame(tx, side, null);
        }
      case CardId.reentry:
        final mine = List<int>.of(tx.board.of(side));
        final theirs = tx.board.of(opp);
        var placed = true;
        while (mine[Pos.bar] > 0 && placed) {
          placed = false;
          for (var rel = 19; rel <= 24; rel++) {
            if (theirs[25 - rel] == 0) {
              mine[Pos.bar]--;
              mine[rel]++;
              tx.events.add(PhoenixRose(side, toAbsolute(side, rel)));
              placed = true;
              break;
            }
          }
        }
        tx.board = tx.board.withSide(side, mine);
      case CardId.stoneSkin:
        for (final p in targets) {
          tx.addEffect(
            EffectKind.shield,
            owner: side,
            affected: opp,
            turns: 3,
            point: p,
          );
        }
      case CardId.caltrops:
        for (final p in targets) {
          tx.addEffect(
            EffectKind.toll,
            owner: side,
            affected: opp,
            turns: 8,
            point: p,
          );
        }
      case CardId.bait:
        tx.addEffect(
          EffectKind.landmine,
          owner: side,
          affected: opp,
          turns: 8,
          point: targets.first,
        );
      case CardId.rally:
        if (tx.board.pips(side) - tx.board.pips(opp) >= 20) {
          tx.rollQueue.add(<int>[]);
        } else {
          tx.setInv(side, inv().copyWith(rerolls: inv().rerolls + 1));
        }
      case CardId.fortuneTeller:
        for (var i = 0; i < 2; i++) {
          tx.addEffect(
            EffectKind.bonusOffer,
            owner: side,
            affected: side,
            turns: 9999,
          );
        }
      case CardId.destiny:
        tx.addEffect(
          EffectKind.bonusPick,
          owner: side,
          affected: side,
          turns: 9999,
        );
      case CardId.highStakes:
        tx.cubeValue = (tx.cubeValue * 2).clamp(1, 64);
      case CardId.exile:
        final rel = toRelative(opp, targets.first);
        final theirs = List<int>.of(tx.board.of(opp));
        theirs[rel]--;
        theirs[Pos.bar]++;
        tx.board = tx.board.withSide(opp, theirs);
        tx.events.add(CheckerHit(opp, targets.first));
        EffectSystem.cleanup(tx);
      case CardId.oasis:
        tx.effects.removeWhere((e) => e.affected == side && _isDiceCurse(e));
      case CardId.doubleAgent:
        final theirCards = tx.inv(opp).cards;
        final last = theirCards.isEmpty ? null : theirCards.last;
        const banned = {
          CardId.doubleAgent,
          CardId.timeStop,
          CardId.bloodPact,
          CardId.homecoming,
          CardId.reentry,
          CardId.oasis,
          CardId.lantern,
          CardId.earthquake,
        };
        if (last != null &&
            cardById(last).target == TargetKind.none &&
            !banned.contains(last)) {
          apply(tx, side, last, const []);
          tx.events.add(CardPicked(side, last));
        } else {
          tx.setInv(side, inv().copyWith(rerolls: inv().rerolls + 1));
        }
      default:
        throw ArgumentError('No logic for card $card');
    }
  }

  static void _nextTurn(Tx tx, Side side, EffectKind k) =>
      tx.addEffect(k, owner: side, affected: side, turns: 1, immediate: false);

  static void _steal(Tx tx, Side side) {
    final opp = side.opponent;
    final o = tx.inv(opp);
    final items = <String>[
      for (var i = 0; i < o.phoenix; i++) 'phoenix',
      for (var i = 0; i < o.ghost; i++) 'ghost',
      for (var i = 0; i < o.rerolls; i++) 'reroll',
      for (var i = 0; i < o.lucky; i++) 'lucky',
    ];
    final me = tx.inv(side);
    if (items.isEmpty) {
      tx.setInv(side, me.copyWith(rerolls: me.rerolls + 1));
      tx.events.add(TokenGranted(side, 'reroll'));
      return;
    }
    final item = items[tx.rng.nextInt(items.length)];
    switch (item) {
      case 'phoenix':
        tx.setInv(opp, o.copyWith(phoenix: o.phoenix - 1));
        tx.setInv(side, me.copyWith(phoenix: me.phoenix + 1));
      case 'ghost':
        tx.setInv(opp, o.copyWith(ghost: o.ghost - 1));
        tx.setInv(side, me.copyWith(ghost: me.ghost + 1));
      case 'reroll':
        tx.setInv(opp, o.copyWith(rerolls: o.rerolls - 1));
        tx.setInv(side, me.copyWith(rerolls: me.rerolls + 1));
      default:
        tx.setInv(opp, o.copyWith(lucky: o.lucky - 1));
        tx.setInv(side, me.copyWith(lucky: me.lucky + 1));
    }
    tx.events.add(ItemStolen(side, item));
  }

  static void _bloodPact(Tx tx, Side side) {
    final mine = List<int>.of(tx.board.of(side));
    if (tx.board.allHome(side)) {
      for (var n = 0; n < 2; n++) {
        for (var p = 6; p >= 1; p--) {
          if (mine[p] > 0) {
            mine[p]--;
            mine[Pos.off]++;
            tx.events.add(CheckerBorneOff(side, toAbsolute(side, p)));
            break;
          }
        }
      }
      tx.board = tx.board.withSide(side, mine);
      EffectSystem.cleanup(tx);
      if (tx.board.borneOff(side) == Pos.checkers) {
        Engine.endGame(tx, side, null);
      }
      return;
    }
    for (var p = 1; p <= 24; p++) {
      if (mine[p] > 0) {
        mine[p]--;
        mine[Pos.bar]++;
        tx.events.add(CheckerHit(side, toAbsolute(side, p)));
        break;
      }
    }
    tx.board = tx.board.withSide(side, mine);
    EffectSystem.cleanup(tx);
  }

  /// Deals a 7–7 offer for [side] into `tx.offer`.
  static void dealOffer(Tx tx, Side side) {
    final mods = tx.config.mods(side);
    var size = tx.config.offerSize + mods.offerBonus;
    var picks = 1 + mods.pickBonus;
    for (final e in List.of(tx.effects)) {
      if (e.affected != side) continue;
      if (e.kind == EffectKind.bonusOffer) {
        size++;
        tx.removeEffect(e.id);
      } else if (e.kind == EffectKind.bonusPick) {
        picks++;
        tx.removeEffect(e.id);
      } else if (e.kind == EffectKind.offerMalus) {
        size--;
        tx.removeEffect(e.id);
      }
    }
    if (size < 1) size = 1;
    final ids =
        mods.cardPool ?? tx.config.cardPool ?? [for (final c in kCards) c.id];
    final pool = [
      for (final id in ids)
        if (kCardById.containsKey(id) && isPlayable(tx, side, id)) id,
    ];
    final byRarity = <Rarity, List<String>>{
      for (final r in Rarity.values) r: [],
    };
    for (final id in pool) {
      byRarity[cardById(id).rarity]!.add(id);
    }
    final inv = tx.inv(side);
    final pity = inv.pity;
    final offer = <String>[];
    for (var slot = 0; slot < size; slot++) {
      final avail = [
        for (final r in Rarity.values)
          if (byRarity[r]!.isNotEmpty) r,
      ];
      if (avail.isEmpty) break;
      final weights = [
        for (final r in avail)
          switch (r) {
            Rarity.common => 60.0,
            Rarity.rare => 28.0,
            Rarity.epic => 10.0 + pity * 3,
            Rarity.legendary => 2.0 + pity,
          },
      ];
      final r = avail[tx.rng.weighted(weights)];
      final list = byRarity[r]!;
      if (mods.favored.isEmpty) {
        offer.add(list.removeAt(tx.rng.nextInt(list.length)));
      } else {
        final w = [
          for (final id in list)
            if (mods.favored.contains(id)) 3.0 else 1.0,
        ];
        offer.add(list.removeAt(tx.rng.weighted(w)));
      }
    }
    final high = offer.any(
      (c) => cardById(c).rarity.index >= Rarity.epic.index,
    );
    tx.setInv(side, tx.inv(side).copyWith(pity: high ? 0 : pity + 1));
    tx.offer = offer;
    tx.picksLeft = picks < offer.length ? picks : offer.length;
  }
}
