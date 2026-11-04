/// Cosmetic catalogue: every purchasable/equipable item. Rendering for each id
/// lives in `lib/game/themes/`.
library;

enum ItemType {
  board,
  environment,
  checker,
  dice,
  cardBack,
  cardFrame,
  victory,
  emote,
}

enum ItemTier { standard, premium, special }

class CosmeticItem {
  const CosmeticItem({
    required this.id,
    required this.type,
    required this.nameEn,
    required this.nameFa,
    this.descEn = '',
    this.descFa = '',
    this.coins = 0,
    this.gems = 0,
    this.tier = ItemTier.standard,
    this.unlockLevel = 0,
  });

  final String id;
  final ItemType type;
  final String nameEn;
  final String nameFa;
  final String descEn;
  final String descFa;

  /// Price in coins (0 with gems 0 = free / default).
  final int coins;

  /// Alternative premium price in gems.
  final int gems;
  final ItemTier tier;

  /// Player level required before it can be bought.
  final int unlockLevel;

  bool get isFree => coins == 0 && gems == 0;
  String name(String lang) => lang == 'fa' ? nameFa : nameEn;
  String desc(String lang) => lang == 'fa' ? descFa : descEn;
}

const List<CosmeticItem> kItems = [
  // Boards
  CosmeticItem(
    id: 'board_khatam',
    type: ItemType.board,
    nameEn: 'Khatam',
    nameFa: 'خاتم',
    descEn: 'Inlaid wood with star micro-mosaics, the classic Persian board.',
    descFa: 'چوب منبت با ستاره‌های ریز خاتم‌کاری؛ تختهٔ کلاسیک ایرانی.',
    tier: ItemTier.premium,
  ),
  CosmeticItem(
    id: 'board_caravanserai',
    type: ItemType.board,
    nameEn: 'Caravanserai Night',
    nameFa: 'شب کاروانسرا',
    descEn: 'Desert stone, lantern glow and a sky of stars.',
    descFa: 'سنگ کویر، نور فانوس و آسمان پرستاره.',
    coins: 900,
  ),
  CosmeticItem(
    id: 'board_turquoise',
    type: ItemType.board,
    nameEn: 'Turquoise Mosque',
    nameFa: 'فیروزه',
    descEn: 'Glazed tiles in turquoise and gold.',
    descFa: 'کاشی‌های لعاب‌دار فیروزه‌ای و طلایی.',
    coins: 1100,
  ),
  CosmeticItem(
    id: 'board_neon',
    type: ItemType.board,
    nameEn: 'Neon Arcade',
    nameFa: 'آرکید نئون',
    descEn: 'Synthwave grid with glowing lines.',
    descFa: 'شبکهٔ سینت‌ویو با خطوط درخشان.',
    coins: 1300,
    unlockLevel: 3,
  ),
  CosmeticItem(
    id: 'board_marble',
    type: ItemType.board,
    nameEn: 'Marble Palace',
    nameFa: 'کاخ مرمر',
    descEn: 'White marble veined with gold.',
    descFa: 'مرمر سفید با رگه‌های طلا.',
    coins: 1500,
    unlockLevel: 4,
  ),
  CosmeticItem(
    id: 'board_cosmic',
    type: ItemType.board,
    nameEn: 'Cosmic Void',
    nameFa: 'خلأ کیهانی',
    descEn: 'A living nebula beneath the points.',
    descFa: 'سحابی زنده زیر خانه‌ها.',
    gems: 60,
    tier: ItemTier.premium,
    unlockLevel: 5,
  ),
  CosmeticItem(
    id: 'board_frost',
    type: ItemType.board,
    nameEn: 'Frost',
    nameFa: 'یخبندان',
    descEn: 'Carved ice and drifting breath.',
    descFa: 'یخ تراشیده و بخار سرد.',
    coins: 1400,
    unlockLevel: 6,
  ),
  CosmeticItem(
    id: 'board_ember',
    type: ItemType.board,
    nameEn: 'Ember Forge',
    nameFa: 'کورهٔ اخگر',
    descEn: 'Dark iron and rising sparks.',
    descFa: 'آهن تیره و جرقه‌های بالارونده.',
    gems: 70,
    tier: ItemTier.premium,
    unlockLevel: 8,
  ),
  CosmeticItem(
    id: 'board_garden',
    type: ItemType.board,
    nameEn: 'Persian Garden',
    nameFa: 'باغ ایرانی',
    descEn: 'Chahar-bagh channels and cypress green.',
    descFa: 'جوی‌های چهارباغ و سبزی سرو.',
    coins: 1600,
    unlockLevel: 10,
  ),
  // Environments
  CosmeticItem(
    id: 'env_lantern_hall',
    type: ItemType.environment,
    nameEn: 'Lantern Hall',
    nameFa: 'تالار فانوس',
    descEn: 'Warm lanterns sway above a carpeted table.',
    descFa: 'فانوس‌های گرم بالای میزی فرش‌پوش تاب می‌خورند.',
  ),
  CosmeticItem(
    id: 'env_desert_night',
    type: ItemType.environment,
    nameEn: 'Desert Night',
    nameFa: 'شب کویر',
    descEn: 'Dunes under a turning sky of stars.',
    descFa: 'تپه‌های شنی زیر آسمان چرخان پرستاره.',
    coins: 1200,
  ),
  CosmeticItem(
    id: 'env_mosque_court',
    type: ItemType.environment,
    nameEn: 'Mosque Courtyard',
    nameFa: 'صحن مسجد',
    descEn: 'Light shafts fall through a tiled arch.',
    descFa: 'نور از میان طاق کاشی‌کاری فرو می‌ریزد.',
    coins: 1500,
    unlockLevel: 3,
  ),
  CosmeticItem(
    id: 'env_neon_city',
    type: ItemType.environment,
    nameEn: 'Neon Skyline',
    nameFa: 'افق نئون',
    descEn: 'A synthwave sun sinks behind the grid.',
    descFa: 'خورشید سینت‌ویو پشت شبکه غروب می‌کند.',
    coins: 1800,
    unlockLevel: 5,
  ),
  CosmeticItem(
    id: 'env_cosmos',
    type: ItemType.environment,
    nameEn: 'Starfield',
    nameFa: 'میدان ستارگان',
    descEn: 'Drift among nebulae and falling stars.',
    descFa: 'میان سحابی‌ها و شهاب‌ها شناور باش.',
    gems: 50,
    tier: ItemTier.premium,
    unlockLevel: 6,
  ),
  CosmeticItem(
    id: 'env_snowfall',
    type: ItemType.environment,
    nameEn: 'Snowfall',
    nameFa: 'برف',
    descEn: 'Quiet snow over a frozen terrace.',
    descFa: 'برف آرام روی ایوانی یخ‌زده.',
    coins: 1600,
    unlockLevel: 7,
  ),
  CosmeticItem(
    id: 'env_forge',
    type: ItemType.environment,
    nameEn: 'Forge Cavern',
    nameFa: 'غار کوره',
    descEn: 'Embers rise from glowing coals.',
    descFa: 'اخگرها از زغال گداخته برمی‌خیزند.',
    gems: 55,
    tier: ItemTier.premium,
    unlockLevel: 9,
  ),
  // Checkers
  CosmeticItem(
    id: 'chk_wood',
    type: ItemType.checker,
    nameEn: 'Walnut & Maple',
    nameFa: 'گردو و افرا',
  ),
  CosmeticItem(
    id: 'chk_glass',
    type: ItemType.checker,
    nameEn: 'Glass',
    nameFa: 'شیشه',
    coins: 500,
  ),
  CosmeticItem(
    id: 'chk_jade',
    type: ItemType.checker,
    nameEn: 'Jade & Onyx',
    nameFa: 'یشم و عقیق',
    coins: 650,
  ),
  CosmeticItem(
    id: 'chk_obsidian',
    type: ItemType.checker,
    nameEn: 'Obsidian & Ivory',
    nameFa: 'آبسیدین و عاج',
    coins: 700,
    unlockLevel: 2,
  ),
  CosmeticItem(
    id: 'chk_pearl',
    type: ItemType.checker,
    nameEn: 'Pearl & Lapis',
    nameFa: 'مروارید و لاجورد',
    coins: 800,
    unlockLevel: 3,
  ),
  CosmeticItem(
    id: 'chk_neon',
    type: ItemType.checker,
    nameEn: 'Neon Rings',
    nameFa: 'حلقه‌های نئون',
    coins: 900,
    unlockLevel: 4,
  ),
  CosmeticItem(
    id: 'chk_coin',
    type: ItemType.checker,
    nameEn: 'Old Coins',
    nameFa: 'سکه‌های قدیمی',
    coins: 950,
    unlockLevel: 5,
  ),
  CosmeticItem(
    id: 'chk_gem',
    type: ItemType.checker,
    nameEn: 'Ruby & Emerald',
    nameFa: 'یاقوت و زمرد',
    gems: 40,
    tier: ItemTier.premium,
    unlockLevel: 6,
  ),
  CosmeticItem(
    id: 'chk_comet',
    type: ItemType.checker,
    nameEn: 'Comet Trail',
    nameFa: 'دنبالهٔ شهاب',
    descEn: 'Leaves a trail of light and flares on hits.',
    descFa: 'ردی از نور به جا می‌گذارد و هنگام زدن شعله می‌کشد.',
    gems: 60,
    tier: ItemTier.special,
    unlockLevel: 8,
  ),
  // Dice
  CosmeticItem(
    id: 'dice_bone',
    type: ItemType.dice,
    nameEn: 'Bone',
    nameFa: 'استخوانی',
  ),
  CosmeticItem(
    id: 'dice_wood',
    type: ItemType.dice,
    nameEn: 'Carved Wood',
    nameFa: 'چوب حکاکی',
    coins: 350,
  ),
  CosmeticItem(
    id: 'dice_crystal',
    type: ItemType.dice,
    nameEn: 'Crystal',
    nameFa: 'کریستال',
    coins: 600,
    unlockLevel: 2,
  ),
  CosmeticItem(
    id: 'dice_gold',
    type: ItemType.dice,
    nameEn: 'Gold',
    nameFa: 'طلا',
    coins: 900,
    unlockLevel: 4,
  ),
  CosmeticItem(
    id: 'dice_pixel',
    type: ItemType.dice,
    nameEn: 'Pixel',
    nameFa: 'پیکسلی',
    coins: 700,
    unlockLevel: 3,
  ),
  CosmeticItem(
    id: 'dice_ember',
    type: ItemType.dice,
    nameEn: 'Ember (sparks)',
    nameFa: 'اخگر (جرقه)',
    descEn: 'Rolls in a shower of sparks.',
    descFa: 'با بارانی از جرقه می‌چرخد.',
    gems: 35,
    tier: ItemTier.special,
    unlockLevel: 5,
  ),
  CosmeticItem(
    id: 'dice_smoke',
    type: ItemType.dice,
    nameEn: 'Mystic (smoke)',
    nameFa: 'رازآلود (دود)',
    descEn: 'Rolls through a curl of violet smoke.',
    descFa: 'از میان پیچ‌وتاب دود بنفش می‌چرخد.',
    gems: 35,
    tier: ItemTier.special,
    unlockLevel: 7,
  ),
  // Card backs & frames
  CosmeticItem(
    id: 'back_star',
    type: ItemType.cardBack,
    nameEn: 'Eight-point Star',
    nameFa: 'ستارهٔ هشت‌پر',
  ),
  CosmeticItem(
    id: 'back_boteh',
    type: ItemType.cardBack,
    nameEn: 'Boteh',
    nameFa: 'بته‌جقه',
    coins: 400,
  ),
  CosmeticItem(
    id: 'back_peacock',
    type: ItemType.cardBack,
    nameEn: 'Peacock',
    nameFa: 'طاووس',
    coins: 550,
    unlockLevel: 3,
  ),
  CosmeticItem(
    id: 'back_simorgh',
    type: ItemType.cardBack,
    nameEn: 'Simorgh Wing',
    nameFa: 'بال سیمرغ',
    gems: 30,
    tier: ItemTier.premium,
    unlockLevel: 5,
  ),
  CosmeticItem(
    id: 'frame_gold',
    type: ItemType.cardFrame,
    nameEn: 'Gilded',
    nameFa: 'طلاکوب',
  ),
  CosmeticItem(
    id: 'frame_silver',
    type: ItemType.cardFrame,
    nameEn: 'Silver Filigree',
    nameFa: 'ملیله نقره',
    coins: 450,
  ),
  CosmeticItem(
    id: 'frame_enamel',
    type: ItemType.cardFrame,
    nameEn: 'Minakari Enamel',
    nameFa: 'میناکاری',
    coins: 700,
    unlockLevel: 4,
  ),
  // Victory effects
  CosmeticItem(
    id: 'vic_fireworks',
    type: ItemType.victory,
    nameEn: 'Fireworks',
    nameFa: 'آتش‌بازی',
  ),
  CosmeticItem(
    id: 'vic_petals',
    type: ItemType.victory,
    nameEn: 'Rose Petal Storm',
    nameFa: 'طوفان گلبرگ',
    coins: 800,
    unlockLevel: 2,
  ),
  CosmeticItem(
    id: 'vic_coins',
    type: ItemType.victory,
    nameEn: 'Golden Coins',
    nameFa: 'باران سکه',
    coins: 1000,
    unlockLevel: 4,
  ),
  CosmeticItem(
    id: 'vic_lanterns',
    type: ItemType.victory,
    nameEn: 'Sky Lanterns',
    nameFa: 'فانوس‌های آسمانی',
    gems: 45,
    tier: ItemTier.premium,
    unlockLevel: 6,
  ),
  // Emotes
  CosmeticItem(
    id: 'emo_wellplayed',
    type: ItemType.emote,
    nameEn: 'Well played',
    nameFa: 'خوب بازی کردی',
  ),
  CosmeticItem(
    id: 'emo_wow',
    type: ItemType.emote,
    nameEn: 'Wow!',
    nameFa: 'وای!',
  ),
  CosmeticItem(
    id: 'emo_oops',
    type: ItemType.emote,
    nameEn: 'Oops',
    nameFa: 'اوه',
  ),
  CosmeticItem(
    id: 'emo_luck',
    type: ItemType.emote,
    nameEn: 'Good luck',
    nameFa: 'موفق باشی',
    coins: 150,
  ),
  CosmeticItem(
    id: 'emo_thinking',
    type: ItemType.emote,
    nameEn: 'Hmm…',
    nameFa: 'هوم…',
    coins: 150,
  ),
  CosmeticItem(
    id: 'emo_seven',
    type: ItemType.emote,
    nameEn: 'Seven!',
    nameFa: 'هفت!',
    coins: 250,
    unlockLevel: 2,
  ),
  CosmeticItem(
    id: 'emo_bravo',
    type: ItemType.emote,
    nameEn: 'Bravo!',
    nameFa: 'آفرین!',
    coins: 200,
  ),
  CosmeticItem(
    id: 'emo_mars',
    type: ItemType.emote,
    nameEn: 'Mars!',
    nameFa: 'مارس!',
    gems: 15,
    tier: ItemTier.premium,
    unlockLevel: 4,
  ),
];

