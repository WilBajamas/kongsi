import 'package:flutter_test/flutter_test.dart';
import 'package:kongsi/core/validation/validators.dart';

void main() {
  group('isValidEmail', () {
    test('accepts an ordinary address', () {
      expect(isValidEmail('ali@example.com'), isTrue);
      expect(isValidEmail('ali.bin.abu+tag@mail.example.co.uk'), isTrue);
    });

    test('trims surrounding spaces before judging', () {
      expect(isValidEmail('  ali@example.com  '), isTrue);
    });

    test('rejects the shapes people actually mistype', () {
      expect(isValidEmail(null), isFalse);
      expect(isValidEmail(''), isFalse);
      expect(isValidEmail('ali'), isFalse);
      expect(isValidEmail('ali@'), isFalse);
      expect(isValidEmail('ali@example'), isFalse); // no dot
      expect(isValidEmail('ali example@mail.com'), isFalse); // space inside
      expect(isValidEmail('a@b@c.com'), isFalse); // two @
    });
  });

  group('isValidPassword', () {
    test('accepts anything at or over the minimum', () {
      expect(isValidPassword('a' * minPasswordLength), isTrue);
      expect(isValidPassword('a' * (minPasswordLength + 5)), isTrue);
    });

    test('rejects short or missing values', () {
      expect(isValidPassword(null), isFalse);
      expect(isValidPassword(''), isFalse);
      expect(isValidPassword('a' * (minPasswordLength - 1)), isFalse);
    });

    // Deliberate: length is the only rule. Blocking spaces or demanding symbols
    // pushes people toward weaker, more memorable passwords.
    test('does not object to spaces or simple characters', () {
      expect(isValidPassword('correct horse battery'), isTrue);
    });
  });
}
