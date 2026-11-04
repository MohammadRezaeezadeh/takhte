import 'dart:math' as math;

import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rng/rng.dart';
import 'package:haftnard/core/rules/state.dart';

/// A passive relic for the current run (Balatro "Joker" equivalent).
class Talisman {
  const Talisman({
    required this.id,
    required this.nameEn,
    required this.nameFa,
    required this.descEn,
    required this.descFa,
    required this.price,
    this.glyph = 0,
  });
  final String id;
  final String nameEn;
  final String nameFa;
  final String descEn;
  final String descFa;
  final int price;

  /// Card glyph reused as the talisman's emblem.
  final int glyph;

  String name(String lang) => lang == 'fa' ? nameFa : nameEn;
  String desc(String lang) => lang == 'fa' ? descFa : descEn;
}

const List<Talisman> kTalismans = [
  Talisman(
    id: 'hit_purse',
    nameEn: 'Hit Purse',
    nameFa: 'کیسهٔ ضربه',
    descEn: '+3 run coins for every checker you hit.',
    descFa: 'به ازای هر مهره‌ای که می‌زنی ۳ سکهٔ سفر.',
    price: 45,
    glyph: 23,
  ),
  Talisman(
    id: 'first_light',
    nameEn: 'First Light',
    nameFa: 'نخستین پرتو',
    descEn: 'Your first bear-off each match grants a reroll token.',
    descFa: 'اولین خروج مهره در هر بازی یک ژتون تکرار تاس می‌دهد.',
    price: 50,
    glyph: 3,
  ),
  Talisman(
    id: 'fourth_card',
    nameEn: 'Fourth Card',
    nameFa: 'کارت چهارم',
    descEn: 'Your 7–7 offers show 4 cards.',
    descFa: 'پیشنهادهای هفت‌هفت تو چهار کارت دارند.',
    price: 90,
  ),
  Talisman(
    id: 'dervish',
    nameEn: 'Whirling Dervish',
    nameFa: 'درویش چرخان',
    descEn: 'Every 3rd double you roll grants a reroll token.',
    descFa: 'هر سومین جفتی که می‌آوری یک ژتون تکرار تاس می‌دهد.',
    price: 60,
    glyph: 1,
  ),
  Talisman(
    id: 'lucky_star',
    nameEn: 'Lucky Star',
    nameFa: 'ستارهٔ بخت',
    descEn: '+50% chance to roll 7–7.',
    descFa: '۵۰٪ شانس بیشتر برای هفت‌هفت.',
    price: 80,
    glyph: 5,
  ),
  Talisman(
    id: 'phoenix_feather',
    nameEn: 'Phoenix Feather',
    nameFa: 'پر ققنوس',
    descEn: 'Start every match with a Phoenix.',
    descFa: 'هر بازی را با یک ققنوس شروع کن.',
    price: 70,
    glyph: 15,
  ),
  Talisman(
    id: 'ghost_lantern',
    nameEn: 'Ghost Lantern',
    nameFa: 'فانوس شبح',
    descEn: 'Start every match with a Ghost Step.',
    descFa: 'هر بازی را با یک گام شبح شروع کن.',
    price: 70,
    glyph: 14,
  ),
  Talisman(
    id: 'gamblers_purse',
    nameEn: "Gambler's Purse",
    nameFa: 'کیف قمارباز',
    descEn: 'Start every match with a reroll token.',
    descFa: 'هر بازی را با یک ژتون تکرار تاس شروع کن.',
    price: 55,
    glyph: 22,
  ),
  Talisman(
    id: 'horseshoe',
    nameEn: 'Blue Bead',
    nameFa: 'مهرهٔ آبی',
    descEn: 'Start every match with a Lucky Charm.',
    descFa: 'هر بازی را با یک طلسم بخت شروع کن.',
    price: 45,
    glyph: 4,
  ),
  Talisman(
    id: 'merchant_scale',
    nameEn: "Merchant's Scale",
    nameFa: 'ترازوی تاجر',
    descEn: '+30% run coins from wins.',
    descFa: '۳۰٪ سکهٔ سفر بیشتر از بردها.',
    price: 60,
    glyph: 19,
  ),
  Talisman(
    id: 'mars_medal',
    nameEn: 'Medal of Mars',
    nameFa: 'مدال مارس',
    descEn: '+25 run coins when you win with a Mars.',
    descFa: 'برد مارس ۲۵ سکهٔ سفر اضافه دارد.',
    price: 50,
    glyph: 20,
  ),
  Talisman(
    id: 'seventh_seal',
    nameEn: 'Seventh Seal',
    nameFa: 'مهر هفتم',
    descEn: 'Double chance to roll 7–7, but offers show one card fewer.',
    descFa: 'شانس هفت‌هفت دو برابر، اما پیشنهادها یک کارت کمتر.',
    price: 75,
    glyph: 21,
  ),
  Talisman(
    id: 'golden_touch',
    nameEn: 'Golden Touch',
    nameFa: 'دست طلایی',
    descEn: '+12 run coins for every 7–7 you roll.',
    descFa: 'هر هفت‌هفت ۱۲ سکهٔ سفر.',
    price: 55,
    glyph: 5,
  ),
  Talisman(
    id: 'iron_will',
    nameEn: 'Iron Will',
    nameFa: 'ارادهٔ آهنین',
    descEn: 'Start every match with two reroll tokens.',
    descFa: 'هر بازی را با دو ژتون تکرار تاس شروع کن.',
    price: 95,
    glyph: 13,
  ),
  Talisman(
    id: 'caravan_map',
    nameEn: 'Caravan Map',
    nameFa: 'نقشهٔ کاروان',
    descEn: 'Shop items cost 20% less.',
    descFa: 'اقلام حجره ۲۰٪ ارزان‌ترند.',
    price: 65,
    glyph: 16,
  ),
  Talisman(
    id: 'second_wind',
    nameEn: 'Second Wind',
    nameFa: 'نفس دوباره',
    descEn:
        'Once per run, a lost match is replayed instead of ending the journey.',
    descFa: 'یک بار در هر سفر، باخت به‌جای پایان سفر دوباره بازی می‌شود.',
    price: 120,
    glyph: 3,
  ),
  Talisman(
    id: 'lucky_bones',
    nameEn: 'Lucky Bones',
    nameFa: 'استخوان‌های خوش‌یُمن',
    descEn: 'Every match opens with Lucky Six in effect.',
    descFa: 'هر بازی با «شش خوش» فعال شروع می‌شود.',
    price: 60,
    glyph: 31,
  ),
  Talisman(
    id: 'desert_wind',
    nameEn: 'Desert Wind',
    nameFa: 'باد صحرا',
    descEn: 'Every match opens with Tailwind in effect.',
    descFa: 'هر بازی با «باد موافق» فعال شروع می‌شود.',
    price: 60,
    glyph: 35,
  ),
  Talisman(
    id: 'moon_veil',
    nameEn: 'Moon Veil',
    nameFa: 'پردهٔ ماه',
    descEn: 'Every match opens with Nightfall in effect.',
    descFa: 'هر بازی با «شب‌هنگام» فعال شروع می‌شود.',
    price: 55,
    glyph: 28,
  ),
  Talisman(
    id: 'fortune_purse',
    nameEn: 'Fortune Purse',
    nameFa: 'کیسهٔ بخت',
    descEn: 'Every match opens with Bazaar Bargain in effect.',
    descFa: 'هر بازی با «چانه‌زنی بازار» فعال شروع می‌شود.',
    price: 50,
    glyph: 25,
  ),
  Talisman(
    id: 'simorgh_egg',
    nameEn: 'Simorgh Egg',
    nameFa: 'تخم سیمرغ',
    descEn: "Every match opens with Simorgh's Blessing in effect.",
    descFa: 'هر بازی با «برکت سیمرغ» فعال شروع می‌شود.',
    price: 85,
    glyph: 27,
  ),
  Talisman(
    id: 'sand_clock',
    nameEn: 'Sand Clock',
    nameFa: 'ساعت شنی',
    descEn: 'Every match opens with Hourglass Sand in effect.',
    descFa: 'هر بازی با «شن ساعت» فعال شروع می‌شود.',
    price: 60,
    glyph: 26,
  ),
  Talisman(
    id: 'mirror_shard',
    nameEn: 'Mirror Shard',
    nameFa: 'تکهٔ آینه',
    descEn: 'Every match opens with Mirror in effect.',
    descFa: 'هر بازی با «آینه» فعال شروع می‌شود.',
    price: 75,
    glyph: 10,
  ),
  Talisman(
    id: 'loaded_bones',
    nameEn: 'Loaded Bones',
    nameFa: 'تاس‌های سنگین',
    descEn: 'Every match opens with Loaded Hand in effect.',
    descFa: 'هر بازی با «دست سنگین» فعال شروع می‌شود.',
    price: 70,
    glyph: 12,
  ),
  Talisman(
    id: 'broken_bones',
    nameEn: 'Broken Bones',
    nameFa: 'استخوان شکسته',
    descEn: 'Every match opens with Broken Die on your opponent.',
    descFa: 'هر بازی با «تاس شکسته» روی حریف شروع می‌شود.',
    price: 80,
    glyph: 6,
  ),
  Talisman(
    id: 'fog_horn',
    nameEn: 'Fog Horn',
    nameFa: 'شیپور مه',
    descEn: 'Every match opens with Fog on your opponent.',
    descFa: 'هر بازی با «مه» روی حریف شروع می‌شود.',
    price: 65,
    glyph: 8,
  ),
  Talisman(
    id: 'seven_compass',
    nameEn: 'Seven Compass',
    nameFa: 'قطب‌نمای هفت',
    descEn: 'Every match opens with Seven Magnet in effect.',
    descFa: 'هر بازی با «آهنربای هفت» فعال شروع می‌شود.',
    price: 65,
    glyph: 5,
  ),
  Talisman(
    id: 'greedy_ring',
    nameEn: 'Greedy Ring',
    nameFa: 'انگشتر طمع',
    descEn: 'Every match opens with Greed in effect.',
    descFa: 'هر بازی با «طمع» فعال شروع می‌شود.',
    price: 45,
    glyph: 23,
  ),
  Talisman(
    id: 'prayer_beads',
    nameEn: 'Prayer Beads',
    nameFa: 'تسبیح',
    descEn: 'Every 2nd double you roll grants a reroll token.',
    descFa: 'هر دومین جفتی که می‌آوری یک ژتون تکرار تاس می‌دهد.',
    price: 90,
    glyph: 14,
  ),
  Talisman(
    id: 'twin_fate',
    nameEn: 'Twin Fate',
    nameFa: 'سرنوشت دوقلو',
    descEn: 'Take one extra card from every 7–7 offer.',
    descFa: 'از هر پیشنهاد هفت‌هفت یک کارت بیشتر برمی‌داری.',
    price: 120,
    glyph: 13,
  ),
  Talisman(
    id: 'evil_eye',
    nameEn: 'Evil Eye',
    nameFa: 'چشم‌زخم',
    descEn: 'Your opponents roll 7–7 half as often.',
    descFa: 'حریفانت نصف دفعات هفت‌هفت می‌آورند.',
    price: 70,
    glyph: 19,
  ),
  Talisman(
    id: 'dull_blade',
    nameEn: 'Dull Blade',
    nameFa: 'تیغ کُند',
    descEn: "Your opponents' doubles play as two dice.",
    descFa: 'جفت‌های حریف مثل دو تاس معمولی بازی می‌شوند.',
    price: 85,
    glyph: 9,
  ),
  Talisman(
    id: 'heavy_hand',
    nameEn: 'Heavy Hand',
    nameFa: 'دست سنگین‌بار',
    descEn: "Your opponents' dice never show more than 5.",
    descFa: 'تاس‌های حریف هیچ‌وقت بیشتر از ۵ نمی‌آیند.',
    price: 95,
    glyph: 7,
  ),
  Talisman(
    id: 'jackpot',
    nameEn: 'Jackpot',
    nameFa: 'بُرد کلان',
    descEn: '+40 run coins when you win with a Kup-Mars.',
    descFa: 'وقتی با کوپ‌مارس می‌بری ۴۰ سکهٔ سفر بیشتر.',
    price: 50,
    glyph: 21,
  ),
  Talisman(
    id: 'bounty',
    nameEn: 'Bounty',
    nameFa: 'جایزهٔ سر',
    descEn: '+40 run coins for every boss you defeat.',
    descFa: 'به ازای شکست هر رئیس ۴۰ سکهٔ سفر.',
    price: 55,
    glyph: 22,
  ),
  Talisman(
    id: 'wanderer_boots',
    nameEn: 'Wanderer Boots',
    nameFa: 'چکمهٔ رهنورد',
    descEn: '+8 run coins from every win.',
    descFa: 'از هر برد ۸ سکهٔ سفر بیشتر.',
    price: 40,
    glyph: 20,
  ),
  Talisman(
    id: 'banker',
    nameEn: 'Banker',
    nameFa: 'صراف',
    descEn: 'After each win, earn 10% interest on your run coins (up to 30).',
    descFa: 'بعد از هر برد ۱۰٪ سود روی سکه‌های سفرت (تا ۳۰).',
    price: 70,
    glyph: 16,
  ),
  Talisman(
    id: 'tax_collector',
    nameEn: 'Tax Collector',
    nameFa: 'تحصیلدار',
    descEn: 'When you win, +1 run coin for every 5 pips you lead by.',
    descFa: 'وقتی می‌بری به ازای هر ۵ خانه جلوتر بودن ۱ سکهٔ سفر.',
    price: 50,
    glyph: 4,
  ),
  Talisman(
    id: 'ledger',
    nameEn: 'Ledger',
    nameFa: 'دفتر حساب',
    descEn: 'Shop items cost 10% less (stacks with the Caravan Map).',
    descFa: 'اجناس فروشگاه ۱۰٪ ارزان‌تر (با نقشهٔ کاروان جمع می‌شود).',
    price: 45,
    glyph: 15,
  ),
  Talisman(
    id: 'serpent_eye',
    nameEn: 'Serpent Eye',
    nameFa: 'چشم مار',
    descEn: 'Every match opens with Curse of Small Numbers on your opponent.',
    descFa: 'هر بازی با «نفرین کوچکی» روی حریف شروع می‌شود.',
    price: 70,
    glyph: 9,
  ),
  Talisman(
    id: 'storm_cloak',
    nameEn: 'Storm Cloak',
    nameFa: 'ردای توفان',
    descEn: 'Every match opens with Headwind on your opponent.',
    descFa: 'هر بازی با «باد مخالف» روی حریف شروع می‌شود.',
    price: 60,
    glyph: 36,
  ),
  Talisman(
    id: 'even_pearl',
    nameEn: 'Even Pearl',
    nameFa: 'مروارید زوج',
    descEn: 'Every match opens with Even Odds in effect.',
    descFa: 'هر بازی با «زوج‌گرا» فعال شروع می‌شود.',
    price: 50,
    glyph: 37,
  ),
  Talisman(
    id: 'ward_amulet',
    nameEn: 'Ward Amulet',
    nameFa: 'بازوبند دفع',
    descEn: 'Every match opens with Ward of Low Rolls in effect.',
    descFa: 'هر بازی با «دفع تاس کم» فعال شروع می‌شود.',
    price: 50,
    glyph: 38,
  ),
  Talisman(
    id: 'crown_shard',
    nameEn: 'Crown Shard',
    nameFa: 'تکهٔ تاج',
    descEn: 'Every match opens with Royal Roll in effect.',
    descFa: 'هر بازی با «تاس شاهانه» فعال شروع می‌شود.',
    price: 75,
    glyph: 40,
  ),
  Talisman(
    id: 'lead_seal',
    nameEn: 'Lead Seal',
    nameFa: 'مُهر سربی',
    descEn: 'Every match opens with Leaden Dice on your opponent.',
    descFa: 'هر بازی با «تاس سربی» روی حریف شروع می‌شود.',
    price: 85,
    glyph: 42,
  ),
  Talisman(
    id: 'oracle_cup',
    nameEn: 'Oracle Cup',
    nameFa: 'جام پیشگو',
    descEn: 'Every match opens with Fortune Teller in effect.',
    descFa: 'هر بازی با «فالگیر» فعال شروع می‌شود.',
    price: 55,
    glyph: 54,
  ),
  Talisman(
    id: 'star_chart',
    nameEn: 'Star Chart',
    nameFa: 'نقشهٔ ستارگان',
    descEn: 'Every match opens with Destiny in effect.',
    descFa: 'هر بازی با «سرنوشت» فعال شروع می‌شود.',
    price: 90,
    glyph: 55,
  ),
  Talisman(
    id: 'peace_banner',
    nameEn: 'Peace Banner',
    nameFa: 'پرچم صلح',
    descEn: 'Every match opens with Truce in effect.',
    descFa: 'هر بازی با «آتش‌بس» فعال شروع می‌شود.',
    price: 55,
    glyph: 34,
  ),
  Talisman(
    id: 'shield_sigil',
    nameEn: 'Shield Sigil',
    nameFa: 'نشان سپر',
    descEn: 'Every match opens with Shield Wall in effect.',
    descFa: 'هر بازی با «دیوار سپر» فعال شروع می‌شود.',
    price: 60,
    glyph: 47,
  ),
  Talisman(
    id: 'hex_doll',
    nameEn: 'Hex Doll',
    nameFa: 'عروسک جادو',
    descEn: 'Every match opens with Hex of Sevens on your opponent.',
    descFa: 'هر بازی با «طلسم هفت‌ها» روی حریف شروع می‌شود.',
    price: 50,
    glyph: 45,
  ),
  Talisman(
    id: 'twin_mirror',
    nameEn: 'Twin Mirror',
    nameFa: 'آینهٔ همزاد',
    descEn: 'Every match opens with Twin Dice in effect.',
    descFa: 'هر بازی با «تاس‌های همزاد» فعال شروع می‌شود.',
    price: 110,
    glyph: 39,
  ),
  Talisman(
    id: 'fate_quill',
    nameEn: 'Fate Quill',
    nameFa: 'قلم تقدیر',
    descEn: "Every match opens with Fate's Edit in effect.",
    descFa: 'هر بازی با «دست تقدیر» فعال شروع می‌شود.',
    price: 80,
    glyph: 2,
  ),
  Talisman(
    id: 'gambit_coin',
    nameEn: 'Gambit Coin',
    nameFa: 'سکهٔ گامبی',
    descEn: "Every match opens with a Gambler's Coin flip.",
    descFa: 'هر بازی با پرتاب «سکه قمار» شروع می‌شود.',
    price: 50,
    glyph: 22,
  ),
  Talisman(
    id: 'clover',
    nameEn: 'Four-Leaf Clover',
    nameFa: 'شبدر چهاربرگ',
    descEn: '+25% chance to roll 7–7.',
    descFa: '۲۵٪ شانس بیشتر برای هفت‌هفت.',
    price: 55,
    glyph: 5,
  ),
  Talisman(
    id: 'mosaic_lens',
    nameEn: 'Mosaic Lens',
    nameFa: 'عدسی کاشی',
    descEn: 'Your 7–7 offers show one card more, but you roll 7–7 a quarter less often.',
    descFa: 'پیشنهادهای هفت‌هفت یک کارت بیشتر دارند، ولی یک‌چهارم کمتر هفت‌هفت می‌آوری.',
    price: 70,
    glyph: 13,
  ),
  Talisman(
    id: 'witch_knot',
    nameEn: 'Witch Knot',
    nameFa: 'گره جادوگر',
    descEn: "Your opponents' 7–7 offers show one card fewer.",
    descFa: 'پیشنهادهای هفت‌هفت حریف یک کارت کمتر دارند.',
    price: 75,
    glyph: 45,
  ),
  Talisman(
    id: 'sultan_ring',
    nameEn: 'Sultan Ring',
    nameFa: 'انگشتر سلطان',
    descEn: 'Start every match with a Lucky Charm and a reroll token.',
    descFa: 'هر بازی را با یک «طلسم بخت» و یک ژتون تکرار تاس شروع کن.',
    price: 75,
    glyph: 4,
  ),
  Talisman(
    id: 'pilgrim_staff',
    nameEn: 'Pilgrim Staff',
    nameFa: 'عصای زائر',
    descEn: '+3 run coins per stage reached, on every win.',
    descFa: 'در هر برد به ازای هر مرحلهٔ طی‌شده ۳ سکهٔ سفر.',
    price: 50,
    glyph: 20,
  ),
  Talisman(
    id: 'miser_chest',
    nameEn: 'Miser Chest',
    nameFa: 'صندوق خسیس',
    descEn: 'Keep 60% of your run coins if the run fails (instead of 40%).',
    descFa: 'اگر سفر شکست بخورد ۶۰٪ سکه‌های سفر را نگه می‌داری (به جای ۴۰٪).',
    price: 40,
    glyph: 16,
  ),
  Talisman(
    id: 'treasure_map',
    nameEn: 'Treasure Map',
    nameFa: 'نقشهٔ گنج',
    descEn: '+60 coins when the run ends, win or lose.',
    descFa: '۶۰ سکه در پایان سفر، چه ببری چه ببازی.',
    price: 55,
    glyph: 15,
  ),
];

