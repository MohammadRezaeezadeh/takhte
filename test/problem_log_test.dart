import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/meta/problem_log.dart';
import 'package:haftnard/ui/screens/settings_screen.dart';
import 'package:haftnard/ui/widgets/jewel.dart';

import 'visual/flows_test.dart' show pump;

void main() {
  test('keeps only the last few minutes, capped', () {
    var now = DateTime(2026, 1, 1, 12);
    final log = ProblemLog(clock: () => now, capacity: 50)
      ..add(ProblemKind.info, 'old');
    now = now.add(const Duration(minutes: 11));
    for (var i = 0; i < 80; i++) {
      log.add(ProblemKind.audio, 'audio $i');
    }
    expect(log.entries, hasLength(50));
    expect(log.entries.any((e) => e.message == 'old'), isFalse);
    expect(log.entries.last.message, 'audio 79');
  });

  test('report carries version, device facts and entries', () {
    final log = ProblemLog()
      ..version = '9.9.9'
      ..add(ProblemKind.error, 'boom')
      ..onFrames(const []);
    final r = log.report(extra: {'audio': '34 voices'});
    expect(r, contains('version: 9.9.9'));
    expect(r, contains('[error] boom'));
    expect(r, contains('audio: 34 voices'));
    expect(r, contains('cpus:'));
  });

  testWidgets('uncaught Flutter errors are captured, not lost', (t) async {
    final previous = FlutterError.onError;
    ProblemLog.instance.install();
    final before = ProblemLog.instance.entries.length;
    final handler = FlutterError.onError!;
    FlutterError.onError = (d) {
      // Record without failing the test for the deliberate error below.
      ProblemLog.instance.error(d.exception, d.stack);
    };
    FlutterError.reportError(
      FlutterErrorDetails(exception: StateError('deliberate')),
    );
    FlutterError.onError = previous;
    expect(handler, isNotNull);
    expect(ProblemLog.instance.entries.length, greaterThan(before));
    expect(ProblemLog.instance.entries.last.message, contains('deliberate'));
  });

  testWidgets('Settings → Report a problem shows the copyable log', (t) async {
    ProblemLog.instance.add(ProblemKind.audio, 'audio error: play hit');
    await pump(t, const SettingsScreen());
    final button = find.byKey(const ValueKey('report-problem'));
    await t.scrollUntilVisible(button, 200);
    t.widget<JewelButton>(button).onPressed!();
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 60));
    }
    final text = t.widget<SelectableText>(
      find.byKey(const ValueKey('problem-report')),
    );
    expect(text.data, contains('audio error: play hit'));
    expect(text.data, contains('HaftNard problem report'));
    expect(find.text('Copy'), findsOneWidget);
  });
}
