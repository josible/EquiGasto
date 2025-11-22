import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/di/providers.dart';
import 'core/services/play_integrity_service.dart';

const String _googleServerClientId =
    '363848646486-amk51ebf9fqvbqufmk3a9g2a78b014t8.apps.googleusercontent.com';

// Canal de notificaciones para Android (debe ser el mismo que en PushNotificationsService)
const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'expenses_updates',
  'Alertas de gastos',
  description: 'Notificaciones cuando se registran nuevos gastos',
  importance: Importance.high,
);

// Instancia global del plugin de notificaciones locales para el handler de background
final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar notificaciones locales en el isolate de background
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const darwinSettings = DarwinInitializationSettings();
  const initializationSettings = InitializationSettings(
    android: androidSettings,
    iOS: darwinSettings,
    macOS: darwinSettings,
  );

  await _localNotificationsPlugin.initialize(initializationSettings);
  
  // Crear el canal de notificaciones en Android
  await _localNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_androidChannel);

  // Mostrar la notificación
  final notification = message.notification;
  if (notification != null) {
    await _localNotificationsPlugin.show(
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
          showWhen: true,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['groupId'],
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar Play Integrity (App Check)
  final playIntegrityService = PlayIntegrityService();
  await playIntegrityService.initialize();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  unawaited(MobileAds.instance.initialize());
  unawaited(
    GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    ),
  );

  // Configurar listener de deep links
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen(
    (uri) {
      _handleDeepLink(uri);
    },
    onError: (err) {
      debugPrint('Error en deep link: $err');
    },
  );

  // Manejar deep link inicial si la app se abrió desde uno
  appLinks.getInitialLink().then((uri) {
    if (uri != null) {
      _handleDeepLink(uri);
    }
  });

  runApp(const ProviderScope(child: EquiGastoApp()));
}

void _handleDeepLink(Uri uri) {
  debugPrint('🔗 Deep link recibido: $uri');
  debugPrint('🔗 Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');

  // Manejar formato: equigasto://app/join/<code>
  if (uri.scheme == 'equigasto' && uri.host == 'app') {
    final path = uri.path;
    debugPrint('🔗 Path procesado: $path');
    if (path.startsWith('/join/')) {
      final code = path.substring('/join/'.length);
      debugPrint('🔗 Código extraído: $code');
      if (code.isNotEmpty) {
        // Navegar a la ruta de unión
        debugPrint('🔗 Navegando a: /join/$code');
        AppRouter.router.go('/join/$code');
      } else {
        debugPrint('🔗 ERROR: Código vacío');
      }
    } else {
      debugPrint('🔗 ERROR: Path no comienza con /join/');
    }
  } else {
    debugPrint(
        '🔗 ERROR: Scheme u host no coinciden. Esperado: equigasto://app');
  }
}

class EquiGastoApp extends ConsumerStatefulWidget {
  const EquiGastoApp({super.key});

  @override
  ConsumerState<EquiGastoApp> createState() => _EquiGastoAppState();
}

class _EquiGastoAppState extends ConsumerState<EquiGastoApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushNotificationsServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EquiGasto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
