# 🔧 Solución Completa: Error Google Sign-In y Icono

## ❌ Problemas Actuales
1. **Error Google Sign-In**: `PlatformException(sign_in_failed, com.google.android.gms.common.api.j: 10:)`
2. **Icono por defecto de Flutter** en lugar del logo de EquiGasto

## ✅ Solución 1: Arreglar Google Sign-In

### Paso 1: Verificar SHA en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona el proyecto **equigasto**
3. Ve a **Configuración del proyecto** (⚙️) > **Configuración general**
4. En la sección **Tus aplicaciones**, selecciona tu app Android (`com.sire.equigasto`)
5. Verifica que tengas estos SHA agregados:

**SHA-1 de Producción:**
```
B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69
```

**SHA-256 de Producción (IMPORTANTE - Agregar si falta):**
```
C4:E5:47:7E:48:4E:28:A7:88:8D:E1:45:4A:4D:6A:E4:2E:A1:B3:C1:B1:1E:2D:91:B5:BF:E5:13:6E:15:56:1A
```

### Paso 2: Descargar nuevo google-services.json

1. **DESPUÉS** de agregar/verificar los SHA, haz clic en **Descargar google-services.json**
2. **Reemplaza** el archivo en `android/app/google-services.json` con el nuevo archivo descargado
3. **IMPORTANTE**: El nuevo archivo debe tener un OAuth client con el SHA-256 de producción

### Paso 3: Verificar Google Sign-In habilitado

1. En Firebase Console, ve a **Authentication** > **Sign-in method**
2. Asegúrate de que **Google** esté **habilitado** (toggle verde)
3. Verifica que el **Email de soporte del proyecto** esté configurado

## ✅ Solución 2: Arreglar Icono

### Verificar que el archivo de icono sea correcto

1. El archivo `web/icons/Icon-512.png` debe ser el logo de EquiGasto (monedero azul)
2. Si no lo es, reemplázalo con el logo correcto
3. El archivo debe ser PNG de 512x512 píxeles

### Regenerar iconos

Los iconos ya se han regenerado con la configuración correcta. Si aún ves el icono de Flutter:

1. Desinstala completamente la app del dispositivo
2. Reinstala desde el nuevo AAB generado

## 🔄 Después de Actualizar google-services.json

Una vez que hayas descargado el nuevo `google-services.json`:

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

## 📝 Notas Importantes

- El error código 10 significa que el OAuth client no coincide con el certificado usado
- El SHA-256 es **obligatorio** para Google Sign-In en Android moderno
- Después de agregar SHA en Firebase, espera 5-10 minutos antes de probar
- El icono puede tardar en actualizarse - desinstala y reinstala la app completamente

## 🔍 Verificar SHA del Keystore

Para verificar que los SHA son correctos:

```bash
keytool -list -v -keystore android/upload-keystore.jks -alias upload -storepass equigasto123 -keypass equigasto123
```

Los SHA mostrados deben coincidir exactamente con los agregados en Firebase Console.

