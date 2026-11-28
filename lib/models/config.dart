import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'models.dart';
import 'package:prism_ui/prism_ui.dart';

part 'generated/config.freezed.dart';
part 'generated/config.g.dart';

const defaultBypassDomain = [
  '*gosuslugi.ru',
  '*nalog.gov.ru',
  '*mos.ru',
  '*sberbank.ru',
  '*tbank.ru',
  '*alfabank.ru',
  '*vtb.ru',
  '*yandex.ru',
  '*yandex.net',
  '*ya.ru',
  '*kinopoisk.ru',
  '*vk.com',
  '*userapi.com',
  '*mail.ru',
  '*ozon.ru',
  '*wildberries.ru',
  '*wb.ru',
  '*avito.ru',
  'localhost',
  '*.local',
  '127.*',
  '10.*',
  '172.16.*',
  '172.17.*',
  '172.18.*',
  '172.19.*',
  '172.20.*',
  '172.21.*',
  '172.22.*',
  '172.23.*',
  '172.24.*',
  '172.25.*',
  '172.26.*',
  '172.27.*',
  '172.28.*',
  '172.29.*',
  '172.30.*',
  '172.31.*',
  '192.168.*',
];

/// WinINet's entry for every host without a dot; the other platforms leave it
/// out when they write the list.
const windowsLocalBypass = '<local>';

/// The field default keeps the shared list because it must be const.
final List<String> platformDefaultBypassDomain = system.isWindows
    ? const [...defaultBypassDomain, windowsLocalBypass]
    : defaultBypassDomain;

/// `%mixed-port%` is replaced with the mixed port when the script is served.
const defaultPacScript = '''function FindProxyForURL(url, host) {
  if (isPlainHostName(host)) {
    return "DIRECT";
  }
  return "PROXY 127.0.0.1:%mixed-port%; SOCKS5 127.0.0.1:%mixed-port%; DIRECT";
}
''';

const defaultUserAgents = ['clash-verge/v2.4.2', 'ClashforWindows/0.19.23'];

/// Country filters for the nodes Russian subscriptions carry, by flag,
/// Russian and English name, capital and code, then the service entries
/// subscriptions list among their nodes.
const defaultFilters = [
  Filter(
    label: 'United States',
    regex:
        r'(?i)🇺🇸|сша|америк|(?<![a-z])usa?(?![a-z])|united\s*states|нью-йорк|new\s*york|лос-анджелес|los\s*angeles|майами|miami',
  ),
  Filter(
    label: 'Germany',
    regex:
        r'(?i)🇩🇪|герман|germany|франкфурт|frankfurt|берлин|berlin|(?<![a-z])de(?![a-z])',
  ),
  Filter(
    label: 'Poland',
    regex: r'(?i)🇵🇱|польш|poland|варшав|warsaw|(?<![a-z])pl(?![a-z])',
  ),
  Filter(
    label: 'Netherlands',
    regex:
        r'(?i)🇳🇱|нидерланд|netherlands|голланд|holland|амстердам|amsterdam|(?<![a-z])nl(?![a-z])',
  ),
  Filter(
    label: 'United Kingdom',
    regex:
        r'(?i)🇬🇧|великобритан|англи|лондон|(?<![a-z])uk(?![a-z])|united\s*kingdom|britain|london',
  ),
  Filter(
    label: 'Turkey',
    regex:
        r'(?i)🇹🇷|турци|turkey|türkiye|стамбул|istanbul|(?<![a-z])tr(?![a-z])',
  ),
  Filter(
    label: 'France',
    regex: r'(?i)🇫🇷|франци|france|париж|paris|(?<![a-z])fr(?![a-z])',
  ),
  Filter(
    label: 'Sweden',
    regex: r'(?i)🇸🇪|швеци|sweden|стокгольм|stockholm|(?<![a-z])se(?![a-z])',
  ),
  Filter(
    label: 'Finland',
    regex: r'(?i)🇫🇮|финлянд|finland|хельсинки|helsinki|(?<![a-z])fi(?![a-z])',
  ),
  Filter(
    label: 'Lithuania',
    regex: r'(?i)🇱🇹|литв|lithuania|вильнюс|vilnius|(?<![a-z])lt(?![a-z])',
  ),
  Filter(
    label: 'Kazakhstan',
    regex: r'(?i)🇰🇿|казахстан|kazakhstan|алматы|almaty|(?<![a-z])kz(?![a-z])',
  ),
  Filter(
    label: 'Russia',
    regex: r'(?i)🇷🇺|росси|russia|москв|moscow|(?<![a-z])ru(?![a-z])',
  ),
  Filter(
    label: 'Singapore',
    regex: r'(?i)🇸🇬|сингапур|singapore|(?<![a-z])sg(?![a-z])',
  ),
  Filter(
    label: 'Japan',
    regex: r'(?i)🇯🇵|япони|токио|japan|tokyo|(?<![a-z])jp(?![a-z])',
  ),
  Filter(
    label: 'Hong Kong',
    regex: r'(?i)🇭🇰|гонконг|hong\s*kong|(?<![a-z])hk(?![a-z])',
  ),
  Filter(
    label: 'Remaining Traffic',
    regex: r'(?i)остал|остаток|трафик|traffic|remaining',
  ),
  Filter(
    label: 'Expiry Date',
    regex: r'(?i)истека|истёк|истек|действует до|срок|expir',
  ),
  Filter(label: 'Traffic Reset', regex: r'(?i)сброс|обновлен|reset'),
  Filter(
    label: 'Website & Notices',
    regex:
        r'(?i)сайт|канал|телеграм|поддержк|website|telegram|(?<![a-z])tg(?![a-z])',
  ),
];

