import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/scene/board_game.dart';

/// App version shown in Settings (kept in sync with pubspec by a test).
const String kAppVersion = '1.1.0';

/// Small on-screen readout of real frame timings (build + raster), for
/// checking the 60 fps target on a device.
class FpsOverlay extends StatefulWidget {
  const FpsOverlay({super.key});

  @override
  State<FpsOverlay> createState() => _FpsOverlayState();
}

class _FpsOverlayState extends State<FpsOverlay> {
  final List<FrameTiming> _frames = [];
  double _fps = 0;
  double _avgMs = 0;
  double _worstMs = 0;
  int _janky = 0;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    _frames.addAll(timings);
    if (_frames.length > 120) _frames.removeRange(0, _frames.length - 120);
    if (_frames.length < 2 || !mounted) return;
    final span =
        _frames.last.timestampInMicroseconds(FramePhase.rasterFinish) -
        _frames.first.timestampInMicroseconds(FramePhase.buildStart);
    var total = 0.0;
    var worst = 0.0;
    var janky = 0;
    for (final f in _frames) {
      final ms = f.totalSpan.inMicroseconds / 1000;
      total += ms;
      if (ms > worst) worst = ms;
      if (ms > 16.7) janky++;
    }
    setState(() {
      _fps = span > 0 ? (_frames.length - 1) * 1e6 / span : 0;
      _avgMs = total / _frames.length;
      _worstMs = worst;
      _janky = janky;
    });
  }

  /// Scene and audio counters (second line), when a game is on screen.
  static String _sceneLine() {
    final g = BoardGame.current;
    final a = Sfx.instance.manager;
    final parts = <String>[
      if (g != null && g.isLoaded) ...[
        '${g.debugStats()['components']} comp',
        '${g.debugStats()['particles']} fx',
      ],
      if (a != null) '${a.activeCount}/${a.voiceCount} sfx',
      if (a != null && a.stats.resets > 0) '${a.stats.resets} audio resets',
    ];
    return parts.isEmpty ? '' : '\n${parts.join(' · ')}';
  }

  @override
  Widget build(BuildContext context) {
    final good = _avgMs < 12 && _janky < 6;
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xCC000000),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: good ? const Color(0xFF2EC27E) : const Color(0xFFFF6B6B),
          ),
        ),
        child: Text(
          '${_fps.toStringAsFixed(0)} fps · ${_avgMs.toStringAsFixed(1)} ms avg · '
          '${_worstMs.toStringAsFixed(0)} ms worst · $_janky/120 janky'
          '${_sceneLine()}',
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFFFFFFFF),
            fontFamily: 'Vazirmatn',
          ),
        ),
      ),
    );
  }
}
