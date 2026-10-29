import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'app_localizations.dart';
import 'print.dart';

const hwidHeader = 'x-hwid';
const deviceOsHeader = 'x-device-os';
const deviceOsVersionHeader = 'x-ver-os';
const deviceModelHeader = 'x-device-model';
const deviceLimitReachedHeader = 'x-hwid-max-devices-reached';
const deviceIdUnsupportedHeader = 'x-hwid-not-supported';
const announceHeader = 'announce';

const _cryptographyKey = r'HKLM\SOFTWARE\Microsoft\Cryptography';
const _currentVersionKey = r'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion';
const _compactHwidLength = 16;
const _firstWindows11Build = 22000;

typedef DeviceHeaders = Future<Map<String, String>> Function();

typedef _Details = ({String? id, String os, String? version, String? model});

class DeviceIdentity {
  Future<Map<String, String>>? _headers;

  Future<Map<String, String>> headers() => _headers ??= _resolve();

  Future<Map<String, String>> _resolve() async {
    try {
      final details = await _platformDetails();
      if (details == null) {
        return const {};
      }
      final id = details.id;
      final hwid = id == null || id.isEmpty
          ? null
          : Platform.isAndroid
          ? id
          : compactHwid(id);
      return {
        hwidHeader: ?hwid,
        deviceOsHeader: details.os,
        if (details.version case final version? when version.isNotEmpty)
          deviceOsVersionHeader: version,
        if (details.model case final model? when model.isNotEmpty)
          deviceModelHeader: model,
      };
    } catch (error) {
      commonPrint.log('device identity unavailable: $error');
      return const {};
    }
  }

  Future<_Details?> _platformDetails() async {
    if (Platform.isAndroid) {
      final info = await app!.getDeviceIdentity();
      final id = info['androidId'];
      return (
        id: id != null && id.isNotEmpty
            ? id
            : '${info['brand']}-${info['device']}-${info['hardware']}-'
                  '${info['buildId']}',
        os: 'Android',
        version: info['release'],
        model: '${info['manufacturer']} ${info['model']}',
      );
    }
    if (Platform.isWindows) {
      final crypto = registryValues(
        await _run('reg', ['query', _cryptographyKey]),
      );
      final current = registryValues(
        await _run('reg', ['query', _currentVersionKey]),
      );
      return (
        id: crypto['MachineGuid'] ?? Platform.localHostname,
        os: 'Windows',
        version: current['DisplayVersion'],
        model: windowsProductName(current),
      );
    }
    if (Platform.isMacOS) {
      final uuid = ioregPlatformUuid(
        await _run('ioreg', ['-rd1', '-c', 'IOPlatformExpertDevice']),
      );
      final model = (await _run('sysctl', ['-n', 'hw.model'])).trim();
      return (
        id: uuid ?? '$model-${Platform.localHostname}',
        os: 'macOS',
        version: (await _run('sw_vers', ['-productVersion'])).trim(),
        model: model,
      );
    }
    if (Platform.isLinux) {
      final release = osRelease(
        _readFirst(['/etc/os-release', '/usr/lib/os-release']) ?? '',
      );
      final machineId = _readFirst([
        '/etc/machine-id',
        '/var/lib/dbus/machine-id',
      ])?.trim();
      return (
        id: machineId != null && machineId.isNotEmpty
            ? machineId
            : '${release['ID'] ?? 'linux'}-${release['NAME'] ?? 'Linux'}',
        os: 'Linux',
        version: release['VERSION_ID'],
        model: release['NAME'] ?? 'Linux',
      );
    }
    return null;
  }

  Future<String> _run(String executable, List<String> arguments) async {
    try {
      final result = await Process.run(executable, arguments);
      return result.exitCode == 0 ? result.stdout.toString() : '';
    } on ProcessException {
      return '';
    }
  }

  String? _readFirst(List<String> paths) {
    for (final path in paths) {
      final file = File(path);
      try {
        if (file.existsSync()) {
          return file.readAsStringSync();
        }
      } on FileSystemException {
        continue;
      }
    }
    return null;
  }
}

final _registryLine = RegExp(r'^\s+(\S+)\s+REG_\w+\s+(.*?)\s*$');

/// Values of one key as `reg query` prints them.
@visibleForTesting
Map<String, String> registryValues(String output) {
  return {
    for (final line in const LineSplitter().convert(output))
      if (_registryLine.firstMatch(line) case final match?)
        match[1]!: match[2]!,
  };
}

/// Windows 11 still names itself Windows 10 in `ProductName`.
@visibleForTesting
String? windowsProductName(Map<String, String> currentVersion) {
  final name = currentVersion['ProductName'];
  final build = int.tryParse(currentVersion['CurrentBuildNumber'] ?? '');
  if (name == null || build == null || build < _firstWindows11Build) {
    return name;
  }
  return name.replaceFirst('Windows 10', 'Windows 11');
}

final _ioregUuid = RegExp(r'"IOPlatformUUID"\s*=\s*"([^"]+)"');

@visibleForTesting
String? ioregPlatformUuid(String output) => _ioregUuid.firstMatch(output)?[1];

/// `KEY=value` lines of os-release(5), quotes dropped.
@visibleForTesting
Map<String, String> osRelease(String text) {
  final values = <String, String>{};
  for (final line in const LineSplitter().convert(text)) {
    final index = line.indexOf('=');
    if (index <= 0 || line.trimLeft().startsWith('#')) {
      continue;
    }
    var value = line.substring(index + 1).trim();
    if (value.length >= 2 &&
        (value[0] == '"' || value[0] == "'") &&
        value[value.length - 1] == value[0]) {
      value = value.substring(1, value.length - 1);
    }
    values[line.substring(0, index).trim()] = value;
  }
  return values;
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
