import 'dart:math' as math;

/// Short gameplay tips shown on loading moments.
const List<(String, String)> kTips = [
  (
    'Make points in your home board early: they trap enemy checkers on the bar.',
    'زود در خانه‌ات خانه ببند؛ مهره‌های حریف روی بار گیر می‌افتند.',
  ),
  (
    'A lone checker (a blot) can be hit. Two or more make a safe point.',
    'مهرهٔ تنها (لنگ) زده می‌شود؛ دو مهره یا بیشتر خانهٔ امن می‌سازند.',
  ),
  (
    'Six points in a row form a prime — nothing can jump it.',
    'شش خانهٔ پشت سر هم «دیوار» می‌سازد و هیچ مهره‌ای از آن نمی‌پرد.',
  ),
  (
    'Winning before your opponent bears off any checker scores a Mars (2 points).',
    'اگر پیش از خروج اولین مهرهٔ حریف ببری، «مارس» (۲ امتیاز) گرفته‌ای.',
  ),
  (
    'A 7–7 never wastes your turn: you still roll normally after picking a card.',
    'هفت‌هفت هیچ‌وقت نوبتت را نمی‌سوزاند؛ بعد از برداشتن کارت باز هم تاس می‌ریزی.',
  ),
  (
    'Legendary cards are mighty, but read the red drawback first.',
    'کارت‌های افسانه‌ای قدرتمندند؛ ولی اول بهای قرمزشان را بخوان.',
  ),
  (
    'Long-press an effect icon on a player panel to see what it does and how long it lasts.',
    'روی آیکون اثرها انگشتت را نگه دار تا کار و مدتشان را ببینی.',
  ),
  (
    'Tap a checker, then a glowing point — or just drag it. Tap it again to play the larger die.',
    'روی مهره بزن و بعد خانهٔ روشن را انتخاب کن، یا بکشش. دوباره بزنی، تاس بزرگ‌تر بازی می‌شود.',
  ),
  (
    'Undo is free until you press Done.',
    'تا دکمهٔ «تمام» را نزده‌ای، برگشت مجانی است.',
  ),
  (
    'In a pure race, count pips: the lower count is ahead.',
    'در مسابقهٔ خالص خانه‌ها را بشمار؛ هر که کمتر دارد جلوتر است.',
  ),
  (
    'Journey talismans stack: build a combo around dice, traps or tempo.',
    'طلسم‌های سفر روی هم جمع می‌شوند؛ حول تاس، تله یا ضرب‌آهنگ ترکیب بساز.',
  ),
  (
    'Hidden mines are only visible to their owner. Lantern of Truth reveals and destroys them.',
    'مین‌های پنهان فقط برای صاحبشان پیداست؛ «فانوس حقیقت» آشکار و نابودشان می‌کند.',
  ),
  (
    'Every daily journey uses the same seed for everyone today.',
    'سفر روزانه برای همه در یک روز با یک بذر یکسان ساخته می‌شود.',
  ),
  (
    'Checkers on the bar must re-enter before any other move.',
    'مهرهٔ روی بار باید پیش از هر حرکت دیگری وارد شود.',
  ),
];

/// A random tip in [lang] ('fa' or 'en').
String randomTip(String lang, [math.Random? rng]) {
  final t = kTips[(rng ?? math.Random()).nextInt(kTips.length)];
  return lang == 'fa' ? t.$2 : t.$1;
}
