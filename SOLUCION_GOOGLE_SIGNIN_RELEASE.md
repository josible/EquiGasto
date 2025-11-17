# 🔧 Solución: Google Sign-In no funciona en Release/Play Store

## ❌ Problema

El login con Google funciona en desarrollo pero **NO funciona en la versión de producción** subida a Play Store.

## 🔍 Causa

Firebase requiere registrar el **SHA-1 del certificado de firma de producción** (diferente al de debug) para que Google Sign-In funcione en apps firmadas con el keystore de release.

## ✅ Solución: Agregar SHA-1 de Release a Firebase

### Paso 1: Obtener los SHAs del keystore de producción

Ya se obtuvieron los SHAs del keystore de release:

**SHA-1:**
```
B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69
```

**SHA-256:**
```
C4:E5:47:7E:48:4E:28:A7:88:8D:E1:45:4A:4D:6A:E4:2E:A1:B3:C1:B1:1E:2D:91:B5:BF:E5:13:6E:15:56:1A
```

### Paso 2: Agregar SHA-1 a Firebase Console

1. **Ve a Firebase Console**: https://console.firebase.google.com/
2. **Selecciona el proyecto**: `equigasto`
3. **Ve a Configuración del proyecto** (ícono de engranaje > Configuración del proyecto)
4. **Ve a la pestaña "Tus aplicaciones"**
5. **Selecciona la app Android** (`com.sire.equigasto`)
6. **Haz clic en "Agregar huella digital de certificado"** (si no está visible, haz clic en los 3 puntos > "Configuración de la app")
7. **Pega el SHA-1 de producción**:
   ```
   B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69
   ```
8. **Haz clic en "Guardar"**

### Paso 3: Descargar el nuevo google-services.json

1. **Descarga el archivo `google-services.json` actualizado** desde Firebase Console
2. **Reemplaza el archivo** en `android/app/google-services.json`
3. **Asegúrate de que el archivo está en el repositorio** (si es necesario, agrégale al git)

### Paso 4: Actualizar Google Cloud Console (Opcional pero recomendado)

Si también configuraste OAuth en Google Cloud Console directamente:

1. **Ve a Google Cloud Console**: https://console.cloud.google.com/
2. **Selecciona el proyecto**: `equigasto` (ID: 363848646486)
3. **Ve a APIs & Services** > **Credentials**
4. **Encuentra el OAuth 2.0 Client ID para Android**
5. **Agrega el SHA-1 de producción** en la sección "SHA certificate fingerprints"
6. **Guarda los cambios**

### Paso 5: Generar nueva versión del AAB

Después de actualizar Firebase:

1. **Espera 5-10 minutos** para que los cambios se propaguen
2. **Genera un nuevo AAB**:
   ```bash
   flutter build appbundle --release
   ```
3. **Sube la nueva versión** a Play Store

## ⚠️ Importante

- **Los cambios pueden tardar 5-10 minutos** en propagarse después de agregar el SHA-1
- **NO es necesario cambiar el código** - solo agregar el SHA-1 en Firebase Console
- **Cada keystore tiene su propio SHA-1** - si cambias el keystore, necesitarás agregar el nuevo SHA-1

## 🔍 Verificación

Para verificar que funciona:

1. **Genera un AAB de prueba** con el nuevo `google-services.json`
2. **Instala en un dispositivo físico** usando el AAB
3. **Prueba el login con Google**

## 📝 Notas Adicionales

### Si también quieres agregar SHA-256:

Puedes agregar también el SHA-256 en Firebase Console (es opcional, pero recomendado):

```
C4:E5:47:7E:48:4E:28:A7:88:8D:E1:45:4A:4D:6A:E4:2E:A1:B3:C1:B1:1E:2D:91:B5:BF:E5:13:6E:15:56:1A
```

### Cómo obtener los SHAs manualmente (si es necesario):

```bash
cd android
keytool -list -v -keystore upload-keystore.jks -alias upload -storepass equigasto123 -keypass equigasto123
```

Busca las líneas:
- `SHA1: B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69`
- `SHA256: C4:E5:47:7E:48:4E:28:A7:88:8D:E1:45:4A:4D:6A:E4:2E:A1:B3:C1:B1:1E:2D:91:B5:BF:E5:13:6E:15:56:1A`

---

**✅ Después de seguir estos pasos, Google Sign-In debería funcionar correctamente en la versión de producción.**