final Map<String, CosmeticItem> kItemById = {for (final i in kItems) i.id: i};

CosmeticItem? itemById(String id) => kItemById[id];

List<CosmeticItem> itemsOfType(ItemType t) =>
    kItems.where((i) => i.type == t).toList();

/// The loadout every new profile starts with (all free items are owned).
const Map<ItemType, String> kDefaultLoadout = {
  ItemType.board: 'board_khatam',
  ItemType.environment: 'env_lantern_hall',
  ItemType.checker: 'chk_wood',
  ItemType.dice: 'dice_bone',
  ItemType.cardBack: 'back_star',
  ItemType.cardFrame: 'frame_gold',
  ItemType.victory: 'vic_fireworks',
  ItemType.emote: 'emo_wellplayed',
};

/// A themed bundle sold at a discount.
class Bundle {
  const Bundle({
    required this.id,
    required this.nameEn,
    required this.nameFa,
    required this.items,
    required this.coins,
  });
  final String id;
  final String nameEn;
  final String nameFa;
  final List<String> items;
  final int coins;
  String name(String lang) => lang == 'fa' ? nameFa : nameEn;
}

const List<Bundle> kBundles = [
  Bundle(
    id: 'bundle_night',
    nameEn: 'Caravan by Night',
    nameFa: 'کاروان شبانه',
    items: ['board_caravanserai', 'env_desert_night', 'dice_wood'],
    coins: 1950,
  ),
  Bundle(
    id: 'bundle_arcade',
    nameEn: 'Arcade Pack',
    nameFa: 'بستهٔ آرکید',
    items: ['board_neon', 'env_neon_city', 'chk_neon', 'dice_pixel'],
    coins: 3800,
  ),
  Bundle(
    id: 'bundle_shah',
    nameEn: "Shah's Treasury",
    nameFa: 'خزانهٔ شاه',
    items: ['board_marble', 'chk_coin', 'dice_gold', 'vic_coins'],
    coins: 3500,
  ),
];
