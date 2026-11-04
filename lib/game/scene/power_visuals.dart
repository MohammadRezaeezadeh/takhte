import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rules/events.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';

/// Persistent on-board indicators ("show, don't tell"): one per active
/// effect, drawn for the effect's whole duration with a turn counter.
enum VisualKind {
  /// Chained / frozen checkers: ice blocks with a snowflake badge.
  ice,

  /// Protected checker or point: a glowing bubble.
  shield,

  /// A lone checker blocking like a made point: an iron gate.
  gate,

  /// Hidden mine (only its owner sees the mark).
  mine,

  /// Quicksand: swirling sand on the point.
  quicksand,

  /// Toll gate: two posts and a bar.
  toll,

  /// Truce: a white flag over the whole board.
  truce,

  /// Affected player's dice area visuals.
  diceCrack,
  diceFog,
  diceCurse,
  diceHeadwind,
  diceTailwind,
  magnet,
  noSeven,

  /// A buff waiting for its owner's next roll (6–6, a 6, 3+, even…).
  diceBuff,

  /// Skipped turn: an hourglass on the affected side.
  skip,

  /// Bigger / smaller next 7–7 offer, or an extra pick.
  offerUp,
  offerDown,

  /// Mirror: the next roll will be copied.
  mirror,
}

class PowerVisual {
  const PowerVisual({
    required this.effectId,
    required this.kind,
    required this.side,
    required this.point,
    required this.count,
    required this.turns,
    required this.pending,
    required this.cardId,
  });

  final int effectId;
  final VisualKind kind;

  /// The affected side (whose dice/checkers the visual sits on).
  final Side side;

  /// Absolute point for board visuals, 0 for dice-area / board-wide ones.
  final int point;

  /// Checker count for ice (how many are frozen).
  final int count;

  /// Turns left (null when not meaningful, e.g. "until next 7–7").
  final int? turns;

  /// Not active yet (fires on the affected side's next turn).
  final bool pending;

  /// Card that produced it (for the icon).
  final String cardId;

  String get key => '${kind.name}@$effectId';
}

/// One-shot effects played at the moment something happens.
enum MomentKind {
  iceForm,
  iceCrack,
  shieldUp,
  shieldPop,
  shieldBlock,
  gateSlam,
  gateOpen,
  mineSet,
  mineBoom,
  sandSwirl,
  tollSet,
  diceShatter,
  fogRoll,
  curseDrain,
  windGust,
  magnetPulse,
  sevenSeal,
  buffSparkle,
  tokensFly,
  steal,
  teleportBlink,
  timeFreeze,
  coinFlip,
  phoenixRise,
  bearOffBlessing,
  exileStrike,
  stakesUp,
  cleanse,
  reveal,
  quake,
  copy,
  rollAgain,
  offerBoost,
  offerHex,
  mirrorShine,
  truceFlag,
  skipTurn,
  fizzle,
  fade,
}

class Moment {
  const Moment(this.kind, this.side, {this.point = 0, this.cardId});
  final MomentKind kind;
  final Side side;
  final int point;
  final String? cardId;
  @override
  String toString() =>
      '${kind.name}(${side.name}${point > 0 ? '@$point' : ''})';
}

