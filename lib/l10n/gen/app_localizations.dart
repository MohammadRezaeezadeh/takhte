import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HaftNard'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Backgammon, with a Double Seven'**
  String get tagline;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @journey.
  ///
  /// In en, this message translates to:
  /// **'Journey'**
  String get journey;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @locker.
  ///
  /// In en, this message translates to:
  /// **'Locker'**
  String get locker;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @onlineTeaser.
  ///
  /// In en, this message translates to:
  /// **'Duel players across the world. The caravan is on its way.'**
  String get onlineTeaser;

  /// No description provided for @tutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get tutorial;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @resumeMatch.
  ///
  /// In en, this message translates to:
  /// **'Resume match'**
  String get resumeMatch;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @modeClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get modeClassic;

  /// No description provided for @modeClassicDesc.
  ///
  /// In en, this message translates to:
  /// **'Pure backgammon. No cards, no sevens.'**
  String get modeClassicDesc;

  /// No description provided for @modeSeven.
  ///
  /// In en, this message translates to:
  /// **'Seven'**
  String get modeSeven;

  /// No description provided for @modeSevenDesc.
  ///
  /// In en, this message translates to:
  /// **'Roll the glowing 7–7 and choose a power card.'**
  String get modeSevenDesc;

  /// No description provided for @modePassPlay.
  ///
  /// In en, this message translates to:
  /// **'Pass & Play'**
  String get modePassPlay;

  /// No description provided for @modePassPlayDesc.
  ///
  /// In en, this message translates to:
  /// **'Two players, one device.'**
  String get modePassPlayDesc;

  /// No description provided for @chooseMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get chooseMode;

  /// No description provided for @chooseOpponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get chooseOpponent;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @diffBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get diffBeginner;

  /// No description provided for @diffEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get diffEasy;

  /// No description provided for @diffMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get diffMedium;

  /// No description provided for @diffHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get diffHard;

  /// No description provided for @diffMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get diffMaster;

  /// No description provided for @matchLength.
  ///
  /// In en, this message translates to:
  /// **'Match length'**
  String get matchLength;

  /// No description provided for @pointsN.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 point} other{{n} points}}'**
  String pointsN(int n);

  /// No description provided for @doublingCube.
  ///
  /// In en, this message translates to:
  /// **'Doubling cube'**
  String get doublingCube;

  /// No description provided for @doublingCubeDesc.
  ///
  /// In en, this message translates to:
  /// **'Off by default, as in Persian tavla.'**
  String get doublingCubeDesc;

  /// No description provided for @human.
  ///
  /// In en, this message translates to:
  /// **'Human'**
  String get human;

  /// No description provided for @player1.
  ///
  /// In en, this message translates to:
  /// **'Player 1'**
  String get player1;

  /// No description provided for @player2.
  ///
  /// In en, this message translates to:
  /// **'Player 2'**
  String get player2;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @yourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get yourTurn;

  /// No description provided for @theirTurn.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s turn'**
  String theirTurn(String name);

  /// No description provided for @tapToRoll.
  ///
  /// In en, this message translates to:
  /// **'Tap the dice to roll'**
  String get tapToRoll;

  /// No description provided for @rollOpening.
  ///
  /// In en, this message translates to:
  /// **'Roll to see who starts'**
  String get rollOpening;

  /// No description provided for @openingTie.
  ///
  /// In en, this message translates to:
  /// **'Tie! Roll again.'**
  String get openingTie;

  /// No description provided for @startsFirst.
  ///
  /// In en, this message translates to:
  /// **'{name} starts'**
  String startsFirst(String name);

  /// No description provided for @noMoves.
  ///
  /// In en, this message translates to:
  /// **'No legal moves — turn passes'**
  String get noMoves;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @endTurn.
  ///
  /// In en, this message translates to:
  /// **'End turn'**
  String get endTurn;

  /// No description provided for @double.
  ///
  /// In en, this message translates to:
  /// **'Double'**
  String get double;

  /// No description provided for @take.
  ///
  /// In en, this message translates to:
  /// **'Take'**
  String get take;

  /// No description provided for @drop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get drop;

  /// No description provided for @doubleOffered.
  ///
  /// In en, this message translates to:
  /// **'{name} offers to double to {value}'**
  String doubleOffered(String name, int value);

  /// No description provided for @pips.
  ///
  /// In en, this message translates to:
  /// **'Pips'**
  String get pips;

  /// No description provided for @pipsN.
  ///
  /// In en, this message translates to:
  /// **'{n} pips'**
  String pipsN(int n);

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @matchTo.
  ///
  /// In en, this message translates to:
  /// **'Match to {n}'**
  String matchTo(int n);

  /// No description provided for @crawford.
  ///
  /// In en, this message translates to:
  /// **'Crawford'**
  String get crawford;

  /// No description provided for @sevenTitle.
  ///
  /// In en, this message translates to:
  /// **'DOUBLE SEVEN'**
  String get sevenTitle;

  /// No description provided for @choosePower.
  ///
  /// In en, this message translates to:
  /// **'Choose your power'**
  String get choosePower;

  /// No description provided for @chooseTwo.
  ///
  /// In en, this message translates to:
  /// **'Choose {n} powers'**
  String chooseTwo(int n);

  /// No description provided for @opponentChose.
  ///
  /// In en, this message translates to:
  /// **'{name} chose {card}'**
  String opponentChose(String card, String name);

  /// No description provided for @selectTargets.
  ///
  /// In en, this message translates to:
  /// **'Select targets'**
  String get selectTargets;

  /// No description provided for @targetEnemy2.
  ///
  /// In en, this message translates to:
  /// **'Tap two enemy checkers to chain'**
  String get targetEnemy2;

  /// No description provided for @targetOwn.
  ///
  /// In en, this message translates to:
  /// **'Tap one of your checkers'**
  String get targetOwn;

  /// No description provided for @targetOwnBlot.
  ///
  /// In en, this message translates to:
  /// **'Tap one of your lone checkers'**
  String get targetOwnBlot;

  /// No description provided for @targetEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tap an empty point'**
  String get targetEmpty;

  /// No description provided for @targetPoint.
  ///
  /// In en, this message translates to:
  /// **'Tap a point'**
  String get targetPoint;

  /// No description provided for @targetTeleportFrom.
  ///
  /// In en, this message translates to:
  /// **'Tap the checker to teleport'**
  String get targetTeleportFrom;

  /// No description provided for @targetTeleportTo.
  ///
  /// In en, this message translates to:
  /// **'Tap where it lands'**
  String get targetTeleportTo;

  /// No description provided for @chooseDiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Loaded Hand: keep two dice'**
  String get chooseDiceTitle;

  /// No description provided for @fateTitle.
  ///
  /// In en, this message translates to:
  /// **'Fate\'s Edit: tap a die to change it'**
  String get fateTitle;

  /// No description provided for @useReroll.
  ///
  /// In en, this message translates to:
  /// **'Reroll'**
  String get useReroll;

  /// No description provided for @useLucky.
  ///
  /// In en, this message translates to:
  /// **'+1'**
  String get useLucky;

  /// No description provided for @useFate.
  ///
  /// In en, this message translates to:
  /// **'Fate'**
  String get useFate;

  /// No description provided for @activeEffects.
  ///
  /// In en, this message translates to:
  /// **'Active effects'**
  String get activeEffects;

  /// No description provided for @turnsLeft.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 turn} other{{n} turns}}'**
  String turnsLeft(int n);

  /// No description provided for @stored.
  ///
  /// In en, this message translates to:
  /// **'Stored'**
  String get stored;

  /// No description provided for @victory.
  ///
  /// In en, this message translates to:
  /// **'Victory!'**
  String get victory;

  /// No description provided for @defeat.
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get defeat;

  /// No description provided for @winsGame.
  ///
  /// In en, this message translates to:
  /// **'{name} wins'**
  String winsGame(String name);

  /// No description provided for @winNormal.
  ///
  /// In en, this message translates to:
  /// **'Single game'**
  String get winNormal;

  /// No description provided for @winGammon.
  ///
  /// In en, this message translates to:
  /// **'Mars!'**
  String get winGammon;

  /// No description provided for @winBackgammon.
  ///
  /// In en, this message translates to:
  /// **'Kup Mars!'**
  String get winBackgammon;

  /// No description provided for @winDropped.
  ///
  /// In en, this message translates to:
  /// **'Double declined'**
  String get winDropped;

  /// No description provided for @winResigned.
  ///
  /// In en, this message translates to:
  /// **'Resignation'**
  String get winResigned;

  /// No description provided for @pointsWon.
  ///
  /// In en, this message translates to:
  /// **'+{n} points'**
  String pointsWon(int n);

  /// No description provided for @matchWon.
  ///
  /// In en, this message translates to:
  /// **'Match won!'**
  String get matchWon;

  /// No description provided for @matchLost.
  ///
  /// In en, this message translates to:
  /// **'Match lost'**
  String get matchLost;

  /// No description provided for @nextGame.
  ///
  /// In en, this message translates to:
  /// **'Next game'**
  String get nextGame;

  /// No description provided for @rematch.
  ///
  /// In en, this message translates to:
  /// **'Rematch'**
  String get rematch;

  /// No description provided for @mainMenu.
  ///
  /// In en, this message translates to:
  /// **'Main menu'**
  String get mainMenu;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @resign.
  ///
  /// In en, this message translates to:
  /// **'Resign'**
  String get resign;

  /// No description provided for @resignConfirm.
  ///
  /// In en, this message translates to:
  /// **'Resign this game?'**
  String get resignConfirm;

  /// No description provided for @coinsEarned.
  ///
  /// In en, this message translates to:
  /// **'+{n} coins'**
  String coinsEarned(int n);

  /// No description provided for @xpEarned.
  ///
  /// In en, this message translates to:
  /// **'+{n} XP'**
  String xpEarned(int n);

  /// No description provided for @levelUp.
  ///
  /// In en, this message translates to:
  /// **'Level up! Level {n}'**
  String levelUp(int n);

  /// No description provided for @coins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coins;

  /// No description provided for @gems.
  ///
  /// In en, this message translates to:
  /// **'Gems'**
  String get gems;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level {n}'**
  String level(int n);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Device default'**
  String get languageSystem;

  /// No description provided for @boardOrientation.
  ///
  /// In en, this message translates to:
  /// **'Board direction'**
  String get boardOrientation;

  /// No description provided for @orientationCcw.
  ///
  /// In en, this message translates to:
  /// **'Home on the right'**
  String get orientationCcw;

  /// No description provided for @orientationCw.
  ///
  /// In en, this message translates to:
  /// **'Home on the left'**
  String get orientationCw;

  /// No description provided for @animationSpeed.
  ///
  /// In en, this message translates to:
  /// **'Animation speed'**
  String get animationSpeed;

  /// No description provided for @speedSlow.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get speedSlow;

  /// No description provided for @speedNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get speedNormal;

  /// No description provided for @speedFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get speedFast;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get sound;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get haptics;

  /// No description provided for @colorblind.
  ///
  /// In en, this message translates to:
  /// **'Colorblind-safe highlights'**
  String get colorblind;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrast;

  /// No description provided for @reducedMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduced motion'**
  String get reducedMotion;

  /// No description provided for @leftHanded.
  ///
  /// In en, this message translates to:
  /// **'Left-handed layout'**
  String get leftHanded;

  /// No description provided for @autoMove.
  ///
  /// In en, this message translates to:
  /// **'Auto-play forced moves'**
  String get autoMove;

  /// No description provided for @confirmMoves.
  ///
  /// In en, this message translates to:
  /// **'Confirm before ending turn'**
  String get confirmMoves;

  /// No description provided for @showPips.
  ///
  /// In en, this message translates to:
  /// **'Show pip counts'**
  String get showPips;

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get resetProgress;

  /// No description provided for @resetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Erase all progress? This cannot be undone.'**
  String get resetConfirm;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutText.
  ///
  /// In en, this message translates to:
  /// **'HaftNard is an original game. All art and sound are generated by code. Fonts: Vazirmatn, Lalezar, Cinzel Decorative (SIL Open Font License).'**
  String get aboutText;

  /// No description provided for @replayLast.
  ///
  /// In en, this message translates to:
  /// **'Replay last game'**
  String get replayLast;

  /// No description provided for @replay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get replay;

  /// No description provided for @storeBoards.
  ///
  /// In en, this message translates to:
  /// **'Boards'**
  String get storeBoards;

  /// No description provided for @storeEnvironments.
  ///
  /// In en, this message translates to:
  /// **'Environments'**
  String get storeEnvironments;

  /// No description provided for @storeCheckers.
  ///
  /// In en, this message translates to:
  /// **'Checkers'**
  String get storeCheckers;

  /// No description provided for @storeDice.
  ///
  /// In en, this message translates to:
  /// **'Dice'**
  String get storeDice;

  /// No description provided for @storeCardBacks.
  ///
  /// In en, this message translates to:
  /// **'Card backs'**
  String get storeCardBacks;

  /// No description provided for @storeVictory.
  ///
  /// In en, this message translates to:
  /// **'Victory effects'**
  String get storeVictory;

  /// No description provided for @storeEmotes.
  ///
  /// In en, this message translates to:
  /// **'Emotes'**
  String get storeEmotes;

  /// No description provided for @storeBundles.
  ///
  /// In en, this message translates to:
  /// **'Bundles'**
  String get storeBundles;

  /// No description provided for @dailyShop.
  ///
  /// In en, this message translates to:
  /// **'Daily shop'**
  String get dailyShop;

  /// No description provided for @refreshesIn.
  ///
  /// In en, this message translates to:
  /// **'Refreshes in {time}'**
  String refreshesIn(String time);

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @owned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get owned;

  /// No description provided for @equip.
  ///
  /// In en, this message translates to:
  /// **'Equip'**
  String get equip;

  /// No description provided for @equipped.
  ///
  /// In en, this message translates to:
  /// **'Equipped'**
  String get equipped;

  /// No description provided for @notEnough.
  ///
  /// In en, this message translates to:
  /// **'Not enough currency'**
  String get notEnough;

  /// No description provided for @purchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased!'**
  String get purchased;

  /// No description provided for @randomizeLoadout.
  ///
  /// In en, this message translates to:
  /// **'Randomize loadout'**
  String get randomizeLoadout;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @statGames.
  ///
  /// In en, this message translates to:
  /// **'Games played'**
  String get statGames;

  /// No description provided for @statWins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get statWins;

  /// No description provided for @statWinRate.
  ///
  /// In en, this message translates to:
  /// **'Win rate'**
  String get statWinRate;

  /// No description provided for @statMars.
  ///
  /// In en, this message translates to:
  /// **'Mars wins'**
  String get statMars;

  /// No description provided for @statKupMars.
  ///
  /// In en, this message translates to:
  /// **'Kup Mars wins'**
  String get statKupMars;

  /// No description provided for @statSevens.
  ///
  /// In en, this message translates to:
  /// **'Double sevens rolled'**
  String get statSevens;

  /// No description provided for @statHits.
  ///
  /// In en, this message translates to:
  /// **'Checkers hit'**
  String get statHits;

  /// No description provided for @statFavoriteCard.
  ///
  /// In en, this message translates to:
  /// **'Favorite card'**
  String get statFavoriteCard;

  /// No description provided for @statBestRun.
  ///
  /// In en, this message translates to:
  /// **'Best journey'**
  String get statBestRun;

  /// No description provided for @statJourneysWon.
  ///
  /// In en, this message translates to:
  /// **'Journeys completed'**
  String get statJourneysWon;

  /// No description provided for @statStreak.
  ///
  /// In en, this message translates to:
  /// **'Best win streak'**
  String get statStreak;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get none;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @newRun.
  ///
  /// In en, this message translates to:
  /// **'New journey'**
  String get newRun;

  /// No description provided for @continueRun.
  ///
  /// In en, this message translates to:
  /// **'Continue journey'**
  String get continueRun;

  /// No description provided for @dailyRun.
  ///
  /// In en, this message translates to:
  /// **'Daily journey'**
  String get dailyRun;

  /// No description provided for @seed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get seed;

  /// No description provided for @act.
  ///
  /// In en, this message translates to:
  /// **'Act {n}'**
  String act(int n);

  /// No description provided for @actBazaar.
  ///
  /// In en, this message translates to:
  /// **'The Bazaar'**
  String get actBazaar;

  /// No description provided for @actCaravanserai.
  ///
  /// In en, this message translates to:
  /// **'The Caravanserai'**
  String get actCaravanserai;

  /// No description provided for @actPalace.
  ///
  /// In en, this message translates to:
  /// **'The Palace'**
  String get actPalace;

  /// No description provided for @boss.
  ///
  /// In en, this message translates to:
  /// **'Boss'**
  String get boss;

  /// No description provided for @bossRule.
  ///
  /// In en, this message translates to:
  /// **'Rule: {rule}'**
  String bossRule(String rule);

  /// No description provided for @runShop.
  ///
  /// In en, this message translates to:
  /// **'Bazaar stall'**
  String get runShop;

  /// No description provided for @talismans.
  ///
  /// In en, this message translates to:
  /// **'Talismans'**
  String get talismans;

  /// No description provided for @removeCard.
  ///
  /// In en, this message translates to:
  /// **'Banish a card'**
  String get removeCard;

  /// No description provided for @removeCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove a card from your 7–7 offers for this journey.'**
  String get removeCardDesc;

  /// No description provided for @upgradeOffer.
  ///
  /// In en, this message translates to:
  /// **'Wider offers'**
  String get upgradeOffer;

  /// No description provided for @upgradeOfferDesc.
  ///
  /// In en, this message translates to:
  /// **'Your 7–7 offers show one more card.'**
  String get upgradeOfferDesc;

  /// No description provided for @luckUp.
  ///
  /// In en, this message translates to:
  /// **'Seven\'s favour'**
  String get luckUp;

  /// No description provided for @luckUpDesc.
  ///
  /// In en, this message translates to:
  /// **'+25% chance of rolling 7–7.'**
  String get luckUpDesc;

  /// No description provided for @leaveShop.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get leaveShop;

  /// No description provided for @runCoins.
  ///
  /// In en, this message translates to:
  /// **'Run coins'**
  String get runCoins;

  /// No description provided for @runOver.
  ///
  /// In en, this message translates to:
  /// **'Journey over'**
  String get runOver;

  /// No description provided for @runWon.
  ///
  /// In en, this message translates to:
  /// **'Journey complete!'**
  String get runWon;

  /// No description provided for @runKept.
  ///
  /// In en, this message translates to:
  /// **'You keep {n} coins'**
  String runKept(int n);

  /// No description provided for @opponentN.
  ///
  /// In en, this message translates to:
  /// **'Opponent {n} of {total}'**
  String opponentN(int n, int total);

  /// No description provided for @fight.
  ///
  /// In en, this message translates to:
  /// **'Fight'**
  String get fight;

  /// No description provided for @tutorialBasics.
  ///
  /// In en, this message translates to:
  /// **'Backgammon basics'**
  String get tutorialBasics;

  /// No description provided for @tutorialSevens.
  ///
  /// In en, this message translates to:
  /// **'The Double Seven'**
  String get tutorialSevens;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @tip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tip;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @emoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Emotes'**
  String get emoteTitle;

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get aiThinking;

  /// No description provided for @pickTalisman.
  ///
  /// In en, this message translates to:
  /// **'Choose a talisman'**
  String get pickTalisman;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @dailyBonus.
  ///
  /// In en, this message translates to:
  /// **'Daily bonus'**
  String get dailyBonus;

  /// No description provided for @claim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get claim;

  /// No description provided for @replayControls.
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}'**
  String replayControls(int n, int total);

  /// No description provided for @gameN.
  ///
  /// In en, this message translates to:
  /// **'Game {n}'**
  String gameN(int n);

  /// No description provided for @sevenMode.
  ///
  /// In en, this message translates to:
  /// **'Seven mode'**
  String get sevenMode;

  /// No description provided for @classicMode.
  ///
  /// In en, this message translates to:
  /// **'Classic mode'**
  String get classicMode;

  /// No description provided for @turnSkipped.
  ///
  /// In en, this message translates to:
  /// **'{name} loses a turn!'**
  String turnSkipped(String name);

  /// No description provided for @coinHeads.
  ///
  /// In en, this message translates to:
  /// **'Heads! Opponent skips a turn.'**
  String get coinHeads;

  /// No description provided for @coinTails.
  ///
  /// In en, this message translates to:
  /// **'Tails! You skip a turn.'**
  String get coinTails;

  /// No description provided for @mineBoom.
  ///
  /// In en, this message translates to:
  /// **'A hidden mine!'**
  String get mineBoom;

  /// No description provided for @phoenixRises.
  ///
  /// In en, this message translates to:
  /// **'The phoenix rises!'**
  String get phoenixRises;

  /// No description provided for @stolen.
  ///
  /// In en, this message translates to:
  /// **'Stolen: {item}'**
  String stolen(String item);

  /// No description provided for @itemReroll.
  ///
  /// In en, this message translates to:
  /// **'Reroll'**
  String get itemReroll;

  /// No description provided for @itemLucky.
  ///
  /// In en, this message translates to:
  /// **'Lucky Charm'**
  String get itemLucky;

  /// No description provided for @itemGhost.
  ///
  /// In en, this message translates to:
  /// **'Ghost Step'**
  String get itemGhost;

  /// No description provided for @itemPhoenix.
  ///
  /// In en, this message translates to:
  /// **'Phoenix'**
  String get itemPhoenix;

  /// No description provided for @gripped.
  ///
  /// In en, this message translates to:
  /// **'Stuck in quicksand!'**
  String get gripped;

  /// No description provided for @extraTurn.
  ///
  /// In en, this message translates to:
  /// **'Time stops — extra turn!'**
  String get extraTurn;

  /// No description provided for @bonusRoll.
  ///
  /// In en, this message translates to:
  /// **'Bonus roll!'**
  String get bonusRoll;

  /// No description provided for @fizzled.
  ///
  /// In en, this message translates to:
  /// **'{card} had no target'**
  String fizzled(String card);

  /// No description provided for @rarityCommon.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get rarityCommon;

  /// No description provided for @rarityRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get rarityRare;

  /// No description provided for @rarityEpic.
  ///
  /// In en, this message translates to:
  /// **'Epic'**
  String get rarityEpic;

  /// No description provided for @rarityLegendary.
  ///
  /// In en, this message translates to:
  /// **'Legendary'**
  String get rarityLegendary;

  /// No description provided for @drawback.
  ///
  /// In en, this message translates to:
  /// **'Drawback'**
  String get drawback;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get howToPlay;

  /// No description provided for @targetOwnBlot2.
  ///
  /// In en, this message translates to:
  /// **'Tap two of your lone checkers'**
  String get targetOwnBlot2;

  /// No description provided for @targetEmpty2.
  ///
  /// In en, this message translates to:
  /// **'Tap two empty points'**
  String get targetEmpty2;

  /// No description provided for @targetPoint2.
  ///
  /// In en, this message translates to:
  /// **'Tap two points'**
  String get targetPoint2;

  /// No description provided for @bar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get bar;

  /// No description provided for @targetEnemy1.
  ///
  /// In en, this message translates to:
  /// **'Tap an enemy checker'**
  String get targetEnemy1;

  /// No description provided for @targetEnemyBlot.
  ///
  /// In en, this message translates to:
  /// **'Tap an enemy lone checker'**
  String get targetEnemyBlot;

  /// No description provided for @targetOwn2.
  ///
  /// In en, this message translates to:
  /// **'Tap two of your points'**
  String get targetOwn2;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to HaftNard'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Classic Persian backgammon — with a twist: roll the glowing Double Seven and claim a power card. New to the board? A two-minute interactive lesson will get you playing.'**
  String get welcomeBody;

  /// No description provided for @welcomeSkip.
  ///
  /// In en, this message translates to:
  /// **'I know how to play'**
  String get welcomeSkip;

  /// No description provided for @codex.
  ///
  /// In en, this message translates to:
  /// **'Card codex'**
  String get codex;

  /// No description provided for @codexProgress.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total} cards unlocked'**
  String codexProgress(int n, int total);

  /// No description provided for @attuneCard.
  ///
  /// In en, this message translates to:
  /// **'Attune a card'**
  String get attuneCard;

  /// No description provided for @attuneCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose a card: it appears three times as often in your 7–7 offers this journey.'**
  String get attuneCardDesc;

  /// No description provided for @cubeExplain.
  ///
  /// In en, this message translates to:
  /// **'Your opponent wants this game to count double ({value} points). Accept to keep playing for {value}, or decline and lose {current} now.'**
  String cubeExplain(int value, int current);

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'How to read the board'**
  String get help;

  /// No description provided for @helpDice.
  ///
  /// In en, this message translates to:
  /// **'Dice: tap to roll. Used dice dim in place. 7–7 opens a card offer.'**
  String get helpDice;

  /// No description provided for @helpPips.
  ///
  /// In en, this message translates to:
  /// **'Player panel: name, pips left to bear off (lower is better) and checkers already off.'**
  String get helpPips;

  /// No description provided for @helpBar.
  ///
  /// In en, this message translates to:
  /// **'Bar (middle): hit checkers wait here and must re-enter before anything else moves.'**
  String get helpBar;

  /// No description provided for @helpOff.
  ///
  /// In en, this message translates to:
  /// **'Tray (side): borne-off checkers. All 15 there wins the game.'**
  String get helpOff;

  /// No description provided for @helpCube.
  ///
  /// In en, this message translates to:
  /// **'Doubling cube: the current stakes. Only in matches with the cube switched on.'**
  String get helpCube;

  /// No description provided for @helpSeven.
  ///
  /// In en, this message translates to:
  /// **'7–7: roll it to pick a power card. It gets likelier every turn without one, and it is certain after 12 dry turns.'**
  String get helpSeven;

  /// No description provided for @helpEffects.
  ///
  /// In en, this message translates to:
  /// **'Glowing chips: powers in play, with the turns left. Tap a chip for details.'**
  String get helpEffects;

  /// No description provided for @helpCharges.
  ///
  /// In en, this message translates to:
  /// **'Charges: reroll tokens, Lucky Charms, Ghost Steps and Phoenixes you can still use.'**
  String get helpCharges;

  /// No description provided for @helpButtons.
  ///
  /// In en, this message translates to:
  /// **'Buttons: undo a move, use a reroll token, auto-play the best move, or finish your turn.'**
  String get helpButtons;

  /// No description provided for @helpEmotes.
  ///
  /// In en, this message translates to:
  /// **'Emotes (bottom corner): send a quick reaction.'**
  String get helpEmotes;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
