import 'dart:async';

import 'package:flutter/material.dart';
import 'package:haftnard/ui/app.dart';
import 'package:haftnard/ui/screens/main_menu.dart';
import 'package:haftnard/ui/widgets/logo.dart';
import 'package:haftnard/ui/widgets/menu_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      unawaited(
        Navigator.of(context)
            .pushReplacement(fadeRoute<void>(const MainMenuScreen())),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    return Scaffold(
      body: MenuBackground(
        child: Center(
          child: FadeTransition(
            opacity: _c,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.7, end: 1).animate(curve),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HaftNardLogo(size: 1.2),
                  const SizedBox(height: 18),
                  Text(
                    context.l10n.tagline,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