const defaultAppSettingProps = AppSettingProps();
const defaultVpnProps = VpnProps();
const defaultAuthenticationProps = AuthenticationProps();
const defaultNetworkProps = NetworkProps();
const defaultProxiesStyleProps = ProxiesStyleProps();
const defaultWindowProps = WindowProps();
const defaultAccessControlProps = AccessControlProps();
const defaultThemeProps = ThemeProps(primaryColor: defaultPrimaryColor);

HotKeyAction _defaultHotKeyAction(HotAction action, PhysicalKeyboardKey key) {
  return HotKeyAction(
    action: action,
    key: key.usbHidUsage,
    modifiers: const {KeyboardModifier.control, KeyboardModifier.alt},
  );
}

// Windows reports AltGr as Ctrl+Alt, and every letter is an AltGr character
// on some layout (@ on German Q, ś on Polish S), so a default there would fire
// while the user types.
final List<HotKeyAction> defaultHotKeyActions = system.isWindows
    ? const []
    : [
        _defaultHotKeyAction(HotAction.view, PhysicalKeyboardKey.keyV),
        _defaultHotKeyAction(HotAction.start, PhysicalKeyboardKey.keyS),
        _defaultHotKeyAction(HotAction.mode, PhysicalKeyboardKey.keyM),
        _defaultHotKeyAction(HotAction.proxy, PhysicalKeyboardKey.keyP),
        _defaultHotKeyAction(HotAction.delayTest, PhysicalKeyboardKey.keyD),
      ];

const List<DashboardWidget> defaultDashboardWidgets = [
  DashboardWidget.currentOutbound,
  DashboardWidget.networkSpeed,
  DashboardWidget.outboundMode,
  DashboardWidget.vpnButton,
  DashboardWidget.networkTakeover,
  DashboardWidget.intranetIp,
  DashboardWidget.serviceStatus,
  DashboardWidget.profiles,
  DashboardWidget.proxyGroups,
  DashboardWidget.connectionStats,
];

/// A phone starts without the VPN switch and the diagnostic cards, which stay
/// addable. The field default keeps the shared list because it must be const.
final List<DashboardWidget> platformDefaultDashboardWidgets = system.isAndroid
    ? const [
        DashboardWidget.currentOutbound,
        DashboardWidget.networkSpeed,
        DashboardWidget.outboundMode,
        DashboardWidget.profiles,
        DashboardWidget.proxyGroups,
      ]
    : defaultDashboardWidgets;

const _legacyDefaultDashboardWidgets = {
  'networkSpeed',
  'systemProxyButton',
  'tunButton',
  'outboundMode',
  'networkDetection',
  'trafficUsage',
  'intranetIp',
};

