import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haftnard/game/audio.dart';
import 'package:haftnard/game/scene/board_game.dart';
import 'package:haftnard/meta/problem_log.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/theme.dart';
import 'package:haftnard/ui/widgets/jewel.dart';
import 'package:haftnard/ui/widgets/menu_background.dart';
import 'package:haftnard/ui/widgets/top_bar.dart';

/// Settings → Report a problem: the rolling diagnostic log, ready to copy.
class ProblemReportScreen extends StatefulWidget {
  const ProblemReportScreen({super.key});

  @override
  State<ProblemReportScreen> createState() => _ProblemReportScreenState();
}

class _ProblemReportScreenState extends State<ProblemReportScreen> {
  bool _copied = false;

  String _build() {
    final a = Sfx.instance.manager;
    final g = BoardGame.current;
    return ProblemLog.instance.report(
      extra: {
        if (a != null)
          'audio':
              '${a.voiceCount} voices, ${a.stats.played} played, '
              '${a.stats.failures} failures, ${a.stats.resets} resets',
        if (g != null && g.isLoaded) 'scene': '${g.debugStats()}',
        'sound': '${Sfx.instance.soundOn}/${Sfx.instance.musicOn}',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = _build();
    return Scaffold(
      body: MenuBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: l.reportProblem),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l.reportProblemHint,
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Panel(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      text,
                      key: const ValueKey('problem-report'),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: JewelButton(
                  label: _copied ? l.copiedReport : l.copyReport,
                  icon: _copied ? Icons.check : Icons.copy,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (mounted) setState(() => _copied = true);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
