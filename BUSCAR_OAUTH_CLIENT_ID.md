# 🔍 Cómo encontrar el OAuth 2.0 Client ID para Android

## ❗ Importante

Estás viendo la configuración de una **API Key**, pero para Google Sign-In necesitas encontrar el **OAuth 2.0 Client ID** (es diferente).

## 📋 Pasos para encontrar el OAuth 2.0 Client ID

### Paso 1: Ve a Credenciales
1. Estás en: **APIs & Services** > **Credenciales**
2. Ya estás en la página correcta ✅

### Paso 2: Busca "OAuth 2.0 Client IDs"
1. **Desplázate hacia abajo** en la página de credenciales
2. Busca la sección **"OAuth 2.0 Client IDs"** (no "API Keys")
3. Deberías ver algo como:
   ```
   OAuth 2.0 Client IDs
   ├── Web client (auto created by Google Service)
   ├── Android client (auto created by Google Service)  ← ESTE
   └── iOS client (auto created by Google Service)
   ```

### Paso 3: Haz clic en el Client ID de Android
1. **Haz clic en** el OAuth 2.0 Client ID que diga **"Android client"** o que tenga el package name `com.sire.equigasto`
2. Debería tener un **Client ID** similar a: `363848646486-jkqt1j6j2p4tqn1n0gq1gchje1t73s5n.apps.googleusercontent.com`

### Paso 4: Verifica el SHA-1
En la página del OAuth Client ID de Android, deberías ver:

**Application restrictions:**
- ✅ "Android apps" debe estar seleccionado

**SHA certificate fingerprints:**
Deberías ver una lista de SHA-1 como:
```
✅ SHA-1: B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69
   (o puede aparecer otro SHA-1 de debug)
```

### Paso 5: Si falta el SHA-1
Si **NO ves** el SHA-1 de release (`B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69`):

1. Haz clic en **"Agregar huella digital SHA-1"** o **"Add fingerprint"**
2. Pega el SHA-1: `B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69`
3. Haz clic en **"Guardar"** o **"Save"**
4. Espera 5-10 minutos

## 🔗 URL directa

Si quieres ir directamente, intenta esta URL:
```
https://console.cloud.google.com/apis/credentials?project=363848646486
```

Luego busca la sección "OAuth 2.0 Client IDs" y haz clic en el que sea para Android.

## ⚠️ Diferencia importante

- **API Key**: Lo que estás viendo ahora - se usa para APIs de Firebase
- **OAuth 2.0 Client ID**: Necesario para Google Sign-In - **ESTO es lo que necesitas verificar**

## 📝 Nota

El OAuth Client ID de Android **debería haberse creado automáticamente** cuando agregaste el SHA-1 en Firebase Console. Si no lo ves, puede ser que necesites:

1. Verificar que el SHA-1 esté correctamente agregado en Firebase Console
2. Esperar unos minutos más
3. O agregarlo manualmente en Google Cloud Console







