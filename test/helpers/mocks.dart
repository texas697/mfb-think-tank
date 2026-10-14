import 'package:firebase_auth/firebase_auth.dart';
import 'package:mfb_think_tank/features/auth/data/account_deletion_gateway.dart';
import 'package:mfb_think_tank/features/auth/data/app_user.dart';
import 'package:mfb_think_tank/features/auth/data/apple_sign_in_gateway.dart';
import 'package:mfb_think_tank/features/auth/data/auth_repository.dart';
import 'package:mfb_think_tank/features/auth/data/google_sign_in_gateway.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// A signed-in [AppUser] with sensible defaults for widget tests.
AppUser fakeAppUser({
  String uid = 'u1',
  String? email = 'ann@example.com',
  String? displayName = 'Ann',
  bool emailVerified = true,
  List<String> providerIds = const [AuthProviderIds.password],
}) => AppUser(
  uid: uid,
  email: email,
  displayName: displayName,
  emailVerified: emailVerified,
  providerIds: providerIds,
);

class MockAccountDeletionGateway extends Mock
    implements AccountDeletionGateway {}

class MockGoogleSignInGateway extends Mock implements GoogleSignInGateway {}

class MockAppleSignInGateway extends Mock implements AppleSignInGateway {}

/// mocktail-based Firebase fakes, for flows `firebase_auth_mocks` does not
/// cover (provider data, re-authentication, token revocation).
class MockFirebaseAuthStrict extends Mock implements FirebaseAuth {}

class MockFirebaseUser extends Mock implements User {}

class FakeAuthCredential extends Fake implements AuthCredential {}

class FakeUserCredential extends Fake implements UserCredential {}

class FakeUserInfo extends Fake implements UserInfo {
  FakeUserInfo(this.providerId);

  @override
  final String providerId;
}

/// Call once in `setUpAll` before using `any()` with these types.
void registerAuthFallbackValues() {
  registerFallbackValue(FakeAuthCredential());
}
