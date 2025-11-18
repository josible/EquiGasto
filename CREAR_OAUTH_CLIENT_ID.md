# 🔧 Cómo crear/verificar OAuth 2.0 Client ID para Android

## 🔍 Situación actual

Solo ves "Claves de API" (API Keys), pero **no ves "OAuth 2.0 Client IDs"**.

## ✅ Solución 1: Buscar más abajo en la página

1. **Desplázate hacia abajo** en la página de Credenciales
2. Los OAuth 2.0 Client IDs deberían aparecer **después** de las API Keys
3. Si los ves, haz clic en el que diga "Android client"

## ✅ Solución 2: Si no aparecen, crear OAuth Client ID

Si **NO ves** la sección "OAuth 2.0 Client IDs" después de desplazarte:

### Opción A: Crear desde Google Cloud Console

1. En la misma página de Credenciales
2. **Arriba a la izquierda**, haz clic en **"+ CREAR CREDENCIALES"** o **"+ CREATE CREDENTIALS"**
3. Selecciona **"ID de cliente de OAuth"** o **"OAuth client ID"**
4. Si te pide, selecciona **"Configurar pantalla de consentimiento"** primero (si no está configurada)
5. En el tipo de aplicación, selecciona **"Android"**
6. Configura:
   - **Nombre**: `EquiGasto Android` (o el que prefieras)
   - **Nombre del paquete**: `com.sire.equigasto`
   - **SHA-1 fingerprint**: `B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69`
7. Haz clic en **"CREAR"** o **"CREATE"**

### Opción B: Verificar desde Firebase Console

Los OAuth Client IDs se crean automáticamente cuando agregas el SHA-1 en Firebase:

1. Ve a **Firebase Console**: https://console.firebase.google.com/
2. Selecciona el proyecto **equigasto**
3. Ve a **Configuración del proyecto** (ícono de engranaje)
4. Pestaña **"Tus aplicaciones"**
5. Selecciona la app **Android** (`com.sire.equigasto`)
6. Verifica que el SHA-1 de release esté en la lista:
   ```
   B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69
   ```
7. Si falta, agrégalo
8. Espera 5-10 minutos
9. Los OAuth Client IDs deberían crearse automáticamente en Google Cloud Console

## 🔗 URLs útiles

### Ver credenciales de OAuth directamente:
```
https://console.cloud.google.com/apis/credentials/consent?project=363848646486
```

### Crear OAuth Client ID:
```
https://console.cloud.google.com/apis/credentials/oauthclient?project=363848646486
```

## 📝 Nota importante

- Los OAuth Client IDs se crean **automáticamente** cuando agregas SHA-1 en Firebase Console
- Si ya agregaste el SHA-1 en Firebase pero no aparecen aquí, **espera 5-10 minutos**
- Si después de esperar no aparecen, créalos manualmente con la Opción A

## ✅ Verificación

Una vez que tengas el OAuth Client ID de Android:

1. Debe tener el **package name**: `com.sire.equigasto`
2. Debe tener el **SHA-1**: `B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69`
3. El **Client ID** debe coincidir con uno de los que aparece en tu `google-services.json`

En tu `google-services.json`, el Client ID de Android con el SHA-1 de release es:
```
363848646486-jkqt1j6j2p4tqn1n0gq1gchje1t73s5n.apps.googleusercontent.com
```

Este debería aparecer en el OAuth Client ID de Android en Google Cloud Console.







