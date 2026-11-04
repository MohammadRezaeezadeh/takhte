import 'package:flutter/material.dart';

void main() {
  runApp(const HaftNardApp());
}

class HaftNardApp extends StatelessWidget {
  const HaftNardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'HaftNard',
      home: Scaffold(body: Center(child: Text('HaftNard'))),
    );
  }
}
