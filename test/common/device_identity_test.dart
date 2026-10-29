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
}
