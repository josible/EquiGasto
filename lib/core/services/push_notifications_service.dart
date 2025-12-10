import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../di/providers.dart';

class PushNotificationsService {
  PushNotificationsService(
    this._ref,
    this._messaging,
    this._localNotifications,
  );

  final Ref _ref;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSubscription;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'expenses_updates',
    'Alertas de gastos',
    description: 'Notificaciones cuando se registran nuevos gastos',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermissions();
    await _setupLocalNotifications();

    // Manejar notificaciones cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Manejar cuando el usuario toca una notificación y la app se abre
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Manejar cuando la app se abre desde una notificación (app cerrada)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    _ref.listen<AsyncValue<User?>>(
      authStateProvider,
      (previous, next) {
        final user = next.value;
        if (user != null) {
          unawaited(_registerToken(user.id));
        } else {
          _tokenRefreshSubscription?.cancel();
          _tokenRefreshSubscription = null;
        }
      },
      fireImmediately: true,
    );
  }

  Future<void> _requestPermissions() async {
    final isApplePlatform = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    if (isApplePlatform) {
      await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } else {
      // Para Android, solicitar permisos de Firebase Messaging
      await _messaging.requestPermission();
      
      // Para Android 13+ (API 33+), también solicitar el permiso POST_NOTIFICATIONS
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.notification.request();
        if (status.isDenied) {
          debugPrint('⚠️ Permiso de notificaciones denegado');
        } else if (status.isPermanentlyDenied) {
          debugPrint('⚠️ Permiso de notificaciones permanentemente denegado');
        }
      }
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _localNotifications.initialize(initializationSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<void> _registerToken(String userId) async {
    try {
    final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('⚠️ No se pudo obtener el token FCM');
        return;
      }
      debugPrint('✅ Token FCM obtenido: ${token.substring(0, 20)}...');
    await _saveToken(userId, token);
    _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 Token FCM actualizado: ${newToken.substring(0, 20)}...');
        _saveToken(userId, newToken);
      });
    } catch (e) {
      debugPrint('❌ Error al registrar token FCM: $e');
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    try {
    final firestore = _ref.read(firebaseFirestoreProvider);
    await firestore.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
      debugPrint('✅ Token FCM guardado para usuario: $userId');
    } catch (e) {
      debugPrint('❌ Error al guardar token FCM: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Notificación recibida en foreground');
    debugPrint('📱 Título: ${message.notification?.title}');
    debugPrint('📱 Cuerpo: ${message.notification?.body}');
    debugPrint('📱 Data: ${message.data}');
    
    final notification = message.notification;
    if (notification == null) {
      debugPrint('⚠️ Notificación sin payload de notification, usando data');
      // Si no hay notification, intentar usar data
      final title = message.data['title'] ?? 'Nueva notificación';
      final body = message.data['body'] ?? message.data['message'] ?? '';
      if (title.isEmpty && body.isEmpty) return;
      
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      _localNotifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['groupId'] ?? '',
      );
      return;
    }
    
    // Generar un ID único para la notificación usando timestamp
    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    
    _localNotifications.show(
      notificationId,
      notification.title ?? 'Nueva notificación',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['groupId'] ?? '',
    );
    debugPrint('✅ Notificación mostrada en foreground');
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navegar a la pantalla correspondiente cuando el usuario toca la notificación
    final groupId = message.data['groupId'];
    if (groupId != null && groupId.isNotEmpty) {
      // Navegar al grupo correspondiente
      // Esto se puede implementar según tu lógica de navegación
      debugPrint('📱 Notificación tocada - Grupo: $groupId');
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }
}
