import 'package:haftnard/core/effects/cards.dart';

/// Who a card acts on (the tag on the card face).
enum CardWho { opponent, self, board }

/// Plain-language facts for the card face and the copy tests.
class CardMeta {
  const CardMeta(this.who, this.turns);

  final CardWho who;

  /// Duration in turns; 0 = instant or until used; -1 = until the next 7–7.
  final int turns;

  static const int untilSeven = -1;
}

/// Every card's target and duration.
const Map<String, CardMeta> kCardMeta = {
  CardId.loadedHand: CardMeta(CardWho.self, 1),
  CardId.doubleDown: CardMeta(CardWho.self, 0),
  CardId.fatesEdit: CardMeta(CardWho.self, 1),
  CardId.secondChance: CardMeta(CardWho.self, 0),
  CardId.luckyCharm: CardMeta(CardWho.self, 0),
  CardId.sevenMagnet: CardMeta(CardWho.self, 5),
  CardId.brokenDie: CardMeta(CardWho.opponent, 2),
  CardId.chains: CardMeta(CardWho.opponent, 2),
  CardId.fog: CardMeta(CardWho.opponent, 3),
  CardId.curse: CardMeta(CardWho.opponent, 2),
  CardId.mirror: CardMeta(CardWho.self, 1),
  CardId.thief: CardMeta(CardWho.opponent, 0),
  CardId.holyShield: CardMeta(CardWho.self, 3),
  CardId.ironGate: CardMeta(CardWho.self, 2),
  CardId.ghostStep: CardMeta(CardWho.self, 0),
  CardId.phoenix: CardMeta(CardWho.self, 0),
  CardId.teleport: CardMeta(CardWho.self, 0),
  CardId.landmine: CardMeta(CardWho.board, 8),
  CardId.quicksand: CardMeta(CardWho.board, 6),
  CardId.tollGate: CardMeta(CardWho.board, 8),
  CardId.timeStop: CardMeta(CardWho.self, 0),
  CardId.bloodPact: CardMeta(CardWho.self, 0),
  CardId.gamblersCoin: CardMeta(CardWho.opponent, 1),
  CardId.greed: CardMeta(CardWho.self, 0),
  CardId.twinAnchors: CardMeta(CardWho.self, 2),
  CardId.bargain: CardMeta(CardWho.self, 0),
  CardId.hourglassSand: CardMeta(CardWho.opponent, 1),
  CardId.simorgh: CardMeta(CardWho.self, 0),
  CardId.nightfall: CardMeta(CardWho.opponent, 6),
  CardId.lantern: CardMeta(CardWho.board, 0),
  CardId.earthquake: CardMeta(CardWho.board, 0),
  CardId.luckySix: CardMeta(CardWho.self, 1),
  CardId.vortex: CardMeta(CardWho.board, 6),
  CardId.minefield: CardMeta(CardWho.board, 8),
  CardId.truce: CardMeta(CardWho.board, 2),
  CardId.tailwind: CardMeta(CardWho.self, 1),
  CardId.headwind: CardMeta(CardWho.opponent, 2),
  CardId.evenOdds: CardMeta(CardWho.self, 1),
  CardId.wardOnes: CardMeta(CardWho.self, 1),
  CardId.twinDice: CardMeta(CardWho.self, 1),
  CardId.royalRoll: CardMeta(CardWho.self, 1),
  CardId.silkPurse: CardMeta(CardWho.self, 0),
  CardId.leadenDice: CardMeta(CardWho.opponent, 2),
  CardId.shackle: CardMeta(CardWho.opponent, 4),
  CardId.pickpocket: CardMeta(CardWho.opponent, 0),
  CardId.hexSevens: CardMeta(CardWho.opponent, -1),
  CardId.sprint: CardMeta(CardWho.self, 0),
  CardId.shieldWall: CardMeta(CardWho.self, 1),
  CardId.homecoming: CardMeta(CardWho.self, 0),
  CardId.reentry: CardMeta(CardWho.self, 0),
  CardId.stoneSkin: CardMeta(CardWho.self, 3),
  CardId.caltrops: CardMeta(CardWho.board, 8),
  CardId.bait: CardMeta(CardWho.board, 8),
  CardId.rally: CardMeta(CardWho.self, 0),
  CardId.fortuneTeller: CardMeta(CardWho.self, -1),
  CardId.destiny: CardMeta(CardWho.self, -1),
  CardId.highStakes: CardMeta(CardWho.board, 0),
  CardId.exile: CardMeta(CardWho.opponent, 0),
  CardId.oasis: CardMeta(CardWho.self, 0),
  CardId.doubleAgent: CardMeta(CardWho.self, 0),
  CardId.sandstorm: CardMeta(CardWho.opponent, 1),
  CardId.caravan: CardMeta(CardWho.self, 0),
  CardId.spiritWard: CardMeta(CardWho.self, 0),
  CardId.mirage: CardMeta(CardWho.opponent, 2),
  CardId.mountainPass: CardMeta(CardWho.opponent, 1),
  CardId.saffron: CardMeta(CardWho.self, 1),
  CardId.treasury: CardMeta(CardWho.self, 0),
  CardId.starReader: CardMeta(CardWho.self, -1),
  CardId.sevenfold: CardMeta(CardWho.self, 5),
  CardId.hailstorm: CardMeta(CardWho.opponent, 2),
  CardId.falconEye: CardMeta(CardWho.self, 1),
  CardId.ironDice: CardMeta(CardWho.opponent, 2),
  CardId.eclipse: CardMeta(CardWho.opponent, 4),
  CardId.sultansFavor: CardMeta(CardWho.self, 1),
  CardId.bandit: CardMeta(CardWho.opponent, -1),
  CardId.desertRose: CardMeta(CardWho.self, 0),
  CardId.twinSuns: CardMeta(CardWho.self, 1),
  CardId.coldSnap: CardMeta(CardWho.opponent, 2),
  CardId.pilgrimage: CardMeta(CardWho.self, -1),
  CardId.stormEye: CardMeta(CardWho.opponent, 2),
};

CardMeta cardMeta(String id) =>
    kCardMeta[id] ?? const CardMeta(CardWho.self, 0);
