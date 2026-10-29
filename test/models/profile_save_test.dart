import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Locale;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/device_identity.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod/riverpod.dart';

import '../helpers/app_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('profile_save_test');
    await useAppPaths(tempDir);
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('Profile.saveFile', () {
    // EditProfileView relies on this throwing rather than silently
    // succeeding, so a caller-level try/catch can surface the failure.
    test('rejects an invalid config without touching the saved file', () async {
      final profile = Profile.normal(label: 'p');
      final bytes = Uint8List.fromList(utf8.encode('bad: ['));

      await expectLater(
        profile.saveFile(bytes, validate: (_, _) async => 'invalid config'),
        throwsA(
          isA<MessageException>().having(
            (e) => e.message,
            'message',
            'invalid config',
          ),
        ),
      );

      final savedFile = await profile.file;
      expect(await savedFile.length(), 0);
    });

    test('copies validated bytes and stamps the update time', () async {
      final profile = Profile.normal(label: 'p');
      final bytes = Uint8List.fromList(utf8.encode('proxies: []'));

      final saved = await profile.saveFile(bytes, validate: (_, _) async => '');

      expect(saved.lastUpdateDate, isNotNull);
      final savedFile = await profile.file;
      expect(await savedFile.readAsString(), 'proxies: []');
    });

    test('validates with the profile age key', () async {
      final profile = Profile.normal(
        label: 'p',
      ).copyWith(ageSecretKey: 'AGE-SECRET-KEY-1A');
      final bytes = Uint8List.fromList(utf8.encode('proxies: []'));
      String? ageSecretKey;

      await profile.saveFile(
        bytes,
        validate: (_, key) async {
          ageSecretKey = key;
          return '';
        },
      );

      expect(ageSecretKey, 'AGE-SECRET-KEY-1A');
    });
  });

  /// The test binding answers every request with a 400, so its override is
  /// lifted for a real download over loopback.
  group('Profile.update', () {
    late HttpServer server;
    late HttpHeaders received;
    late Map<String, String> replyHeaders;

    setUp(() async {
      globalState.packageInfo = PackageInfo(
        appName: 'FlClash',
        packageName: 'com.follow.clash',
        version: '1.0.0',
        buildNumber: '1',
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      globalState.container = container;
      final bindingOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = bindingOverrides);
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      replyHeaders = {};
      server.listen((request) async {
        received = request.headers;
        replyHeaders.forEach(request.response.headers.set);
        request.response.write('proxies: []');
        await request.response.close();
      });
    });

    test('sends the profile headers with the download', () async {
      final profile = Profile.normal(
        url: 'http://127.0.0.1:${server.port}/sub',
      ).copyWith(headers: {'x-hwid': 'abc123', 'User-Agent': 'client/1.0'});

      await profile.update(validate: (_, _) async => '');

      expect(received.value('x-hwid'), 'abc123');
      expect(received.value(HttpHeaders.userAgentHeader), 'client/1.0');
    });

    test('sends the device headers under the profile ones', () async {
      final profile = Profile.normal(
        url: 'http://127.0.0.1:${server.port}/sub',
      ).copyWith(headers: {'X-HWID': 'mine'});

      await profile.update(
        validate: (_, _) async => '',
        deviceHeaders: () async => {hwidHeader: 'DEVICE', deviceOsHeader: 'Linux'},
      );

      expect(received.value(hwidHeader), 'mine');
      expect(received.value(deviceOsHeader), 'Linux');
    });

    test('sends no device headers when the profile turns them off', () async {
      final profile = Profile.normal(
        url: 'http://127.0.0.1:${server.port}/sub',
      ).copyWith(sendDeviceHeaders: false);

      await profile.update(
        validate: (_, _) async => '',
        deviceHeaders: () async => {hwidHeader: 'DEVICE'},
      );

      expect(received.value(hwidHeader), isNull);
    });

    test('a device limit fails the update and keeps the saved file', () async {
      await AppLocalizations.load(const Locale('en'));
      final profile = Profile.normal(
        url: 'http://127.0.0.1:${server.port}/sub',
      );
      final savedFile = await profile.file;
      await savedFile.writeAsString('proxies: [kept]');
      replyHeaders = {
        deviceLimitReachedHeader: 'true',
        announceHeader: 'base64:${base64.encode(utf8.encode('Remove a device'))}',
      };

      await expectLater(
        profile.update(
          validate: (_, _) async => '',
          deviceHeaders: () async => {hwidHeader: 'DEVICE'},
        ),
        throwsA(
          isA<MessageException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains(currentAppLocalizations.deviceLimitReached),
              contains('Remove a device'),
            ),
          ),
        ),
      );
      expect(await savedFile.readAsString(), 'proxies: [kept]');
    });

    test('URL credentials win over an Authorization header', () async {
      final profile = Profile.normal(
        url: 'http://me:pw@127.0.0.1:${server.port}/sub',
      ).copyWith(headers: {'Authorization': 'Bearer token'});

      await profile.update(validate: (_, _) async => '');

      expect(received[HttpHeaders.authorizationHeader], [
        'Basic ${base64.encode(utf8.encode('me:pw'))}',
      ]);
    });
  });
}
