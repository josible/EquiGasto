import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';

const String _googleServerClientId =
    '363848646486-amk51ebf9fqvbqufmk3a9g2a78b014t8.apps.googleusercontent.com';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  unawaited(MobileAds.instance.initialize());
  unawaited(
    GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    ),
  );

  runApp(const ProviderScope(child: EquiGastoApp()));
}

class EquiGastoApp extends StatelessWidget {
  const EquiGastoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EquiGasto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
