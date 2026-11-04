import 'package:haftnard/core/rng/rng.dart';
import 'package:haftnard/core/rules/board.dart';
import 'package:haftnard/core/rules/types.dart';

/// Turn state machine phases.
enum Phase {
  /// Each side rolls one die; higher starts.
  opening,

  /// Current side may offer the cube or roll.
  preRoll,

  /// Opponent must take or drop the offered cube.
  cubeOffered,

  /// A 7–7 was rolled: current side picks from the card offer.
  sevenPick,

  /// The picked card needs board targets.
  cardTarget,

  /// Loaded Hand: choose two of three rolled dice.
  chooseDice,

  /// Playing checkers with the remaining dice.
  moving,

  /// Game finished.
  gameOver,
}

/// Game modes.
enum GameMode { classic, seven, journey }

/// Per-side rule modifiers from talismans and bosses (Journey mode).
class SideMods {
  const SideMods({
    this.p7Multiplier = 1,
    this.offerBonus = 0,
    this.doublesCount = true,
    this.rerollEveryNthDouble = 0,
    this.firstBearOffReroll = false,
    this.startRerolls = 0,
    this.startPhoenix = 0,
    this.startGhost = 0,
    this.startLucky = 0,
    this.capDice = 6,
  });

  factory SideMods.fromJson(Map<String, Object?> j) => SideMods(
    p7Multiplier: (j['p7m'] as num?)?.toDouble() ?? 1,
    offerBonus: j['ob'] as int? ?? 0,
    doublesCount: j['dc'] as bool? ?? true,
    rerollEveryNthDouble: j['rn'] as int? ?? 0,
    firstBearOffReroll: j['fbs'] as bool? ?? false,
    startRerolls: j['sr'] as int? ?? 0,
    startPhoenix: j['sp'] as int? ?? 0,
    startGhost: j['sg'] as int? ?? 0,
    startLucky: j['sl'] as int? ?? 0,
    capDice: j['cap'] as int? ?? 6,
  );

  /// Multiplier on this side's 7–7 chance (0 disables).
  final double p7Multiplier;

  /// Extra cards in this side's 7–7 offers.
  final int offerBonus;

  /// When false, this side's doubles are played as two dice.
  final bool doublesCount;

  /// Every Nth double rolled grants a reroll token (0 = off).
  final int rerollEveryNthDouble;

  /// The first checker this side bears off grants a reroll token.
  final bool firstBearOffReroll;

  final int startRerolls;
  final int startPhoenix;
  final int startGhost;
  final int startLucky;

  /// Maximum die value this side can roll (boss curse), 6 = none.
  final int capDice;

  static const SideMods none = SideMods();

  Map<String, Object?> toJson() => {
    if (p7Multiplier != 1) 'p7m': p7Multiplier,
    if (offerBonus != 0) 'ob': offerBonus,
    if (!doublesCount) 'dc': false,
    if (rerollEveryNthDouble != 0) 'rn': rerollEveryNthDouble,
    if (firstBearOffReroll) 'fbs': true,
    if (startRerolls != 0) 'sr': startRerolls,
    if (startPhoenix != 0) 'sp': startPhoenix,
    if (startGhost != 0) 'sg': startGhost,
    if (startLucky != 0) 'sl': startLucky,
    if (capDice != 6) 'cap': capDice,
  };
}

/// Static configuration of a single game.
class GameConfig {
  const GameConfig({
    this.mode = GameMode.seven,
    this.seed = 1,
    this.p7 = 1 / 36,
    this.cubeEnabled = false,
    this.crawford = false,
    this.offerSize = 3,
    this.cardPool,
    this.white = SideMods.none,
    this.black = SideMods.none,
    this.startingBoard,
  });