/// Card shown as the icon of an effect.
String cardOfEffect(EffectKind k) => switch (k) {
  EffectKind.brokenDie => CardId.brokenDie,
  EffectKind.fog => CardId.fog,
  EffectKind.curse => CardId.leadenDice,
  EffectKind.chains => CardId.chains,
  EffectKind.shield => CardId.holyShield,
  EffectKind.ironGate => CardId.ironGate,
  EffectKind.quicksand => CardId.quicksand,
  EffectKind.quicksandFreeze => CardId.quicksand,
  EffectKind.toll => CardId.tollGate,
  EffectKind.landmine => CardId.landmine,
  EffectKind.sevenMagnet => CardId.sevenMagnet,
  EffectKind.loadedHand => CardId.loadedHand,
  EffectKind.fateEdit => CardId.fatesEdit,
  EffectKind.mirrorWatch => CardId.mirror,
  EffectKind.mirrorBonus => CardId.mirror,
  EffectKind.skipTurn => CardId.gamblersCoin,
  EffectKind.bonusPick => CardId.destiny,
  EffectKind.bonusOffer => CardId.fortuneTeller,
  EffectKind.sevenBlock => CardId.nightfall,
  EffectKind.sixNext => CardId.luckySix,
  EffectKind.truce => CardId.truce,
  EffectKind.tailwind => CardId.tailwind,
  EffectKind.headwind => CardId.headwind,
  EffectKind.evenUp => CardId.evenOdds,
  EffectKind.wardOnes => CardId.wardOnes,
  EffectKind.twinDice => CardId.twinDice,
  EffectKind.minThree => CardId.royalRoll,
  EffectKind.offerMalus => CardId.hexSevens,
  EffectKind.halveDice => CardId.curse,
};

abstract final class PowerVisuals {
  /// The visual for an effect kind.
  static VisualKind kindOf(EffectKind k) => switch (k) {
    EffectKind.chains || EffectKind.quicksandFreeze => VisualKind.ice,
    EffectKind.shield => VisualKind.shield,
    EffectKind.ironGate => VisualKind.gate,
    EffectKind.landmine => VisualKind.mine,
    EffectKind.quicksand => VisualKind.quicksand,
    EffectKind.toll => VisualKind.toll,
    EffectKind.truce => VisualKind.truce,
    EffectKind.brokenDie => VisualKind.diceCrack,
    EffectKind.fog => VisualKind.diceFog,
    EffectKind.curse || EffectKind.halveDice => VisualKind.diceCurse,
    EffectKind.headwind => VisualKind.diceHeadwind,
    EffectKind.tailwind => VisualKind.diceTailwind,
    EffectKind.sevenMagnet => VisualKind.magnet,
    EffectKind.sevenBlock => VisualKind.noSeven,
    EffectKind.sixNext ||
    EffectKind.twinDice ||
    EffectKind.minThree ||
    EffectKind.evenUp ||
    EffectKind.wardOnes ||
    EffectKind.loadedHand ||
    EffectKind.fateEdit => VisualKind.diceBuff,
    EffectKind.skipTurn => VisualKind.skip,
    EffectKind.bonusPick || EffectKind.bonusOffer => VisualKind.offerUp,
    EffectKind.offerMalus => VisualKind.offerDown,
    EffectKind.mirrorWatch || EffectKind.mirrorBonus => VisualKind.mirror,
  };

  /// Everything to draw for [s]. Mines are only visible to their owner.
  static List<PowerVisual> forState(GameState s, {required Side? viewer}) => [
    for (final e in s.effects)
      if (e.kind != EffectKind.landmine || e.owner == viewer)
        PowerVisual(
          effectId: e.id,
          kind: kindOf(e.kind),
          side: e.affected,
          point: e.point,
          count: e.count,
          turns: e.turnsLeft < 50 ? e.turnsLeft : null,
          pending: !e.isActive(s.turnNumber),
          cardId: cardOfEffect(e.kind),
        ),
  ];

  static MomentKind _arrival(EffectKind k) => switch (kindOf(k)) {
    VisualKind.ice => MomentKind.iceForm,
    VisualKind.shield => MomentKind.shieldUp,
    VisualKind.gate => MomentKind.gateSlam,
    VisualKind.mine => MomentKind.mineSet,
    VisualKind.quicksand => MomentKind.sandSwirl,
    VisualKind.toll => MomentKind.tollSet,
    VisualKind.truce => MomentKind.truceFlag,
    VisualKind.diceCrack => MomentKind.diceShatter,
    VisualKind.diceFog => MomentKind.fogRoll,
    VisualKind.diceCurse => MomentKind.curseDrain,
    VisualKind.diceHeadwind || VisualKind.diceTailwind => MomentKind.windGust,
    VisualKind.magnet => MomentKind.magnetPulse,
    VisualKind.noSeven => MomentKind.sevenSeal,
    VisualKind.diceBuff => MomentKind.buffSparkle,
    VisualKind.skip => MomentKind.skipTurn,
    VisualKind.offerUp => MomentKind.offerBoost,
    VisualKind.offerDown => MomentKind.offerHex,
    VisualKind.mirror => MomentKind.mirrorShine,
  };

