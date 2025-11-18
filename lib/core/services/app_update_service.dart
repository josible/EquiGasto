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
      // Incluir el build number en el formato "X.Y.Z+B"
      final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

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
    // Separar versión y build number (formato: "X.Y.Z+B" o "X.Y.Z")
    final currentParts = current.split('+');
    final targetParts = target.split('+');
    
    final currentVersion = currentParts[0];
    final currentBuild = currentParts.length > 1 ? int.tryParse(currentParts[1]) ?? 0 : 0;
    
    final targetVersion = targetParts[0];
    final targetBuild = targetParts.length > 1 ? int.tryParse(targetParts[1]) ?? 0 : 0;
    
    // Comparar versión (X.Y.Z)
    final currentVersionParts =
        currentVersion.split('.').map(int.tryParse).whereType<int>().toList();
    final targetVersionParts =
        targetVersion.split('.').map(int.tryParse).whereType<int>().toList();

    final maxLength = currentVersionParts.length > targetVersionParts.length
        ? currentVersionParts.length
        : targetVersionParts.length;

    for (var i = 0; i < maxLength; i++) {
      final currentValue = i < currentVersionParts.length ? currentVersionParts[i] : 0;
      final targetValue = i < targetVersionParts.length ? targetVersionParts[i] : 0;
      if (currentValue < targetValue) return true;
      if (currentValue > targetValue) return false;
    }
    
    // Si las versiones son iguales, comparar build number
    if (currentBuild < targetBuild) return true;
    if (currentBuild > targetBuild) return false;

    return false;
  }
}
