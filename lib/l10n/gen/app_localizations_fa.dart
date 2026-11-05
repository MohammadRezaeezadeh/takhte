// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'هفت‌نرد';

  @override
  String get tagline => 'تخته‌نرد، با یک جفت هفت';

  @override
  String get play => 'بازی';

  @override
  String get journey => 'سفر';

  @override
  String get store => 'فروشگاه';

  @override
  String get locker => 'کمد';

  @override
  String get profile => 'پروفایل';

  @override
  String get settings => 'تنظیمات';

  @override
  String get online => 'آنلاین';

  @override
  String get comingSoon => 'به‌زودی';

  @override
  String get onlineTeaser =>
      'با بازیکنان سراسر دنیا رقابت کن. کاروان در راه است.';

  @override
  String get tutorial => 'آموزش';

  @override
  String get resume => 'ادامه';

  @override
  String get resumeMatch => 'ادامهٔ بازی';

  @override
  String get back => 'بازگشت';

  @override
  String get start => 'شروع';

  @override
  String get close => 'بستن';

  @override
  String get ok => 'باشه';

  @override
  String get cancel => 'انصراف';

  @override
  String get confirm => 'تأیید';

  @override
  String get yes => 'بله';

  @override
  String get no => 'خیر';

  @override
  String get modeClassic => 'کلاسیک';

  @override
  String get modeClassicDesc => 'تخته‌نرد خالص؛ بدون کارت و بدون هفت.';

  @override
  String get modeSeven => 'هفت';

  @override
  String get modeSevenDesc => 'جفت هفتِ درخشان بیاور و یک کارت قدرت انتخاب کن.';

  @override
  String get modePassPlay => 'دو نفره';

  @override
  String get modePassPlayDesc => 'دو بازیکن، یک دستگاه.';

  @override
  String get chooseMode => 'حالت';

  @override
  String get chooseOpponent => 'حریف';

  @override
  String get difficulty => 'سختی';

  @override
  String get diffBeginner => 'نوآموز';

  @override
  String get diffEasy => 'آسان';

  @override
  String get diffMedium => 'متوسط';

  @override
  String get diffHard => 'سخت';

  @override
  String get diffMaster => 'استاد';

  @override
  String get matchLength => 'طول مسابقه';

  @override
  String pointsN(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString امتیاز',
      one: '۱ امتیاز',
    );
    return '$_temp0';
  }

  @override
  String get doublingCube => 'تاس دوبل';

  @override
  String get doublingCubeDesc =>
      'به‌طور پیش‌فرض خاموش است، مثل تخته‌نرد ایرانی.';

  @override
  String get human => 'انسان';

  @override
  String get player1 => 'بازیکن ۱';

  @override
  String get player2 => 'بازیکن ۲';

  @override
  String get you => 'تو';

  @override
  String get yourTurn => 'نوبت توست';

  @override
  String theirTurn(String name) {
    return 'نوبت $name';
  }

  @override
  String get tapToRoll => 'برای ریختن تاس، روی تاس‌ها بزن';

  @override
  String get rollOpening => 'تاس بریز تا شروع‌کننده مشخص شود';

  @override
  String get openingTie => 'مساوی! دوباره تاس بریز.';

  @override
  String startsFirst(String name) {
    return '$name شروع می‌کند';
  }

  @override
  String get noMoves => 'حرکتی ممکن نیست؛ نوبت رد می‌شود';

  @override
  String get undo => 'برگشت';

  @override
  String get done => 'تمام';

  @override
  String get endTurn => 'پایان نوبت';

  @override
  String get double => 'دوبل';

  @override
  String get take => 'قبول';

  @override
  String get drop => 'رد';

  @override
  String doubleOffered(String name, int value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '$name پیشنهاد دوبل به $valueString می‌دهد';
  }

  @override
  String get pips => 'خانه';

  @override
  String pipsN(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString خانه';
  }

  @override
  String get score => 'امتیاز';

  @override
  String matchTo(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'مسابقه تا $nString';
  }

  @override
  String get crawford => 'کرافورد';

  @override
  String get sevenTitle => 'جفت هفت';

  @override
  String get choosePower => 'قدرتت را انتخاب کن';

  @override
  String chooseTwo(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString قدرت انتخاب کن';
  }

  @override
  String opponentChose(String card, String name) {
    return '$name کارت «$card» را برداشت';
  }

  @override
  String get selectTargets => 'هدف را انتخاب کن';

  @override
  String get targetEnemy2 => 'دو مهرهٔ حریف را برای زنجیر انتخاب کن';

  @override
  String get targetOwn => 'یکی از مهره‌هایت را انتخاب کن';

  @override
  String get targetOwnBlot => 'یکی از مهره‌های تنهایت را انتخاب کن';

  @override
  String get targetEmpty => 'یک خانهٔ خالی را انتخاب کن';

  @override
  String get targetPoint => 'یک خانه را انتخاب کن';

  @override
  String get targetTeleportFrom =>
      'مهره‌ای را که می‌خواهی جابه‌جا کنی انتخاب کن';

  @override
  String get targetTeleportTo => 'مقصد را انتخاب کن';

  @override
  String get chooseDiceTitle => 'دست سنگین: دو تاس را نگه دار';

  @override
  String get fateTitle => 'دست تقدیر: روی تاسی بزن تا تغییرش دهی';

  @override
  String get useReroll => 'تکرار تاس';

  @override
  String get useLucky => '+۱';

  @override
  String get useFate => 'تقدیر';

  @override
  String get activeEffects => 'اثرهای فعال';

  @override
  String turnsLeft(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString نوبت',
      one: '۱ نوبت',
    );
    return '$_temp0';
  }

  @override
  String get stored => 'ذخیره';

  @override
  String get victory => 'پیروزی!';

  @override
  String get defeat => 'شکست';

  @override
  String winsGame(String name) {
    return '$name برنده شد';
  }

  @override
  String get winNormal => 'برد ساده';

  @override
  String get winGammon => 'مارس!';

  @override
  String get winBackgammon => 'کوپ مارس!';

  @override
  String get winDropped => 'دوبل رد شد';

  @override
  String get winResigned => 'تسلیم';

  @override
  String pointsWon(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '+$nString امتیاز';
  }

  @override
  String get matchWon => 'مسابقه را بردی!';

  @override
  String get matchLost => 'مسابقه را باختی';

  @override
  String get nextGame => 'بازی بعد';

  @override
  String get rematch => 'بازی دوباره';

  @override
  String get mainMenu => 'منوی اصلی';

  @override
  String get paused => 'توقف';

  @override
  String get resign => 'تسلیم';

  @override
  String get resignConfirm => 'از این بازی انصراف می‌دهی؟';

  @override
  String coinsEarned(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '+$nString سکه';
  }

  @override
  String xpEarned(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '+$nString تجربه';
  }

  @override
  String levelUp(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'سطح جدید! سطح $nString';
  }

  @override
  String get coins => 'سکه';

  @override
  String get gems => 'جواهر';

  @override
  String level(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'سطح $nString';
  }

  @override
  String get language => 'زبان';

  @override
  String get languageSystem => 'پیش‌فرض دستگاه';

  @override
  String get boardOrientation => 'جهت تخته';

  @override
  String get orientationCcw => 'خانه در سمت راست';

  @override
  String get orientationCw => 'خانه در سمت چپ';

  @override
  String get animationSpeed => 'سرعت انیمیشن';

  @override
  String get speedSlow => 'آرام';

  @override
  String get speedNormal => 'معمولی';

  @override
  String get speedFast => 'سریع';

  @override
  String get sound => 'جلوه‌های صوتی';

  @override
  String get music => 'موسیقی';

  @override
  String get haptics => 'لرزش';

  @override
  String get colorblind => 'رنگ‌های مناسب کوررنگی';

  @override
  String get highContrast => 'کنتراست بالا';

  @override
  String get reducedMotion => 'حرکت کمتر';

  @override
  String get leftHanded => 'چیدمان چپ‌دست';

  @override
  String get autoMove => 'اجرای خودکار حرکت‌های اجباری';

  @override
  String get confirmMoves => 'تأیید پیش از پایان نوبت';

  @override
  String get showPips => 'نمایش شمارش خانه‌ها';

  @override
  String get resetProgress => 'بازنشانی پیشرفت';

  @override
  String get resetConfirm => 'همهٔ پیشرفت پاک شود؟ این کار برگشت‌پذیر نیست.';

  @override
  String get about => 'درباره';

  @override
  String get aboutText =>
      'هفت‌نرد یک بازی اصیل است. همهٔ تصاویر و صداها با کد ساخته شده‌اند. قلم‌ها: وزیرمتن، لاله‌زار و سینزل (مجوز SIL OFL).';

  @override
  String get replayLast => 'بازپخش آخرین بازی';

  @override
  String get replay => 'بازپخش';

  @override
  String get storeBoards => 'تخته';

  @override
  String get storeEnvironments => 'محیط';

  @override
  String get storeCheckers => 'مهره';

  @override
  String get storeDice => 'تاس';

  @override
  String get storeCardBacks => 'پشت کارت';

  @override
  String get storeVictory => 'جلوهٔ پیروزی';

  @override
  String get storeEmotes => 'ایموت';

  @override
  String get storeBundles => 'بسته‌ها';

  @override
  String get dailyShop => 'فروشگاه روزانه';

  @override
  String refreshesIn(String time) {
    return 'تازه‌سازی تا $time';
  }

  @override
  String get buy => 'خرید';

  @override
  String get owned => 'داری';

  @override
  String get equip => 'استفاده';

  @override
  String get equipped => 'در حال استفاده';

  @override
  String get notEnough => 'موجودی کافی نیست';

  @override
  String get purchased => 'خریداری شد!';

  @override
  String get randomizeLoadout => 'چیدمان تصادفی';

  @override
  String get preview => 'پیش‌نمایش';

  @override
  String get statistics => 'آمار';

  @override
  String get achievements => 'دستاوردها';

  @override
  String get statGames => 'بازی‌ها';

  @override
  String get statWins => 'بردها';

  @override
  String get statWinRate => 'درصد برد';

  @override
  String get statMars => 'بردهای مارس';

  @override
  String get statKupMars => 'بردهای کوپ مارس';

  @override
  String get statSevens => 'جفت هفت‌ها';

  @override
  String get statHits => 'مهره‌های زده‌شده';

  @override
  String get statFavoriteCard => 'کارت محبوب';

  @override
  String get statBestRun => 'بهترین سفر';

  @override
  String get statJourneysWon => 'سفرهای کامل';

  @override
  String get statStreak => 'بهترین برد پیاپی';

  @override
  String get none => '—';

  @override
  String get unlocked => 'باز شد';

  @override
  String get locked => 'قفل';

  @override
  String get newRun => 'سفر تازه';

  @override
  String get continueRun => 'ادامهٔ سفر';

  @override
  String get dailyRun => 'سفر روزانه';

  @override
  String get seed => 'بذر';

  @override
  String act(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'پردهٔ $nString';
  }

  @override
  String get actBazaar => 'بازار';

  @override
  String get actCaravanserai => 'کاروانسرا';

  @override
  String get actPalace => 'کاخ';

  @override
  String get boss => 'سرکرده';

  @override
  String bossRule(String rule) {
    return 'قانون: $rule';
  }

  @override
  String get runShop => 'حجرهٔ بازار';

  @override
  String get talismans => 'طلسم‌ها';

  @override
  String get removeCard => 'تبعید یک کارت';

  @override
  String get removeCardDesc =>
      'یک کارت را برای این سفر از پیشنهادهای هفت‌هفت حذف کن.';

  @override
  String get upgradeOffer => 'پیشنهاد بیشتر';

  @override
  String get upgradeOfferDesc =>
      'پیشنهادهای هفت‌هفت تو یک کارت بیشتر نشان می‌دهند.';

  @override
  String get luckUp => 'لطف هفت';

  @override
  String get luckUpDesc => '۲۵٪ شانس بیشتر برای هفت‌هفت.';

  @override
  String get leaveShop => 'ادامه';

  @override
  String get runCoins => 'سکهٔ سفر';

  @override
  String get runOver => 'سفر به پایان رسید';

  @override
  String get runWon => 'سفر کامل شد!';

  @override
  String runKept(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString سکه برایت می‌ماند';
  }

  @override
  String opponentN(int n, int total) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'حریف $nString از $totalString';
  }

  @override
  String get fight => 'نبرد';

  @override
  String get tutorialBasics => 'اصول تخته‌نرد';

  @override
  String get tutorialSevens => 'جفت هفت';

  @override
  String get next => 'بعدی';

  @override
  String get skip => 'رد کردن';

  @override
  String get finish => 'پایان';

  @override
  String get tip => 'نکته';

  @override
  String get loading => 'در حال بارگذاری…';

  @override
  String get emoteTitle => 'ایموت‌ها';

  @override
  String get aiThinking => 'در حال فکر…';

  @override
  String get pickTalisman => 'یک طلسم انتخاب کن';

  @override
  String get free => 'رایگان';

  @override
  String get dailyBonus => 'جایزهٔ روزانه';

  @override
  String get claim => 'دریافت';

  @override
  String replayControls(int n, int total) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'گام $nString از $totalString';
  }

  @override
  String gameN(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'بازی $nString';
  }

  @override
  String get sevenMode => 'حالت هفت';

  @override
  String get classicMode => 'حالت کلاسیک';

  @override
  String turnSkipped(String name) {
    return '$name یک نوبت را از دست داد!';
  }

  @override
  String get coinHeads => 'شیر! حریف یک نوبت را از دست می‌دهد.';

  @override
  String get coinTails => 'خط! تو یک نوبت را از دست می‌دهی.';

  @override
  String get mineBoom => 'یک مین پنهان!';

  @override
  String get phoenixRises => 'ققنوس برخاست!';

  @override
  String stolen(String item) {
    return 'دزدیده شد: $item';
  }

  @override
  String get itemReroll => 'ژتون تکرار تاس';

  @override
  String get itemLucky => 'طلسم بخت';

  @override
  String get itemGhost => 'گام شبح';

  @override
  String get itemPhoenix => 'ققنوس';

  @override
  String get gripped => 'در باتلاق گیر افتاد!';

  @override
  String get extraTurn => 'زمان ایستاد؛ نوبت اضافه!';

  @override
  String get bonusRoll => 'تاس اضافه!';

  @override
  String fizzled(String card) {
    return '«$card» هدفی نداشت';
  }

  @override
  String get rarityCommon => 'معمولی';

  @override
  String get rarityRare => 'کمیاب';

  @override
  String get rarityEpic => 'حماسی';

  @override
  String get rarityLegendary => 'افسانه‌ای';

  @override
  String get drawback => 'بها';

  @override
  String get howToPlay => 'روش بازی';

  @override
  String get targetOwnBlot2 => 'دو مهرهٔ تنهای خودت را انتخاب کن';

  @override
  String get targetEmpty2 => 'دو خانهٔ خالی را انتخاب کن';

  @override
  String get targetPoint2 => 'دو خانه را انتخاب کن';

  @override
  String get bar => 'بار';

  @override
  String get targetEnemy1 => 'یک مهرهٔ حریف را انتخاب کن';

  @override
  String get targetEnemyBlot => 'یک مهرهٔ تنهای حریف را انتخاب کن';

  @override
  String get targetOwn2 => 'دو خانهٔ خودت را انتخاب کن';

  @override
  String get welcomeTitle => 'به هفت‌نرد خوش آمدی';

  @override
  String get welcomeBody =>
      'تخته‌نرد کلاسیک ایرانی، با یک پیچش: جفت هفتِ درخشان بیاور و یک کارت قدرت بردار. تازه‌کاری؟ یک آموزش تعاملی دو دقیقه‌ای راهت می‌اندازد.';

  @override
  String get welcomeSkip => 'بازی را بلدم';

  @override
  String get codex => 'دانشنامهٔ کارت‌ها';

  @override
  String codexProgress(int n, int total) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$nString از $totalString کارت باز شده';
  }

  @override
  String get attuneCard => 'کوک کردن کارت';

  @override
  String get attuneCardDesc =>
      'کارتی را انتخاب کن تا در این سفر سه برابر بیشتر در پیشنهادهای هفت‌هفت تو بیاید.';

  @override
  String cubeExplain(int value, int current) {
    return 'حریف می‌خواد امتیاز این دست دوبرابر بشه ($value امتیاز). قبول کنی بازی روی $value ادامه پیدا می‌کنه؛ رد کنی همین الان $current امتیاز می‌بازی.';
  }

  @override
  String get help => 'راهنمای صفحه';

  @override
  String get helpDice =>
      'تاس‌ها: بزن تا بریزی. تاس استفاده‌شده همان‌جا کم‌رنگ می‌شود. هفت‌هفت پیشنهاد کارت باز می‌کند.';

  @override
  String get helpPips =>
      'پنل بازیکن: نام، خانه‌های باقی‌مانده تا خروج (کمتر بهتر است) و مهره‌های خارج‌شده.';

  @override
  String get helpBar =>
      'بار (وسط تخته): مهره‌های زده‌شده این‌جا منتظرند و اول باید وارد بازی شوند.';

  @override
  String get helpOff =>
      'سینی کنار: مهره‌های خارج‌شده. هر ۱۵ مهره که آن‌جا برسد بازی را برده‌ای.';

  @override
  String get helpCube =>
      'تاس دوبل: ارزش فعلی این دست. فقط در مسابقه‌هایی که دوبل روشن است.';

  @override
  String get helpSeven =>
      'هفت‌هفت: با آوردنش یک کارت قدرت انتخاب می‌کنی. هر نوبت بدون آن احتمالش بیشتر می‌شود و بعد از ۱۲ نوبت حتماً می‌آید.';

  @override
  String get helpEffects =>
      'نشان‌های درخشان: قدرت‌های فعال با تعداد نوبت باقی‌مانده. برای جزئیات رویشان بزن.';

  @override
  String get helpCharges =>
      'ژتون‌ها: تکرار تاس، طلسم بخت، گام شبح و ققنوس‌هایی که هنوز داری.';

  @override
  String get helpButtons =>
      'دکمه‌ها: برگرداندن حرکت، استفاده از ژتون تکرار تاس، بهترین حرکت خودکار و پایان نوبت.';

  @override
  String get helpEmotes => 'شکلک‌ها (گوشهٔ پایین): یک واکنش سریع بفرست.';

  @override
  String get reportProblem => 'گزارش مشکل';

  @override
  String get reportProblemHint =>
      'این متن را کپی کن و برای سازنده بفرست. شامل خطاها و کندی‌های چند دقیقهٔ اخیر و مشخصات دستگاه است و هیچ اطلاعات شخصی ندارد.';

  @override
  String get copyReport => 'کپی';

  @override
  String get copiedReport => 'کپی شد';

  @override
  String get tagOpponent => 'حریف';

  @override
  String get tagSelf => 'خودت';

  @override
  String get tagBoard => 'تخته';

  @override
  String durTurns(String n) {
    return '$n نوبت';
  }

  @override
  String get durNext => 'نوبت بعد';

  @override
  String get durSeven => 'تا هفت‌هفت بعدی';

  @override
  String get durInstant => 'فوری';

  @override
  String get pickCard => 'انتخاب';

  @override
  String get cardHoldHint =>
      'روی کارت بزن تا اثرش رو روی تخته ببینی · نگه دار برای جزئیات';

  @override
  String targetProgress(String done, String total) {
    return '$done/$total';
  }

  @override
  String get undoTarget => 'برگردان';

  @override
  String get confirmTargets => 'تأیید';

  @override
  String get pendingNext => 'نوبت بعد حریف';

  @override
  String get pendingMine => 'نوبت بعد خودت';

  @override
  String resultDone(String name, String effect) {
    return '✓ $name: $effect';
  }

  @override
  String get guide1 => 'هفت‌هفت آوردی! یکی از این کارت‌های قدرت مال توئه.';

  @override
  String get guide2 =>
      'روی یه کارت بزن: تخته دقیقاً نشون می‌ده روی چی اثر می‌ذاره.';

  @override
  String get guide3 =>
      'پسندیدی؟ «انتخاب» رو بزن. برای جزئیات کامل، کارت رو نگه دار.';

  @override
  String get guideNext => 'فهمیدم';

  @override
  String get musicVolume => 'بلندی موسیقی';

  @override
  String get sfxVolume => 'بلندی جلوه‌های صوتی';

  @override
  String get aiOffer => 'حریف هفت‌هفت آورد';

  @override
  String get aiPickedHeader => 'حریف این کارت رو انتخاب کرد';

  @override
  String get cardHistory => 'کارت‌های بازی‌شده';

  @override
  String get cardHistoryEmpty => 'هنوز کارتی بازی نشده';

  @override
  String get lanPlay => 'دوست (وای‌فای)';

  @override
  String get lanPlayDesc => 'دو گوشی، یه وای‌فای یا هات‌اسپات';

  @override
  String get lanHost => 'ساختن بازی';

  @override
  String get lanJoin => 'پیوستن به بازی';

  @override
  String get lanWaiting => 'منتظر دوستت…';

  @override
  String get lanYourAddress => 'آدرس تو';

  @override
  String get lanHelp =>
      'هر دو گوشی روی یه وای‌فای باشن؛ یا یکی هات‌اسپات رو روشن کنه و اون یکی بهش وصل شه.';

  @override
  String get lanSearching => 'دنبال بازی می‌گردیم…';

  @override
  String get lanNoGames =>
      'هنوز بازی‌ای پیدا نشد. می‌تونی آدرس میزبان رو هم بنویسی.';

  @override
  String get lanAddressHint => 'آدرس میزبان (مثلاً 192.168.43.1)';

  @override
  String get lanConnect => 'وصل شو';

  @override
  String get lanYourName => 'اسمت';

  @override
  String get lanHostDefault => 'میزبان';

  @override
  String get lanGuestDefault => 'مهمان';

  @override
  String get lanErrUnreachable => 'به این آدرس وصل نشدیم.';

  @override
  String get lanErrFull => 'این بازی پره؛ دو نفر دارن بازی می‌کنن.';

  @override
  String get lanErrVersion => 'نسخه‌ی بازی دوستت فرق داره.';

  @override
  String get lanErrNoAnswer => 'این آدرس جواب نداد.';

  @override
  String get lanLost => 'اتصال قطع شد؛ داریم دوباره وصل می‌شیم…';

  @override
  String get lanLeft => 'دوستت از بازی رفت.';

  @override
  String get lanSyncing => 'همگام‌سازی…';
}