  factory GameConfig.fromJson(Map<String, Object?> j) => GameConfig(
    mode: GameMode.values.byName(j['mode']! as String),
    seed: j['seed']! as int,
    p7: (j['p7'] as num?)?.toDouble() ?? 1 / 36,
    cubeEnabled: j['cube'] as bool? ?? false,
    crawford: j['crawford'] as bool? ?? false,
    offerSize: j['offer'] as int? ?? 3,
    cardPool: (j['pool'] as List<Object?>?)?.cast<String>(),
    white: SideMods.fromJson(
      (j['wm'] as Map<Object?, Object?>? ?? const {}).cast<String, Object?>(),
    ),
    black: SideMods.fromJson(
      (j['bm'] as Map<Object?, Object?>? ?? const {}).cast<String, Object?>(),
    ),
    startingBoard: j['board'] == null
        ? null
        : Board.fromJson((j['board']! as Map).cast<String, Object?>()),
  );

  final GameMode mode;
  final int seed;

  /// Base chance of the Seven Event per roll.
  final double p7;
  final bool cubeEnabled;

  /// This game is the Crawford game (no doubling).
  final bool crawford;
  final int offerSize;

  /// Allowed card ids in offers (null = all cards).
  final List<String>? cardPool;
  final SideMods white;
  final SideMods black;

  /// Optional custom starting position (tutorials, tests).
  final Board? startingBoard;

  bool get sevenEnabled => mode != GameMode.classic;

  SideMods mods(Side s) => s == Side.white ? white : black;

  GameConfig copyWith({
    GameMode? mode,
    int? seed,
    double? p7,
    bool? cubeEnabled,
    bool? crawford,
    int? offerSize,
    List<String>? cardPool,
    SideMods? white,
    SideMods? black,
    Board? startingBoard,
  }) => GameConfig(
    mode: mode ?? this.mode,
    seed: seed ?? this.seed,
    p7: p7 ?? this.p7,
    cubeEnabled: cubeEnabled ?? this.cubeEnabled,
    crawford: crawford ?? this.crawford,
    offerSize: offerSize ?? this.offerSize,
    cardPool: cardPool ?? this.cardPool,
    white: white ?? this.white,
    black: black ?? this.black,
    startingBoard: startingBoard ?? this.startingBoard,
  );

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'seed': seed,
    'p7': p7,
    'cube': cubeEnabled,
    'crawford': crawford,
    'offer': offerSize,
    if (cardPool != null) 'pool': cardPool,
    'wm': white.toJson(),
    'bm': black.toJson(),
    if (startingBoard != null) 'board': startingBoard!.toJson(),
  };
}

/// Kinds of ongoing effects. Each has a handler in the effect system.
enum EffectKind {
  brokenDie,
  fog,
  curse,
  chains,
  shield,
  ironGate,
  quicksand,
  quicksandFreeze,
  toll,
  landmine,
  sevenMagnet,
  loadedHand,
  fateEdit,
  mirrorWatch,
  mirrorBonus,
  skipTurn,
  bonusPick,
  bonusOffer,
}

/// An effect living on the board or on a side.
///
/// Durations count the [affected] side's turns: the counter decrements at the
/// end of each of the affected side's turns once the effect is active.
/// Non-[immediate] effects activate on the first turn after the one they were
/// created in.
class ActiveEffect {
  const ActiveEffect({
    required this.id,
    required this.kind,
    required this.owner,
    required this.affected,
    required this.turnsLeft,
    required this.createdTurn,
    this.immediate = true,
    this.point = 0,
    this.count = 0,
    this.values = const [],
  });

  factory ActiveEffect.fromJson(Map<String, Object?> j) => ActiveEffect(
    id: j['id']! as int,
    kind: EffectKind.values.byName(j['k']! as String),
    owner: Side.values.byName(j['o']! as String),
    affected: Side.values.byName(j['a']! as String),
    turnsLeft: j['n']! as int,
    createdTurn: j['c']! as int,
    immediate: j['i'] as bool? ?? true,
    point: j['p'] as int? ?? 0,
    count: j['q'] as int? ?? 0,
    values: (j['v'] as List<Object?>? ?? const []).cast<int>(),
  );

  /// Unique id within the game (stable for UI animations).
  final int id;
  final EffectKind kind;
  final Side owner;
  final Side affected;
  final int turnsLeft;
  final int createdTurn;
  final bool immediate;

  /// Absolute point (1..24) for board effects, 0 if none.
  final int point;

  /// Checker count (chains, freeze).
  final int count;

  /// Extra values (mirror dice).
  final List<int> values;

