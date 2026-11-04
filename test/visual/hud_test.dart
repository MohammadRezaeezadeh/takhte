import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/core/ai/personality.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/l10n/gen/app_localizations.dart';
import 'package:haftnard/ui/game/hud.dart';

void main() {
  testWidgets('crowded player panel does not overflow on a small phone', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(360, 640);
    await t.binding.setSurfaceSize(const Size(360, 640));
    final session = MatchSession(
      match: MatchState(const MatchConfig(length: 5, cubeEnabled: true)),
      white: const SeatConfig.human('A very long player name indeed'),
      black: const SeatConfig.ai(
        personalityId: 'gambler',
        difficulty: Difficulty.hard,
      ),
    );
    var s = GameState.initial(const GameConfig(cubeEnabled: true));
    final tx = Tx(s);
    for (final k in [
      EffectKind.curse,
      EffectKind.fog,
      EffectKind.brokenDie,
      EffectKind.headwind,
      EffectKind.sevenBlock,
    ]) {
      tx.addEffect(k, owner: Side.black, affected: Side.white, turns: 3);
    }
    s = tx.freeze().copyWith(
      white: const SideInv(rerolls: 3, lucky: 2, ghost: 1, phoenix: 2),
      cubeValue: 4,
      cubeOwner: Side.white,
    );
    final ctrl = MatchController(session, initialState: s, useIsolates: false);
    for (final lang in ['en', 'fa']) {
      await t.pumpWidget(
        MaterialApp(
          locale: Locale(lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: Scaffold(
            body: Column(
              children: [
                PlayerPanel(controller: ctrl, side: Side.white, showPips: true),
                PlayerPanel(controller: ctrl, side: Side.black, showPips: true),
              ],
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(t.takeException(), isNull, reason: lang);
    }
    ctrl.dispose();
  });
}
