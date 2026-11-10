import 'package:expense_tracker/core/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

// import 'package:expense_tracker/core/utils/money.dart';

void main() {
  group('Result', () {
    test('Success carries value', () {
      const r = Success<int>(42);
      expect(r.isSuccess, true);
      expect(r.isFailure, false);
      expect(r.valueOrNull, 42);
      expect(r.messageOrNull, isNull);
    });

    test('Failure carries message', () {
      const r = Failure<int>('boom');
      expect(r.isSuccess, false);
      expect(r.isFailure, true);
      expect(r.valueOrNull, isNull);
      expect(r.messageOrNull, 'boom');
    });

    test('exhaustive switch', () {
      String describe(Result<int> r) => switch (r) {
        Success(:final value) => 'ok $value',
        Failure(:final message) => 'err $message',
      };
      expect(describe(const Success(1)), 'ok 1');
      expect(describe(const Failure('x')), 'err x');
    });
  });
}
