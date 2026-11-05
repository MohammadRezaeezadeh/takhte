import 'dart:convert';
import 'dart:math' as math;

import 'package:haftnard/meta/profile.dart';
import 'package:haftnard/meta/save.dart';
import 'package:haftnard/meta/settings.dart';
import 'package:test/test.dart';

/// Every leaf path of a JSON tree.
List<List<Object>> paths(Object? node, [List<Object> prefix = const []]) {
  final out = <List<Object>>[];
  if (node is Map) {
    for (final e in node.entries) {
      final p = [...prefix, e.key as Object];
      out
        ..add(p)
        ..addAll(paths(e.value, p));
    }
  } else if (node is List) {
    for (var i = 0; i < node.length; i++) {
      final p = [...prefix, i];
      out
        ..add(p)
        ..addAll(paths(node[i], p));
    }
  }
  return out;
}

const List<Object?> junk = [
  null,
  'x',
  -7,
  3.5,
  true,
  <Object?>[],
  <String, Object?>{},
];

void mutate(Object? root, List<Object> path, math.Random r) {
  var parent = root;
  for (final k in path.take(path.length - 1)) {
    parent = parent is Map ? parent[k] : (parent! as List)[k as int];
  }
  final key = path.last;
  final value = junk[r.nextInt(junk.length)];
  if (parent is Map) {
    if (r.nextInt(4) == 0) {
      parent.remove(key);
    } else {
      parent[key] = value;
    }
  } else if (parent is List) {
    parent[key as int] = value;
  }
}

void main() {
  final rich =
      SaveData(
          settings: const Settings(sound: false, animSpeed: 1.6),
          profile: Profile()
            ..coins = 4321
            ..xp = 900,
        )
        ..activeMatch = {'garbage': true}
        ..lastRecord = {'moves': <Object?>[]};
  final source = jsonEncode(rich.toJson());

  test('damaged fields never throw and spare the other sections', () {
    final all = paths(jsonDecode(source));
    final r = math.Random(7);
    for (var i = 0; i < 2000; i++) {
      final tree = jsonDecode(source) as Map<String, Object?>;
      final path = all[r.nextInt(all.length)];
      mutate(tree, path, r);
      final SaveData d;
      try {
        d = SaveData.fromJson(tree);
      } on Object catch (e) {
        fail('mutation at $path threw $e');
      }
      if (path.first == 'settings') {
        expect(d.profile.coins, 4321, reason: 'settings damage at $path');
      }
      if (path.first == 'profile') {
        expect(d.settings.language, 'fa', reason: 'profile damage at $path');
      }
      // The result must serialize again.
      jsonEncode(d.toJson());
    }
  });

  test('wrong top-level types load as defaults', () {
    for (final v in junk) {
      final d = SaveData.fromJson({'version': v, 'settings': v, 'profile': v});
      expect(d.profile.coins, Profile().coins);
    }
  });

  test('truncated files load without throwing', () async {
    for (var cut = 0; cut < source.length; cut += 7) {
      final store = MemorySaveStore(source.substring(0, cut));
      await SaveService(store).load();
    }
  });
}
