# 🔧 Solución: Error "No credentials available" en Google Sign-In

## ❌ Problema

Error al autenticar con Google en modo **DEBUG** (emulador/desarrollo):
```
Error al autenticar con Google: No credential available: No credentials available
```

## 🎯 Causa

Firebase Console **solo tiene configurado el SHA-1/SHA-256 de RELEASE** (producción), pero cuando ejecutas la app en modo debug desde Android Studio o con `flutter run`, la app usa el certificado de DEBUG, que tiene un SHA-1/SHA-256 diferente.

## ✅ Solución: Agregar SHA de DEBUG en Firebase

### Paso 1: Copiar los SHA de DEBUG

Tus certificados de DEBUG son:

**SHA-1 de DEBUG:**
```
D2:EE:D9:C6:CB:1A:34:0E:1A:CF:F4:47:A9:90:75:A0:09:16:87:7B
```

**SHA-256 de DEBUG:**
```
13:24:27:D1:09:DC:F0:C4:12:97:DD:F7:EC:CC:56:DB:AE:12:1E:E9:2B:C3:B1:FC:DC:87:15:94:10:1A:77:A8
```

### Paso 2: Agregar en Firebase Console

1. **Ve a Firebase Console**: https://console.firebase.google.com/
2. **Selecciona tu proyecto**: equigasto
3. **Ve a**: ⚙️ Configuración del proyecto → Configuración general
4. **Baja hasta**: "Tus aplicaciones" → Android (`com.sire.equigasto`)
5. **En "Huellas digitales del certificado SHA"**, haz clic en **"Agregar huella digital"**
6. **Agrega el SHA-1 de DEBUG**:
   ```
   D2:EE:D9:C6:CB:1A:34:0E:1A:CF:F4:47:A9:90:75:A0:09:16:87:7B
   ```
7. **Haz clic nuevamente en "Agregar huella digital"**
8. **Agrega el SHA-256 de DEBUG**:
   ```
   13:24:27:D1:09:DC:F0:C4:12:97:DD:F7:EC:CC:56:DB:AE:12:1E:E9:2B:C3:B1:FC:DC:87:15:94:10:1A:77:A8
   ```

### Paso 3: Descargar nuevo google-services.json

1. **Después de agregar los SHA**, haz clic en **"Descargar google-services.json"**
2. **Reemplaza** el archivo en `android/app/google-services.json` con el nuevo

### Paso 4: Limpiar y reconstruir

```bash
flutter clean
flutter pub get
flutter run
```

## 📋 Verificación

Después de agregar los SHA, deberías tener **4 huellas digitales** en Firebase Console:

| Tipo | SHA-1 | SHA-256 |
|------|-------|---------|
| **DEBUG** | D2:EE:D9:C6:CB:1A:34... | 13:24:27:D1:09:DC:F0... |
| **RELEASE** | B1:03:D8:3B:09:1D:8B... | C4:E5:47:7E:48:4E:28... |

## 🎯 Resumen

- **DEBUG** (desarrollo): Usa `~/.android/debug.keystore` automático
- **RELEASE** (producción): Usa `android/upload-keystore.jks` personalizado
- **Ambos necesitan estar configurados** en Firebase Console para que Google Sign-In funcione en ambos modos

## ⏱️ Tiempo de propagación

Después de agregar los SHA en Firebase Console:
- Espera **2-5 minutos** antes de probar
- Si no funciona inmediatamente, espera hasta **10 minutos**

## 🔍 Validación

Para verificar que los SHA se agregaron correctamente, puedes ejecutar:

```bash
cd android
./gradlew signingReport
```

Y comparar con los que agregaste en Firebase Console.