Talisman talismanById(String id) => kTalismans.firstWhere((t) => t.id == id);

/// A boss rule set.
class Boss {
  const Boss({
    required this.id,
    required this.nameEn,
    required this.nameFa,
    required this.ruleEn,
    required this.ruleFa,
    required this.personality,
    this.player = SideMods.none,
    this.boss = SideMods.none,
  });
  final String id;
  final String nameEn;
  final String nameFa;
  final String ruleEn;
  final String ruleFa;
  final String personality;
  final SideMods player;
  final SideMods boss;

  String name(String lang) => lang == 'fa' ? nameFa : nameEn;
  String rule(String lang) => lang == 'fa' ? ruleFa : ruleEn;
}

const List<Boss> kBosses = [
  Boss(
    id: 'iron_vizier',
    nameEn: 'The Iron Vizier',
    nameFa: 'وزیر آهنین',
    ruleEn: "Your doubles don't count.",
    ruleFa: 'جفت‌های تو حساب نمی‌شوند.',
    personality: 'builder',
    player: SideMods(doublesCount: false),
  ),
  Boss(
    id: 'veiled_oracle',
    nameEn: 'The Veiled Oracle',
    nameFa: 'پیشگوی نقاب‌دار',
    ruleEn: 'You can never roll 7–7. She rolls it twice as often.',
    ruleFa: 'تو هرگز هفت‌هفت نمی‌آوری؛ او دو برابر.',
    personality: 'sage',
    player: SideMods(p7Multiplier: 0),
    boss: SideMods(p7Multiplier: 2),
  ),
  Boss(
    id: 'moneylender',
    nameEn: 'The Moneylender',
    nameFa: 'رباخوار',
    ruleEn: 'Starts with two reroll tokens and a Phoenix.',
    ruleFa: 'با دو ژتون تکرار تاس و یک ققنوس شروع می‌کند.',
    personality: 'gambler',
    boss: SideMods(startRerolls: 2, startPhoenix: 1),
  ),
  Boss(
    id: 'sandstorm_khan',
    nameEn: 'The Sandstorm Khan',
    nameFa: 'خانِ طوفان شن',
    ruleEn: 'Your dice never roll higher than 5.',
    ruleFa: 'تاس‌های تو هرگز بیشتر از ۵ نمی‌آیند.',
    personality: 'hammer',
    player: SideMods(capDice: 5),
  ),
  Boss(
    id: 'shadow_twin',
    nameEn: 'The Shadow Twin',
    nameFa: 'همزاد سایه',
    ruleEn: 'Sees two extra cards at every 7–7 and starts with a Ghost Step.',
    ruleFa: 'در هر هفت‌هفت دو کارت بیشتر می‌بیند و با گام شبح شروع می‌کند.',
    personality: 'fox',
    boss: SideMods(offerBonus: 2, startGhost: 1, p7Multiplier: 1.5),
  ),
  Boss(
    id: 'twin_viziers',
    nameEn: 'The Twin Viziers',
    nameFa: 'وزیران دوقلو',
    ruleEn: 'They begin with Tailwind and Loaded Hand.',
    ruleFa: 'با «باد موافق» و «دست سنگین» شروع می‌کنند.',
    personality: 'builder',
    boss: SideMods(startCards: ['tailwind', 'loaded_hand']),
  ),
  Boss(
    id: 'desert_witch',
    nameEn: 'The Desert Witch',
    nameFa: 'جادوگر کویر',
    ruleEn: 'Night falls on you: no 7–7 for your first six turns. She starts with a Phoenix.',
    ruleFa: 'شب بر تو می‌افتد: تا شش نوبت اول هفت‌هفت نداری. او با یک ققنوس شروع می‌کند.',
    personality: 'fox',
    boss: SideMods(startCards: ['nightfall'], startPhoenix: 1),
  ),
  Boss(
    id: 'iron_wall',
    nameEn: 'The Iron Wall',
    nameFa: 'دیوار آهنین',
    ruleEn: 'Your dice never roll higher than 5. He starts with a reroll and a Lucky Charm.',
    ruleFa: 'تاس‌های تو هرگز بیشتر از ۵ نمی‌آیند. او با ژتون تکرار تاس و طلسم بخت شروع می‌کند.',
    personality: 'builder',
    player: SideMods(capDice: 5),
    boss: SideMods(startCards: ['bazaar_bargain']),
  ),
  Boss(
    id: 'gambler_king',
    nameEn: 'The Gambler King',
    nameFa: 'شاهِ قماربازان',
    ruleEn: 'Chaos: both sides roll 7–7 three times as often, and he takes two cards each time.',
    ruleFa: 'آشوب: هر دو طرف سه برابر هفت‌هفت می‌آورند و او هر بار دو کارت برمی‌دارد.',
    personality: 'gambler',
    player: SideMods(p7Multiplier: 3),
    boss: SideMods(p7Multiplier: 3, pickBonus: 1),
  ),
  Boss(
    id: 'tax_collector',
    nameEn: 'The Tax Collector',
    nameFa: 'باج‌گیر',
    ruleEn: 'Pockets your reroll tokens at the start and plays for Greed.',
    ruleFa: 'در شروع ژتون‌های تکرار تاسِ تو را به جیب می‌زند و با «طمع» بازی می‌کند.',
    personality: 'gambler',
    boss: SideMods(startCards: ['pickpocket', 'greed']),
  ),
  Boss(
    id: 'storm_caller',
    nameEn: 'The Storm Caller',
    nameFa: 'طوفان‌خوان',
    ruleEn: "Your dice never exceed 5 and your doubles don't count.",
    ruleFa: 'تاس‌های تو از ۵ بیشتر نمی‌آیند و جفت‌هایت حساب نمی‌شوند.',
    personality: 'hammer',
    player: SideMods(capDice: 5, doublesCount: false),
  ),
  Boss(
    id: 'mirror_mage',
    nameEn: 'The Mirror Mage',
    nameFa: 'جادوگر آینه',
    ruleEn: 'Copies your first roll and rolls 7–7 more often.',
    ruleFa: 'اولین تاس تو را کپی می‌کند و بیشتر هفت‌هفت می‌آورد.',
    personality: 'fox',
    boss: SideMods(startCards: ['mirror'], p7Multiplier: 1.5),
  ),
  Boss(
    id: 'sultan_of_sand',
    nameEn: 'The Sultan of Sand',
    nameFa: 'سلطان شن',
    ruleEn: 'Buries your first turn in Hourglass Sand and rides a Tailwind.',
    ruleFa: 'نوبت اول تو را در «شن ساعت» دفن می‌کند و با «باد موافق» می‌تازد.',
    personality: 'sage',
    boss: SideMods(startCards: ['hourglass_sand', 'tailwind']),
  ),
  Boss(
    id: 'card_sharp',
    nameEn: 'The Card Sharp',
    nameFa: 'کارت‌باز',
    ruleEn: 'Sees an extra card and takes two at every 7–7.',
    ruleFa: 'در هر هفت‌هفت یک کارت بیشتر می‌بیند و دو کارت برمی‌دارد.',
    personality: 'gambler',
    boss: SideMods(offerBonus: 1, pickBonus: 1, p7Multiplier: 1.3),
  ),
];

