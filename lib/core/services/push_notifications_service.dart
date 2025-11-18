import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  );

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermissions();
    await _setupLocalNotifications();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

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
      await _messaging.requestPermission();
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
    final token = await _messaging.getToken();
    if (token == null) return;
    await _saveToken(userId, token);
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh
        .listen((newToken) => _saveToken(userId, newToken));
  }

  Future<void> _saveToken(String userId, String token) async {
    final firestore = _ref.read(firebaseFirestoreProvider);
    await firestore.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['groupId'],
    );
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }
}
