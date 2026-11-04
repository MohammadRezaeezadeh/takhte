import 'dart:convert';

import 'package:haftnard/core/rules/match.dart';
import 'package:haftnard/core/rules/state.dart';
import 'package:haftnard/core/rules/types.dart';
import 'package:test/test.dart';

void main() {
  test('match to 3 ends when a side reaches 3', () {
    final m = MatchState(const MatchConfig(length: 3));
    m.recordResult(const GameResult(Side.white, WinType.gammon, 2));
    expect(m.isOver, isFalse);
    m.recordResult(const GameResult(Side.black, WinType.normal, 1));
    expect(m.isOver, isFalse);
    m.recordResult(const GameResult(Side.white, WinType.normal, 1));
    expect(m.winner, Side.white);
  });

  test('crawford game follows reaching match point, once', () {
    final m = MatchState(const MatchConfig(length: 5, cubeEnabled: true));
    m.recordResult(const GameResult(Side.white, WinType.normal, 4));
    expect(m.current.config.crawford, isTrue);
    m.recordResult(const GameResult(Side.black, WinType.normal, 1));
    expect(m.current.config.crawford, isFalse);
    m.recordResult(const GameResult(Side.black, WinType.normal, 1));
    expect(m.current.config.crawford, isFalse);
  });

  test('games get distinct derived seeds and JSON round-trips', () {
    final m = MatchState(const MatchConfig(length: 5, seed: 42));
    final s0 = m.current.config.seed;
    m.recordResult(const GameResult(Side.white, WinType.normal, 1));
    expect(m.current.config.seed, isNot(s0));
    final back = MatchState.fromJson(
      (jsonDecode(jsonEncode(m.toJson())) as Map).cast<String, Object?>(),
    );
    expect(back.scores, m.scores);
    expect(back.current.config.seed, m.current.config.seed);
    expect(back.config.mode, GameMode.seven);
  });
}
