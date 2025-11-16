# Solución: Error Google Sign-In Android (Código 10)

## 🔴 Error
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.j: 10:, null, null)
```

Este error indica que las huellas digitales SHA no están correctamente configuradas en Firebase Console.

## ✅ Solución

### Paso 1: Agregar SHA-256 en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona el proyecto **equigasto**
3. Ve a **Configuración del proyecto** (⚙️) > **Configuración general**
4. En la sección **Tus aplicaciones**, selecciona tu app Android (`com.sire.equigasto`)
5. En **Huellas digitales del certificado SHA**, agrega:

**SHA-1 (ya está agregado):**
```
B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69
```

**SHA-256 (AGREGAR ESTE):**
```
C4:E5:47:7E:48:4E:28:A7:88:8D:E1:45:4A:4D:6A:E4:2E:A1:B3:C1:B1:1E:2D:91:B5:BF:E5:13:6E:15:56:1A
```

### Paso 2: Descargar nuevo google-services.json

1. Después de agregar el SHA-256, haz clic en **Descargar google-services.json**
2. Reemplaza el archivo en `android/app/google-services.json` con el nuevo archivo descargado

### Paso 3: Verificar que Google Sign-In esté habilitado

1. En Firebase Console, ve a **Authentication** > **Sign-in method**
2. Asegúrate de que **Google** esté habilitado
3. Verifica que el **Email de soporte del proyecto** esté configurado

### Paso 4: Regenerar la aplicación

Después de actualizar el `google-services.json`, regenera la aplicación:

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

## 📝 Notas

- El SHA-1 de producción ya está en el `google-services.json` actual
- El SHA-256 es necesario para Google Sign-In en Android
- Después de agregar los SHA, espera 5-10 minutos antes de probar
- Si el error persiste, verifica que el `package_name` sea exactamente `com.sire.equigasto`

## 🔍 Verificación

Para verificar que los SHA están correctos, ejecuta:

```bash
keytool -list -v -keystore android/upload-keystore.jks -alias upload -storepass equigasto123 -keypass equigasto123
```

Los SHA mostrados deben coincidir con los agregados en Firebase Console.

