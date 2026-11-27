import 'dart:convert';

import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/clash_config.dart';

Rule asAddedRule(Rule rule) {
  final target = rule.ruleTarget;
  return rule.copyWith(
    customExit: target != null && !RuleTarget.ruleTargets.contains(target),
  );
}

String? ruleTextOfDocument(Object? document) {
  final items = switch (document) {
    Map() => switch (document['rules']) {
      final List rules => rules,
      _ => null,
    },
    List() => document,
    _ => null,
  };
  if (items == null) {
    return null;
  }
  return items.map((item) => '- ${jsonEncode(item.toString())}\n').join();
}
