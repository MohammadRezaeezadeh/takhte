// Persian is the default language; old saves that followed the phone's
// language (English on English phones) open in Persian too.
import 'package:flutter_test/flutter_test.dart';
import 'package:haftnard/meta/settings.dart';

void main() {
  test('Persian by default, old "system" saves become Persian', () {
    expect(const Settings().language, 'fa');
    expect(Settings.fromJson(const {}).language, 'fa');
    expect(Settings.fromJson(const {'language': 'system'}).language, 'fa');
    expect(Settings.fromJson(const {'language': 'en'}).language, 'en');
    expect(Settings.fromJson(const {'language': 'fa'}).language, 'fa');
    final round = Settings.fromJson(const Settings(language: 'en').toJson());
    expect(round.language, 'en');
  });
}