const Boss kFinalBoss = Boss(
  id: 'shah',
  nameEn: 'The Shadow Shah',
  nameFa: 'شاهِ سایه',
  ruleEn: "Your doubles don't count. Starts with a Phoenix, a Ghost Step and a reroll.",
  ruleFa: 'جفت‌های تو حساب نمی‌شوند. با ققنوس، گام شبح و یک ژتون تکرار تاس شروع می‌کند.',
  personality: 'sage',
  player: SideMods(doublesCount: false),
  boss: SideMods(
    startPhoenix: 1,
    startGhost: 1,
    startRerolls: 1,
    p7Multiplier: 1.5,
  ),
);

/// One opponent on the map.
class JourneyStage {
  const JourneyStage({
    required this.index,
    required this.personality,
    required this.difficulty,
    this.boss,
  });
  final int index;
  final String personality;
  final Difficulty difficulty;
  final Boss? boss;

  int get act => index < 3 ? 0 : (index < 6 ? 1 : 2);
}

/// A shop offer between matches.
class ShopOffer {
  const ShopOffer(this.kind, this.price, {this.talisman});
  factory ShopOffer.fromJson(Map<String, Object?> j) =>
      ShopOffer(j['k']! as String, j['p']! as int, talisman: j['t'] as String?);

  /// 'talisman', 'banish', 'offer', 'luck'.
  final String kind;
  final int price;
  final String? talisman;
  Map<String, Object?> toJson() => {
    'k': kind,
    'p': price,
    if (talisman != null) 't': talisman,
  };
}

