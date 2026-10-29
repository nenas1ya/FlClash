import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:win32_registry/win32_registry.dart';

import 'app_localizations.dart';
import 'print.dart';

const hwidHeader = 'x-hwid';
const deviceOsHeader = 'x-device-os';
const deviceOsVersionHeader = 'x-ver-os';
const deviceModelHeader = 'x-device-model';
const deviceLimitReachedHeader = 'x-hwid-max-devices-reached';
const deviceIdUnsupportedHeader = 'x-hwid-not-supported';
const announceHeader = 'announce';

const _machineGuidKey = r'SOFTWARE\Microsoft\Cryptography';
const _compactHwidLength = 16;

typedef DeviceHeaders = Future<Map<String, String>> Function();

class DeviceIdentity {
  DeviceIdentity({DeviceInfoPlugin? plugin})
    : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;
  Future<Map<String, String>>? _headers;

  Future<Map<String, String>> headers() => _headers ??= _resolve();

  Future<Map<String, String>> _resolve() async {
    try {
      final (id, os, version, model) = await _platformDetails();
      final hwid = id == null || id.isEmpty
          ? null
          : Platform.isAndroid
          ? id
          : compactHwid(id);
      return {
        hwidHeader: ?hwid,
        deviceOsHeader: ?os,
        if (version != null && version.isNotEmpty)
          deviceOsVersionHeader: version,
        if (model != null && model.isNotEmpty) deviceModelHeader: model,
      };
    } catch (error) {
      commonPrint.log('device identity unavailable: $error');
      return const {};
    }
  }

  Future<(String?, String?, String?, String?)> _platformDetails() async {
    if (Platform.isAndroid) {
      final info = await _plugin.androidInfo;
      final id = await app?.getAndroidId();
      return (
        id != null && id.isNotEmpty
            ? id
            : '${info.brand}-${info.device}-${info.hardware}-${info.id}',
        'Android',
        info.version.release,
        '${info.manufacturer} ${info.model}',
      );
    }
    if (Platform.isWindows) {
      final info = await _plugin.windowsInfo;
      return (
        _machineGuid() ??
            '${info.computerName}-${info.deviceId}-${info.productId}',
        'Windows',
        info.displayVersion,
        info.productName,
      );
    }
    if (Platform.isMacOS) {
      final info = await _plugin.macOsInfo;
      return (
        info.systemGUID ?? '${info.model}-${info.computerName}',
        'macOS',
        info.osRelease,
        info.model,
      );
    }
    if (Platform.isLinux) {
      final info = await _plugin.linuxInfo;
      return (
        info.machineId ?? '${info.id}-${info.name}',
        'Linux',
        info.versionId,
        info.name,
      );
    }
    return (null, null, null, null);
  }

  String? _machineGuid() {
    try {
      final key = LOCAL_MACHINE.open(_machineGuidKey);
      try {
        return switch (key.getValue('MachineGuid')) {
          StringValue(:final value) => value,
          _ => null,
        };
      } finally {
        key.close();
      }
    } catch (_) {
      return null;
    }
  }
}

@visibleForTesting
String compactHwid(String id) => sha256
    .convert(utf8.encode(id))
    .toString()
    .substring(0, _compactHwidLength)
    .toUpperCase();

Map<String, String> subscriptionRequestHeaders({
  required Map<String, String> device,
  required Map<String, String> custom,
}) {
  final overridden = {for (final key in custom.keys) key.toLowerCase()};
  return {
    for (final MapEntry(:key, :value) in device.entries)
      if (!overridden.contains(key.toLowerCase())) key: value,
    ...custom,
  };
}

enum DeviceRejection { limitReached, unsupported }

DeviceRejection? deviceRejectionOf(String? Function(String name) header) {
  bool flag(String name) => header(name)?.trim().toLowerCase() == 'true';
  if (flag(deviceLimitReachedHeader)) {
    return DeviceRejection.limitReached;
  }
  if (flag(deviceIdUnsupportedHeader)) {
    return DeviceRejection.unsupported;
  }
  return null;
}

String deviceRejectionMessage(
  DeviceRejection rejection, {
  required bool hwidSent,
  String? announce,
}) {
  final appLocalizations = currentAppLocalizations;
  final reason = switch (rejection) {
    DeviceRejection.limitReached => appLocalizations.deviceLimitReached,
    DeviceRejection.unsupported when hwidSent =>
      appLocalizations.deviceIdUnsupported,
    DeviceRejection.unsupported => appLocalizations.deviceIdNotSent,
  };
  return announce == null ? reason : '$reason\n\n$announce';
}

String? decodeAnnounce(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  const prefix = 'base64:';
  if (!value.startsWith(prefix)) {
    return value;
  }
  try {
    final text = utf8.decode(base64.decode(value.substring(prefix.length)));
    return text.trim().isEmpty ? null : text.trim();
  } catch (_) {
    return null;
  }
}

DeviceIdentity deviceIdentity = DeviceIdentity();
