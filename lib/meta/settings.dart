/// User preferences (persisted).
class Settings {
  const Settings({
    this.language = 'fa',
    this.homeOnRight = true,
    this.animSpeed = 1,
    this.sound = true,
    this.music = true,
    this.haptics = true,
    this.colorblind = false,
    this.highContrast = false,
    this.reducedMotion = false,
    this.leftHanded = false,
    this.autoMove = true,
    this.showPips = true,
    this.tutorialDone = false,
    this.sevenGuideDone = false,
    this.musicVolume = 0.35,
    this.sfxVolume = 1,
    this.sevenTutorialDone = false,
    this.showFps = false,
  });

  factory Settings.fromJson(Map<String, Object?> j) => Settings(
    // Persian is the default; the old "follow the phone" choice (which
    // showed English on English phones) becomes Persian too.
    language: switch (j['language']) {
      'en' => 'en',
      _ => 'fa',
    },
    homeOnRight: j['homeOnRight'] as bool? ?? true,
    animSpeed: (j['animSpeed'] as num?)?.toDouble() ?? 1,
    sound: j['sound'] as bool? ?? true,
    music: j['music'] as bool? ?? true,
    haptics: j['haptics'] as bool? ?? true,
    colorblind: j['colorblind'] as bool? ?? false,
    highContrast: j['highContrast'] as bool? ?? false,
    reducedMotion: j['reducedMotion'] as bool? ?? false,
    leftHanded: j['leftHanded'] as bool? ?? false,
    autoMove: j['autoMove'] as bool? ?? true,
    showPips: j['showPips'] as bool? ?? true,
    tutorialDone: j['tutorialDone'] as bool? ?? false,
    sevenGuideDone: j['sevenGuideDone'] as bool? ?? false,
    musicVolume: (j['musicVolume'] as num?)?.toDouble() ?? 0.35,
    sfxVolume: (j['sfxVolume'] as num?)?.toDouble() ?? 1,
    sevenTutorialDone: j['sevenTutorialDone'] as bool? ?? false,
    showFps: j['showFps'] as bool? ?? false,
  );

  /// 'fa' (default) or 'en'.
  final String language;

  /// White's home board on the bottom right (counter-clockwise play).
  final bool homeOnRight;

  /// Animation speed multiplier: 0.7 relaxed, 1 normal, 1.6 fast.
  final double animSpeed;
  final bool sound;
  final bool music;
  final bool haptics;
  final bool colorblind;
  final bool highContrast;
  final bool reducedMotion;
  final bool leftHanded;
  final bool autoMove;
  final bool showPips;
  final bool tutorialDone;

  /// The first-7–7 walkthrough of the card choice was shown.
  final bool sevenGuideDone;

  /// Music sits below the effects by default.
  final double musicVolume;
  final double sfxVolume;
  final bool sevenTutorialDone;

  /// Hidden developer overlay with frame timings.
  final bool showFps;

  Settings copyWith({
    String? language,
    bool? homeOnRight,
    double? animSpeed,
    bool? sound,
    bool? music,
    bool? haptics,
    bool? colorblind,
    bool? highContrast,
    bool? reducedMotion,
    bool? leftHanded,
    bool? autoMove,
    bool? showPips,
    bool? tutorialDone,
    bool? sevenGuideDone,
    double? musicVolume,
    double? sfxVolume,
    bool? sevenTutorialDone,
    bool? showFps,
  }) => Settings(
    language: language ?? this.language,
    homeOnRight: homeOnRight ?? this.homeOnRight,
    animSpeed: animSpeed ?? this.animSpeed,
    sound: sound ?? this.sound,
    music: music ?? this.music,
    haptics: haptics ?? this.haptics,
    colorblind: colorblind ?? this.colorblind,
    highContrast: highContrast ?? this.highContrast,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    leftHanded: leftHanded ?? this.leftHanded,
    autoMove: autoMove ?? this.autoMove,
    showPips: showPips ?? this.showPips,
    tutorialDone: tutorialDone ?? this.tutorialDone,
    sevenGuideDone: sevenGuideDone ?? this.sevenGuideDone,
    musicVolume: musicVolume ?? this.musicVolume,
    sfxVolume: sfxVolume ?? this.sfxVolume,
    sevenTutorialDone: sevenTutorialDone ?? this.sevenTutorialDone,
    showFps: showFps ?? this.showFps,
  );

  Map<String, Object?> toJson() => {
    'language': language,
    'homeOnRight': homeOnRight,
    'animSpeed': animSpeed,
    'sound': sound,
    'music': music,
    'haptics': haptics,
    'colorblind': colorblind,
    'highContrast': highContrast,
    'reducedMotion': reducedMotion,
    'leftHanded': leftHanded,
    'autoMove': autoMove,
    'showPips': showPips,
    'tutorialDone': tutorialDone,
    'sevenGuideDone': sevenGuideDone,
    'musicVolume': musicVolume,
    'sfxVolume': sfxVolume,
    'sevenTutorialDone': sevenTutorialDone,
    'showFps': showFps,
  };
}