/// Persistent state of a Journey run.
class JourneyRun {
  JourneyRun({
    required this.seed,
    this.daily = false,
    this.stage = 0,
    this.coins = 20,
    List<String>? talismans,
    List<String>? banished,
    List<String>? attuned,
    this.offerUpgrades = 0,
    this.luckUpgrades = 0,
    this.over = false,
    this.won = false,
    this.secondWindUsed = false,
    List<ShopOffer>? shop,
    this.inShop = false,
    this.activeSession,
  }) : talismans = talismans ?? [],
       banished = banished ?? [],
       attuned = attuned ?? [],
       shop = shop ?? [];

  factory JourneyRun.fromJson(Map<String, Object?> j) => JourneyRun(
    seed: j['seed']! as int,
    daily: j['daily'] as bool? ?? false,
    stage: j['stage'] as int? ?? 0,
    coins: j['coins'] as int? ?? 0,
    talismans: ((j['tal'] as List<Object?>?) ?? const [])
        .cast<String>()
        .toList(),
    banished: ((j['ban'] as List<Object?>?) ?? const [])
        .cast<String>()
        .toList(),
    attuned: ((j['att'] as List<Object?>?) ?? const []).cast<String>().toList(),
    offerUpgrades: j['ou'] as int? ?? 0,
    luckUpgrades: j['lu'] as int? ?? 0,
    over: j['over'] as bool? ?? false,
    won: j['won'] as bool? ?? false,
    secondWindUsed: j['sw'] as bool? ?? false,
    shop: [
      for (final o in (j['shop'] as List<Object?>?) ?? const [])
        ShopOffer.fromJson((o! as Map).cast()),
    ],
    inShop: j['inShop'] as bool? ?? false,
    activeSession: (j['session'] as Map?)?.cast<String, Object?>(),
  );

