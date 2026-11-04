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

  /// Two of your lone checkers (one if only one exists).
  ownBlot2,

  /// Two distinct empty points.
  emptyPoint2,

  /// Two distinct points that are empty or hold enemy checkers.
  enemyOrEmpty2,

  /// One enemy checker on the board.
  enemyChecker,

  /// One enemy lone checker on the board.
  enemyBlot,

  /// Two of your occupied points (one if only one exists).
  ownPoint2,

  /// One of your checkers that can move exactly 4 pips forward.
  sprint,
}

/// Target kinds whose points may be chosen in any order.
bool isUnorderedTarget(TargetKind k) =>
    k == TargetKind.enemyCheckers2 ||
    k == TargetKind.ownBlot2 ||
    k == TargetKind.emptyPoint2 ||
    k == TargetKind.enemyOrEmpty2 ||
    k == TargetKind.ownPoint2;

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
  static const twinAnchors = 'twin_anchors';
  static const bargain = 'bazaar_bargain';
  static const hourglassSand = 'hourglass_sand';
  static const simorgh = 'simorgh_blessing';
  static const nightfall = 'nightfall';
  static const lantern = 'lantern_truth';
  static const earthquake = 'earthquake';
  static const luckySix = 'lucky_six';
  static const vortex = 'vortex';
  static const minefield = 'minefield';
  static const truce = 'truce';
  static const tailwind = 'tailwind';
  static const headwind = 'headwind';
  static const evenOdds = 'even_odds';
  static const wardOnes = 'ward_ones';
  static const twinDice = 'twin_dice';
  static const royalRoll = 'royal_roll';
  static const silkPurse = 'silk_purse';
  static const leadenDice = 'leaden_dice';
  static const shackle = 'shackle';
  static const pickpocket = 'pickpocket';
  static const hexSevens = 'hex_sevens';
  static const sprint = 'sprint';
  static const shieldWall = 'shield_wall';
  static const homecoming = 'homecoming';
  static const reentry = 'reentry';
  static const stoneSkin = 'stone_skin';
  static const caltrops = 'caltrops';
  static const bait = 'bait';
  static const rally = 'rally';
  static const fortuneTeller = 'fortune_teller';
  static const destiny = 'destiny';
  static const highStakes = 'high_stakes';
  static const exile = 'exile';
  static const oasis = 'oasis';
  static const doubleAgent = 'double_agent';
  static const sandstorm = 'sandstorm';
  static const caravan = 'caravan';
  static const spiritWard = 'spirit_ward';
  static const mirage = 'mirage';
  static const mountainPass = 'mountain_pass';
  static const saffron = 'saffron';
  static const treasury = 'treasury';
  static const starReader = 'star_reader';
  static const sevenfold = 'sevenfold';
  static const hailstorm = 'hailstorm';
  static const falconEye = 'falcon_eye';
  static const ironDice = 'iron_dice';
  static const eclipse = 'eclipse';
  static const sultansFavor = 'sultans_favor';
  static const bandit = 'bandit';
  static const desertRose = 'desert_rose';
  static const twinSuns = 'twin_suns';
  static const coldSnap = 'cold_snap';
  static const pilgrimage = 'pilgrimage';
  static const stormEye = 'storm_eye';
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
    descEn: 'Next turn you roll 3 dice and keep the 2 you like.',
    descFa: 'نوبت بعد ۳ تاس می‌ریزی و ۲ تای دلخواهت رو نگه می‌داری',
  ),
  CardDef(
    id: CardId.doubleDown,
    rarity: Rarity.epic,
    category: CardCategory.dice,
    nameEn: 'Roll Again',
    nameFa: 'تاس دوباره',
    descEn: 'Roll again this turn and play both rolls.',
    descFa: 'همین نوبت دوباره تاس می‌ریزی و هر دو رو بازی می‌کنی',
    glyph: 1,
  ),
  CardDef(
    id: CardId.fatesEdit,
    rarity: Rarity.rare,
    category: CardCategory.dice,
    nameEn: "Fate's Edit",
    nameFa: 'دست تقدیر',
    descEn: 'Next turn you set one of your dice to any number.',
    descFa: 'نوبت بعد یکی از تاس‌هات رو هر عددی بخوای می‌کنی',
    glyph: 2,
  ),
  CardDef(
    id: CardId.secondChance,
    rarity: Rarity.common,
    category: CardCategory.dice,
    nameEn: 'Second Chance',
    nameFa: 'بخت دوباره',
    descEn: 'Get a reroll token: reroll your dice any time before moving.',
    descFa: 'یه ژتون تکرار تاس می‌گیری؛ هر وقت خواستی تاس رو دوباره بریز',
    glyph: 3,
  ),
  CardDef(
    id: CardId.luckyCharm,
    rarity: Rarity.common,
    category: CardCategory.dice,
    nameEn: 'Lucky Charm',
    nameFa: 'طلسم بخت',
    descEn: 'Get a Lucky Charm: once, add +1 to one of your dice.',
    descFa: 'یه طلسم بخت می‌گیری: یه بار +۱ به یکی از تاس‌هات',
    glyph: 4,
  ),
  CardDef(
    id: CardId.sevenMagnet,
    rarity: Rarity.common,
    category: CardCategory.dice,
    nameEn: 'Seven Magnet',
    nameFa: 'آهنربای هفت',
    descEn: 'For 5 turns your chance of 7–7 is doubled.',
    descFa: '۵ نوبت شانس هفت‌هفتت دو برابر می‌شه',
    glyph: 5,
  ),
  // SABOTAGE
  CardDef(
    id: CardId.brokenDie,
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Broken Die',
    nameFa: 'تاس شکسته',
    descEn: 'For 2 turns your opponent rolls only one die.',
    descFa: 'حریف ۲ نوبت فقط با یه تاس بازی می‌کنه',
    glyph: 6,
  ),
  CardDef(
    id: CardId.chains,
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Chains',
    nameFa: 'زنجیر',
    descEn: "Pick 2 enemy checkers: they can't move for 2 turns.",
    descFa: '۲ مهره‌ی حریف رو انتخاب کن — ۲ نوبت نمی‌تونن حرکت کنن',
    target: TargetKind.enemyCheckers2,
    glyph: 7,
  ),
  CardDef(
    id: CardId.fog,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Fog',
    nameFa: 'مه',
    descEn: 'For 3 turns your opponent: dice max 5, no doubles, no 7–7.',
    descFa: 'حریف ۳ نوبت تو مه‌ه: تاس حداکثر ۵، بدون جفت و هفت‌هفت',
    glyph: 8,
  ),
  CardDef(
    id: CardId.curse,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Curse of Small Numbers',
    nameFa: 'نفرین کوچکی',
    descEn: "For 2 turns your opponent's dice are halved (6→3), no doubles.",
    descFa: '۲ نوبت تاس‌های حریف نصف می‌شه (۶ می‌شه ۳) و جفت حساب نمی‌شه',
    glyph: 9,
  ),
  CardDef(
    id: CardId.mirror,
    rarity: Rarity.epic,
    category: CardCategory.sabotage,
    nameEn: 'Mirror',
    nameFa: 'آینه',
    descEn: "Your opponent's next roll is copied to you as a bonus next turn.",
    descFa: 'تاس بعدی حریف کپی می‌شه و نوبت بعد مال تو هم هست',
    glyph: 10,
  ),
  CardDef(
    id: CardId.thief,
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Thief',
    nameFa: 'دزد',
    descEn: "Steal one of your opponent's charges, or get a reroll token.",
    descFa: 'یکی از ژتون‌های حریف رو می‌دزدی؛ اگه نداشت یه تکرار تاس می‌گیری',
    glyph: 11,
  ),
  // CHECKER POWERS
  CardDef(
    id: CardId.holyShield,
    rarity: Rarity.common,
    category: CardCategory.checker,
    nameEn: 'Holy Shield',
    nameFa: 'سپر مقدس',
    descEn: "Pick one of your checkers: it can't be hit for 3 turns.",
    descFa: 'یه مهره‌ت رو انتخاب کن — ۳ نوبت کسی نمی‌تونه بزنتش',
    target: TargetKind.ownChecker,
    glyph: 12,
  ),
  CardDef(
    id: CardId.ironGate,
    rarity: Rarity.rare,
    category: CardCategory.checker,
    nameEn: 'Iron Gate',
    nameFa: 'دروازه آهنی',
    descEn: 'Pick a lone checker: for 2 turns it blocks like a made point.',
    descFa:
        'یه مهره‌ی تکت رو انتخاب کن — ۲ نوبت مثل خونه‌ی بسته راه رو می‌بنده',
    target: TargetKind.ownBlot,
    glyph: 13,
  ),
  CardDef(
    id: CardId.ghostStep,
    rarity: Rarity.epic,
    category: CardCategory.checker,
    nameEn: 'Ghost Step',
    nameFa: 'گام شبح',
    descEn:
        'Once, if your landing point is blocked, your checker glides past it.',
    descFa: 'یه بار اگه جای فرودت بسته بود، مهره‌ت از روش رد می‌شه',
    glyph: 14,
  ),
  CardDef(
    id: CardId.phoenix,
    rarity: Rarity.common,
    category: CardCategory.checker,
    nameEn: 'Phoenix',
    nameFa: 'ققنوس',
    descEn: 'The next checker of yours that gets hit comes straight back in.',
    descFa: 'اولین مهره‌ت که زده بشه فوری برمی‌گرده تو بازی',
    glyph: 15,
  ),
  CardDef(
    id: CardId.teleport,
    rarity: Rarity.epic,
    category: CardCategory.checker,
    nameEn: 'Teleport',
    nameFa: 'جابه‌جایی',
    descEn: 'Move one of your checkers 1–3 pips forward, no dice needed.',
    descFa: 'یه مهره‌ت رو ۱ تا ۳ خونه جلو ببر، بدون تاس',
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
    descEn: 'Hide a mine on an empty point for 8 turns: an enemy that lands goes to the bar.',
    descFa:
        'رو یه خونه‌ی خالی مین بذار — ۸ نوبت؛ مهره‌ی حریف بیاد می‌پره رو بار',
    target: TargetKind.emptyPoint,
    glyph: 17,
  ),
  CardDef(
    id: CardId.quicksand,
    rarity: Rarity.common,
    category: CardCategory.trap,
    nameEn: 'Quicksand',
    nameFa: 'باتلاق',
    descEn:
        'Mark a point for 6 turns: enemy checkers there get stuck for a turn.',
    descFa: 'یه خونه رو ماسه‌ی روان کن — ۶ نوبت؛ مهره‌ی حریف اون‌جا گیر می‌کنه',
    target: TargetKind.enemyOrEmpty,
    glyph: 18,
  ),
  CardDef(
    id: CardId.tollGate,
    rarity: Rarity.common,
    category: CardCategory.trap,
    nameEn: 'Toll Gate',
    nameFa: 'عوارضی',
    descEn:
        'Mark a point for 8 turns: your opponent pays 1 extra pip to pass it.',
    descFa:
        'یه خونه رو عوارضی کن — ۸ نوبت؛ حریف برای رد شدن ۱ خونه بیشتر می‌ده',
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
    descEn: 'Take one more full turn right after this one.',
    descFa: 'بعد از این نوبت، یه نوبت کامل دیگه هم بازی می‌کنی',
    drawbackEn: 'Your opponent picks one extra card at their next 7–7.',
    drawbackFa: 'حریف تو هفت‌هفت بعدیش یه کارت اضافه برمی‌داره',
    glyph: 20,
  ),
  CardDef(
    id: CardId.bloodPact,
    rarity: Rarity.legendary,
    category: CardCategory.tempo,
    nameEn: 'Blood Pact',
    nameFa: 'پیمان خون',
    descEn: 'If all your checkers are home, bear off 2 of them right now.',
    descFa: 'اگه همه‌ی مهره‌هات تو خونه‌ان، همین الان ۲ تا رو بیرون ببر',
    drawbackEn:
        'The pact is paid in blood: your opponent gains a reroll token.',
    drawbackFa: 'بهای پیمان: حریف یه ژتون تکرار تاس می‌گیره',
    glyph: 21,
  ),
  CardDef(
    id: CardId.gamblersCoin,
    rarity: Rarity.rare,
    category: CardCategory.tempo,
    nameEn: "Gambler's Coin",
    nameFa: 'سکه قمار',
    descEn: 'Flip a coin: heads, your opponent skips their next turn.',
    descFa: 'سکه می‌اندازی: شیر بیاد، حریف نوبت بعدش رو از دست می‌ده',
    drawbackEn: 'Tails, you skip your next turn.',
    drawbackFa: 'خط بیاد، خودت نوبت بعدت رو از دست می‌دی',
    glyph: 22,
  ),
  CardDef(
    id: CardId.greed,
    rarity: Rarity.common,
    category: CardCategory.tempo,
    nameEn: 'Greed',
    nameFa: 'طمع',
    descEn: 'Win this game to earn bonus coins.',
    descFa: 'اگه این بازی رو ببری، سکه‌ی جایزه‌ی بیشتری می‌گیری',
    drawbackEn: "Your opponent's next 7–7 offers one extra card.",
    drawbackFa: 'هفت‌هفت بعدی حریف یه کارت بیشتر داره',
    glyph: 23,
  ),
  // EXPANSION 1
  CardDef(
    id: CardId.twinAnchors,
    rarity: Rarity.rare,
    category: CardCategory.checker,
    nameEn: 'Twin Anchors',
    nameFa: 'لنگرهای دوقلو',
    descEn: 'Pick 2 lone checkers: for 2 turns each blocks like a made point.',
    descFa: '۲ مهره‌ی تکت رو انتخاب کن — ۲ نوبت مثل خونه‌ی بسته راه رو می‌بندن',
    target: TargetKind.ownBlot2,
    glyph: 24,
  ),
  CardDef(
    id: CardId.bargain,
    rarity: Rarity.common,
    category: CardCategory.dice,
    nameEn: 'Bazaar Bargain',
    nameFa: 'چانه‌زنی بازار',
    descEn: 'Get a reroll token and a Lucky Charm.',
    descFa: 'یه ژتون تکرار تاس و یه طلسم بخت می‌گیری',
    drawbackEn:
        'A bargain cuts both ways: your opponent gains a Lucky Charm too.',
    drawbackFa: 'معامله دوطرفه‌ست: حریف هم یه طلسم بخت می‌گیره',
    glyph: 25,
  ),
  CardDef(
    id: CardId.hourglassSand,
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Hourglass Sand',
    nameFa: 'شن ساعت',
    descEn: 'Next turn your opponent: dice max 4, doubles count as normal.',
    descFa: 'نوبت بعد حریف: تاس حداکثر ۴ و جفتش معمولی حساب می‌شه',
    glyph: 26,
  ),
  CardDef(
    id: CardId.simorgh,
    rarity: Rarity.rare,
    category: CardCategory.checker,
    nameEn: "Simorgh's Blessing",
    nameFa: 'برکت سیمرغ',
    descEn: 'Get 2 Phoenixes: your next 2 hit checkers come straight back in.',
    descFa: '۲ ققنوس می‌گیری: ۲ مهره‌ی بعدی‌ت که زده بشن فوری برمی‌گردن',
    glyph: 27,
  ),
  CardDef(
    id: CardId.nightfall,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Nightfall',
    nameFa: 'شب‌هنگام',
    descEn: "Your opponent can't roll 7–7 for 6 turns.",
    descFa: 'حریف ۶ نوبت هفت‌هفت نمی‌آره',
    glyph: 28,
  ),
  CardDef(
    id: CardId.lantern,
    rarity: Rarity.common,
    category: CardCategory.trap,
    nameEn: 'Lantern of Truth',
    nameFa: 'فانوس حقیقت',
    descEn:
        "Reveal and destroy all your opponent's mines, quicksand and tolls.",
    descFa: 'همه‌ی مین‌ها، ماسه‌ها و عوارضی‌های حریف پیدا و نابود می‌شن',
    glyph: 29,
  ),
  CardDef(
    id: CardId.earthquake,
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Earthquake',
    nameFa: 'زلزله',
    descEn:
        'Break the chains and quicksand on you, and enemy shields and gates.',
    descFa: 'زنجیر و ماسه‌ی مهره‌هات می‌شکنه، سپر و دروازه‌ی حریف هم',
    glyph: 30,
  ),
  CardDef(
    id: CardId.luckySix,
    rarity: Rarity.common,
    category: CardCategory.dice,
    nameEn: 'Lucky Six',
    nameFa: 'شش خوش',
    descEn: 'Next turn your first die is a 6.',
    descFa: 'نوبت بعد اولین تاست حتماً ۶ میاد',
    glyph: 31,
  ),
  CardDef(
    id: CardId.vortex,
    rarity: Rarity.rare,
    category: CardCategory.trap,
    nameEn: 'Vortex',
    nameFa: 'گرداب',
    descEn: 'Turn 2 points into quicksand for 6 turns.',
    descFa: '۲ خونه رو ماسه‌ی روان کن — ۶ نوبت',
    target: TargetKind.enemyOrEmpty2,
    glyph: 32,
  ),
  CardDef(
    id: CardId.minefield,
    rarity: Rarity.epic,
    category: CardCategory.trap,
    nameEn: 'Minefield',
    nameFa: 'میدان مین',
    descEn: 'Hide mines on 2 empty points for 8 turns.',
    descFa: 'رو ۲ خونه‌ی خالی مین مخفی بذار — ۸ نوبت',
    target: TargetKind.emptyPoint2,
    glyph: 33,
  ),
  CardDef(
    id: CardId.truce,
    rarity: Rarity.epic,
    category: CardCategory.tempo,
    nameEn: 'Truce',
    nameFa: 'آتش‌بس',
    descEn: 'For 2 turns no checker on either side can be hit.',
    descFa: '۲ نوبت هیچ مهره‌ای از هیچ‌کدوم زده نمی‌شه',
    glyph: 34,
  ),
  CardDef(
    id: CardId.tailwind,
    rarity: Rarity.common,
    category: CardCategory.dice,
    nameEn: 'Tailwind',
    nameFa: 'باد موافق',
    descEn: 'Next turn each of your dice gets +1 (up to 6).',
    descFa: 'نوبت بعد به هر کدوم از تاس‌هات ۱ اضافه می‌شه',
    glyph: 35,
  ),
  CardDef(
    id: CardId.headwind,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Headwind',
    nameFa: 'باد مخالف',
    descEn: "For 2 turns each of your opponent's dice gets −1.",
    descFa: '۲ نوبت از هر تاس حریف ۱ کم می‌شه',
    glyph: 36,
  ),
  // EXPANSION 2
  CardDef(
    id: CardId.evenOdds,
    rarity: Rarity.common,
    category: CardCategory.dice,
    nameEn: 'Even Odds',
    nameFa: 'زوج‌گرا',
    descEn: 'Next turn your odd dice go up by 1 to an even number.',
    descFa: 'نوبت بعد تاس‌های فردت یکی بالا می‌رن و زوج می‌شن',
    glyph: 37,
  ),
  CardDef(
    id: CardId.wardOnes,
    rarity: Rarity.common,
    category: CardCategory.dice,
    nameEn: 'Ward of Low Rolls',
    nameFa: 'دفع تاس کم',
    descEn: 'Next turn any 1 or 2 you roll is rerolled once.',
    descFa: 'نوبت بعد اگه ۱ یا ۲ بیاری، اون تاس یه بار دوباره ریخته می‌شه',
    glyph: 38,
  ),
  CardDef(
    id: CardId.twinDice,
    rarity: Rarity.epic,
    category: CardCategory.dice,
    nameEn: 'Twin Dice',
    nameFa: 'تاس‌های همزاد',
    descEn: 'Next turn you roll a guaranteed 6–6.',
    descFa: 'نوبت بعد حتماً جفت‌شش میاری',
    glyph: 39,
  ),
  CardDef(
    id: CardId.royalRoll,
    rarity: Rarity.rare,
    category: CardCategory.dice,
    nameEn: 'Royal Roll',
    nameFa: 'تاس شاهانه',
    descEn: 'Next turn none of your dice shows less than 3.',
    descFa: 'نوبت بعد هیچ تاسی کمتر از ۳ نمیاد',
    glyph: 40,
  ),
  CardDef(
    id: CardId.silkPurse,
    rarity: Rarity.rare,
    category: CardCategory.dice,
    nameEn: 'Silk Purse',
    nameFa: 'کیسهٔ ابریشم',
    descEn: 'Get 2 reroll tokens.',
    descFa: '۲ ژتون تکرار تاس می‌گیری',
    glyph: 41,
  ),
  CardDef(
    id: CardId.leadenDice,
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Leaden Dice',
    nameFa: 'تاس سربی',
    descEn: "For 2 turns your opponent's dice show at most 3.",
    descFa: '۲ نوبت تاس‌های حریف حداکثر ۳ میاد',
    glyph: 42,
  ),
  CardDef(
    id: CardId.shackle,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Shackle',
    nameFa: 'پابند',
    descEn: "Pick 1 enemy checker: it can't move for 4 turns.",
    descFa: 'یه مهره‌ی حریف رو انتخاب کن — ۴ نوبت نمی‌تونه حرکت کنه',
    target: TargetKind.enemyChecker,
    glyph: 43,
  ),
  CardDef(
    id: CardId.pickpocket,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Pickpocket',
    nameFa: 'جیب‌بر',
    descEn: "Steal all your opponent's reroll tokens, or get a Lucky Charm.",
    descFa:
        'همه‌ی تکرار تاس‌های حریف رو می‌دزدی؛ اگه نداشت یه طلسم بخت می‌گیری',
    glyph: 44,
  ),
  CardDef(
    id: CardId.hexSevens,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Hex of Sevens',
    nameFa: 'طلسم هفت‌ها',
    descEn: "Your opponent's next 7–7 shows one card fewer.",
    descFa: 'هفت‌هفت بعدی حریف یه کارت کمتر داره',
    glyph: 45,
  ),
  CardDef(
    id: CardId.sprint,
    rarity: Rarity.rare,
    category: CardCategory.checker,
    nameEn: 'Sprint',
    nameFa: 'دوندگی',
    descEn: 'Move one of your checkers exactly 4 pips forward, no dice needed.',
    descFa: 'یه مهره‌ت رو دقیقاً ۴ خونه جلو ببر، بدون تاس',
    target: TargetKind.sprint,
    glyph: 46,
  ),
  CardDef(
    id: CardId.shieldWall,
    rarity: Rarity.epic,
    category: CardCategory.checker,
    nameEn: 'Shield Wall',
    nameFa: 'دیوار سپر',
    descEn: "During your opponent's next turn none of your lone checkers can be hit.",
    descFa: 'نوبت بعد حریف، هیچ مهره‌ی تکت زده نمی‌شه',
    glyph: 47,
  ),
  CardDef(
    id: CardId.homecoming,
    rarity: Rarity.rare,
    category: CardCategory.tempo,
    nameEn: 'Homecoming',
    nameFa: 'بازگشت به خانه',
    descEn: 'If all your checkers are home, bear one off right now.',
    descFa: 'اگه همه‌ی مهره‌هات تو خونه‌ان، همین الان یکی رو بیرون ببر',
    glyph: 48,
  ),
  CardDef(
    id: CardId.reentry,
    rarity: Rarity.rare,
    category: CardCategory.checker,
    nameEn: 'Rallying Cry',
    nameFa: 'بانگ بازگشت',
    descEn: 'All your checkers on the bar re-enter at once.',
    descFa: 'همه‌ی مهره‌هات که رو بارن یک‌جا برمی‌گردن تو بازی',
    glyph: 49,
  ),
  CardDef(
    id: CardId.stoneSkin,
    rarity: Rarity.rare,
    category: CardCategory.checker,
    nameEn: 'Stone Skin',
    nameFa: 'پوست سنگی',
    descEn: "Pick 2 of your points: their checkers can't be hit for 3 turns.",
    descFa: '۲ خونه‌ت رو انتخاب کن — ۳ نوبت مهره‌هاش زده نمی‌شن',
    target: TargetKind.ownPoint2,
    glyph: 50,
  ),
  CardDef(
    id: CardId.caltrops,
    rarity: Rarity.rare,
    category: CardCategory.trap,
    nameEn: 'Caltrops',
    nameFa: 'خارپشت',
    descEn: 'Put toll gates on 2 points for 8 turns.',
    descFa: 'رو ۲ خونه عوارضی بذار — ۸ نوبت',
    target: TargetKind.enemyOrEmpty2,
    glyph: 51,
  ),
  CardDef(
    id: CardId.bait,
    rarity: Rarity.rare,
    category: CardCategory.trap,
    nameEn: 'Bait',
    nameFa: 'طعمه',
    descEn: 'Hide a mine under a lone checker for 8 turns: whoever hits it goes to the bar.',
    descFa: 'زیر یه مهره‌ی تکت مین بذار — ۸ نوبت؛ هر کی بزنتش می‌پره رو بار',
    target: TargetKind.ownBlot,
    glyph: 52,
  ),
  CardDef(
    id: CardId.rally,
    rarity: Rarity.rare,
    category: CardCategory.tempo,
    nameEn: 'Rally',
    nameFa: 'تجدید قوا',
    descEn:
        'Trailing by 20+ pips? Roll again now. Otherwise get a reroll token.',
    descFa: 'اگه ۲۰ خونه یا بیشتر عقبی، همین نوبت دوباره تاس بریز؛ وگرنه یه تکرار تاس',
    glyph: 53,
  ),
  CardDef(
    id: CardId.fortuneTeller,
    rarity: Rarity.common,
    category: CardCategory.tempo,
    nameEn: 'Fortune Teller',
    nameFa: 'فالگیر',
    descEn: 'Your next 7–7 shows 2 extra cards.',
    descFa: 'هفت‌هفت بعدی‌ت ۲ کارت بیشتر نشون می‌ده',
    glyph: 54,
  ),
  CardDef(
    id: CardId.destiny,
    rarity: Rarity.rare,
    category: CardCategory.tempo,
    nameEn: 'Destiny',
    nameFa: 'سرنوشت',
    descEn: 'At your next 7–7 you take 2 cards.',
    descFa: 'تو هفت‌هفت بعدی‌ت ۲ تا کارت برمی‌داری',
    glyph: 55,
  ),
  CardDef(
    id: CardId.highStakes,
    rarity: Rarity.rare,
    category: CardCategory.tempo,
    nameEn: 'High Stakes',
    nameFa: 'شرط سنگین',
    descEn: 'This game counts double.',
    descFa: 'امتیاز این دست دوبرابر می‌شه',
    drawbackEn: 'If you lose, you lose double too.',
    drawbackFa: 'اگه ببازی، دوبرابر می‌بازی',
    glyph: 56,
  ),
  CardDef(
    id: CardId.exile,
    rarity: Rarity.epic,
    category: CardCategory.sabotage,
    nameEn: 'Exile',
    nameFa: 'تبعید',
    descEn: 'Pick a lone enemy checker and send it to the bar.',
    descFa: 'یه مهره‌ی تک حریف رو انتخاب کن تا بره رو بار',
    target: TargetKind.enemyBlot,
    glyph: 57,
  ),
  CardDef(
    id: CardId.oasis,
    rarity: Rarity.common,
    category: CardCategory.tempo,
    nameEn: 'Oasis',
    nameFa: 'واحه',
    descEn: 'Wash away every dice curse your opponent put on you.',
    descFa: 'همه‌ی طلسم‌های تاسی که حریف روی تو گذاشته پاک می‌شه',
    glyph: 58,
  ),
  CardDef(
    id: CardId.doubleAgent,
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Double Agent',
    nameFa: 'جاسوس دوجانبه',
    descEn: "Copy your opponent's last card, or get a reroll token.",
    descFa: 'آخرین کارت حریف رو کپی می‌کنی؛ اگه نشد یه تکرار تاس می‌گیری',
    glyph: 59,
  ),
  CardDef(
    id: CardId.sandstorm,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Sandstorm',
    nameFa: 'طوفان شن',
    descEn: 'Next turn your opponent: dice max 4, no doubles.',
    descFa: 'نوبت بعد حریف: تاس حداکثر ۴ و بدون جفت',
    glyph: 60,
  ),
  CardDef(
    id: CardId.caravan,
    rarity: Rarity.common,
    category: CardCategory.tempo,
    nameEn: 'Caravan',
    nameFa: 'کاروان',
    descEn: 'Get a reroll token and a Lucky Charm, free.',
    descFa: 'یه تکرار تاس و یه طلسم بخت می‌گیری، بی‌هزینه',
    glyph: 61,
  ),
  CardDef(
    id: CardId.spiritWard,
    rarity: Rarity.rare,
    category: CardCategory.checker,
    nameEn: 'Spirit Ward',
    nameFa: 'حرز روح',
    descEn: 'Get a Phoenix and a Ghost Step.',
    descFa: 'یه ققنوس و یه گام شبح می‌گیری',
    glyph: 62,
  ),
  CardDef(
    id: CardId.mirage,
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Mirage',
    nameFa: 'سراب',
    descEn: "Your opponent's next roll is halved and they can't roll 7–7 for 2 turns.",
    descFa: 'تاس بعدی حریف نصف می‌شه و ۲ نوبت هفت‌هفت نمی‌آره',
    glyph: 63,
  ),
  CardDef(
    id: CardId.mountainPass,
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Mountain Pass',
    nameFa: 'گردنه',
    descEn: 'Next turn your opponent rolls one die, and it counts 1 less.',
    descFa: 'نوبت بعد حریف فقط یه تاس می‌ریزه، اونم ۱ کمتر',
    glyph: 64,
  ),
  CardDef(
    id: CardId.saffron,
    rarity: Rarity.rare,
    category: CardCategory.dice,
    nameEn: 'Saffron Thread',
    nameFa: 'رشتهٔ زعفران',
    descEn: 'Next turn 1s and 2s are rerolled and odd dice become even.',
    descFa: 'نوبت بعد ۱ و ۲ دوباره ریخته می‌شن و تاس فرد زوج می‌شه',
    glyph: 65,
  ),
  CardDef(
    id: CardId.treasury,
    rarity: Rarity.rare,
    category: CardCategory.tempo,
    nameEn: 'Royal Treasury',
    nameFa: 'خزانهٔ شاهی',
    descEn: 'Get 2 reroll tokens and a Phoenix.',
    descFa: '۲ تکرار تاس و یه ققنوس می‌گیری',
    glyph: 69,
  ),
  CardDef(
    id: CardId.starReader,
    rarity: Rarity.epic,
    category: CardCategory.tempo,
    nameEn: 'Star Reader',
    nameFa: 'ستاره‌خوان',
    descEn: 'Your next 7–7 shows 2 extra cards and you take 2.',
    descFa: 'هفت‌هفت بعدی‌ت ۲ کارت بیشتر داره و ۲ تا برمی‌داری',
    glyph: 66,
  ),
  CardDef(
    id: CardId.sevenfold,
    rarity: Rarity.epic,
    category: CardCategory.tempo,
    nameEn: 'Sevenfold',
    nameFa: 'هفت‌گانه',
    descEn:
        'For 5 turns your 7–7 chance doubles; their next 7–7 has 1 card fewer.',
    descFa: '۵ نوبت شانس هفت‌هفتت دوبرابر، هفت‌هفت بعدی حریف یه کارت کمتر',
    glyph: 67,
  ),
  CardDef(
    id: CardId.hailstorm,
    rarity: Rarity.epic,
    category: CardCategory.sabotage,
    nameEn: 'Hailstorm',
    nameFa: 'تگرگ',
    descEn: "For 2 turns your opponent's dice get −1 and doubles don't count.",
    descFa: '۲ نوبت از تاس‌های حریف ۱ کم می‌شه و جفتش حساب نمی‌شه',
    glyph: 68,
  ),
  CardDef(
    id: CardId.falconEye,
    rarity: Rarity.rare,
    category: CardCategory.dice,
    nameEn: "Falcon's Eye",
    nameFa: 'چشم شاهین',
    descEn: 'Next turn one die is a 6, and a 1 or 2 on the other is rerolled.',
    descFa:
        'نوبت بعد یه تاست ۶ میاد و اگه اون یکی ۱ یا ۲ بود دوباره ریخته می‌شه',
    glyph: 70,
  ),
  CardDef(
    id: CardId.ironDice,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Iron Dice',
    nameFa: 'تاس آهنی',
    descEn: "For 2 turns your opponent's dice show at most 4.",
    descFa: '۲ نوبت تاس‌های حریف حداکثر ۴ میاد',
    glyph: 71,
  ),
  CardDef(
    id: CardId.eclipse,
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Eclipse',
    nameFa: 'خورشیدگرفتگی',
    descEn: "Your opponent can't roll 7–7 for 4 turns; their next one has 1 card fewer.",
    descFa: 'حریف ۴ نوبت هفت‌هفت نمی‌آره و هفت‌هفت بعدیش یه کارت کمتر داره',
    glyph: 72,
  ),
  CardDef(
    id: CardId.sultansFavor,
    rarity: Rarity.epic,
    category: CardCategory.dice,
    nameEn: "Sultan's Favor",
    nameFa: 'عنایت سلطان',
    descEn: 'Next turn every die you roll is a 4 or a 6.',
    descFa: 'نوبت بعد همه‌ی تاس‌هات ۴ یا ۶ میاد',
    glyph: 73,
  ),
  CardDef(
    id: CardId.bandit,
    rarity: Rarity.rare,
    category: CardCategory.tempo,
    nameEn: 'Bandit',
    nameFa: 'راهزن',
    descEn: 'Steal an enemy charge; their next 7–7 shows one card fewer.',
    descFa: 'یه ژتون حریف رو می‌دزدی و هفت‌هفت بعدیش یه کارت کمتر داره',
    glyph: 74,
  ),
  CardDef(
    id: CardId.desertRose,
    rarity: Rarity.common,
    category: CardCategory.checker,
    nameEn: 'Desert Rose',
    nameFa: 'گل سرخ صحرا',
    descEn: 'Get a Ghost Step and a Lucky Charm.',
    descFa: 'یه گام شبح و یه طلسم بخت می‌گیری',
    glyph: 75,
  ),
  CardDef(
    id: CardId.twinSuns,
    rarity: Rarity.legendary,
    category: CardCategory.tempo,
    nameEn: 'Twin Suns',
    nameFa: 'خورشیدهای همزاد',
    descEn:
        'Next turn you roll 6–6, and you take an extra card at your next 7–7.',
    descFa:
        'نوبت بعد حتماً جفت‌شش میاری و تو هفت‌هفت بعدی یه کارت اضافه برمی‌داری',
    drawbackEn: "Your opponent's next 7–7 offers one extra card.",
    drawbackFa: 'هفت‌هفت بعدی حریف یه کارت بیشتر داره',
    glyph: 76,
  ),
  CardDef(
    id: CardId.coldSnap,
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Cold Snap',
    nameFa: 'سرمای ناگهانی',
    descEn: "Next turn your opponent rolls one die, and can't roll 7–7 for 2 turns.",
    descFa: 'نوبت بعد حریف فقط یه تاس می‌ریزه و ۲ نوبت هفت‌هفت نمی‌آره',
    glyph: 77,
  ),
  CardDef(
    id: CardId.pilgrimage,
    rarity: Rarity.common,
    category: CardCategory.tempo,
    nameEn: 'Pilgrimage',
    nameFa: 'زیارت',
    descEn: 'Get a reroll token; your next 7–7 shows one extra card.',
    descFa: 'یه تکرار تاس می‌گیری و هفت‌هفت بعدی‌ت یه کارت بیشتر داره',
    glyph: 78,
  ),
  CardDef(
    id: CardId.stormEye,
    rarity: Rarity.epic,
    category: CardCategory.sabotage,
    nameEn: 'Eye of the Storm',
    nameFa: 'چشم توفان',
    descEn: 'Next turn your opponent rolls one die, then 2 turns of fog: no doubles, max 5.',
    descFa: 'نوبت بعد حریف یه تاس می‌ریزه، بعد ۲ نوبت تو مه: بدون جفت، تاس حداکثر ۵',
    glyph: 79,
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
