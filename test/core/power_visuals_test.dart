// "Show, don't tell": every card produces an on-board moment when it takes
// effect, a persistent indicator for as long as it lasts, and the indicator
// goes away (with an expiry moment) when the effect ends.
import 'package:haftnard/core/effects/card_logic.dart';
import 'package:haftnard/core/effects/card_meta.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rules/actions.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/events.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/game/scene/power_visuals.dart';
import 'package:test/test.dart';

import 'helpers.dart';

const noSeven = GameConfig(p7: 0);

/// A position in which [card] can actually do its thing.
GameState setupFor(String card) {
  final home = Board.fromMaps(
    white: const {6: 5, 5: 5, 4: 3, 2: 2},
    black: const {19: 5, 20: 5, 13: 5},
  );
  switch (card) {
    case CardId.ironGate:
    case CardId.twinAnchors:
    case CardId.shieldWall:
    case CardId.bait:
      final blots = Board.fromMaps(
        white: const {6: 5, 8: 3, 13: 3, 24: 2, 10: 1, 15: 1},
        black: const {19: 5, 17: 3, 12: 5, 1: 2},
      );
      return sevenState(blots, [card], config: noSeven);
    case CardId.bloodPact:
    case CardId.homecoming:
      return sevenState(home, [card], config: noSeven);
    case CardId.reentry:
      final b = Board.fromMaps(
        white: const {6: 5, 8: 3, 13: 4, 24: 1, 25: 2},
        black: const {19: 5, 17: 3, 12: 5, 1: 2},
      );
      return sevenState(b, [card], config: noSeven);
    case CardId.exile:
      final b = Board.fromMaps(
        white: const {6: 5, 8: 3, 13: 5, 24: 2},
        black: const {19: 5, 17: 3, 12: 5, 1: 1, 3: 1},
      );
      return sevenState(b, [card], config: noSeven);
    case CardId.oasis:
      final s = sevenState(Board.initial(), [card], config: noSeven);
      return s.copyWith(
        effects: [
          const ActiveEffect(
            id: 90,
            kind: EffectKind.brokenDie,
            owner: Side.black,
            affected: Side.white,
            turnsLeft: 2,
            createdTurn: 0,
          ),
        ],
      );
    default:
      return sevenState(Board.initial(), [card], config: noSeven);
  }
}

/// Picks the only offered card (and its first legal targets).
(GameState, List<GameEvent>) play(GameState s) {
  final r1 = Engine.apply(s, const PickCard(0));
  var st = r1.state;
  final events = [...r1.events];
  if (st.phase == Phase.cardTarget) {
    final targets = CardLogic.allTargets(Tx(st), st.current, st.pendingCard!);
    expect(targets, isNotEmpty);
    final r2 = Engine.apply(st, ChooseTargets(targets.first));
    st = r2.state;
    events.addAll(r2.events);
  }
  return (st, events);
}

void main() {
  test('every effect kind has a visual, an arrival and an icon', () {
    for (final k in EffectKind.values) {
      PowerVisuals.kindOf(k);
      expect(kCardById, contains(cardOfEffect(k)), reason: k.name);
    }
  });

  test('mines are visible only to their owner', () {
    var s = sevenState(Board.initial(), [CardId.landmine], config: noSeven);
    final (after, _) = play(s);
    s = after;
    expect(
      PowerVisuals.forState(s, viewer: Side.white).map((v) => v.kind),
      contains(VisualKind.mine),
    );
    expect(
      PowerVisuals.forState(s, viewer: Side.black).map((v) => v.kind),
      isNot(contains(VisualKind.mine)),
    );
  });

  for (final card in kCards) {
    test("show, don't tell: ${card.id}", () {
      final before = setupFor(card.id);
      final (after, events) = play(before);
      final moments = PowerVisuals.moments(
        before,
        after,
        events,
        viewer: Side.white,
      );
      expect(
        moments,
        isNotEmpty,
        reason: '${card.id}: nothing visible when it takes effect',
      );
      expect(
        moments.map((m) => m.kind),
        isNot(contains(MomentKind.fizzle)),
        reason: '${card.id} fizzled in its test position',
      );

      final created = {
        for (final e in after.effects)
          if (!before.effects.any((b) => b.id == e.id)) e.id: e,
      };
      final visuals = PowerVisuals.forState(after, viewer: Side.white);
      final meta = cardMeta(card.id);
      if (meta.turns > 0) {
        expect(
          visuals.where((v) => created.containsKey(v.effectId)),
          isNotEmpty,
          reason: '${card.id}: no persistent indicator for its duration',
        );
      }
      for (final v in visuals.where((v) => created.containsKey(v.effectId))) {
        if (v.turns != null) {
          expect(v.turns, greaterThan(0), reason: 'turn counter');
        }
      }

      // Play on until every timed effect of this card has ended: its
      // indicator must disappear, with an expiry moment.
      final timed = {
        for (final e in created.values)
          if (e.turnsLeft < 50 && e.kind != EffectKind.landmine) e.id,
      };
      if (timed.isEmpty) return;
      var s = after;
      final ended = <MomentKind>[];
      for (var i = 0; i < 40 && !s.isOver; i++) {
        if (!s.effects.any((e) => timed.contains(e.id))) break;
        final prev = s;
        s = finishCurrentTurn(s);
        ended.addAll(
          PowerVisuals.moments(
            prev,
            s,
            const [],
            viewer: Side.white,
          ).map((m) => m.kind),
        );
      }
      final still = PowerVisuals.forState(
        s,
        viewer: Side.white,
      ).where((v) => timed.contains(v.effectId));
      expect(still, isEmpty, reason: '${card.id}: indicator never removed');
      expect(ended, isNotEmpty, reason: '${card.id}: no expiry moment');
    });
  }
}