  bool isActive(int turnNumber) => immediate || turnNumber > createdTurn;

  ActiveEffect copyWith({int? turnsLeft, int? point, int? count}) =>
      ActiveEffect(
        id: id,
        kind: kind,
        owner: owner,
        affected: affected,
        turnsLeft: turnsLeft ?? this.turnsLeft,
        createdTurn: createdTurn,
        immediate: immediate,
        point: point ?? this.point,
        count: count ?? this.count,
        values: values,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'k': kind.name,
    'o': owner.name,
    'a': affected.name,
    'n': turnsLeft,
    'c': createdTurn,
    if (!immediate) 'i': false,
    if (point != 0) 'p': point,
    if (count != 0) 'q': count,
    if (values.isNotEmpty) 'v': values,
  };
}

/// Stored charges and per-side counters.
class SideInv {
  const SideInv({
    this.rerolls = 0,
    this.lucky = 0,
    this.ghost = 0,
    this.phoenix = 0,
    this.greed = 0,
    this.pity = 0,
    this.sevens = 0,
    this.hits = 0,
    this.doubles = 0,
    this.borneFirst = false,
    this.cards = const [],
  });

  factory SideInv.fromJson(Map<String, Object?> j) => SideInv(
    rerolls: j['r'] as int? ?? 0,
    lucky: j['l'] as int? ?? 0,
    ghost: j['g'] as int? ?? 0,
    phoenix: j['p'] as int? ?? 0,
    greed: j['gr'] as int? ?? 0,
    pity: j['pi'] as int? ?? 0,
    sevens: j['s'] as int? ?? 0,
    hits: j['h'] as int? ?? 0,
    doubles: j['d'] as int? ?? 0,
    borneFirst: j['bf'] as bool? ?? false,
    cards: (j['c'] as List<Object?>? ?? const []).cast<String>(),
  );

  /// Second Chance reroll tokens.
  final int rerolls;

  /// Lucky Charm (+1 to a die) charges.
  final int lucky;

  /// Ghost Step charges.
  final int ghost;

  /// Phoenix charges.
  final int phoenix;

  /// Greed stacks (bonus coins on a win).
  final int greed;

  /// Offers since the last Epic or Legendary (bad-luck protection).
  final int pity;
  final int sevens;
  final int hits;
  final int doubles;
  final bool borneFirst;

  /// Card ids taken this game, in order.
  final List<String> cards;

  /// Number of stealable stored items.
  int get stealable => rerolls + lucky + ghost + phoenix;

  SideInv copyWith({
    int? rerolls,
    int? lucky,
    int? ghost,
    int? phoenix,
    int? greed,
    int? pity,
    int? sevens,
    int? hits,
    int? doubles,
    bool? borneFirst,
    List<String>? cards,
  }) => SideInv(
    rerolls: rerolls ?? this.rerolls,
    lucky: lucky ?? this.lucky,
    ghost: ghost ?? this.ghost,
    phoenix: phoenix ?? this.phoenix,
    greed: greed ?? this.greed,
    pity: pity ?? this.pity,
    sevens: sevens ?? this.sevens,
    hits: hits ?? this.hits,
    doubles: doubles ?? this.doubles,
    borneFirst: borneFirst ?? this.borneFirst,
    cards: cards ?? this.cards,
  );

  Map<String, Object?> toJson() => {
    if (rerolls != 0) 'r': rerolls,
    if (lucky != 0) 'l': lucky,
    if (ghost != 0) 'g': ghost,
    if (phoenix != 0) 'p': phoenix,
    if (greed != 0) 'gr': greed,
    if (pity != 0) 'pi': pity,
    if (sevens != 0) 's': sevens,
    if (hits != 0) 'h': hits,
    if (doubles != 0) 'd': doubles,
    if (borneFirst) 'bf': true,
    if (cards.isNotEmpty) 'c': cards,
  };
}

/// Final result of a game.
class GameResult {
  const GameResult(this.winner, this.type, this.points);

  factory GameResult.fromJson(Map<String, Object?> j) => GameResult(
    Side.values.byName(j['w']! as String),
    WinType.values.byName(j['t']! as String),
    j['p']! as int,
  );

