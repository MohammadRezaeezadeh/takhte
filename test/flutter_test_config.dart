import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every test: answer the platform channel like a device would.
///
/// Haptics (`HapticFeedback.*`) go over `flutter/platform`; flutter_tester
/// never replies, so each call left a pending future (with its whole
/// async stack chain) in `TestDefaultBinaryMessenger._pendingMessages` —
/// ~250 per match, which looked like a ~1.5 MB/match leak in the soak.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async => null,
        );
  });
  await testMain();
}
