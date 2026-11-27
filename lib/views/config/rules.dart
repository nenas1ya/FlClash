import 'dart:convert';
import 'dart:typed_data';

import 'package:fl_clash/common/added_rules.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/features.dart';
import 'package:fl_clash/models/clash_config.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddedRulesView extends ConsumerStatefulWidget {
  const AddedRulesView({super.key});

  @override
  ConsumerState<AddedRulesView> createState() => _AddedRulesViewState();
}

class _AddedRulesViewState extends ConsumerState<AddedRulesView> {
  final _key = uniqueId;
  var _query = SearchQuery('');
  final _searchTexts = Expando<String>();
  bool _importing = false;

  List<Rule> _visibleRules(List<Rule> rules) {
    return rules
        .whereMatches(_query, (rule) => rule.searchFields, texts: _searchTexts)
        .toList();
  }

  void _handleSearch(String query) {
    setState(() {
      _query = SearchQuery(query);
    });
  }

  Future<void> _handleAddOrUpdate([Rule? rule]) async {
    final exits = customExitsOf(ref.read(globalRulesProvider).value ?? []);
    final res = await showFormSheet<Rule>(
      context: context,
      builder: (_) => RuleForm(rule: rule, exits: exits),
    );
    if (res == null || !mounted) {
      return;
    }
    ref.read(globalRulesProvider.notifier).put(res);
  }

  String? _ruleError(Rule rule) {
    final appLocalizations = context.appLocalizations;
    final payloadError = rule.payloadError;
    if (payloadError != null) {
      return payloadError.getMessage(context);
    }
    if (rule.ruleAction != RuleAction.MATCH &&
        rule.realContent?.isNotEmpty != true) {
      return rule.ruleAction == RuleAction.RULE_SET
          ? appLocalizations.emptyTip(appLocalizations.ruleSet)
          : appLocalizations.contentNotEmpty;
    }
    if (rule.realTarget?.isNotEmpty != true) {
      return appLocalizations.splitStrategyNotEmpty;
    }
    return null;
  }

  ({List<Rule> rules, int skippedSubRules}) _decodeRules(String content) {
    final appLocalizations = context.appLocalizations;
    final rules = <Rule>[];
    var skippedSubRules = 0;
    try {
      for (final (:line, :rule) in decodeRuleList(
        content,
        previous: ref.read(globalRulesProvider).value ?? const [],
      )) {
        if (rule.ruleAction == RuleAction.SUB_RULE) {
          skippedSubRules++;
          continue;
        }
        if (_ruleError(rule) case final error?) {
          throw MessageException(appLocalizations.lineIssueTip(line, error));
        }
        rules.add(asAddedRule(rule));
      }
    } on RuleLineException catch (error) {
      throw MessageException(
        appLocalizations.lineIssueTip(
          error.line,
          appLocalizations.ruleTextInvalid,
        ),
      );
    }
    return (rules: rules, skippedSubRules: skippedSubRules);
  }

  void _setRules(({List<Rule> rules, int skippedSubRules}) decoded) {
    ref.read(globalRulesProvider.notifier).setAll(decoded.rules);
    if (decoded.skippedSubRules > 0 && mounted) {
      dialogs.showAlert(
        title: context.appLocalizations.addedRules,
        message: TextSpan(
          text: context.appLocalizations.addedRulesSkippedSubRules(
            decoded.skippedSubRules,
          ),
        ),
      );
    }
  }

  Future<void> _handleQuickEdit() {
    final appLocalizations = context.appLocalizations;
    final rules = ref.read(globalRulesProvider).value;
    if (rules == null) {
      return Future.value();
    }
    return showQuickEdit(
      context,
      title: appLocalizations.addedRules,
      content: encodeRuleList(rules),
      schema: EditorSchema.rules,
      invalidMessage: appLocalizations.ruleListInvalid,
      apply: (content) => _setRules(_decodeRules(content)),
    );
  }

  Future<String?> _readRuleText(String url) async {
    final response = await request.getFileResponseForUrl(url);
    final text = utf8.decode(
      decompressUnlabeled(response.data ?? Uint8List(0)),
      allowMalformed: true,
    );
    return ruleTextOfDocument(loadPlainYaml(text));
  }

  Future<void> _handleImportFromUrl() async {
    final appLocalizations = context.appLocalizations;
    final url = await dialogs.showUrlInput(title: appLocalizations.importUrl);
    if (url == null || !mounted) {
      return;
    }
    final decoded = await globalState.safeRun(
      () async {
        final content = await _readRuleText(url);
        if (content == null) {
          throw MessageException(appLocalizations.ruleListInvalid);
        }
        return _decodeRules(content);
      },
      title: appLocalizations.importUrl,
      silence: false,
      onStart: () => setState(() => _importing = true),
      onEnd: () {
        if (mounted) setState(() => _importing = false);
      },
    );
    if (decoded == null || !mounted) {
      return;
    }
    if ((ref.read(globalRulesProvider).value ?? const []).isNotEmpty) {
      final res = await dialogs.showMessage(
        message: TextSpan(text: appLocalizations.addedRulesImportReplaceTip),
        destructive: true,
        confirmText: appLocalizations.replace,
      );
      if (res != true || !mounted) {
        return;
      }
    }
    _setRules(decoded);
  }

