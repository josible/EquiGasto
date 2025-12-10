import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:app_links/app_links.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
  playSound: true,
  enableVibration: true,
  showBadge: true,
);

// Instancia global del plugin de notificaciones locales para el handler de background
final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Handler de background llamado');
  debugPrint('🔔 Título: ${message.notification?.title}');
  debugPrint('🔔 Cuerpo: ${message.notification?.body}');
  debugPrint('🔔 Data: ${message.data}');
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar notificaciones locales en el isolate de background
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const darwinSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
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

  // Mostrar la notificación siempre, incluso si viene solo con data
  final notification = message.notification;
  final title = notification?.title ?? message.data['title'] ?? 'Nueva notificación';
  final body = notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';
  
  debugPrint('🔔 Mostrando notificación - Título: $title, Cuerpo: $body');
  
  if (title.isNotEmpty || body.isNotEmpty) {
    // Generar un ID único para la notificación usando timestamp
    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    
    await _localNotificationsPlugin.show(
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
          ongoing: false,
          autoCancel: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['groupId'] ?? '',
    );
    debugPrint('✅ Notificación mostrada en background');
  } else {
    debugPrint('⚠️ Notificación vacía, no se muestra');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar formato de fecha en español
  await initializeDateFormatting('es_ES', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar Play Integrity (App Check)
  final playIntegrityService = PlayIntegrityService();
  await playIntegrityService.initialize();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  unawaited(MobileAds.instance.initialize());

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
      locale: const Locale('es', 'ES'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
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
        ).copyWith(
          surface: const Color(0xFF1E1E1E),
          surfaceContainerHighest: const Color(0xFF2D2D2D),
          onSurface: Colors.white,
          onSurfaceVariant: Colors.grey[300],
          primary: Colors.blue[400],
          onPrimary: Colors.white,
          secondary: Colors.blue[300],
          onSecondary: Colors.white,
          error: Colors.red[400],
          onError: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardThemeData(
          color: const Color(0xFF2D2D2D),
          elevation: 2,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
