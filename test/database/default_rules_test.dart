import 'package:drift/native.dart';
import 'package:fl_clash/common/default_rules.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/features/form/rule_preset.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the default rules are the quick actions a new install starts with', () {
    expect(defaultGlobalRules, [
      ...RulePreset.blockLoopback.rawRules,
      ...RulePreset.lanDirect.rawRules,
      ...RulePreset.bittorrentDirect.rawRules,
    ]);
  });

  test(
    'a new database starts with the default global rules in order',
    () async {
      final database = Database(NativeDatabase.memory(), true);
      addTearDown(database.close);

      final rules = await database.rulesDao.queryGlobalRules().get();

      expect(rules.map((rule) => rule.rawValue), [
        for (final line in defaultGlobalRules) Rule.parse(line).rawValue,
      ]);
    },
  );
}
