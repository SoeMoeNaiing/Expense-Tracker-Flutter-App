import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/utils/money.dart';

void main() {
  group('Money.format', () {
    test('zero', () => expect(const Money(0).format(), '0 Ks'));
    test('small no comma', () => expect(const Money(999).format(), '999 Ks'));
    test('thousands', () => expect(const Money(1500).format(), '1,500 Ks'));
    test(
      'millions',
      () => expect(const Money(1500000).format(), '1,500,000 Ks'),
    );
    test('negative', () => expect(const Money(-2500).format(), '-2,500 Ks'));
    test(
      'custom suffix',
      () => expect(const Money(100).format(suffix: 'MMK'), '100 MMK'),
    );
  });

  group('Money arithmetic', () {
    test(
      'add',
      () => expect(const Money(100) + const Money(250), const Money(350)),
    );
    test(
      'sub',
      () => expect(const Money(500) - const Money(250), const Money(250)),
    );
    test('equality', () {
      expect(const Money(100), const Money(100));
      expect(const Money(100) == const Money(101), false);
    });
  });
}
