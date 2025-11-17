# 📱 Configuración de Publicidad con Firebase AdMob

## ✅ Paso 1: Permiso agregado en AndroidManifest.xml

Ya se ha agregado el permiso necesario en `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="com.google.android.gms.permission.AD_ID"/>
```

## 📋 Paso 2: Declaración en Google Play Console

### Configurar la declaración de ID de publicidad:

1. **Ve a Google Play Console**: https://play.google.com/console
2. **Selecciona tu app** (EquiGasto)
3. **Ve a**: Política → Contenido de la app → ID de publicidad
4. **Selecciona**: "Sí, mi app usa un ID de publicidad"
5. **Indica el uso**:
   - ✅ Publicidad
   - ✅ Analíticas
   - ✅ Fraude/prevención de abusos
   - ✅ Seguridad
   - ✅ Personalización
   - (Selecciona los que apliquen a tu caso)

6. **Guarda los cambios**

## 🔧 Paso 3: Agregar dependencia de AdMob (Opcional - si aún no lo has hecho)

Si aún no has agregado AdMob a tu proyecto, agrega esta dependencia en `pubspec.yaml`:

```yaml
dependencies:
  google_mobile_ads: ^5.0.0  # O la versión más reciente
```

Luego ejecuta:
```bash
flutter pub get
```

## 📝 Paso 4: Configurar AdMob en Firebase

1. **Ve a Firebase Console**: https://console.firebase.google.com/
2. **Selecciona tu proyecto** (equigasto)
3. **Ve a**: Monetización → AdMob
4. **Vincula tu cuenta de AdMob** (o créala si no la tienes)
5. **Obtén tu App ID** de AdMob

## 🔑 Paso 5: Agregar App ID de AdMob al AndroidManifest

Después de obtener tu App ID de AdMob, agrégalo al `AndroidManifest.xml`:

```xml
<application>
    <!-- ... otros elementos ... -->
    
    <!-- AdMob App ID -->
    <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
</application>
```

**Nota**: Reemplaza `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX` con tu App ID real de AdMob.

## 📱 Paso 6: Configurar IDs de Banner en el Código

Ya se ha implementado un banner pequeño en la parte inferior de la pantalla principal. Para usar publicidad real:

1. **Obtén tu Banner Ad Unit ID** de AdMob:
   - Ve a AdMob Console → Apps → Tu app → Ad units
   - Crea un nuevo "Banner" ad unit
   - Copia el Ad Unit ID (formato: `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`)

2. **Actualiza el código**:
   - Abre `lib/core/widgets/ad_banner.dart`
   - Reemplaza `BannerAd.testAdUnitId` con tu Banner Ad Unit ID real:
   ```dart
   _bannerAd = BannerAd(
     adUnitId: 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX', // Tu ID real
     size: AdSize.banner,
     // ...
   );
   ```

3. **Actualiza el App ID en main.dart** (opcional, pero recomendado):
   - Abre `lib/main.dart`
   - Si quieres inicializar con tu App ID específico, puedes hacerlo así:
   ```dart
   MobileAds.instance.initialize();
   // O con App ID específico:
   // MobileAds.instance.initialize().then((status) {
   //   // AdMob inicializado
   // });
   ```

## ✅ Características del Banner Implementado

- ✅ **No invasivo**: Banner pequeño en la parte inferior (320x50 píxeles)
- ✅ **Solo se muestra si carga**: Si falla, no se muestra nada
- ✅ **Visible en todas las pestañas**: Aparece en Inicio, Grupos y Configuración
- ✅ **No interrumpe la experiencia**: El contenido principal sigue siendo accesible

## ✅ Paso 7: Regenerar AAB

Después de hacer estos cambios:

```bash
flutter clean
flutter build appbundle --release
```

## 📌 Notas Importantes

- El permiso `AD_ID` ya está agregado en el AndroidManifest
- La declaración en Play Console es **obligatoria** si usas publicidad
- Sin el permiso, el ID de publicidad será todo ceros y perderás ingresos
- El App ID de AdMob es diferente para cada plataforma (Android/iOS)

## 🔍 Verificación

Para verificar que todo está correcto:

1. ✅ Permiso agregado en AndroidManifest.xml
2. ✅ Declaración actualizada en Play Console
3. ✅ App ID de AdMob configurado (si usas AdMob)
4. ✅ AAB regenerado con los cambios

