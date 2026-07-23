import 'package:flutter_test/flutter_test.dart';
import 'package:kongsi/core/error/app_error.dart';
import 'package:kongsi/core/result/result.dart';

// Result Unit Test
void main() {
  group('Result', () {
    test('Success carries its value', () {
      const result = Success<int>(42);
      expect(result.value, 42);
    });

    test('Failure carries its AppError', () {
      const error = NetworkError(message: 'offline');
      const result = Failure<int>(error);
      expect(result.error, same(error));
    });

    test('pattern-matches exhaustively over the sealed hierarchy', () {
      String describe(Result<int> r) => switch (r) {
        Success(:final value) => 'ok:$value',
        Failure(:final error) => 'err:${error.message}',
      };

      expect(describe(const Success(1)), 'ok:1');
      expect(
        describe(const Failure(ValidationError(message: 'bad'))),
        'err:bad',
      );
    });
  });
}