  static const int stages = 8;

  final int seed;
  final bool daily;
  int stage;
  int coins;
  final List<String> talismans;
  final List<String> banished;

  /// Attuned (upgraded) cards: offered three times as often.
  final List<String> attuned;
  int offerUpgrades;
  int luckUpgrades;
  bool over;
  bool won;
  bool secondWindUsed;
  List<ShopOffer> shop;
  bool inShop;

  /// In-progress match (MatchSession JSON).
  Map<String, Object?>? activeSession;

  bool has(String talisman) => talismans.contains(talisman);

  /// The map: 2 regulars + boss, 2 regulars + boss, 1 regular + final boss.
  List<JourneyStage> get map {
    final rng = Rng.seeded(seed);
    final bosses = List.of(kBosses);
    rng.shuffle(bosses);
    final people = kPersonalities.map((p) => p.id).toList();
    const diffs = [
      Difficulty.easy,
      Difficulty.easy,
      Difficulty.medium,
      Difficulty.medium,
      Difficulty.medium,
      Difficulty.hard,
      Difficulty.hard,
      Difficulty.master,
    ];
    final out = <JourneyStage>[];
    var b = 0;
    for (var i = 0; i < stages; i++) {
      Boss? boss;
      if (i == 2 || i == 5) boss = bosses[b++];
      if (i == 7) boss = kFinalBoss;
      out.add(
        JourneyStage(
          index: i,
          personality: boss?.personality ?? people[rng.nextInt(people.length)],
          difficulty: diffs[i],
          boss: boss,
        ),
      );
    }
    return out;
  }

