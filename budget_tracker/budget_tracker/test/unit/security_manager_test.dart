import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mayperapa/infrastructure/security/key_management/security_manager.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }
}

class FakeLocalAuthentication extends Fake implements LocalAuthentication {
  bool isSupported = true;
  bool canCheck = true;
  List<BiometricType> biometrics = [BiometricType.fingerprint];
  bool authResult = true;
  Exception? throwOnAuth;
  Exception? throwOnCheck;

  @override
  Future<bool> isDeviceSupported() async {
    if (throwOnCheck != null) throw throwOnCheck!;
    return isSupported;
  }

  @override
  Future<bool> get canCheckBiometrics async {
    if (throwOnCheck != null) throw throwOnCheck!;
    return canCheck;
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (throwOnCheck != null) throw throwOnCheck!;
    return biometrics;
  }

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<dynamic> authMessages = const [],
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    if (throwOnAuth != null) throw throwOnAuth!;
    return authResult;
  }

  @override
  Future<bool> stopAuthentication() async => true;
}

void main() {
  group('SecurityManager Biometrics & Key Management Tests', () {
    late FakeFlutterSecureStorage fakeStorage;
    late FakeLocalAuthentication fakeLocalAuth;
    late SecurityManager securityManager;

    setUp(() {
      fakeStorage = FakeFlutterSecureStorage();
      fakeLocalAuth = FakeLocalAuthentication();
      securityManager = SecurityManager(storage: fakeStorage, localAuth: fakeLocalAuth);
    });

    test('isBiometricAvailable returns true when supported and enrolled', () async {
      final available = await securityManager.isBiometricAvailable();
      expect(available, isTrue);
    });

    test('isBiometricAvailable returns false when no biometrics enrolled or supported', () async {
      fakeLocalAuth.isSupported = false;
      fakeLocalAuth.canCheck = false;
      fakeLocalAuth.biometrics = [];

      final available = await securityManager.isBiometricAvailable();
      expect(available, isFalse);
    });

    test('isBiometricAvailable catches PlatformException safely and returns false', () async {
      fakeLocalAuth.throwOnCheck = PlatformException(
        code: 'no_fragment_activity',
        message: 'local_auth plugin requires the use of a FragmentActivity',
      );

      final available = await securityManager.isBiometricAvailable();
      expect(available, isFalse);
    });

    test('authenticateWithBiometrics returns true on successful auth', () async {
      fakeLocalAuth.authResult = true;
      final result = await securityManager.authenticateWithBiometrics();
      expect(result, isTrue);
    });

    test('authenticateWithBiometrics catches PlatformException safely and returns false', () async {
      fakeLocalAuth.throwOnAuth = PlatformException(
        code: 'NotEnrolled',
        message: 'No biometrics enrolled on device',
      );

      final result = await securityManager.authenticateWithBiometrics();
      expect(result, isFalse);
    });

    test('sets, verifies, and distinguishes correct/incorrect PIN and tracks length', () async {
      expect(await securityManager.hasPINConfigured(), isFalse);
      expect(await securityManager.getPinLength(), equals(4));

      await securityManager.setPIN('1234');
      expect(await securityManager.hasPINConfigured(), isTrue);
      expect(await securityManager.getPinLength(), equals(4));

      expect(await securityManager.verifyPIN('1234'), isTrue);
      expect(await securityManager.verifyPIN('0000'), isFalse);
      expect(await securityManager.verifyPIN('12345'), isFalse);

      await securityManager.setPIN('123456');
      expect(await securityManager.getPinLength(), equals(6));
      expect(await securityManager.verifyPIN('123456'), isTrue);
    });

    test('database encryption key generates and persists idempotently', () async {
      final key1 = await securityManager.getOrCreateDatabaseKey();
      expect(key1, isNotEmpty);

      final key2 = await securityManager.getOrCreateDatabaseKey();
      expect(key1, equals(key2));
    });
  });
}
