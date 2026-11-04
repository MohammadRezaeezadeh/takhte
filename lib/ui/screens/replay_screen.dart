import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haftnard/core/rules/engine.dart';
import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/record.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/game/match_controller.dart';
import 'package:haftnard/game/scene/board_game.dart';
import 'package:haftnard/meta/cosmetics.dart';
import 'package:haftnard/meta/meta_state.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/jewel.dart';
import 'package:haftnard/ui/widgets/top_bar.dart';

/// Replays a recorded game from its seed and action log (which also proves
/// that the engine is deterministic).
class ReplayScreen extends ConsumerStatefulWidget {
  const ReplayScreen({required this.record, super.key});
  final GameRecord record;

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  late final List<GameState> _states = widget.record.replayStates();
  late final MatchController _ctrl;
  late final BoardGame _game;
  int _i = 0;
  bool _playing = false;
  bool _stepping = false;

  @override
  void initState() {
    super.initState();
    final m = ref.read(metaProvider);
    final eq = m.profile.equipped;
    final session = MatchSession(
      match: MatchState(
        MatchConfig(
          mode: widget.record.config.mode,
          seed: widget.record.config.seed,
        ),
        current: GameRecord(widget.record.config),
      ),
      white: const SeatConfig.human(''),
      black: const SeatConfig.human(''),
      origin: 'replay',
    );
    _ctrl = MatchController(session, viewOnly: true);
    _game = BoardGame(
      controller: _ctrl,
      config: SceneConfig(
        boardId: eq[ItemType.board]!,
        envId: eq[ItemType.environment]!,
        checkerId: eq[ItemType.checker]!,
        diceId: eq[ItemType.dice]!,
        homeOnRight: m.settings.homeOnRight,
        animSpeed: m.settings.animSpeed * 1.4,
        reducedMotion: m.settings.reducedMotion,
      ),
    );
    _ctrl.presenter = _game;
  }

  @override
  void dispose() {
    _playing = false;
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _step() async {
    if (_stepping || _i >= _states.length - 1) return;
    _stepping = true;
    final action = widget.record.actions[_i];
    final r = Engine.apply(_states[_i], action);
    _i++;
    setState(() {});
    await _ctrl.showState(_states[_i], r.events);
    _stepping = false;
  }

  void _back() {
    if (_stepping || _i == 0) return;
    _i--;
    _ctrl.jumpTo(_states[_i]);
    setState(() {});
  }

  Future<void> _play() async {
    setState(() => _playing = !_playing);
    while (_playing && mounted && _i < _states.length - 1) {
      await _step();
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (mounted) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final total = _states.length - 1;
    return Scaffold(
      backgroundColor: AppColors.night,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.replay),
            Expanded(child: GameWidget(game: _game)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                l.replayControls(_i, total),
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
            Slider(
              value: _i.toDouble(),
              max: total.toDouble().clamp(1, double.infinity),
              onChanged: (v) {
                _i = v.round().clamp(0, total);
                _ctrl.jumpTo(_states[_i]);
                setState(() {});
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                JewelIconButton(
                  icon: Icons.skip_previous,
                  tooltip: l.back,
                  onPressed: _back,
                ),
                const SizedBox(width: 16),
                JewelIconButton(
                  icon: _playing ? Icons.pause : Icons.play_arrow,
                  tooltip: l.replay,
                  size: 60,
                  onPressed: () => unawaited(_play()),
                ),
                const SizedBox(width: 16),
                JewelIconButton(
                  icon: Icons.skip_next,
                  tooltip: l.next,
                  onPressed: () => unawaited(_step()),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