  void _handleQuickActions() {
    showNestedSheet<void>(
      context,
      builder: (_) => RulePresetSheet(
        onAdd: (rules) => ref.read(globalRulesProvider.notifier).putAll(rules),
      ),
    );
  }

  void _handleSelected(int ruleId) {
    ref.read(itemsProvider(_key).notifier).update((selectedRules) {
      final newSelectedRules = Set<int>.from(selectedRules)
        ..addOrRemove(ruleId);
      return newSelectedRules;
    });
  }

  void _handleSelectAll() {
    final ids = _visibleRules(
      ref.read(globalRulesProvider).value ?? [],
    ).map((item) => item.id).toSet();
    ref.read(itemsProvider(_key).notifier).update((selected) {
      return selected.containsAll(ids) ? {} : ids;
    });
  }

  Future<void> _handleDelete() async {
    final appLocalizations = context.appLocalizations;
    final res = await dialogs.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(
        text: appLocalizations.deleteMultipTip(appLocalizations.rule),
      ),
      destructive: true,
      confirmText: appLocalizations.delete,
    );
    if (res != true || !mounted) {
      return;
    }
    final selectedRules = ref.read(itemsProvider(_key));
    final deletedIds = _visibleRules(
      ref.read(globalRulesProvider).value ?? [],
    ).map((item) => item.id).where(selectedRules.contains).toSet();
    ref.read(globalRulesProvider.notifier).delAll(deletedIds);
    ref.read(itemsProvider(_key).notifier).value = selectedRules.difference(
      deletedIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final rulesState = ref.watch(globalRulesProvider);
    final rules = _visibleRules(rulesState.value ?? []);
    final isSearching = _query.isNotEmpty;
    final selectedRules = ref.watch(itemsProvider(_key));
    final isSelecting = selectedRules.isNotEmpty;
    final selectionActions = [
      IconButtonData(
        glyph: AppGlyphs.delete,
        onPressed: _handleDelete,
        tooltip: appLocalizations.delete,
      ),
      IconButtonData(
        glyph: AppGlyphs.selectAll,
        onPressed: _handleSelectAll,
        tooltip: appLocalizations.selectAll,
      ),
    ];
    return PopGuard(
      onPop: isSelecting
          ? (_) {
              ref.read(itemsProvider(_key).notifier).value = {};
              return false;
            }
          : null,
      child: Scaffold(
        title: appLocalizations.addedRules,
        searchState: AppBarSearchState(onSearch: _handleSearch),
        actions: [
          if (!isSelecting)
            IconButton(
              tooltip: appLocalizations.add,
              onPressed: _handleAddOrUpdate,
              icon: const GlyphIcon(AppGlyphs.addCircle),
            ),
        ],
        isLoading: _importing,
        iconActions: [
          if (!isSelecting) ...[
            customQuickEditAction(context, onPressed: _handleQuickEdit),
            IconButtonData(
              glyph: AppGlyphs.cloudDownload,
              onPressed: _importing ? null : _handleImportFromUrl,
              tooltip: appLocalizations.importUrl,
            ),
            IconButtonData(
              glyph: AppGlyphs.rulePresets,
              onPressed: _handleQuickActions,
              tooltip: appLocalizations.quickActions,
            ),
          ],
        ],
        selectionActions: isSelecting ? selectionActions : const [],
        body: NullStatusSwitcher(
          isLoading: rulesState.isLoading,
          isEmpty: rules.isEmpty,
          isSearching: isSearching,
          nullStatus: NullStatus(
            label: appLocalizations.nullTip(appLocalizations.rule),
            illustration: NullStatusIllustration.rules,
          ),
          child: Builder(
            builder: (context) => isSearching
                ? PrismListView(
                    padding: _listPadding(context),
                    itemBuilder: (_, index) =>
                        _buildRuleItem(rules, index, selectedRules),
                    itemExtent: ruleItemHeight,
                    itemCount: rules.length,
                  )
                : PrismReorderableListView(
                    padding: _listPadding(context),
                    itemBuilder: (_, index) => ReorderDragStartListener(
                      key: ObjectKey(rules[index]),
                      index: index,
                      child: _buildRuleItem(rules, index, selectedRules),
                    ),
                    proxyDecorator: (child, index, animation) =>
                        commonProxyDecorator(
                          _buildRuleItem(rules, index, selectedRules),
                          index,
                          animation,
                        ),
                    itemExtent: ruleItemHeight,
                    itemCount: rules.length,
                    onReorderItem: (oldIndex, newIndex) => ref
                        .read(globalRulesProvider.notifier)
                        .order(oldIndex, newIndex),
                  ),
          ),
        ),
      ),
    );
  }

  EdgeInsets _listPadding(BuildContext context) => EdgeInsets.fromLTRB(
    16,
    context.contentTopPadding,
    16,
    16 + context.bottomInset,
  );

  Widget _buildRuleItem(List<Rule> rules, int index, Set<dynamic> selected) {
    final rule = rules[index];
    return ItemPositionProvider(
      key: ObjectKey(rule),
      position: ItemPosition.get(index, rules.length),
      child: RuleItem(
        isEditing: selected.isNotEmpty,
        rule: rule,
        isSelected: selected.contains(rule.id),
        onSelected: () {
          _handleSelected(rule.id);
        },
        onEdit: (Rule rule) {
          _handleAddOrUpdate(rule);
        },
      ),
    );
  }
}
