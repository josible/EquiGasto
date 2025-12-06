import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    // Banner estándar 320x50, colocado en la parte inferior de la pantalla.
    // En debug usamos el ID de prueba oficial de Google para evitar problemas de políticas,
    // en release usamos tu ID real de bloque de anuncios.
    final adUnitId = kReleaseMode
        ? 'ca-app-pub-5041837614112889/3734700605' // ID real (Android, EquiGasto)
        : 'ca-app-pub-3940256099942544/6300978111'; // ID de prueba oficial (Android)

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner, // Banner estándar
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          // Log para depurar por qué no se muestra el anuncio (por ejemplo, no hay fill).
          debugPrint('❌ BannerAd failed to load: ${error.code} - ${error.message}');
          // Si falla, no mostramos el banner (no invasivo)
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink(); // No mostrar nada si no hay ad
    }

    return SafeArea(
      top: false,
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: _bannerAd!.size.height.toDouble(),
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}

