import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_for_jalanidhi/core/utils/validators.dart';

/// Tests for [Validators], the form field checks. Each validator returns
/// `null` when the value is valid and an error message otherwise.
void main() {
  // One test per validator: invalid values give a message, valid give null.
  group('Validators', () {
    test('required rejects null, empty and blank', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
      expect(Validators.required('x'), isNull);
    });

    test('email', () {
      expect(Validators.email('nope'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email('a@b.co'), isNull);
    });

    test('password enforces minimum length', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });

    test('confirmPassword must match', () {
      expect(Validators.confirmPassword('abc123', 'abc124'), isNotNull);
      expect(Validators.confirmPassword('abc123', 'abc123'), isNull);
    });
  });
}