/// The run time has no replacement: it moved onto the current outbound card,
/// as did the outbound IP, whose card became the intranet one.
const _legacyDashboardWidgets = {
  'networkDetection': DashboardWidget.intranetIp,
  'outboundModeV2': DashboardWidget.outboundMode,
  'systemProxyButton': DashboardWidget.networkTakeover,
  'tunButton': DashboardWidget.networkTakeover,
  'connections': DashboardWidget.connectionStats,
  'requests': DashboardWidget.connectionStats,
  'dnsQueries': DashboardWidget.connectionStats,
  'trafficUsage': DashboardWidget.networkSpeed,
};

const _retiredDashboardWidgets = {
  'runTime',
  'overrideDnsButton',
  'overrideNtpButton',
};

/// The current outbound card cannot be removed: a list without it predates it.
List<DashboardWidget> dashboardWidgetsFromJson(
  List<dynamic>? dashboardWidgets,
) {
  if (dashboardWidgets == null) {
    return platformDefaultDashboardWidgets;
  }
  final byName = DashboardWidget.values.asNameMap();
  if (dashboardWidgets.contains(DashboardWidget.currentOutbound.name)) {
    return dashboardWidgets
        .map((e) => _legacyDashboardWidgets[e] ?? byName[e])
        .nonNulls
        .toSet()
        .toList();
  }
  final names = {
    for (final name in dashboardWidgets)
      name == 'outboundModeV2' ? DashboardWidget.outboundMode.name : name,
  };
  if (names.length == _legacyDefaultDashboardWidgets.length &&
      names.containsAll(_legacyDefaultDashboardWidgets)) {
    return platformDefaultDashboardWidgets;
  }
  final kept = dashboardWidgets
      .map((e) => _legacyDashboardWidgets[e] ?? byName[e])
      .nonNulls;
  if (kept.isEmpty &&
      !dashboardWidgets.every(_retiredDashboardWidgets.contains)) {
    return platformDefaultDashboardWidgets;
  }
  return {DashboardWidget.currentOutbound, ...kept}.toList();
}

Object? _readSidebarExpanded(Map<dynamic, dynamic> json, String key) {
  return json.containsKey(key) ? json[key] : json['showLabel'];
}

Object? _readTabAnimation(Map<dynamic, dynamic> json, String key) {
  if (json.containsKey(key)) {
    return json[key];
  }
  return switch (json['isAnimateToPage']) {
    true => TabAnimation.slide.name,
    false => TabAnimation.fade.name,
    _ => null,
  };
}

Object? _readUserAgents(Map<dynamic, dynamic> json, String key) {
  if (json.containsKey(key)) {
    return json[key];
  }
  final legacy = json['customUserAgent'];
  if (legacy is! String) {
    return null;
  }
  final custom = legacy.trim();
  if (custom.isEmpty || defaultUserAgents.contains(custom)) {
    return null;
  }
  return [...defaultUserAgents, custom];
}

@freezed
abstract class Filter with _$Filter {
  const factory Filter({required String label, required String regex}) =
      _Filter;

  factory Filter.fromJson(Map<String, Object?> json) => _$FilterFromJson(json);
}

@freezed
abstract class AppSettingProps with _$AppSettingProps {
  const factory AppSettingProps({
    String? locale,
    @Default(defaultDashboardWidgets)
    @JsonKey(fromJson: dashboardWidgetsFromJson)
    List<DashboardWidget> dashboardWidgets,
    @Default(false) bool onlyStatisticsProxy,
    @Default(true) bool showNotificationStopAction,
    @Default(false) bool autoLaunch,
    @Default(false) bool silentLaunch,
    @Default(false) bool autoRun,
    @Default(false) bool openLogs,
    @Default(true) bool closeConnections,
    @Default(defaultDelayTestTimeout) int delayTestTimeout,
    @Default(TabAnimation.fade)
    @JsonKey(readValue: _readTabAnimation)
    TabAnimation tabAnimation,
    @Default(true) bool floatingNavigationBar,
    @Default(true) bool autoCheckUpdate,
    @Default(UpdateChannel.stable) UpdateChannel updateChannel,
    @Default(true)
    @JsonKey(readValue: _readSidebarExpanded)
    bool sidebarExpanded,
    @Default(0) int acceptedDisclaimerVersion,
    @Default(true) bool minimizeOnExit,
    @Default(false) bool hidden,
    @Default(false) bool developerMode,
    @Default(RestoreStrategy.compatible) RestoreStrategy restoreStrategy,
    @Default(true) bool showTrayTitle,
    @Default(true) bool monochromeTrayIcon,
    @Default(true) bool checkCertificate,
    @Default(defaultUserAgents)
    @JsonKey(readValue: _readUserAgents)
    List<String> userAgents,
    @Default(defaultFilters) List<Filter> filters,
    @Default(false) bool hideIp,
    @Default(false) bool editorLineWrap,
    @Default(EditorFontSize.standard) EditorFontSize editorFontSize,
    @Default([]) List<String> serviceOrder,
    @Default([]) List<String> disabledServices,
    @Default({}) Map<String, Map<String, double>> tableColumnWidths,
  }) = _AppSettingProps;