  final Side winner;
  final WinType type;
  final int points;

  Map<String, Object?> toJson() => {
    'w': winner.name,
    't': type.name,
    'p': points,
  };
}

/// Complete immutable game state. Applying actions to it (see `Engine`) is a
/// pure, deterministic function.
class GameState {
  const GameState({
    required this.config,
    required this.board,
    required this.rng,
    this.phase = Phase.opening,
    this.current = Side.white,
    this.turnNumber = 0,
    this.dice = const [],
    this.rolled = const [],
    this.choiceDice = const [],
    this.movesThisRoll = const [],
    this.rollsThisTurn = 0,
    this.rollQueue = const [],
    this.extraTurn = false,
    this.sevenUsed = false,
    this.effects = const [],
    this.nextEffectId = 1,
    this.white = const SideInv(),
    this.black = const SideInv(),
    this.offer = const [],
    this.picksLeft = 0,
    this.pendingCard,
    this.cubeValue = 1,
    this.cubeOwner,
    this.result,
    this.openingDice = const [],
  });

  factory GameState.fromJson(Map<String, Object?> j) {
    Map<String, Object?> m(Object? o) =>
        (o! as Map<Object?, Object?>).cast<String, Object?>();
    List<int> li(Object? o) => (o as List<Object?>? ?? const []).cast<int>();
    return GameState(
      config: GameConfig.fromJson(m(j['config'])),
      board: Board.fromJson(m(j['board'])),
      rng: li(j['rng']),
      phase: Phase.values.byName(j['phase']! as String),
      current: Side.values.byName(j['cur']! as String),
      turnNumber: j['turn']! as int,
      dice: li(j['dice']),
      rolled: li(j['rolled']),
      choiceDice: li(j['choice']),
      movesThisRoll: [
        for (final e in j['moves'] as List<Object?>? ?? const [])
          Move.fromJson(m(e)),
      ],
      rollsThisTurn: j['rolls'] as int? ?? 0,
      rollQueue: [
        for (final e in j['queue'] as List<Object?>? ?? const []) li(e),
      ],
      extraTurn: j['extra'] as bool? ?? false,
      sevenUsed: j['sevenUsed'] as bool? ?? false,
      effects: [
        for (final e in j['effects'] as List<Object?>? ?? const [])
          ActiveEffect.fromJson(m(e)),
      ],
      nextEffectId: j['nextId'] as int? ?? 1,
      white: SideInv.fromJson(m(j['wi'])),
      black: SideInv.fromJson(m(j['bi'])),
      offer: (j['offer'] as List<Object?>? ?? const []).cast<String>(),
      picksLeft: j['picks'] as int? ?? 0,
      pendingCard: j['pending'] as String?,
      cubeValue: j['cube'] as int? ?? 1,
      cubeOwner: j['cubeOwner'] == null
          ? null
          : Side.values.byName(j['cubeOwner']! as String),
      result: j['result'] == null ? null : GameResult.fromJson(m(j['result'])),
      openingDice: li(j['opening']),
    );
  }

  /// A fresh game in the opening phase.
  factory GameState.initial(GameConfig config) {
    var w = const SideInv();
    var b = const SideInv();
    SideInv seed(SideInv inv, SideMods mods) => inv.copyWith(
      rerolls: mods.startRerolls,
      phoenix: mods.startPhoenix,
      ghost: mods.startGhost,
      lucky: mods.startLucky,
    );
    w = seed(w, config.white);
    b = seed(b, config.black);
    return GameState(
      config: config,
      board: config.startingBoard ?? Board.initial(),
      rng: Rng.seeded(config.seed).state,
      white: w,
      black: b,
    );
  }

  final GameConfig config;
  final Board board;

  /// xoshiro128** state words.
  final List<int> rng;
  final Phase phase;
  final Side current;
  final int turnNumber;

  /// Dice still to be played this roll.
  final List<int> dice;

  /// The dice as rolled (after modifiers), for display.
  final List<int> rolled;

  /// Loaded Hand: three dice to choose from.
  final List<int> choiceDice;

  /// Moves already played with the current roll.
  final List<Move> movesThisRoll;

  /// Number of rolls made this turn (cube only before the first).
  final int rollsThisTurn;

