# ✅ Sincronizar SHA-1 entre Firebase y Google Cloud Console

## 🔍 Situación

✅ **Firebase Console**: El SHA-1 de release **YA ESTÁ configurado**
❌ **Google Cloud Console - OAuth Client ID**: El SHA-1 **NO está** (según lo que viste)

## ⚠️ Problema

Aunque Firebase Console y Google Cloud Console están vinculados, **a veces no se sincronizan automáticamente**. Por eso necesitas agregar el SHA-1 **manualmente** en el OAuth Client ID de Google Cloud Console.

## ✅ Solución: Agregar SHA-1 en Google Cloud Console

### Paso 1: Volver a Google Cloud Console

1. Ve a: https://console.cloud.google.com/apis/credentials?project=363848646486
2. Busca la sección **"OAuth 2.0 Client IDs"**
3. Haz clic en el **Android client** (el que tiene `com.sire.equigasto`)

### Paso 2: Agregar el SHA-1 manualmente

1. En la página del Android OAuth Client ID, busca la sección:
   - **"SHA certificate fingerprints"** o
   - **"Huellas digitales de certificado SHA"**

2. Deberías ver un campo o botón para agregar fingerprints

3. Haz clic en:
   - **"Agregar huella digital"** o
   - **"Add fingerprint"** o
   - **"Agregar otra huella digital"**

4. Pega el SHA-1 de release:
   ```
   B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69
   ```
   **Importante:** Con mayúsculas y dos puntos (:) como se muestra

5. Haz clic en **"Guardar"** o **"Save"**

### Paso 3: Verificar que se agregó

Después de guardar, deberías ver en la lista de SHA certificate fingerprints:
```
✅ B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69
```

## 🔄 Por qué hacer esto manualmente

- Firebase Console agrega el SHA-1 a su configuración
- Google Cloud Console crea los OAuth Client IDs automáticamente
- Pero **a veces el SHA-1 no se propaga** automáticamente al OAuth Client ID
- Por eso necesitas agregarlo **manualmente** para asegurarte de que esté sincronizado

## ✅ Después de agregar

1. **Espera 5-10 minutos** para que se propague
2. **Regenera el AAB** (si ya lo subiste antes de agregar el SHA-1)
3. **Prueba Google Sign-In** en la versión de Play Store

## 📝 SHA-1 de Release

```
B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69
```

Este es el mismo SHA-1 que ya tienes en Firebase Console. Solo necesitas agregarlo también en el OAuth Client ID de Google Cloud Console.









