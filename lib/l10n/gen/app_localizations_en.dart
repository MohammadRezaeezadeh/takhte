// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HaftNard';

  @override
  String get tagline => 'Backgammon, with a Double Seven';

  @override
  String get play => 'Play';

  @override
  String get journey => 'Journey';

  @override
  String get store => 'Store';

  @override
  String get locker => 'Locker';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get online => 'Online';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get onlineTeaser =>
      'Duel players across the world. The caravan is on its way.';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get resume => 'Resume';

  @override
  String get resumeMatch => 'Resume match';

  @override
  String get back => 'Back';

  @override
  String get start => 'Start';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get modeClassic => 'Classic';

  @override
  String get modeClassicDesc => 'Pure backgammon. No cards, no sevens.';

  @override
  String get modeSeven => 'Seven';

  @override
  String get modeSevenDesc => 'Roll the glowing 7–7 and choose a power card.';

  @override
  String get modePassPlay => 'Pass & Play';

  @override
  String get modePassPlayDesc => 'Two players, one device.';

  @override
  String get chooseMode => 'Mode';

  @override
  String get chooseOpponent => 'Opponent';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get diffBeginner => 'Beginner';

  @override
  String get diffEasy => 'Easy';

  @override
  String get diffMedium => 'Medium';

  @override
  String get diffHard => 'Hard';

  @override
  String get diffMaster => 'Master';

  @override
  String get matchLength => 'Match length';

  @override
  String pointsN(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString points',
      one: '1 point',
    );
    return '$_temp0';
  }

  @override
  String get doublingCube => 'Doubling cube';

  @override
  String get doublingCubeDesc => 'Off by default, as in Persian tavla.';

  @override
  String get human => 'Human';

  @override
  String get player1 => 'Player 1';

  @override
  String get player2 => 'Player 2';

  @override
  String get you => 'You';

  @override
  String get yourTurn => 'Your turn';

  @override
  String theirTurn(String name) {
    return '$name\'s turn';
  }

  @override
  String get tapToRoll => 'Tap the dice to roll';

  @override
  String get rollOpening => 'Roll to see who starts';

  @override
  String get openingTie => 'Tie! Roll again.';

  @override
  String startsFirst(String name) {
    return '$name starts';
  }

  @override
  String get noMoves => 'No legal moves — turn passes';

  @override
  String get undo => 'Undo';

  @override
  String get done => 'Done';

  @override
  String get endTurn => 'End turn';

  @override
  String get double => 'Double';

  @override
  String get take => 'Take';

  @override
  String get drop => 'Drop';

  @override
  String doubleOffered(String name, int value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '$name offers to double to $valueString';
  }

  @override
  String get pips => 'Pips';

  @override
  String pipsN(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString pips';
  }

  @override
  String get score => 'Score';

  @override
  String matchTo(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Match to $nString';
  }

  @override
  String get crawford => 'Crawford';

  @override
  String get sevenTitle => 'DOUBLE SEVEN';

  @override
  String get choosePower => 'Choose your power';

  @override
  String chooseTwo(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Choose $nString powers';
  }

  @override
  String opponentChose(String card, String name) {
    return '$name chose $card';
  }

  @override
  String get selectTargets => 'Select targets';

  @override
  String get targetEnemy2 => 'Tap two enemy checkers to chain';

  @override
  String get targetOwn => 'Tap one of your checkers';

  @override
  String get targetOwnBlot => 'Tap one of your lone checkers';

  @override
  String get targetEmpty => 'Tap an empty point';

  @override
  String get targetPoint => 'Tap a point';

  @override
  String get targetTeleportFrom => 'Tap the checker to teleport';

  @override
  String get targetTeleportTo => 'Tap where it lands';

  @override
  String get chooseDiceTitle => 'Loaded Hand: keep two dice';

  @override
  String get fateTitle => 'Fate\'s Edit: tap a die to change it';

  @override
  String get useReroll => 'Reroll';

  @override
  String get useLucky => '+1';

  @override
  String get useFate => 'Fate';

  @override
  String get activeEffects => 'Active effects';

  @override
  String turnsLeft(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString turns',
      one: '1 turn',
    );
    return '$_temp0';
  }

  @override
  String get stored => 'Stored';

  @override
  String get victory => 'Victory!';

  @override
  String get defeat => 'Defeat';

  @override
  String winsGame(String name) {
    return '$name wins';
  }

  @override
  String get winNormal => 'Single game';

  @override
  String get winGammon => 'Mars!';

  @override
  String get winBackgammon => 'Kup Mars!';

  @override
  String get winDropped => 'Double declined';

  @override
  String get winResigned => 'Resignation';

  @override
  String pointsWon(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '+$nString points';
  }

  @override
  String get matchWon => 'Match won!';

  @override
  String get matchLost => 'Match lost';

  @override
  String get nextGame => 'Next game';

  @override
  String get rematch => 'Rematch';

  @override
  String get mainMenu => 'Main menu';

  @override
  String get paused => 'Paused';

  @override
  String get resign => 'Resign';

  @override
  String get resignConfirm => 'Resign this game?';

  @override
  String coinsEarned(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '+$nString coins';
  }

  @override
  String xpEarned(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '+$nString XP';
  }

  @override
  String levelUp(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Level up! Level $nString';
  }

  @override
  String get coins => 'Coins';

  @override
  String get gems => 'Gems';

  @override
  String level(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Level $nString';
  }

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Device default';

  @override
  String get boardOrientation => 'Board direction';

  @override
  String get orientationCcw => 'Home on the right';

  @override
  String get orientationCw => 'Home on the left';

  @override
  String get animationSpeed => 'Animation speed';

  @override
  String get speedSlow => 'Relaxed';

  @override
  String get speedNormal => 'Normal';

  @override
  String get speedFast => 'Fast';

  @override
  String get sound => 'Sound effects';

  @override
  String get music => 'Music';

  @override
  String get haptics => 'Haptics';

  @override
  String get colorblind => 'Colorblind-safe highlights';

  @override
  String get highContrast => 'High contrast';

  @override
  String get reducedMotion => 'Reduced motion';

  @override
  String get leftHanded => 'Left-handed layout';

  @override
  String get autoMove => 'Auto-play forced moves';

  @override
  String get confirmMoves => 'Confirm before ending turn';

  @override
  String get showPips => 'Show pip counts';

  @override
  String get resetProgress => 'Reset progress';

  @override
  String get resetConfirm => 'Erase all progress? This cannot be undone.';

  @override
  String get about => 'About';

  @override
  String get aboutText =>
      'HaftNard is an original game. All art and sound are generated by code. Fonts: Vazirmatn, Lalezar, Cinzel Decorative (SIL Open Font License).';

  @override
  String get replayLast => 'Replay last game';

  @override
  String get replay => 'Replay';

  @override
  String get storeBoards => 'Boards';

  @override
  String get storeEnvironments => 'Environments';

  @override
  String get storeCheckers => 'Checkers';

  @override
  String get storeDice => 'Dice';

  @override
  String get storeCardBacks => 'Card backs';

  @override
  String get storeVictory => 'Victory effects';

  @override
  String get storeEmotes => 'Emotes';

  @override
  String get storeBundles => 'Bundles';

  @override
  String get dailyShop => 'Daily shop';

  @override
  String refreshesIn(String time) {
    return 'Refreshes in $time';
  }

  @override
  String get buy => 'Buy';

  @override
  String get owned => 'Owned';

  @override
  String get equip => 'Equip';

  @override
  String get equipped => 'Equipped';

  @override
  String get notEnough => 'Not enough currency';

  @override
  String get purchased => 'Purchased!';

  @override
  String get randomizeLoadout => 'Randomize loadout';

  @override
  String get preview => 'Preview';

  @override
  String get statistics => 'Statistics';

  @override
  String get achievements => 'Achievements';

  @override
  String get statGames => 'Games played';

  @override
  String get statWins => 'Wins';

  @override
  String get statWinRate => 'Win rate';

  @override
  String get statMars => 'Mars wins';

  @override
  String get statKupMars => 'Kup Mars wins';

  @override
  String get statSevens => 'Double sevens rolled';

  @override
  String get statHits => 'Checkers hit';

  @override
  String get statFavoriteCard => 'Favorite card';

  @override
  String get statBestRun => 'Best journey';

  @override
  String get statJourneysWon => 'Journeys completed';

  @override
  String get statStreak => 'Best win streak';

  @override
  String get none => '—';

  @override
  String get unlocked => 'Unlocked';

  @override
  String get locked => 'Locked';

  @override
  String get newRun => 'New journey';

  @override
  String get continueRun => 'Continue journey';

  @override
  String get dailyRun => 'Daily journey';

  @override
  String get seed => 'Seed';

  @override
  String act(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Act $nString';
  }

  @override
  String get actBazaar => 'The Bazaar';

  @override
  String get actCaravanserai => 'The Caravanserai';

  @override
  String get actPalace => 'The Palace';

  @override
  String get boss => 'Boss';

  @override
  String bossRule(String rule) {
    return 'Rule: $rule';
  }

  @override
  String get runShop => 'Bazaar stall';

  @override
  String get talismans => 'Talismans';

  @override
  String get removeCard => 'Banish a card';

  @override
  String get removeCardDesc =>
      'Remove a card from your 7–7 offers for this journey.';

  @override
  String get upgradeOffer => 'Wider offers';

  @override
  String get upgradeOfferDesc => 'Your 7–7 offers show one more card.';

  @override
  String get luckUp => 'Seven\'s favour';

  @override
  String get luckUpDesc => '+25% chance of rolling 7–7.';

  @override
  String get leaveShop => 'Continue';

  @override
  String get runCoins => 'Run coins';

  @override
  String get runOver => 'Journey over';

  @override
  String get runWon => 'Journey complete!';

  @override
  String runKept(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'You keep $nString coins';
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

    return 'Opponent $nString of $totalString';
  }

  @override
  String get fight => 'Fight';

  @override
  String get tutorialBasics => 'Backgammon basics';

  @override
  String get tutorialSevens => 'The Double Seven';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get finish => 'Finish';

  @override
  String get tip => 'Tip';

  @override
  String get loading => 'Loading…';

  @override
  String get emoteTitle => 'Emotes';

  @override
  String get aiThinking => 'Thinking…';

  @override
  String get pickTalisman => 'Choose a talisman';

  @override
  String get free => 'Free';

  @override
  String get dailyBonus => 'Daily bonus';

  @override
  String get claim => 'Claim';

  @override
  String replayControls(int n, int total) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Step $nString of $totalString';
  }

  @override
  String gameN(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Game $nString';
  }

  @override
  String get sevenMode => 'Seven mode';

  @override
  String get classicMode => 'Classic mode';

  @override
  String turnSkipped(String name) {
    return '$name loses a turn!';
  }

  @override
  String get coinHeads => 'Heads! Opponent skips a turn.';

  @override
  String get coinTails => 'Tails! You skip a turn.';

  @override
  String get mineBoom => 'A hidden mine!';

  @override
  String get phoenixRises => 'The phoenix rises!';

  @override
  String stolen(String item) {
    return 'Stolen: $item';
  }

  @override
  String get itemReroll => 'Reroll';

  @override
  String get itemLucky => 'Lucky Charm';

  @override
  String get itemGhost => 'Ghost Step';

  @override
  String get itemPhoenix => 'Phoenix';

  @override
  String get gripped => 'Stuck in quicksand!';

  @override
  String get extraTurn => 'Time stops — extra turn!';

  @override
  String get bonusRoll => 'Bonus roll!';

  @override
  String fizzled(String card) {
    return '$card had no target';
  }

  @override
  String get rarityCommon => 'Common';

  @override
  String get rarityRare => 'Rare';

  @override
  String get rarityEpic => 'Epic';

  @override
  String get rarityLegendary => 'Legendary';

  @override
  String get drawback => 'Drawback';

  @override
  String get howToPlay => 'How to play';

  @override
  String get targetOwnBlot2 => 'Tap two of your lone checkers';

  @override
  String get targetEmpty2 => 'Tap two empty points';

  @override
  String get targetPoint2 => 'Tap two points';

  @override
  String get bar => 'Bar';

  @override
  String get targetEnemy1 => 'Tap an enemy checker';

  @override
  String get targetEnemyBlot => 'Tap an enemy lone checker';

  @override
  String get targetOwn2 => 'Tap two of your points';

  @override
  String get welcomeTitle => 'Welcome to HaftNard';

  @override
  String get welcomeBody =>
      'Classic Persian backgammon — with a twist: roll the glowing Double Seven and claim a power card. New to the board? A two-minute interactive lesson will get you playing.';

  @override
  String get welcomeSkip => 'I know how to play';

  @override
  String get codex => 'Card codex';

  @override
  String codexProgress(int n, int total) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$nString of $totalString cards unlocked';
  }

  @override
  String get attuneCard => 'Attune a card';

  @override
  String get attuneCardDesc =>
      'Choose a card: it appears three times as often in your 7–7 offers this journey.';

  @override
  String cubeExplain(int value, int current) {
    return 'Your opponent wants this game to count double ($value points). Accept to keep playing for $value, or decline and lose $current now.';
  }

  @override
  String get help => 'How to read the board';

  @override
  String get helpDice =>
      'Dice: tap to roll. Used dice dim in place. 7–7 opens a card offer.';

  @override
  String get helpPips =>
      'Player panel: name, pips left to bear off (lower is better) and checkers already off.';

  @override
  String get helpBar =>
      'Bar (middle): hit checkers wait here and must re-enter before anything else moves.';

  @override
  String get helpOff =>
      'Tray (side): borne-off checkers. All 15 there wins the game.';

  @override
  String get helpCube =>
      'Doubling cube: the current stakes. Only in matches with the cube switched on.';

  @override
  String get helpSeven =>
      '7–7: roll it to pick a power card. It gets likelier every turn without one, and it is certain after 12 dry turns.';

  @override
  String get helpEffects =>
      'Glowing chips: powers in play, with the turns left. Tap a chip for details.';

  @override
  String get helpCharges =>
      'Charges: reroll tokens, Lucky Charms, Ghost Steps and Phoenixes you can still use.';

  @override
  String get helpButtons =>
      'Buttons: undo a move, use a reroll token, auto-play the best move, or finish your turn.';

  @override
  String get helpEmotes => 'Emotes (bottom corner): send a quick reaction.';

  @override
  String get reportProblem => 'Report a problem';

  @override
  String get reportProblemHint =>
      'Copy this text and send it to the developer. It holds the last few minutes of errors and slowdowns, plus device facts, and no personal data.';

  @override
  String get copyReport => 'Copy';

  @override
  String get copiedReport => 'Copied';
}