  static MomentKind _expiry(EffectKind k) => switch (kindOf(k)) {
    VisualKind.ice => MomentKind.iceCrack,
    VisualKind.shield => MomentKind.shieldPop,
    VisualKind.gate => MomentKind.gateOpen,
    _ => MomentKind.fade,
  };

  /// Instant cards that leave no effect behind still get a moment.
  static MomentKind? _cardMoment(String card) => switch (card) {
    CardId.timeStop => MomentKind.timeFreeze,
    CardId.highStakes => MomentKind.stakesUp,
    CardId.lantern => MomentKind.reveal,
    CardId.earthquake => MomentKind.quake,
    CardId.oasis => MomentKind.cleanse,
    CardId.doubleAgent => MomentKind.copy,
    CardId.doubleDown || CardId.rally => MomentKind.rollAgain,
    CardId.exile => MomentKind.exileStrike,
    CardId.bloodPact || CardId.homecoming => MomentKind.bearOffBlessing,
    CardId.reentry => MomentKind.phoenixRise,
    CardId.teleport || CardId.sprint => MomentKind.teleportBlink,
    CardId.greed => MomentKind.tokensFly,
    _ => null,
  };

  /// Moments for one presented step: effects that appeared or ended between
  /// [before] and [after], plus the step's [events].
  static List<Moment> moments(
    GameState before,
    GameState after,
    List<GameEvent> events, {
    required Side? viewer,
  }) {
    final out = <Moment>[];
    final was = {for (final e in before.effects) e.id: e};
    final now = {for (final e in after.effects) e.id: e};
    for (final e in after.effects) {
      if (was.containsKey(e.id)) continue;
      if (e.kind == EffectKind.landmine && e.owner != viewer) continue;
      out.add(Moment(_arrival(e.kind), e.affected, point: e.point));
    }
    for (final e in before.effects) {
      if (now.containsKey(e.id)) continue;
      if (e.kind == EffectKind.landmine) continue; // exploded or expired
      out.add(Moment(_expiry(e.kind), e.affected, point: e.point));
    }
    // Charges gained (reroll tokens, Lucky Charms, Ghost Steps, Phoenixes)
    // fly into that player's dice area.
    for (final side in Side.values) {
      final a = before.inv(side);
      final b = after.inv(side);
      if (b.rerolls > a.rerolls ||
          b.lucky > a.lucky ||
          b.ghost > a.ghost ||
          b.phoenix > a.phoenix) {
        out.add(Moment(MomentKind.tokensFly, side));
      }
    }
    for (final ev in events) {
      switch (ev) {
        case CardPicked(:final side, :final cardId):
          final m = _cardMoment(cardId);
          if (m != null) out.add(Moment(m, side, cardId: cardId));
        case CardFizzled(:final side):
          out.add(Moment(MomentKind.fizzle, side));
        case MineTriggered(:final point, :final victim):
          out.add(Moment(MomentKind.mineBoom, victim, point: point));
        case PhoenixRose(:final side, :final point):
          out.add(Moment(MomentKind.phoenixRise, side, point: point));
        case Teleported(:final side, :final toAbsolute):
          out.add(Moment(MomentKind.teleportBlink, side, point: toAbsolute));
        case TurnSkipped(:final side):
          out.add(Moment(MomentKind.skipTurn, side));
        case CoinFlipped(:final owner):
          out.add(Moment(MomentKind.coinFlip, owner));
        case ItemStolen(:final thief):
          out.add(Moment(MomentKind.steal, thief));
        case TokenGranted(:final side):
          out.add(Moment(MomentKind.tokensFly, side));
        default:
          break;
      }
    }
    return out;
  }
}