  JourneyStage get current => map[math.min(stage, stages - 1)];

  /// Talisman-derived modifiers for the player, merged with a boss rule.
  SideMods playerMods(Boss? boss, {List<String>? pool}) {
    final bp = boss?.player ?? SideMods.none;
    var p7 = 1.0 + 0.25 * luckUpgrades;
    if (has('lucky_star')) p7 *= 1.5;
    if (has('seventh_seal')) p7 *= 2;
    if (has('clover')) p7 *= 1.25;
    if (has('mosaic_lens')) p7 *= 0.75;
    var offer =
        offerUpgrades +
        (has('fourth_card') ? 1 : 0) +
        (has('mosaic_lens') ? 1 : 0) -
        (has('seventh_seal') ? 1 : 0);
    if (offer < -1) offer = -1;
    return SideMods(
      p7Multiplier: p7 * bp.p7Multiplier,
      offerBonus: offer,
      doublesCount: bp.doublesCount,
      rerollEveryNthDouble: has('prayer_beads') ? 2 : (has('dervish') ? 3 : 0),
      firstBearOffReroll: has('first_light'),
      startRerolls:
          (has('gamblers_purse') ? 1 : 0) +
          (has('iron_will') ? 2 : 0) +
          (has('sultan_ring') ? 1 : 0),
      startPhoenix: has('phoenix_feather') ? 1 : 0,
      startGhost: has('ghost_lantern') ? 1 : 0,
      startLucky: (has('horseshoe') ? 1 : 0) + (has('sultan_ring') ? 1 : 0),
      capDice: bp.capDice,
      pickBonus: has('twin_fate') ? 1 : 0,
      favored: List.of(attuned),
      cardPool: pool == null ? null : cardPool(pool),
      startCards: [
        for (final e in _startCardTalismans.entries)
          if (has(e.key)) e.value,
      ],
    );
  }

