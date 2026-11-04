/// Data definitions for 7–7 power cards. Behaviour lives in `card_logic.dart`.
library;

enum Rarity {
  common(60),
  rare(28),
  epic(10),
  legendary(2);

  Rarity(this.weight);

  /// Base offer weight (percent).
  final int weight;
}

enum CardCategory { dice, sabotage, checker, trap, tempo }

/// How a card's targets are chosen.
enum TargetKind {
  none,

  /// Two enemy checkers on the board (same point allowed if it holds 2+).
  enemyCheckers2,

  /// One of your checkers on the board.
  ownChecker,

  /// One of your points holding exactly one checker.
  ownBlot,

  /// An empty point.
  emptyPoint,

  /// A point that is empty or holds enemy checkers.
  enemyOrEmpty,

  /// Teleport: a source (own checker, 0 = bar) and a destination 1–3 pips on.
  teleport,
}

/// Static card data.
class CardDef {
  const CardDef({
    required this.id,
    required this.rarity,
    required this.category,
    required this.nameEn,
    required this.nameFa,
    required this.descEn,
    required this.descFa,
    this.target = TargetKind.none,
    this.drawbackEn,
    this.drawbackFa,
    this.glyph = 0,
  });

  final String id;
  final Rarity rarity;
  final CardCategory category;
  final String nameEn;
  final String nameFa;
  final String descEn;
  final String descFa;
  final TargetKind target;
  final String? drawbackEn;
  final String? drawbackFa;

  /// Index of the procedural glyph used for the card art.
  final int glyph;

  String name(String lang) => lang == 'fa' ? nameFa : nameEn;
  String desc(String lang) => lang == 'fa' ? descFa : descEn;
  String? drawback(String lang) => lang == 'fa' ? drawbackFa : drawbackEn;
}

/// Card ids (stable: used in saves and action logs).
abstract final class CardId {
  static const loadedHand = 'loaded_hand';
  static const doubleDown = 'double_down';
  static const fatesEdit = 'fates_edit';
  static const secondChance = 'second_chance';
  static const luckyCharm = 'lucky_charm';
  static const sevenMagnet = 'seven_magnet';
  static const brokenDie = 'broken_die';
  static const chains = 'chains';
  static const fog = 'fog';
  static const curse = 'curse_small';
  static const mirror = 'mirror';
  static const thief = 'thief';
  static const holyShield = 'holy_shield';
  static const ironGate = 'iron_gate';
  static const ghostStep = 'ghost_step';
  static const phoenix = 'phoenix';
  static const teleport = 'teleport';
  static const landmine = 'landmine';
  static const quicksand = 'quicksand';
  static const tollGate = 'toll_gate';
  static const timeStop = 'time_stop';
  static const bloodPact = 'blood_pact';
  static const gamblersCoin = 'gamblers_coin';
  static const greed = 'greed';
}