  factory AppSettingProps.fromJson(Map<String, Object?> json) =>
      _$AppSettingPropsFromJson(json);

  factory AppSettingProps.safeFromJson(Map<String, Object?>? json) {
    if (json == null) {
      return defaultAppSettingProps;
    }
    return decodeSalvaging('app settings', json, AppSettingProps.fromJson);
  }
}

@freezed
abstract class AccessControlProps with _$AccessControlProps {
  const factory AccessControlProps({
    @Default(false) bool enable,
    @Default(AccessControlMode.rejectSelected) AccessControlMode mode,
    @Default([]) List<String> acceptList,
    @Default([]) List<String> rejectList,
    @Default(AccessSortType.none) AccessSortType sort,
    @Default(true) bool isFilterSystemApp,
    @Default(true) bool isFilterNonInternetApp,
  }) = _AccessControlProps;

  factory AccessControlProps.fromJson(Map<String, Object?> json) =>
      _$AccessControlPropsFromJson(json);
}

extension AccessControlPropsExt on AccessControlProps {
  bool get hasPackages => acceptList.isNotEmpty || rejectList.isNotEmpty;

  List<String> get currentList => switch (mode) {
    AccessControlMode.acceptSelected => acceptList,
    AccessControlMode.rejectSelected => rejectList,
  };

  AccessControlProps copyWithNewList(List<String> value) => switch (mode) {
    AccessControlMode.acceptSelected => copyWith(acceptList: value),
    AccessControlMode.rejectSelected => copyWith(rejectList: value),
  };
}

@freezed
abstract class WindowProps with _$WindowProps {
  const factory WindowProps({
    @Default(0) double width,
    @Default(0) double height,
    double? top,
    double? left,
    double? scale,
  }) = _WindowProps;

  factory WindowProps.fromJson(Map<String, Object?>? json) =>
      json == null ? const WindowProps() : _$WindowPropsFromJson(json);
}

/// Four dashboard columns at full density beside the expanded sidebar, with
/// room for the Windows and Linux title bar.
const defaultWindowSize = Size(1280, 880);

extension WindowPropsExt on WindowProps {
  Size? get savedSize {
    final size = Size(width, height);
    return size.isEmpty ? null : size;
  }

  Size get size => savedSize ?? defaultWindowSize;
}

@freezed
abstract class VpnProps with _$VpnProps {
  const factory VpnProps({
    @Default(true) bool enable,
    @Default(true) bool systemProxy,
    @Default(false) bool ipv6,
    @Default(true) bool allowBypass,
    @Default(false) bool dnsHijacking,
    @Default(defaultAccessControlProps) AccessControlProps accessControlProps,
  }) = _VpnProps;

  factory VpnProps.fromJson(Map<String, Object?>? json) =>
      json == null ? defaultVpnProps : _$VpnPropsFromJson(json);
}

@freezed
abstract class AuthenticationProps with _$AuthenticationProps {
  const factory AuthenticationProps({
    @Default(false) bool enable,
    @Default('') String username,
    @Default('') String password,
  }) = _AuthenticationProps;

  factory AuthenticationProps.fromJson(Map<String, Object?>? json) =>
      json == null
      ? defaultAuthenticationProps
      : _$AuthenticationPropsFromJson(json);
}

extension AuthenticationPropsExt on AuthenticationProps {
  List<String> get credentials =>
      enable && username.isNotEmpty ? ['$username:$password'] : [];
}

