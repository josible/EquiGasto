package com.sire.equigasto

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Habilitar edge-to-edge para Android 15+ y retrocompatibilidad
        // Esto reemplaza las APIs obsoletas setStatusBarColor, setNavigationBarColor, etc.
        // WindowCompat.setDecorFitsSystemWindows permite que el contenido se extienda
        // detrás de las barras del sistema, manejando los insets automáticamente
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // Para Android 15+ (API 35+), asegurar que edge-to-edge esté habilitado
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            // Edge-to-edge está habilitado por defecto en Android 15+ con targetSdk 35
            // Solo necesitamos asegurarnos de que WindowCompat esté configurado
        }
    }
}
