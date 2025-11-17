import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  LocalAuthService(this._localAuth);

  final LocalAuthentication _localAuth;

  Future<bool> authenticate() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        return true;
      }

      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        return await _localAuth.authenticate(
          localizedReason: 'Confirma tu identidad para continuar.',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
      }

      return await _localAuth.authenticate(
        localizedReason: 'Confirma tu identidad para continuar.',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error en autenticación biométrica: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }
}
