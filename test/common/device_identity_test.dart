import 'dart:convert';

import 'package:fl_clash/common/device_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compactHwid', () {
    test('is the first 16 hex digits of the SHA-256, upper-cased', () {
      expect(compactHwid('machine'), hasLength(16));
      expect(compactHwid('machine'), compactHwid('machine'));
      expect(compactHwid('machine'), isNot(compactHwid('other')));
      expect(compactHwid('machine'), matches(RegExp(r'^[0-9A-F]{16}$')));
    });
  });

  group('subscriptionRequestHeaders', () {
    test('a profile header replaces the device one whatever its case', () {
      final headers = subscriptionRequestHeaders(
        device: {hwidHeader: 'DEVICE', deviceOsHeader: 'Windows'},
        custom: {'X-HWID': 'mine'},
      );

      expect(headers, {deviceOsHeader: 'Windows', 'X-HWID': 'mine'});
    });

    test('keeps every header when nothing overlaps', () {
      expect(
        subscriptionRequestHeaders(
          device: {hwidHeader: 'DEVICE'},
          custom: {'User-Agent': 'client'},
        ),
        {hwidHeader: 'DEVICE', 'User-Agent': 'client'},
      );
    });
  });

  group('deviceRejectionOf', () {
    String? Function(String) headers(Map<String, String> values) =>
        (name) => values[name];

    test('reads the limit and unsupported flags', () {
      expect(
        deviceRejectionOf(headers({deviceLimitReachedHeader: 'TRUE'})),
        DeviceRejection.limitReached,
      );
      expect(
        deviceRejectionOf(headers({deviceIdUnsupportedHeader: 'true'})),
        DeviceRejection.unsupported,
      );
    });

    test('ignores absent and false flags', () {
      expect(deviceRejectionOf(headers({})), isNull);
      expect(
        deviceRejectionOf(headers({deviceLimitReachedHeader: 'false'})),
        isNull,
      );
    });
  });

  group('decodeAnnounce', () {
    test('decodes the base64 form and passes plain text through', () {
      final encoded = 'base64:${base64.encode(utf8.encode('Привет'))}';
      expect(decodeAnnounce(encoded), 'Привет');
      expect(decodeAnnounce('plain'), 'plain');
    });

    test('drops empty and undecodable values', () {
      expect(decodeAnnounce(null), isNull);
      expect(decodeAnnounce('  '), isNull);
      expect(decodeAnnounce('base64:%%%'), isNull);
    });
  });

  group('registryValues', () {
    test('reads the values reg query prints under a key', () {
      const output =
          '\r\n'
          'HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Cryptography\r\n'
          '    MachineGuid    REG_SZ    1b2c3d4e-0000-1111-2222-333344445555\r\n'
          '    ProductName    REG_SZ    Windows 10 Pro\r\n'
          '    InstallDate    REG_DWORD    0x6543210\r\n'
          '\r\n';

      expect(registryValues(output), {
        'MachineGuid': '1b2c3d4e-0000-1111-2222-333344445555',
        'ProductName': 'Windows 10 Pro',
        'InstallDate': '0x6543210',
      });
    });
  });

  group('windowsProductName', () {
    test('names Windows 11 by its build', () {
      expect(
        windowsProductName({
          'ProductName': 'Windows 10 Pro',
          'CurrentBuildNumber': '22631',
        }),
        'Windows 11 Pro',
      );
      expect(
        windowsProductName({
          'ProductName': 'Windows 10 Pro',
          'CurrentBuildNumber': '19045',
        }),
        'Windows 10 Pro',
      );
      expect(windowsProductName({}), isNull);
    });
  });

  test('ioregPlatformUuid reads IOPlatformUUID', () {
    expect(
      ioregPlatformUuid(
        '  | "IOPlatformSerialNumber" = "C02X"\n'
        '  | "IOPlatformUUID" = "0A1B2C3D-4E5F-6071-8293-A4B5C6D7E8F9"\n',
      ),
      '0A1B2C3D-4E5F-6071-8293-A4B5C6D7E8F9',
    );
    expect(ioregPlatformUuid(''), isNull);
  });

  test('osRelease unquotes values and skips comments', () {
    expect(
      osRelease(
        '# comment\n'
        'NAME="Arch Linux"\n'
        "VERSION_ID='24.04'\n"
        'ID=arch\n'
        'broken\n',
      ),
      {'NAME': 'Arch Linux', 'VERSION_ID': '24.04', 'ID': 'arch'},
    );
  });
}
