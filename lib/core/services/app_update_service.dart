import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AppUpdateService {
  AppUpdateService(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  static const String _latestVersionKey = 'latestVersion';
  static const String _minSupportedVersionKey = 'minSupportedVersion';
  static const String _messageKey = 'message';
  static const String _updateUrlKey = 'updateUrl';

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await _remoteConfig.setDefaults(const {
        _latestVersionKey: '',
        _minSupportedVersionKey: '',
        _messageKey: 'Hay una nueva versión de EquiGasto disponible.',
        _updateUrlKey: '',
      });

      final activated = await _remoteConfig.fetchAndActivate();
      debugPrint('🛰️ Remote Config actualizado: $activated');

      final latestVersion = _remoteConfig.getString(_latestVersionKey).trim();
      final minSupportedVersion =
          _remoteConfig.getString(_minSupportedVersionKey).trim();
      final updateUrl = _remoteConfig.getString(_updateUrlKey).trim();
      final message = _remoteConfig.getString(_messageKey).trim().isEmpty
          ? 'Hay una nueva versión de EquiGasto disponible.'
          : _remoteConfig.getString(_messageKey).trim();

      if (latestVersion.isEmpty || updateUrl.isEmpty) {
        debugPrint('ℹ️ Remote Config sin latestVersion o updateUrl. Se omite.');
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      // Incluir el build number en el formato "X.Y.Z+B"
      final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      final needsMandatoryUpdate = minSupportedVersion.isNotEmpty &&
          _isVersionLower(currentVersion, minSupportedVersion);
      final hasOptionalUpdate = _isVersionLower(currentVersion, latestVersion);

      if (!needsMandatoryUpdate && !hasOptionalUpdate) {
        debugPrint('✅ No se necesita actualización (current: $currentVersion)');
        return;
      }
      if (!context.mounted) {
        debugPrint('ℹ️ Contexto no montado. Se omite diálogo de actualización.');
        return;
      }

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
    } catch (e, stack) {
      debugPrint('⚠️ Error verificando actualizaciones: $e');
      debugPrint('$stack');
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