@freezed
abstract class NetworkProps with _$NetworkProps {
  const factory NetworkProps({
    @Default(true) bool systemProxy,
    @Default(defaultBypassDomain) List<String> bypassDomain,
    @Default(false) bool pacMode,
    @Default(defaultPacScript) String pacScript,
    @Default(true) bool bypassPrivateRoute,
    @Default(false) bool appendSystemDns,
    @Default(defaultAuthenticationProps) AuthenticationProps authentication,
  }) = _NetworkProps;

  factory NetworkProps.fromJson(Map<String, Object?>? json) =>
      json == null ? const NetworkProps() : _$NetworkPropsFromJson(json);
}

/// Reads the styles named `standard`, `icon` and `none` before they became
/// [ProxiesIconStyle.filled], [ProxiesIconStyle.plain] and
/// [ProxiesIconStyle.hidden].
ProxiesIconStyle proxiesIconStyleSafeFromJson(Object? iconStyle) {
  return switch (iconStyle) {
    'filled' || 'standard' => ProxiesIconStyle.filled,
    'plain' || 'icon' => ProxiesIconStyle.plain,
    'hidden' || 'none' => ProxiesIconStyle.hidden,
    _ => ProxiesIconStyle.filled,
  };
}

ProxyCardType proxyCardTypeSafeFromJson(Object? cardType) {
  return switch (cardType) {
    'loose' || 'expand' => ProxyCardType.loose,
    'standard' || 'shrink' => ProxyCardType.standard,
    'compact' || 'min' => ProxyCardType.compact,
    _ => ProxyCardType.standard,
  };
}

@freezed
abstract class ProxiesStyleProps with _$ProxiesStyleProps {
  const factory ProxiesStyleProps({
    @Default(ProxiesType.list) ProxiesType type,
    @Default(ProxiesSortType.none) ProxiesSortType sortType,
    @Default(ProxiesLayout.standard) ProxiesLayout layout,
    @Default(ProxiesIconStyle.filled)
    @JsonKey(fromJson: proxiesIconStyleSafeFromJson)
    ProxiesIconStyle iconStyle,
    @Default(ProxyCardType.standard)
    @JsonKey(fromJson: proxyCardTypeSafeFromJson)
    ProxyCardType cardType,
    @Default(false) bool hideTimeoutProxies,
  }) = _ProxiesStyleProps;

  factory ProxiesStyleProps.fromJson(Map<String, Object?>? json) => json == null
      ? defaultProxiesStyleProps
      : _$ProxiesStylePropsFromJson(json);
}

@freezed
abstract class TextScale with _$TextScale {
  const factory TextScale({
    @Default(false) bool enable,
    @Default(1.0) double scale,
  }) = _TextScale;

  factory TextScale.fromJson(Map<String, Object?> json) =>
      _$TextScaleFromJson(json);
}

// Older configs name one of Material's nine scheme variants instead.
Object? _readColorStyle(Map<dynamic, dynamic> json, String key) {
  if (json.containsKey(key)) {
    return json[key];
  }
  return switch (json['schemeVariant']) {
    'monochrome' => ColorStyle.monochrome.name,
    'tonalSpot' || 'neutral' => ColorStyle.soft.name,
    _ => null,
  };
}

// Older configs say whether glass is on.
Object? _readLiquidGlass(Map<dynamic, dynamic> json, String key) {
  return switch (json[key]) {
    true => LiquidGlassMode.standard.name,
    false => LiquidGlassMode.none.name,
    final value => value,
  };
}

@freezed
abstract class ThemeProps with _$ThemeProps {
  const factory ThemeProps({
    int? primaryColor,
    @Default(defaultPrimaryColors) List<int> primaryColors,
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(ColorStyle.vivid)
    @JsonKey(readValue: _readColorStyle)
    ColorStyle colorStyle,
    @Default(false) bool pureBlack,
    @Default(false) bool sidebarBlur,
    @Default(LiquidGlassMode.none)
    @JsonKey(readValue: _readLiquidGlass)
    LiquidGlassMode liquidGlass,
    @Default(TextScale()) TextScale textScale,
    // `fontFamily` held the names of a removed enum, which old configs may
    // still carry.
    @JsonKey(name: 'systemFontFamily') String? fontFamily,
  }) = _ThemeProps;

