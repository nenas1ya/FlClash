import 'package:drift/native.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Database database;

  setUp(() {
    database = Database(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('replacing the global rules keeps the ones a profile turned off '
      'and leaves profile rules alone', () async {
    final profile = Profile.normal(label: 'p');
    const kept = Rule(
      id: 1,
      ruleAction: RuleAction.DOMAIN,
      content: 'kept.example',
      ruleTarget: 'PROXY',
      customExit: true,
      order: 'a',
    );
    const gone = Rule(
      id: 2,
      ruleAction: RuleAction.DOMAIN,
      content: 'gone.example',
      ruleTarget: 'DIRECT',
      order: 'b',
    );
    const own = Rule(
      id: 3,
      ruleAction: RuleAction.DOMAIN,
      content: 'own.example',
      ruleTarget: 'DIRECT',
      order: 'a',
    );
    await database.profiles.put(profile.toCompanion());
    await database.rulesDao.putRule(kept);
    await database.rulesDao.putRule(gone);
    await database.rulesDao.putRule(own, profileId: profile.id);
    await database.rulesDao.putDisabled(profile.id, kept.id);
    await database.rulesDao.putDisabled(profile.id, gone.id);

    const added = Rule(
      id: 4,
      ruleAction: RuleAction.GEOIP,
      content: 'RU',
      ruleTarget: 'DIRECT',
      order: 'a',
    );
    await database.batch(
      (b) => database.rulesDao.replaceGlobalRulesWithBatch(
        b,
        [added, kept.copyWith(order: 'b')],
        removedIds: [gone.id, own.id],
      ),
    );

    expect(
      (await database.rulesDao.queryGlobalRules().get()).map((r) => r.id),
      [added.id, kept.id],
    );
    expect(await database.rulesDao.queryDisabledRuleIds(profile.id).get(), [
      kept.id,
    ]);
    expect(
      (await database.rulesDao.queryProfileRules(profile.id).get()).single.id,
      own.id,
    );
  });
}
