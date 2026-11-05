// Riverpod's devtools recorder is internal API; this is the only way to bound
// it. Debug builds only (release never records anything).
// ignore_for_file: implementation_imports, invalid_use_of_internal_member
import 'package:flutter/foundation.dart';
import 'package:riverpod/src/framework.dart' show RiverpodDevtool;

/// Riverpod 3 (debug builds only) appends every provider event, including
/// each disposed ProviderContainer and every state snapshot, to a static
/// list for its devtools, and never trims it. Over many matches that kept
/// every finished match's save data alive. Nothing here uses the Riverpod
/// devtools, so the buffer is dropped after every game.
void trimRiverpodDevtools() {
  if (!kDebugMode || _keep) return;
  RiverpodDevtool.instance.frames.clear();
}

/// Measurement switch: `--dart-define=KEEP_RIVERPOD_DEVTOOLS=true` keeps
/// the old behaviour (to compare heap growth).
const bool _keep = bool.fromEnvironment('KEEP_RIVERPOD_DEVTOOLS');

/// Frames the recorder holds right now (tests).
int get debugRiverpodFrames =>
    kDebugMode ? RiverpodDevtool.instance.frames.length : 0;
