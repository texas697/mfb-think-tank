import 'package:flutter_test/flutter_test.dart';
import 'package:mfb_think_tank/features/auth/presentation/validators.dart';

void main() {
  test('email', () {
    expect(Validators.email(null), isNotNull);
    expect(Validators.email('  '), isNotNull);
    expect(Validators.email('not-an-email'), isNotNull);
    expect(Validators.email('a@b'), isNotNull);
    expect(Validators.email(' ann@example.com '), isNull);
  });

  test('requiredPassword only checks presence', () {
    expect(Validators.requiredPassword(''), isNotNull);
    expect(Validators.requiredPassword('x'), isNull);
  });

  test('newPassword enforces length and letters+numbers', () {
    expect(Validators.newPassword(''), isNotNull);
    expect(Validators.newPassword('abc123'), contains('at least'));
    expect(Validators.newPassword('abcdefgh'), contains('letters and numbers'));
    expect(Validators.newPassword('12345678'), contains('letters and numbers'));
    expect(Validators.newPassword('abcd1234'), isNull);
  });

  test('confirmPassword compares with the original', () {
    var original = 'abcd1234';
    final validate = Validators.confirmPassword(() => original);
    expect(validate('abcd1234'), isNull);
    expect(validate('other'), 'Passwords do not match');
    original = 'other';
    expect(validate('other'), isNull);
  });
}
