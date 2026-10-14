import 'package:mfb_think_tank/features/auth/data/account_deletion_gateway.dart';
import 'package:mfb_think_tank/features/auth/data/app_user.dart';
import 'package:mfb_think_tank/features/auth/data/auth_repository.dart';
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