/// The full card catalogue.
const List<CardDef> kCards = [
  // DICE CONTROL
  CardDef(
    id: CardId.loadedHand,
    rarity: Rarity.common,
    category: CardCategory.dice,
    nameEn: 'Loaded Hand',
    nameFa: 'دست سنگین',
    descEn: 'Next turn, roll 3 dice and keep the 2 you like.',
    descFa: 'نوبت بعد سه تاس بریز و دو تا را به انتخاب خودت نگه دار.',
  ),
  CardDef(
    id: CardId.doubleDown,
    rarity: Rarity.epic,
    category: CardCategory.dice,
    nameEn: 'Double Down',
    nameFa: 'دوبل',
    descEn: 'Roll twice this turn and play both rolls.',
    descFa: 'این نوبت دو بار تاس بریز و هر دو را بازی کن.',
    glyph: 1,
  ),
  CardDef(
    id: CardId.fatesEdit,
    rarity: Rarity.rare,
    category: CardCategory.dice,
    nameEn: "Fate's Edit",
    nameFa: 'دست تقدیر',
    descEn: 'Next turn, set one of your dice to any value.',
    descFa: 'نوبت بعد، یکی از تاس‌هایت را روی هر عددی که بخواهی بگذار.',
    glyph: 2,
  ),
  CardDef(
    id: CardId.secondChance,
    rarity: Rarity.common,
    category: CardCategory.dice,
    nameEn: 'Second Chance',
    nameFa: 'بخت دوباره',
    descEn: 'Gain a reroll token. Use it on any future roll before moving.',
    descFa:
        'یک ژتون تاس دوباره بگیر؛ پیش از حرکت در هر نوبتی قابل استفاده است.',
    glyph: 3,
  ),
  CardDef(
    id: CardId.luckyCharm,
    rarity: Rarity.common,
    category: CardCategory.dice,
    nameEn: 'Lucky Charm',
    nameFa: 'طلسم بخت',
    descEn: 'Once, add +1 to one of your dice (up to 6) before moving.',
    descFa: 'یک بار، پیش از حرکت یک واحد به یکی از تاس‌هایت اضافه کن (تا ۶).',
    glyph: 4,
  ),
  CardDef(
    id: CardId.sevenMagnet,
    rarity: Rarity.common,
    category: CardCategory.dice,
    nameEn: 'Seven Magnet',
    nameFa: 'آهنربای هفت',
    descEn: 'Your chance of rolling 7–7 is doubled for your next 5 turns.',
    descFa: 'شانس هفت‌هفت تو در پنج نوبت بعدی‌ات دو برابر می‌شود.',
    glyph: 5,
  ),
  // SABOTAGE
  CardDef(
    id: CardId.brokenDie,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Broken Die',
    nameFa: 'تاس شکسته',
    descEn: 'Your opponent rolls only one die on their next turn.',
    descFa: 'حریف در نوبت بعدی‌اش فقط با یک تاس بازی می‌کند.',
    glyph: 6,
  ),
  CardDef(
    id: CardId.chains,
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Chains',
    nameFa: 'زنجیر',
    descEn: 'Chain 2 enemy checkers: they cannot move for 2 of their turns.',
    descFa: 'دو مهرهٔ حریف را به زنجیر بکش؛ تا دو نوبتِ او حرکت نمی‌کنند.',
    target: TargetKind.enemyCheckers2,
    glyph: 7,
  ),
  CardDef(
    id: CardId.fog,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Fog',
    nameFa: 'مه',
    descEn: "Your opponent's doubles count as a normal roll next turn.",
    descFa: 'جفتِ حریف در نوبت بعدی‌اش مثل تاس معمولی حساب می‌شود.',
    glyph: 8,
  ),
  CardDef(
    id: CardId.curse,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Curse of Small Numbers',
    nameFa: 'نفرین کوچکی',
    descEn: "Your opponent's dice are capped at 4 next turn.",
    descFa: 'تاس‌های حریف در نوبت بعدی‌اش حداکثر ۴ می‌آیند.',
    glyph: 9,
  ),
  CardDef(
    id: CardId.mirror,
    rarity: Rarity.epic,
    category: CardCategory.sabotage,
    nameEn: 'Mirror',
    nameFa: 'آینه',
    descEn: "Your opponent's next roll is copied to you as a bonus roll on your following turn.",
    descFa: 'تاس بعدی حریف کپی می‌شود و در نوبت بعدی‌ات به‌عنوان تاس اضافه بازی می‌کنی.',
    glyph: 10,
  ),
  CardDef(
    id: CardId.thief,
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Thief',
    nameFa: 'دزد',
    descEn: "Steal one of your opponent's stored charges. If they have none, gain a reroll token.",
    descFa: 'یکی از توانایی‌های ذخیرهٔ حریف را بدزد؛ اگر چیزی نداشت، یک ژتون تاس دوباره بگیر.',
    glyph: 11,
  ),
  // CHECKER POWERS
  CardDef(
    id: CardId.holyShield,
    rarity: Rarity.common,
    category: CardCategory.checker,
    nameEn: 'Holy Shield',
    nameFa: 'سپر مقدس',
    descEn:
        "One of your checkers cannot be hit for 3 of your opponent's turns.",
    descFa: 'یکی از مهره‌هایت تا سه نوبتِ حریف زده نمی‌شود.',
    target: TargetKind.ownChecker,
    glyph: 12,
  ),
  CardDef(
    id: CardId.ironGate,
    rarity: Rarity.rare,
    category: CardCategory.checker,
    nameEn: 'Iron Gate',
    nameFa: 'دروازه آهنی',
    descEn: "A lone checker of yours blocks its point like a made point for 2 of your opponent's turns.",
    descFa: 'یک مهرهٔ تنهای تو تا دو نوبتِ حریف مثل خانهٔ بسته راه را می‌بندد.',
    target: TargetKind.ownBlot,
    glyph: 13,
  ),
  CardDef(
    id: CardId.ghostStep,
    rarity: Rarity.epic,
    category: CardCategory.checker,
    nameEn: 'Ghost Step',
    nameFa: 'گام شبح',
    descEn: 'Once, a checker whose landing point is blocked glides on to the next open point beyond it.',
    descFa: 'یک بار، مهره‌ای که مقصدش بسته است از روی آن عبور می‌کند و در اولین خانهٔ باز بعدی می‌نشیند.',
    glyph: 14,
  ),
  CardDef(
    id: CardId.phoenix,
    rarity: Rarity.common,
    category: CardCategory.checker,
    nameEn: 'Phoenix',
    nameFa: 'ققنوس',
    descEn: 'The next checker of yours that is hit re-enters instantly for free instead of going to the bar.',
    descFa: 'اولین مهره‌ای از تو که زده شود، به‌جای رفتن به بار، فوراً و رایگان دوباره وارد می‌شود.',
    glyph: 15,
  ),
  CardDef(
    id: CardId.teleport,
    rarity: Rarity.epic,
    category: CardCategory.checker,
    nameEn: 'Teleport',
    nameFa: 'جابه‌جایی',
    descEn: 'Move one of your checkers 1–3 pips forward to any legal point, outside the dice.',
    descFa: 'یکی از مهره‌هایت را بیرون از تاس، ۱ تا ۳ خانه به جلو به یک خانهٔ مجاز ببر.',
    target: TargetKind.teleport,
    glyph: 16,
  ),
  // BOARD TRAPS
  CardDef(
    id: CardId.landmine,
    rarity: Rarity.rare,
    category: CardCategory.trap,
    nameEn: 'Landmine',
    nameFa: 'مین',
    descEn: 'Hide a mine on an empty point. An enemy checker landing there goes to the bar.',
    descFa: 'روی یک خانهٔ خالی مین پنهان کن؛ مهرهٔ حریف که آنجا فرود بیاید به بار می‌رود.',
    target: TargetKind.emptyPoint,
    glyph: 17,
  ),
  CardDef(
    id: CardId.quicksand,
    rarity: Rarity.common,
    category: CardCategory.trap,
    nameEn: 'Quicksand',
    nameFa: 'باتلاق',
    descEn: 'Mark a point. Enemy checkers on it at the start of their turn are stuck for that turn.',
    descFa: 'خانه‌ای را علامت بزن؛ مهره‌های حریف که اول نوبتش آنجا باشند آن نوبت گیر می‌کنند.',
    target: TargetKind.enemyOrEmpty,
    glyph: 18,
  ),
  CardDef(
    id: CardId.tollGate,
    rarity: Rarity.common,
    category: CardCategory.trap,
    nameEn: 'Toll Gate',
    nameFa: 'عوارضی',
    descEn: 'Mark a point. For 4 turns your opponent spends 1 extra pip to pass over it.',
    descFa: 'خانه‌ای را علامت بزن؛ تا چهار نوبت، حریف برای عبور از آن یک خانه بیشتر خرج می‌کند.',
    target: TargetKind.enemyOrEmpty,
    glyph: 19,
  ),
  // TEMPO / META
  CardDef(
    id: CardId.timeStop,
    rarity: Rarity.legendary,
    category: CardCategory.tempo,
    nameEn: 'Time Stop',
    nameFa: 'توقف زمان',
    descEn: 'Take an extra full turn right after this one.',
    descFa: 'بلافاصله بعد از این نوبت، یک نوبت کامل دیگر بازی کن.',
    drawbackEn: 'Your opponent picks one extra card at their next 7–7.',
    drawbackFa: 'حریف در هفت‌هفت بعدی‌اش یک کارت اضافه برمی‌دارد.',
    glyph: 20,
  ),
  CardDef(
    id: CardId.bloodPact,
    rarity: Rarity.legendary,
    category: CardCategory.tempo,
    nameEn: 'Blood Pact',
    nameFa: 'پیمان خون',
    descEn: 'If all your checkers are home, instantly bear off 2 of them.',
    descFa: 'اگر همهٔ مهره‌هایت در خانه باشند، فوراً دو مهره را خارج کن.',
    drawbackEn: 'Otherwise your most advanced checker is sent to the bar.',
    drawbackFa: 'وگرنه جلوترین مهره‌ات به بار فرستاده می‌شود.',
    glyph: 21,
  ),
  CardDef(
    id: CardId.gamblersCoin,
    rarity: Rarity.rare,
    category: CardCategory.tempo,
    nameEn: "Gambler's Coin",
    nameFa: 'سکه قمار',
    descEn: 'Flip a coin: heads, your opponent skips their next turn.',
    descFa: 'سکه بینداز: اگر شیر آمد، حریف نوبت بعدی‌اش را از دست می‌دهد.',
    drawbackEn: 'Tails, you skip your next turn.',
    drawbackFa: 'اگر خط آمد، تو نوبت بعدی‌ات را از دست می‌دهی.',
    glyph: 22,
  ),
  CardDef(
    id: CardId.greed,
    rarity: Rarity.common,
    category: CardCategory.tempo,
    nameEn: 'Greed',
    nameFa: 'طمع',
    descEn: 'Earn bonus coins at the end of the match if you win.',
    descFa: 'اگر بازی را ببری، در پایان سکهٔ اضافه می‌گیری.',
    drawbackEn: "Your opponent's next 7–7 offers one extra card.",
    drawbackFa: 'هفت‌هفت بعدی حریف یک کارت بیشتر پیشنهاد می‌دهد.',
    glyph: 23,
  ),
];

final Map<String, CardDef> kCardById = {for (final c in kCards) c.id: c};

CardDef cardById(String id) {
  final c = kCardById[id];
  if (c == null) throw ArgumentError('Unknown card $id');
  return c;
}

/// Coins granted per Greed stack on a win.
const int kGreedCoins = 40;
