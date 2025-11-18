import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AppUpdateService {
  AppUpdateService(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collection = 'app_config';
  static const String _document = 'mobile';

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      final snapshot =
          await _firestore.collection(_collection).doc(_document).get();
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data == null) return;

      final latestVersion = data['latestVersion'] as String?;
      final minSupportedVersion = data['minSupportedVersion'] as String?;
      final updateUrl = data['updateUrl'] as String?;
      final message = data['message'] as String? ??
          'Hay una nueva versión de EquiGasto disponible.';

      if (latestVersion == null || updateUrl == null) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final needsMandatoryUpdate = minSupportedVersion != null &&
          _isVersionLower(currentVersion, minSupportedVersion);
      final hasOptionalUpdate = _isVersionLower(currentVersion, latestVersion);

      if (!needsMandatoryUpdate && !hasOptionalUpdate) return;
      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: !needsMandatoryUpdate,
        builder: (dialogContext) {
          return WillPopScope(
            onWillPop: () async => !needsMandatoryUpdate,
            child: AlertDialog(
              title: const Text('Actualización disponible'),
              content: Text(message),
              actions: [
                if (!needsMandatoryUpdate)
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Más tarde'),
                  ),
                TextButton(
                  onPressed: () async {
                    final uri = Uri.tryParse(updateUrl);
                    if (uri != null) {
                      await launchUrlString(
                        uri.toString(),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                    if (!needsMandatoryUpdate && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Actualizar'),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {
      // Silenciar errores de actualización para no bloquear el inicio
    }
  }

  bool _isVersionLower(String current, String target) {
    final currentParts =
        current.split('.').map(int.tryParse).whereType<int>().toList();
    final targetParts =
        target.split('.').map(int.tryParse).whereType<int>().toList();

    final maxLength = currentParts.length > targetParts.length
        ? currentParts.length
        : targetParts.length;

    for (var i = 0; i < maxLength; i++) {
      final currentValue = i < currentParts.length ? currentParts[i] : 0;
      final targetValue = i < targetParts.length ? targetParts[i] : 0;
      if (currentValue < targetValue) return true;
      if (currentValue > targetValue) return false;
    }

    return false;
  }
}
