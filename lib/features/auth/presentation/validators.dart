/// Form validators shared by the auth screens. Return null when valid.
abstract final class Validators {
  static const minPasswordLength = 8;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email';
    return null;
  }

  /// Presence-only check, for signing in.
  static String? requiredPassword(String? value) =>
      (value == null || value.isEmpty) ? 'Enter your password' : null;

  /// Strength check, for creating a password. Keep in sync with the password
  /// policy in Firebase console > Authentication > Settings, if you set one.
  static String? newPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Enter a password';
    if (password.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters';
    }
    if (!password.contains(RegExp('[A-Za-z]')) ||
        !password.contains(RegExp('[0-9]'))) {
      return 'Use both letters and numbers';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(
    String Function() original,
  ) =>
      (value) => value == original() ? null : 'Passwords do not match';
}
