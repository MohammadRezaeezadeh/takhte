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
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Broken Die',
    nameFa: 'تاس شکسته',
    descEn: 'Your opponent rolls only one die for their next 2 turns.',
    descFa: 'حریف تا دو نوبت بعدی‌اش فقط با یک تاس بازی می‌کند.',
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
    descEn:
        'For 3 turns your opponent is lost in the fog: dice max 5, '
        'no doubles and no 7–7.',
    descFa:
        'حریف تا سه نوبت در مه گم است: تاس حداکثر ۵، '
        'نه جفت حساب می‌شود و نه هفت‌هفت می‌آید.',
    glyph: 8,
  ),
  CardDef(
    id: CardId.curse,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Curse of Small Numbers',
    nameFa: 'نفرین کوچکی',
    descEn:
        "Your opponent's next 2 rolls are halved, rounded up (6 becomes 3), "
        'and doubles do not count.',
    descFa:
        'دو تاس بعدی حریف نصف می‌شود (رو به بالا؛ ۶ می‌شود ۳) '
        'و جفت حساب نمی‌شود.',
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
    descEn: 'Mark a point. For 8 turns your opponent spends 1 extra pip to pass over it.',
    descFa: 'خانه‌ای را علامت بزن؛ تا هشت نوبت، حریف برای عبور از آن یک خانه بیشتر خرج می‌کند.',
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
  // EXPANSION 1
  CardDef(
    id: CardId.twinAnchors,
    rarity: Rarity.rare,
    category: CardCategory.checker,
    nameEn: 'Twin Anchors',
    nameFa: 'لنگرهای دوقلو',
    descEn: "Two of your lone checkers each block their point for 2 of your opponent's turns.",
    descFa: 'دو مهرهٔ تنهای تو هر کدام تا دو نوبتِ حریف خانه‌شان را می‌بندند.',
    target: TargetKind.ownBlot2,
    glyph: 24,
  ),
  CardDef(
    id: CardId.bargain,
    rarity: Rarity.common,
    category: CardCategory.dice,
    nameEn: 'Bazaar Bargain',
    nameFa: 'چانه‌زنی بازار',
    descEn: 'Gain a reroll token and a Lucky Charm.',
    descFa: 'یک ژتون تاس دوباره و یک طلسم بخت بگیر.',
    drawbackEn:
        'A bargain cuts both ways: your opponent gains a Lucky Charm too.',
    drawbackFa: 'معامله دوطرفه است: حریف هم یک طلسم بخت می‌گیرد.',
    glyph: 25,
  ),
  CardDef(
    id: CardId.hourglassSand,
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Hourglass Sand',
    nameFa: 'شن ساعت',
    descEn: "Next turn your opponent's dice are capped at 4 and their doubles count as a normal roll.",
    descFa: 'نوبت بعد تاس‌های حریف حداکثر ۴ می‌آیند و جفتش مثل تاس معمولی حساب می‌شود.',
    glyph: 26,
  ),
  CardDef(
    id: CardId.simorgh,
    rarity: Rarity.rare,
    category: CardCategory.checker,
    nameEn: "Simorgh's Blessing",
    nameFa: 'برکت سیمرغ',
    descEn: 'Gain two Phoenix charges: your next two hit checkers re-enter instantly.',
    descFa: 'دو ققنوس بگیر: دو مهرهٔ بعدی‌ات که زده شوند فوراً دوباره وارد می‌شوند.',
    glyph: 27,
  ),
  CardDef(
    id: CardId.nightfall,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Nightfall',
    nameFa: 'شب‌هنگام',
    descEn: 'Your opponent cannot roll 7–7 during their next 6 turns.',
    descFa: 'حریف تا شش نوبت بعدی‌اش نمی‌تواند هفت‌هفت بیاورد.',
    glyph: 28,
  ),
  CardDef(
    id: CardId.lantern,
    rarity: Rarity.common,
    category: CardCategory.trap,
    nameEn: 'Lantern of Truth',
    nameFa: 'فانوس حقیقت',
    descEn: "Reveal and destroy all of your opponent's mines, quicksand and toll gates.",
    descFa: 'همهٔ مین‌ها، باتلاق‌ها و عوارضی‌های حریف را آشکار و نابود کن.',
    glyph: 29,
  ),
  CardDef(
    id: CardId.earthquake,
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Earthquake',
    nameFa: 'زلزله',
    descEn: 'Break every chain and quicksand on your checkers and shatter enemy shields and gates.',
    descFa: 'همهٔ زنجیرها و باتلاق‌های روی مهره‌هایت را بشکن و سپرها و دروازه‌های حریف را خرد کن.',
    glyph: 30,
  ),
  CardDef(
    id: CardId.luckySix,
    rarity: Rarity.common,
    category: CardCategory.dice,
    nameEn: 'Lucky Six',
    nameFa: 'شش خوش',
    descEn: 'Next turn, your first die is a 6.',
    descFa: 'نوبت بعد، تاس اولت ۶ می‌آید.',
    glyph: 31,
  ),
  CardDef(
    id: CardId.vortex,
    rarity: Rarity.rare,
    category: CardCategory.trap,
    nameEn: 'Vortex',
    nameFa: 'گرداب',
    descEn: 'Mark two points with quicksand.',
    descFa: 'دو خانه را باتلاقی کن.',
    target: TargetKind.enemyOrEmpty2,
    glyph: 32,
  ),
  CardDef(
    id: CardId.minefield,
    rarity: Rarity.epic,
    category: CardCategory.trap,
    nameEn: 'Minefield',
    nameFa: 'میدان مین',
    descEn: 'Hide mines on two empty points.',
    descFa: 'روی دو خانهٔ خالی مین پنهان کن.',
    target: TargetKind.emptyPoint2,
    glyph: 33,
  ),
  CardDef(
    id: CardId.truce,
    rarity: Rarity.epic,
    category: CardCategory.tempo,
    nameEn: 'Truce',
    nameFa: 'آتش‌بس',
    descEn: "No checker on either side can be hit until your opponent's second turn ends.",
    descFa: 'تا پایان دومین نوبتِ حریف، هیچ مهره‌ای از دو طرف زده نمی‌شود.',
    glyph: 34,
  ),
  CardDef(
    id: CardId.tailwind,
    rarity: Rarity.common,
    category: CardCategory.dice,
    nameEn: 'Tailwind',
    nameFa: 'باد موافق',
    descEn: 'Next turn, add 1 to each of your dice (up to 6).',
    descFa: 'نوبت بعد، به هر تاست یکی اضافه می‌شود (تا ۶).',
    glyph: 35,
  ),
  CardDef(
    id: CardId.headwind,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Headwind',
    nameFa: 'باد مخالف',
    descEn: "For their next 2 turns, subtract 1 from each of your opponent's dice (down to 1).",
    descFa: 'تا دو نوبت بعدی حریف، از هر تاسش یکی کم می‌شود (تا ۱).',
    glyph: 36,
  ),
  // EXPANSION 2
  CardDef(
    id: CardId.evenOdds,
    rarity: Rarity.common,
    category: CardCategory.dice,
    nameEn: 'Even Odds',
    nameFa: 'زوج‌گرا',
    descEn:
        'Next turn, every odd die you roll is raised to the next even number.',
    descFa: 'نوبت بعد، هر تاس فردی که بیاوری به عدد زوج بعدی بالا می‌رود.',
    glyph: 37,
  ),
  CardDef(
    id: CardId.wardOnes,
    rarity: Rarity.common,
    category: CardCategory.dice,
    nameEn: 'Ward of Low Rolls',
    nameFa: 'دفع تاس کم',
    descEn: 'Next turn, any die that shows 1 or 2 is rerolled once.',
    descFa: 'نوبت بعد، هر تاسی که ۱ یا ۲ بیاید یک بار دوباره ریخته می‌شود.',
    glyph: 38,
  ),
  CardDef(
    id: CardId.twinDice,
    rarity: Rarity.epic,
    category: CardCategory.dice,
    nameEn: 'Twin Dice',
    nameFa: 'تاس‌های همزاد',
    descEn: 'Next turn you roll a guaranteed 6–6.',
    descFa: 'نوبت بعد حتماً جفت‌شش می‌آوری.',
    glyph: 39,
  ),
  CardDef(
    id: CardId.royalRoll,
    rarity: Rarity.rare,
    category: CardCategory.dice,
    nameEn: 'Royal Roll',
    nameFa: 'تاس شاهانه',
    descEn: 'Next turn, none of your dice can show less than 3.',
    descFa: 'نوبت بعد، هیچ‌کدام از تاس‌هایت کمتر از ۳ نمی‌آید.',
    glyph: 40,
  ),
  CardDef(
    id: CardId.silkPurse,
    rarity: Rarity.rare,
    category: CardCategory.dice,
    nameEn: 'Silk Purse',
    nameFa: 'کیسهٔ ابریشم',
    descEn: 'Gain two reroll tokens.',
    descFa: 'دو ژتون تاس دوباره بگیر.',
    glyph: 41,
  ),
  CardDef(
    id: CardId.leadenDice,
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Leaden Dice',
    nameFa: 'تاس سربی',
    descEn: "Your opponent's dice are capped at 3 for their next 2 turns.",
    descFa: 'تاس‌های حریف تا دو نوبت بعدی‌اش حداکثر ۳ می‌آیند.',
    glyph: 42,
  ),
  CardDef(
    id: CardId.shackle,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Shackle',
    nameFa: 'پابند',
    descEn: 'Chain one enemy checker for 4 of their turns.',
    descFa: 'یک مهرهٔ حریف را تا چهار نوبتِ او به زنجیر بکش.',
    target: TargetKind.enemyChecker,
    glyph: 43,
  ),
  CardDef(
    id: CardId.pickpocket,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Pickpocket',
    nameFa: 'جیب‌بر',
    descEn: "Steal all of your opponent's reroll tokens. If they have none, gain a Lucky Charm.",
    descFa:
        'همهٔ ژتون‌های تاس دوبارهٔ حریف را بدزد؛ اگر نداشت، یک طلسم بخت بگیر.',
    glyph: 44,
  ),
  CardDef(
    id: CardId.hexSevens,
    rarity: Rarity.common,
    category: CardCategory.sabotage,
    nameEn: 'Hex of Sevens',
    nameFa: 'طلسم هفت‌ها',
    descEn: "Your opponent's next 7–7 offers one card fewer.",
    descFa: 'هفت‌هفت بعدی حریف یک کارت کمتر پیشنهاد می‌دهد.',
    glyph: 45,
  ),
  CardDef(
    id: CardId.sprint,
    rarity: Rarity.rare,
    category: CardCategory.checker,
    nameEn: 'Sprint',
    nameFa: 'دوندگی',
    descEn:
        'Move one of your checkers exactly 4 pips forward, outside the dice.',
    descFa: 'یکی از مهره‌هایت را بیرون از تاس دقیقاً ۴ خانه جلو ببر.',
    target: TargetKind.sprint,
    glyph: 46,
  ),
  CardDef(
    id: CardId.shieldWall,
    rarity: Rarity.epic,
    category: CardCategory.checker,
    nameEn: 'Shield Wall',
    nameFa: 'دیوار سپر',
    descEn: "Every lone checker of yours cannot be hit during your opponent's next turn.",
    descFa: 'در نوبت بعدی حریف، هیچ مهرهٔ تنهای تو زده نمی‌شود.',
    glyph: 47,
  ),
  CardDef(
    id: CardId.homecoming,
    rarity: Rarity.rare,
    category: CardCategory.tempo,
    nameEn: 'Homecoming',
    nameFa: 'بازگشت به خانه',
    descEn: 'If all your checkers are home, bear one off now.',
    descFa: 'اگر همهٔ مهره‌هایت در خانه‌اند، همین حالا یکی را خارج کن.',
    glyph: 48,
  ),
  CardDef(
    id: CardId.reentry,
    rarity: Rarity.rare,
    category: CardCategory.checker,
    nameEn: 'Rallying Cry',
    nameFa: 'بانگ بازگشت',
    descEn: 'All your checkers on the bar re-enter at once on the furthest open points.',
    descFa:
        'همهٔ مهره‌هایت روی بار یک‌جا در دورترین خانه‌های باز وارد می‌شوند.',
    glyph: 49,
  ),
  CardDef(
    id: CardId.stoneSkin,
    rarity: Rarity.rare,
    category: CardCategory.checker,
    nameEn: 'Stone Skin',
    nameFa: 'پوست سنگی',
    descEn: "Holy Shield two of your points for 3 of your opponent's turns.",
    descFa: 'دو خانهٔ تو تا سه نوبتِ حریف «سپر مقدس» می‌گیرند.',
    target: TargetKind.ownPoint2,
    glyph: 50,
  ),
  CardDef(
    id: CardId.caltrops,
    rarity: Rarity.rare,
    category: CardCategory.trap,
    nameEn: 'Caltrops',
    nameFa: 'خارپشت',
    descEn: 'Place toll gates on two points for 8 turns.',
    descFa: 'روی دو خانه تا هشت نوبت عوارضی بگذار.',
    target: TargetKind.enemyOrEmpty2,
    glyph: 51,
  ),
  CardDef(
    id: CardId.bait,
    rarity: Rarity.rare,
    category: CardCategory.trap,
    nameEn: 'Bait',
    nameFa: 'طعمه',
    descEn: 'Hide a mine under one of your lone checkers: whoever hits it goes to the bar too.',
    descFa: 'زیر یکی از مهره‌های تنهایت مین پنهان کن: هر کس آن را بزند خودش هم به بار می‌رود.',
    target: TargetKind.ownBlot,
    glyph: 52,
  ),
  CardDef(
    id: CardId.rally,
    rarity: Rarity.rare,
    category: CardCategory.tempo,
    nameEn: 'Rally',
    nameFa: 'تجدید قوا',
    descEn: 'If you trail by 20+ pips, roll again this turn; otherwise gain a reroll token.',
    descFa: 'اگر ۲۰ خانه یا بیشتر عقبی، این نوبت دوباره تاس بریز؛ وگرنه یک ژتون تاس دوباره بگیر.',
    glyph: 53,
  ),
  CardDef(
    id: CardId.fortuneTeller,
    rarity: Rarity.common,
    category: CardCategory.tempo,
    nameEn: 'Fortune Teller',
    nameFa: 'فالگیر',
    descEn: 'Your next 7–7 offers two extra cards.',
    descFa: 'هفت‌هفت بعدی‌ات دو کارت بیشتر پیشنهاد می‌دهد.',
    glyph: 54,
  ),
  CardDef(
    id: CardId.destiny,
    rarity: Rarity.rare,
    category: CardCategory.tempo,
    nameEn: 'Destiny',
    nameFa: 'سرنوشت',
    descEn: 'At your next 7–7 you take two cards.',
    descFa: 'در هفت‌هفت بعدی‌ات دو کارت برمی‌داری.',
    glyph: 55,
  ),
  CardDef(
    id: CardId.highStakes,
    rarity: Rarity.rare,
    category: CardCategory.tempo,
    nameEn: 'High Stakes',
    nameFa: 'شرط سنگین',
    descEn: 'Double the stakes of this game.',
    descFa: 'ارزش این بازی دو برابر می‌شود.',
    drawbackEn: 'If you lose, you lose double too.',
    drawbackFa: 'اگر ببازی، دو برابر می\u200cبازی.',
    glyph: 56,
  ),
  CardDef(
    id: CardId.exile,
    rarity: Rarity.epic,
    category: CardCategory.sabotage,
    nameEn: 'Exile',
    nameFa: 'تبعید',
    descEn: 'Send one enemy lone checker to the bar.',
    descFa: 'یک مهرهٔ تنهای حریف را به بار بفرست.',
    target: TargetKind.enemyBlot,
    glyph: 57,
  ),
  CardDef(
    id: CardId.oasis,
    rarity: Rarity.common,
    category: CardCategory.tempo,
    nameEn: 'Oasis',
    nameFa: 'واحه',
    descEn: "Wash away your opponent's dice curses on you: Broken Die, Fog, Curse, Headwind, Nightfall and coin skips.",
    descFa: 'نفرین‌های تاسی حریف بر تو را بشوی: تاس شکسته، مه، نفرین، باد مخالف، شب‌هنگام و جریمهٔ سکه.',
    glyph: 58,
  ),
  CardDef(
    id: CardId.doubleAgent,
    rarity: Rarity.rare,
    category: CardCategory.sabotage,
    nameEn: 'Double Agent',
    nameFa: 'جاسوس دوجانبه',
    descEn: 'Copy the last card your opponent took (if it needs no target). Otherwise gain a reroll token.',
    descFa: 'آخرین کارتی را که حریف برداشته (اگر هدف نخواهد) برای خودت تکرار کن؛ وگرنه یک ژتون تاس دوباره بگیر.',
    glyph: 59,
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
