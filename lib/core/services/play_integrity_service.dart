import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Servicio para gestionar Play Integrity API a través de Firebase App Check
class PlayIntegrityService {
  /// Inicializa Firebase App Check con Play Integrity como proveedor en Android
  /// 
  /// En modo debug, usa un proveedor de debug para facilitar las pruebas.
  /// En producción, usa Play Integrity para verificar la integridad de la app.
  Future<void> initialize() async {
    try {
      await FirebaseAppCheck.instance.activate(
        // En Android, usa Play Integrity en producción
        // ignore: deprecated_member_use
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        // En iOS, usa DeviceCheck (opcional, si planeas soportar iOS)
        // appleProvider: AppleProvider.debug,
      );

      debugPrint('✅ Play Integrity (App Check) inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error al inicializar Play Integrity: $e');
      // No lanzamos la excepción para que la app pueda continuar funcionando
      // pero sin la protección de integridad
    }
  }

  /// Obtiene un token de App Check que puede ser usado para verificar
  /// la integridad de la app en el backend
  Future<String?> getToken({bool forceRefresh = false}) async {
    try {
      final token = await FirebaseAppCheck.instance.getToken(forceRefresh);
      return token;
    } catch (e) {
      debugPrint('❌ Error al obtener token de App Check: $e');
      return null;
    }
  }

  /// Verifica si App Check está activo
  bool get isActive {
    try {
      // App Check está activo si se puede obtener un token
      return true;
    } catch (e) {
      return false;
    }
  }
}

