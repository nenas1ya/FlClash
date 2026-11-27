import 'package:fl_clash/common/added_rules.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/clash_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('asAddedRule', () {
    test('sends a group target through a custom exit', () {
      final rule = asAddedRule(Rule.parse('DOMAIN-SUFFIX,example.com,PROXY'));

      expect(rule.customExit, isTrue);
      expect(rule.ruleTarget, 'PROXY');
    });

    test('keeps a built-in target as it is', () {
      expect(asAddedRule(Rule.parse('GEOIP,RU,DIRECT')).customExit, isFalse);
      expect(
        asAddedRule(Rule.parse('DOMAIN,ads.example,REJECT')).customExit,
        isFalse,
      );
    });
  });

  group('ruleTextOfDocument', () {
    List<String> decoded(Object? document) => [
      for (final (line: _, :rule) in decodeRuleList(
        ruleTextOfDocument(document)!,
      ))
        rule.rawValue,
    ];

    test('reads the rules of a whole config', () {
      final document = loadPlainYaml(
        'proxies: []\n'
        'rules:\n'
        '  - DOMAIN-SUFFIX,example.com,PROXY\n'
        "  - 'AND,((DOMAIN,a.example),(NETWORK,UDP)),REJECT'\n"
        '  - RULE-SET,ru,DIRECT,no-resolve\n'
        '  - MATCH,PROXY\n',
      );

      expect(decoded(document), [
        'DOMAIN-SUFFIX,example.com,PROXY',
        'AND,((DOMAIN,a.example),(NETWORK,UDP)),REJECT',
        'RULE-SET,ru,DIRECT,no-resolve',
        'MATCH,PROXY',
      ]);
    });

    test('reads a bare list of rules', () {
      expect(decoded(loadPlainYaml('- GEOIP,RU,DIRECT\n')), [
        'GEOIP,RU,DIRECT',
      ]);
    });

    test('is null for a document with no rules', () {
      expect(ruleTextOfDocument(loadPlainYaml('proxies: []\n')), isNull);
      expect(ruleTextOfDocument(loadPlainYaml('rules: none\n')), isNull);
      expect(ruleTextOfDocument('text'), isNull);
    });

    test('keeps the rule actions it reads', () {
      final rules = decodeRuleList(
        ruleTextOfDocument(['SUB-RULE,(NETWORK,TCP),sub', 'MATCH,DIRECT'])!,
      );

      expect(rules.map((entry) => entry.rule.ruleAction), [
        RuleAction.SUB_RULE,
        RuleAction.MATCH,
      ]);
    });
  });
}
