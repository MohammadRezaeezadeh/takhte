import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:haftnard/meta/profile.dart';
import 'package:haftnard/meta/settings.dart';
import 'package:path_provider/path_provider.dart';

/// Raw persistence backend.
abstract interface class SaveStore {
  Future<String?> read();
  Future<void> write(String data);
}

/// Stores the save as a JSON file in the app documents directory, written
/// atomically (temp file + rename) so a kill mid-write cannot corrupt it.
class FileSaveStore implements SaveStore {
  FileSaveStore([this._dir]);
  Directory? _dir;

  Future<File> _file() async {
    _dir ??= await getApplicationDocumentsDirectory();
    return File('${_dir!.path}/haftnard_save.json');
  }

  @override
  Future<String?> read() async {
    try {
      final f = await _file();
      if (f.existsSync()) return await f.readAsString();
      final bak = File('${f.path}.bak');
      if (bak.existsSync()) return await bak.readAsString();
    } on Object {
      return null;
    }
    return null;
  }

  @override
  Future<void> write(String data) async {
    final f = await _file();
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(data, flush: true);
    if (f.existsSync()) await f.copy('${f.path}.bak');
    await tmp.rename(f.path);
  }
}

class MemorySaveStore implements SaveStore {
  MemorySaveStore([this.data]);
  String? data;
  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String d) async => data = d;
}

/// Everything persisted, versioned.
class SaveData {
  SaveData({
    Settings? settings,
    Profile? profile,
    this.activeMatch,
    this.lastRecord,
    this.journey,
  }) : settings = settings ?? const Settings(),
       profile = profile ?? Profile();

  factory SaveData.fromJson(Map<String, Object?> raw) {
    final j = migrate(raw);
    Map<String, Object?>? m(Object? o) =>
        o is Map ? o.cast<String, Object?>() : null;
    // Each section falls back on its own: a damaged field must never wipe
    // the player's whole progress.
    T? safe<T>(T Function() f) {
      try {
        return f();
      } on Object {
        return null;
      }
    }

    return SaveData(
      settings: safe(() => Settings.fromJson(m(j['settings']) ?? const {})),
      profile: safe(() => Profile.fromJson(m(j['profile']) ?? const {})),
      activeMatch: m(j['activeMatch']),
      lastRecord: m(j['lastRecord']),
      journey: m(j['journey']),
    );
  }

  static const int version = 2;

  Settings settings;
  Profile profile;

  /// Serialized in-progress match (see `MatchSession.toJson`).
  Map<String, Object?>? activeMatch;

  /// Last finished game record, for the replay feature.
  Map<String, Object?>? lastRecord;

  /// Serialized Journey run.
  Map<String, Object?>? journey;

  /// Upgrades older save layouts step by step.
  static Map<String, Object?> migrate(Map<String, Object?> j) {
    final raw = j['version'];
    var v = raw is int ? raw : 1;
    final out = Map<String, Object?>.of(j);
    while (v < version) {
      switch (v) {
        case 1:
          // v1 stored settings at the top level as 'prefs'.
          if (out.containsKey('prefs') && !out.containsKey('settings')) {
            out['settings'] = out.remove('prefs');
          }
      }
      v++;
    }
    out['version'] = version;
    return out;
  }

  Map<String, Object?> toJson() => {
    'version': version,
    'settings': settings.toJson(),
    'profile': profile.toJson(),
    if (activeMatch != null) 'activeMatch': activeMatch,
    if (lastRecord != null) 'lastRecord': lastRecord,
    if (journey != null) 'journey': journey,
  };
}

/// Loads and saves [SaveData] with write coalescing.
class SaveService {
  SaveService(this.store);
  final SaveStore store;
  SaveData data = SaveData();
  Future<void>? _pending;
  bool _dirty = false;

  Future<SaveData> load() async {
    final raw = await store.read();
    if (raw != null && raw.isNotEmpty) {
      try {
        data = SaveData.fromJson(
          (jsonDecode(raw) as Map).cast<String, Object?>(),
        );
      } on Object {
        data = SaveData();
      }
    }
    return data;
  }

  /// Schedules a save; multiple calls within a frame are merged.
  Future<void> save() {
    _dirty = true;
    return _pending ??= Future<void>(() async {
      while (_dirty) {
        _dirty = false;
        await store.write(jsonEncode(data.toJson()));
      }
      _pending = null;
    });
  }

  /// Saves immediately (app pause / exit).
  Future<void> flush() async {
    await _pending;
    await store.write(jsonEncode(data.toJson()));
  }
}
