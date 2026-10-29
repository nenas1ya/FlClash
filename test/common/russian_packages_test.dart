import 'package:fl_clash/common/russian_packages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches listed Russian apps by exact package name', () {
    expect(isRussianPackage('ru.sberbankmobile'), isTrue);
    expect(isRussianPackage('com.avito.android'), isTrue);
    expect(isRussianPackage('ru.yandex.taxi'), isTrue);
  });

  test('leaves other apps and partial names alone', () {
    expect(isRussianPackage('com.google.android.youtube'), isFalse);
    expect(isRussianPackage('ru.yandex'), isFalse);
    expect(isRussianPackage(''), isFalse);
  });
}