  factory ThemeProps.fromJson(Map<String, Object?> json) =>
      _$ThemePropsFromJson(json);

  factory ThemeProps.safeFromJson(Map<String, Object?>? json) {
    if (json == null) {
      return defaultThemeProps;
    }
    return decodeSalvaging('theme settings', json, ThemeProps.fromJson);
  }
}

@freezed
abstract class Config with _$Config {
  const factory Config({
    int? currentProfileId,
    @Default([]) List<HotKeyAction> hotKeyActions,
    @JsonKey(fromJson: AppSettingProps.safeFromJson)
    @Default(defaultAppSettingProps)
    AppSettingProps appSettingProps,
    DAVProps? davProps,
    @Default(defaultNetworkProps) NetworkProps networkProps,
    @Default(defaultVpnProps) VpnProps vpnProps,
    @JsonKey(fromJson: ThemeProps.safeFromJson) required ThemeProps themeProps,
    @Default(defaultProxiesStyleProps) ProxiesStyleProps proxiesStyleProps,
    // A new key opens every window once at defaultWindowSize.
    @Default(defaultWindowProps)
    @JsonKey(name: 'windowGeometry')
    WindowProps windowProps,
    @Default(defaultClashConfig) PatchClashConfig patchClashConfig,
    @Default([]) List<String> excludeSSIDs,
  }) = _Config;

  factory Config.fromJson(Map<String, Object?> json) =>
      decodeSalvaging('config', json, Config.strictFromJson);

  factory Config.strictFromJson(Map<String, Object?> json) =>
      _withLegacyOverrideDns(
        _$ConfigFromJson(_withLegacyTestUrl(_withLegacyRouteMode(json))),
        json,
      );

  factory Config.realFromJson(Map<String, Object?>? json) {
    if (json == null) {
      return Config(
        themeProps: defaultThemeProps,
        hotKeyActions: defaultHotKeyActions,
        appSettingProps: AppSettingProps(
          dashboardWidgets: platformDefaultDashboardWidgets,
        ),
        networkProps: NetworkProps(bypassDomain: platformDefaultBypassDomain),
      );
    }
    return Config.fromJson(json);
  }
}

const _legacyOverrideDnsKey = 'overrideDns';

/// An off `overrideDns` left a profile's own DNS section alone.
Config _withLegacyOverrideDns(Config config, Map<String, Object?> json) {
  if (!json.containsKey(_legacyOverrideDnsKey)) {
    return config;
  }
  final keys = json[_legacyOverrideDnsKey] == true
      ? config.patchClashConfig.dnsOverrideKeys.intersection(
          DnsOverrideKey.normalProfileKeys,
        )
      : <DnsOverrideKey>{};
  return config.copyWith.patchClashConfig(dnsOverrideKeys: keys);
}

/// The test URL moved from the app settings into the general overrides.
Map<String, Object?> _withLegacyTestUrl(Map<String, Object?> json) {
  final app = json['appSettingProps'];
  final testUrl = app is Map ? app['testUrl'] : null;
  final clash = json['patchClashConfig'] ?? const <String, Object?>{};
  if (testUrl is! String ||
      testUrl.isEmpty ||
      clash is! Map ||
      clash.containsKey(GeneralOverrideKey.testUrl.path)) {
    return json;
  }
  return {
    ...json,
    'patchClashConfig': {
      ...Map<String, Object?>.from(clash),
      GeneralOverrideKey.testUrl.path: testUrl,
    },
  };
}

Map<String, Object?> _withLegacyRouteMode(Map<String, Object?> json) {
  final network = json['networkProps'];
  if (network is! Map ||
      !network.containsKey('routeMode') ||
      network.containsKey('bypassPrivateRoute')) {
    return json;
  }
  final bypassPrivate = network['routeMode'] == 'bypassPrivate';
  final clash = json['patchClashConfig'];
  final tun = clash is Map ? clash['tun'] : null;
  return {
    ...json,
    'networkProps': {
      ...Map<String, Object?>.from(network),
      'bypassPrivateRoute': bypassPrivate,
    },
    if (bypassPrivate && clash is Map && tun is Map)
      'patchClashConfig': {
        ...Map<String, Object?>.from(clash),
        'tun': {...Map<String, Object?>.from(tun), 'route-address': <String>[]},
      },
  };
}