  static const Map<String, String> _startCardTalismans = {
    'lucky_bones': CardId.luckySix,
    'desert_wind': CardId.tailwind,
    'moon_veil': CardId.nightfall,
    'fortune_purse': CardId.bargain,
    'simorgh_egg': CardId.simorgh,
    'sand_clock': CardId.hourglassSand,
    'mirror_shard': CardId.mirror,
    'loaded_bones': CardId.loadedHand,
    'broken_bones': CardId.brokenDie,
    'fog_horn': CardId.fog,
    'seven_compass': CardId.sevenMagnet,
    'greedy_ring': CardId.greed,
    'serpent_eye': CardId.curse,
    'storm_cloak': CardId.headwind,
    'even_pearl': CardId.evenOdds,
    'ward_amulet': CardId.wardOnes,
    'crown_shard': CardId.royalRoll,
    'lead_seal': CardId.leadenDice,
    'oracle_cup': CardId.fortuneTeller,
    'star_chart': CardId.destiny,
    'peace_banner': CardId.truce,
    'shield_sigil': CardId.shieldWall,
    'hex_doll': CardId.hexSevens,
    'twin_mirror': CardId.twinDice,
    'fate_quill': CardId.fatesEdit,
    'gambit_coin': CardId.gamblersCoin,
  };

