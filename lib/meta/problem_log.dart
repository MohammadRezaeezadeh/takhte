import 'dart:io' show Platform;
import 'dart:ui' show FrameTiming, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

enum ProblemKind { error, audio, perf, info }

class ProblemEntry {
  ProblemEntry(this.at, this.kind, this.message);
  final DateTime at;
  final ProblemKind kind;
  final String message;
}

/// Rolling diagnostic log for playtest bug reports: the last few minutes of
/// uncaught errors, audio errors and frame drops, plus app/device facts.
/// It never records names, profile data or anything typed by the player.
class ProblemLog {
  ProblemLog({
    this.window = const Duration(minutes: 10),
    this.capacity = 400,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static final ProblemLog instance = ProblemLog();

  final Duration window;
  final int capacity;
  final DateTime Function() _clock;
  final List<ProblemEntry> _entries = [];

  /// App version shown in the report (set at startup).
  String version = '?';

  List<ProblemEntry> get entries {
    _trim();
    return List.unmodifiable(_entries);
  }

  void add(ProblemKind kind, String message) {
    final m = message.length > 600 ? '${message.substring(0, 600)}…' : message;
    _entries.add(ProblemEntry(_clock(), kind, m));
    _trim();
  }

  void error(Object e, [StackTrace? st]) {
    final top = st == null
        ? ''
        : '\n${st.toString().split('\n').take(6).join('\n')}';
    add(ProblemKind.error, '$e$top');
  }

  void _trim() {
    final cutoff = _clock().subtract(window);
    _entries.removeWhere((e) => e.at.isBefore(cutoff));
    if (_entries.length > capacity) {
      _entries.removeRange(0, _entries.length - capacity);
    }
  }

  // --- Frame drops ----------------------------------------------------------

  int _slowFrames = 0;
  double _worstMs = 0;
  DateTime? _lastPerfFlush;

  /// Records frames slower than 50 ms, aggregated at most every 5 s.
  void onFrames(List<FrameTiming> timings) {
    for (final t in timings) {
      final ms = t.totalSpan.inMicroseconds / 1000;
      if (ms > 50) {
        _slowFrames++;
        if (ms > _worstMs) _worstMs = ms;
      }
    }
    final now = _clock();
    if (_slowFrames > 0 &&
        (_lastPerfFlush == null ||
            now.difference(_lastPerfFlush!) > const Duration(seconds: 5))) {
      add(
        ProblemKind.perf,
        '$_slowFrames slow frame(s), worst ${_worstMs.round()} ms',
      );
      _slowFrames = 0;
      _worstMs = 0;
      _lastPerfFlush = now;
    }
  }

  // --- Error capture ---------------------------------------------------------

  /// Routes every uncaught Flutter and platform error here (still printed in
  /// debug) so nothing fails silently.
  void install() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      error(details.exception, details.stack);
      if (previous != null) {
        previous(details);
      } else {
        FlutterError.presentError(details);
      }
    };
    PlatformDispatcher.instance.onError = (e, st) {
      error(e, st);
      return true;
    };
    SchedulerBinding.instance.addTimingsCallback(onFrames);
  }

  // --- Report ----------------------------------------------------------------

  /// Plain-text report for copy/paste. No personal data.
  String report({Map<String, String> extra = const {}}) {
    final b = StringBuffer()
      ..writeln('HaftNard problem report')
      ..writeln('version: $version (${kReleaseMode ? 'release' : 'debug'})')
      ..writeln('time: ${_clock().toUtc().toIso8601String()}');
    try {
      b
        ..writeln(
          'os: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        )
        ..writeln('cpus: ${Platform.numberOfProcessors}')
        ..writeln('locale: ${PlatformDispatcher.instance.locale}');
      final views = PlatformDispatcher.instance.views;
      if (views.isNotEmpty) {
        final v = views.first;
        b.writeln(
          'screen: ${v.physicalSize.width.round()}x'
          '${v.physicalSize.height.round()} @${v.devicePixelRatio}',
        );
      }
    } on Object {
      // Platform facts are best-effort.
    }
    for (final e in extra.entries) {
      b.writeln('${e.key}: ${e.value}');
    }
    b
      ..writeln()
      ..writeln('--- last ${window.inMinutes} minutes ---');
    final list = entries;
    if (list.isEmpty) b.writeln('(nothing logged)');
    for (final e in list) {
      final t = e.at.toIso8601String().substring(11, 19);
      b.writeln('$t [${e.kind.name}] ${e.message}');
    }
    return b.toString();
  }
}
