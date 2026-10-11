import 'package:flutter_test/flutter_test.dart';
import 'package:mfb_think_tank/features/auth/data/nonce.dart';

void main() {
  test('generateNonce returns random strings of the requested length', () {
    final a = generateNonce();
    final b = generateNonce();
    expect(a, hasLength(32));
    expect(generateNonce(16), hasLength(16));
    expect(a, isNot(b));
  });

  test('sha256OfString returns the hex digest', () {
    expect(
      sha256OfString('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });
}
