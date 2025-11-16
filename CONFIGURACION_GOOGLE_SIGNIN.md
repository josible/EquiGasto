# Configuración de Google Sign-In

## ⚠️ Problema: People API no habilitada

El error indica que la People API no está habilitada en tu proyecto de Google Cloud. **Esta API es necesaria para que Google Sign-In funcione correctamente en web.**

### ✅ Solución: Habilitar People API (OBLIGATORIO)

**Pasos:**
1. Ve a Google Cloud Console: https://console.cloud.google.com/
2. Selecciona el proyecto: **equigasto** (ID: 363848646486)
3. Ve a **APIs & Services** > **Library**
4. Busca "People API"
5. Haz clic en "Enable"
6. Espera 5-10 minutos para que se propague

**🔗 URL directa para habilitar:**
https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=363848646486

**Nota:** Esta API es gratuita y solo se usa para obtener información básica del perfil (email, nombre, foto) durante el inicio de sesión. No genera costos adicionales.

## Configuración actual

### Web
- **ClientID**: Configurado en `web/index.html` como meta tag
- **ClientID**: `363848646486-amk51ebf9fqvbqufmk3a9g2a78b014t8.apps.googleusercontent.com`

### Android
- **google-services.json**: Ubicado en `android/app/google-services.json`
- **ClientIDs**: Configurados automáticamente desde el archivo

### iOS
- **GoogleService-Info.plist**: Debe estar en `ios/Runner/GoogleService-Info.plist`
- **ClientID**: Configurado automáticamente desde el archivo

## Verificación

1. **Web**: El meta tag en `web/index.html` debe contener el ClientID correcto
2. **Android**: El archivo `google-services.json` debe estar en `android/app/`
3. **iOS**: El archivo `GoogleService-Info.plist` debe estar en `ios/Runner/`

## Notas importantes

- El ClientID es el mismo para desarrollo y producción
- La People API solo es necesaria si quieres acceder a información adicional del perfil de Google
- Firebase Auth proporciona suficiente información (email, nombre, foto) sin necesidad de People API
- Si habilitas la People API, espera 5-10 minutos después de habilitarla antes de probar