  /// The opponent's modifiers: the boss rule plus the player's hexes.
  SideMods opponentMods(Boss? boss) {
    final b = boss?.boss ?? SideMods.none;
    var p7 = b.p7Multiplier;
    if (has('evil_eye')) p7 *= 0.5;
    return SideMods(
      p7Multiplier: p7,
      offerBonus: b.offerBonus - (has('witch_knot') ? 1 : 0),
      doublesCount: b.doublesCount && !has('dull_blade'),
      startRerolls: b.startRerolls,
      startPhoenix: b.startPhoenix,
      startGhost: b.startGhost,
      startLucky: b.startLucky,
      capDice: has('heavy_hand') ? math.min(5, b.capDice) : b.capDice,
      pickBonus: b.pickBonus,
      startCards: b.startCards,
    );
  }

  /// Card pool for this run (both sides), minus banished cards.
  List<String> cardPool(List<String> unlocked) => [
    for (final c in unlocked)
      if (!banished.contains(c)) c,
  ];

  /// Run coins for a won match.
  int winCoins({
    required int points,
    required int hits,
    required int sevens,
    required bool mars,
    bool kupMars = false,
    int pipLead = 0,
    bool boss = false,
  }) {
    var c = 25 + 10 * points + stage * 5;
    if (has('merchant_scale')) c = (c * 1.3).round();
    if (mars && has('mars_medal')) c += 25;
    if (kupMars && has('jackpot')) c += 40;
    if (has('hit_purse')) c += hits * 3;
    if (has('golden_touch')) c += sevens * 12;
    if (has('tax_collector') && pipLead > 0) c += pipLead ~/ 5;
    if (boss && has('bounty')) c += 40;
    if (has('wanderer_boots')) c += 8;
    if (has('pilgrim_staff')) c += stage * 3;
    if (has('banker')) c += math.min(30, ((coins + c) * 0.1).round());
    return c;
  }

  /// Meta coins kept when the run ends.
  int get keptCoins =>
      (coins * (won ? 1.0 : (has('miser_chest') ? 0.6 : 0.4))).round() +
      stage * 20 +
      (won ? 300 : 0) +
      (has('treasure_map') ? 60 : 0);

  /// Generates the shop after a win.
  void openShop() {
    final rng = Rng.seeded(seed ^ (stage * 7919 + 13));
    final pool = kTalismans.where((t) => !talismans.contains(t.id)).toList();
    rng.shuffle(pool);
    final discount =
        (has('caravan_map') ? 0.8 : 1.0) * (has('ledger') ? 0.9 : 1.0);
    int price(int p) => (p * discount).round();
    shop = [
      for (final t in pool.take(3))
        ShopOffer('talisman', price(t.price), talisman: t.id),
      ShopOffer('banish', price(30)),
      ShopOffer('attune', price(40)),
      ShopOffer('offer', price(85 + 40 * offerUpgrades)),
      ShopOffer('luck', price(60 + 30 * luckUpgrades)),
    ];
    inShop = true;
  }

  /// Buys a shop offer. Returns false if unaffordable.
  bool buy(ShopOffer o, {String? banishCard}) {
    if (coins < o.price) return false;
    switch (o.kind) {
      case 'talisman':
        talismans.add(o.talisman!);
      case 'banish':
        if (banishCard == null || !kCardById.containsKey(banishCard)) {
          return false;
        }
        banished.add(banishCard);
      case 'attune':
        if (banishCard == null || !kCardById.containsKey(banishCard)) {
          return false;
        }
        if (!attuned.contains(banishCard)) attuned.add(banishCard);
      case 'offer':
        offerUpgrades++;
      case 'luck':
        luckUpgrades++;
    }
    coins -= o.price;
    shop = [
      for (final s in shop)
        if (!identical(s, o))
          s
        else if (o.kind == 'banish' || o.kind == 'attune')
          s
        else if (o.kind == 'offer' || o.kind == 'luck')
          ShopOffer(o.kind, o.price + (o.kind == 'offer' ? 40 : 30)),
    ];
    return true;
  }

  /// Records a finished match.
  void recordMatch({required bool won, int coinsEarned = 0}) {
    activeSession = null;
    if (won) {
      coins += coinsEarned;
      stage++;
      if (stage >= stages) {
        over = true;
        this.won = true;
      } else {
        openShop();
      }
    } else if (has('second_wind') && !secondWindUsed) {
      secondWindUsed = true;
    } else {
      over = true;
    }
  }

  static int dailySeed(DateTime d) =>
      d.year * 10000 + d.month * 100 + d.day + 7777777;

  Map<String, Object?> toJson() => {
    'seed': seed,
    'daily': daily,
    'stage': stage,
    'coins': coins,
    'tal': talismans,
    'ban': banished,
    'att': attuned,
    'ou': offerUpgrades,
    'lu': luckUpgrades,
    'over': over,
    'won': won,
    'sw': secondWindUsed,
    'shop': [for (final s in shop) s.toJson()],
    'inShop': inShop,
    if (activeSession != null) 'session': activeSession,
  };
}
