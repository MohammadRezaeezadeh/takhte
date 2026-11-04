import 'package:haftnard/core/effects/cards.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';

/// One interactive tutorial lesson.
class TutorialStep {
  const TutorialStep({
    required this.titleEn,
    required this.titleFa,
    required this.bodyEn,
    required this.bodyFa,
    required this.build,
    this.done,
  });

  final String titleEn;
  final String titleFa;
  final String bodyEn;
  final String bodyFa;

  /// The position for this lesson.
  final GameState Function() build;

  /// Lesson goal; null means "read and tap Next".
  final bool Function(GameState s)? done;

  String title(String lang) => lang == 'fa' ? titleFa : titleEn;
  String body(String lang) => lang == 'fa' ? bodyFa : bodyEn;
}

GameState _moving(Board b, List<int> dice, {GameMode mode = GameMode.classic}) {
  final s = GameState.initial(GameConfig(mode: mode, startingBoard: b, p7: 0));
  final raw = dice.length == 4 ? [dice[0], dice[0]] : dice;
  return s.copyWith(
    phase: Phase.moving,
    current: Side.white,
    turnNumber: 1,
    dice: dice,
    rolled: raw,
    rollsThisTurn: 1,
    sevenUsed: true,
  );
}

GameState _seven(Board b, List<String> offer) =>
    GameState.initial(GameConfig(startingBoard: b, p7: 0)).copyWith(
      phase: Phase.sevenPick,
      current: Side.white,
      turnNumber: 1,
      offer: offer,
      picksLeft: 1,
      sevenUsed: true,
      rolled: [7, 7],
    );

final List<TutorialStep> kBasicsTutorial = [
  TutorialStep(
    titleEn: 'Welcome to the board',
    titleFa: 'به تخته خوش آمدی',
    bodyEn: 'You play the light checkers. Move all 15 around the board, counter-clockwise, into your home (bottom right), then bear them off. First to bear off all 15 wins.',
    bodyFa: 'تو با مهره‌های روشن بازی می‌کنی. هر ۱۵ مهره را خلاف جهت عقربه‌های ساعت به خانه‌ات (پایین راست) ببر و بعد بیرونشان بیاور. هر کس زودتر ۱۵ مهره را خارج کند می‌برد.',
    build: () => _moving(Board.initial(), [
      3,
      1,
    ]).copyWith(phase: Phase.preRoll, dice: const []),
  ),
  TutorialStep(
    titleEn: 'Moving',
    titleFa: 'حرکت',
    bodyEn: 'You rolled 3–1. Tap a glowing checker, then a highlighted point (or drag it). Try 8→5 and 6→5 to build a point.',
    bodyFa: '۳ و ۱ آوردی. روی مهرهٔ درخشان بزن و بعد خانهٔ روشن را انتخاب کن (یا بکشش). ۸ به ۵ و ۶ به ۵ را امتحان کن تا خانه ببندی.',
    build: () => _moving(Board.initial(), [3, 1]),
    done: (s) => s.dice.isEmpty || s.current != Side.white,
  ),
  TutorialStep(
    titleEn: 'Hitting',
    titleFa: 'زدن',
    bodyEn: 'A single checker is a blot. Land on an enemy blot to send it to the bar. Hit it now!',
    bodyFa: 'مهرهٔ تنها «لنگ» است. روی لنگ حریف فرود بیا تا به بار برود. حالا بزنش!',
    build: () => _moving(
      Board.fromMaps(
        white: const {10: 1, 6: 5, 8: 3, 13: 6},
        black: const {18: 1, 1: 2, 6: 5, 8: 3, 13: 4},
      ),
      [3, 5],
    ),
    done: (s) => s.board.onBar(Side.black) > 0,
  ),
  TutorialStep(
    titleEn: 'The bar',
    titleFa: 'بار',
    bodyEn: 'A checker on the bar must re-enter in the opponent’s home before any other move. Enter it.',
    bodyFa: 'مهره‌ای که روی بار است باید پیش از هر حرکت دیگری در خانهٔ حریف وارد شود. واردش کن.',
    build: () => _moving(
      Board.fromMaps(
        white: const {25: 1, 6: 5, 8: 3, 13: 6},
        black: const {1: 2, 3: 2, 6: 5, 8: 3, 13: 3},
      ),
      [4, 2],
    ),
    done: (s) => s.board.onBar(Side.white) == 0,
  ),
  TutorialStep(
    titleEn: 'Doubles',
    titleFa: 'جفت',
    bodyEn: 'Rolling a double lets you play the number four times.',
    bodyFa: 'اگر جفت بیاوری، آن عدد را چهار بار بازی می‌کنی.',
    build: () => _moving(Board.initial(), [4, 4, 4, 4]),
    done: (s) => s.dice.isEmpty || s.current != Side.white,
  ),
  TutorialStep(
    titleEn: 'Bearing off',
    titleFa: 'خارج کردن مهره',
    bodyEn: 'All your checkers are home: bear them off by moving past the edge into your tray. Win with no enemy checker borne off for a Mars (2 points)!',
    bodyFa: 'همهٔ مهره‌هایت در خانه‌اند؛ با عبور از لبه آن‌ها را به سینی بیرون ببر. اگر حریف هیچ مهره‌ای خارج نکرده باشد، «مارس» (۲ امتیاز) می‌شود!',
    build: () => _moving(
      Board.fromMaps(
        white: const {6: 4, 5: 4, 4: 3, 2: 2, 1: 2},
        black: const {13: 13, 12: 2},
      ),
      [6, 5],
    ),
    done: (s) => s.board.borneOff(Side.white) >= 2,
  ),
];