  /// Bonus rolls still to play this turn. An empty entry means "roll fresh",
  /// otherwise the entry holds fixed dice values.
  final List<List<int>> rollQueue;

  /// Time Stop: current side takes another turn after this one.
  final bool extraTurn;

  /// The Seven Event has already happened this turn.
  final bool sevenUsed;
  final List<ActiveEffect> effects;
  final int nextEffectId;
  final SideInv white;
  final SideInv black;

  /// Current 7–7 offer (card ids).
  final List<String> offer;
  final int picksLeft;

  /// Card awaiting targets.
  final String? pendingCard;
  final int cubeValue;
  final Side? cubeOwner;
  final GameResult? result;

  /// The opening roll `[white, black]` for display.
  final List<int> openingDice;

  SideInv inv(Side s) => s == Side.white ? white : black;

  bool get isOver => phase == Phase.gameOver;

  Iterable<ActiveEffect> effectsOf(EffectKind kind) =>
      effects.where((e) => e.kind == kind);

  GameState copyWith({
    Board? board,
    List<int>? rng,
    Phase? phase,
    Side? current,
    int? turnNumber,
    List<int>? dice,
    List<int>? rolled,
    List<int>? choiceDice,
    List<Move>? movesThisRoll,
    int? rollsThisTurn,
    List<List<int>>? rollQueue,
    bool? extraTurn,
    bool? sevenUsed,
    List<ActiveEffect>? effects,
    int? nextEffectId,
    SideInv? white,
    SideInv? black,
    List<String>? offer,
    int? picksLeft,
    String? pendingCard,
    bool clearPending = false,
    int? cubeValue,
    Side? cubeOwner,
    GameResult? result,
    List<int>? openingDice,
  }) => GameState(
    config: config,
    board: board ?? this.board,
    rng: rng ?? this.rng,
    phase: phase ?? this.phase,
    current: current ?? this.current,
    turnNumber: turnNumber ?? this.turnNumber,
    dice: dice ?? this.dice,
    rolled: rolled ?? this.rolled,
    choiceDice: choiceDice ?? this.choiceDice,
    movesThisRoll: movesThisRoll ?? this.movesThisRoll,
    rollsThisTurn: rollsThisTurn ?? this.rollsThisTurn,
    rollQueue: rollQueue ?? this.rollQueue,
    extraTurn: extraTurn ?? this.extraTurn,
    sevenUsed: sevenUsed ?? this.sevenUsed,
    effects: effects ?? this.effects,
    nextEffectId: nextEffectId ?? this.nextEffectId,
    white: white ?? this.white,
    black: black ?? this.black,
    offer: offer ?? this.offer,
    picksLeft: picksLeft ?? this.picksLeft,
    pendingCard: clearPending ? null : (pendingCard ?? this.pendingCard),
    cubeValue: cubeValue ?? this.cubeValue,
    cubeOwner: cubeOwner ?? this.cubeOwner,
    result: result ?? this.result,
    openingDice: openingDice ?? this.openingDice,
  );

  GameState withInv(Side s, SideInv inv) =>
      s == Side.white ? copyWith(white: inv) : copyWith(black: inv);

  Map<String, Object?> toJson() => {
    'v': 1,
    'config': config.toJson(),
    'board': board.toJson(),
    'rng': rng,
    'phase': phase.name,
    'cur': current.name,
    'turn': turnNumber,
    'dice': dice,
    'rolled': rolled,
    'choice': choiceDice,
    'moves': [for (final m in movesThisRoll) m.toJson()],
    'rolls': rollsThisTurn,
    'queue': rollQueue,
    'extra': extraTurn,
    'sevenUsed': sevenUsed,
    'effects': [for (final e in effects) e.toJson()],
    'nextId': nextEffectId,
    'wi': white.toJson(),
    'bi': black.toJson(),
    'offer': offer,
    'picks': picksLeft,
    if (pendingCard != null) 'pending': pendingCard,
    'cube': cubeValue,
    if (cubeOwner != null) 'cubeOwner': cubeOwner!.name,
    if (result != null) 'result': result!.toJson(),
    'opening': openingDice,
  };
}