final List<TutorialStep> kSevenTutorial = [
  TutorialStep(
    titleEn: 'The Double Seven',
    titleFa: 'جفت هفت',
    bodyEn: 'Sometimes the dice blaze into a glowing 7–7. Time stops and you pick one of three power cards. Then you still roll normally — a 7–7 never wastes a turn. Pick a card!',
    bodyFa: 'گاهی تاس‌ها به یک جفت هفتِ درخشان تبدیل می‌شوند. زمان می‌ایستد و یکی از سه کارت قدرت را برمی‌داری. بعد باز هم تاس معمولی می‌ریزی؛ هفت‌هفت هیچ‌وقت نوبتت را هدر نمی‌دهد. یک کارت انتخاب کن!',
    build: () => _seven(Board.initial(), const [
      CardId.loadedHand,
      CardId.brokenDie,
      CardId.phoenix,
    ]),
    done: (s) => s.phase != Phase.sevenPick,
  ),
  TutorialStep(
    titleEn: 'Targeted powers',
    titleFa: 'قدرت‌های هدف‌دار',
    bodyEn: 'Some cards ask for a target. Choose Chains, then tap two enemy checkers to lock them for two turns.',
    bodyFa: 'بعضی کارت‌ها هدف می‌خواهند. «زنجیر» را بردار و روی دو مهرهٔ حریف بزن تا دو نوبت قفل شوند.',
    build: () => _seven(Board.initial(), const [CardId.chains]),
    done: (s) => s.phase == Phase.preRoll,
  ),
  TutorialStep(
    titleEn: 'Rarity and risk',
    titleFa: 'کمیابی و ریسک',
    bodyEn: 'Cards are Common, Rare, Epic or Legendary. Legendary cards are mighty but carry a drawback in red. Active effects appear on each player’s panel with a turn counter — long-press for details.',
    bodyFa: 'کارت‌ها معمولی، کمیاب، حماسی یا افسانه‌ای‌اند. کارت‌های افسانه‌ای قدرتمندند اما بهایی دارند که با رنگ قرمز نوشته شده. اثرهای فعال با شمارندهٔ نوبت روی پنل هر بازیکن دیده می‌شوند؛ برای جزئیات انگشتت را نگه دار.',
    build: () => _seven(Board.initial(), const [
      CardId.timeStop,
      CardId.bloodPact,
      CardId.doubleDown,
    ]),
    done: (s) => s.phase != Phase.sevenPick,
  ),
];
