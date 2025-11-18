# 🔧 Solución: Error de Credenciales de Google

## ❌ Error
```
The supplied auth credential is incorrect, malformed or has expired
```

## ✅ Soluciones

### 1. Verificar SHA-256 en Firebase Console

Este error a menudo ocurre cuando falta el SHA-256 en Firebase Console:

1. **Ve a Firebase Console**: https://console.firebase.google.com/
2. **Selecciona tu proyecto** (equigasto)
3. **Ve a**: Configuración del proyecto → Configuración general
4. **En "Tus aplicaciones"**, selecciona tu app Android
5. **Verifica que tengas estos SHA agregados**:

**SHA-1 de Producción:**
```
B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69
```

**SHA-256 de Producción (IMPORTANTE):**
```
C4:E5:47:7E:48:4E:28:A7:88:8D:E1:45:4A:4D:6A:E4:2E:A1:B3:C1:B1:1E:2D:91:B5:BF:E5:13:6E:15:56:1A
```

6. **Si falta el SHA-256, agrégalo y descarga el nuevo `google-services.json`**
7. **Reemplaza** `android/app/google-services.json` con el nuevo archivo

### 2. Verificar Google Sign-In habilitado

1. **Ve a Firebase Console** → Authentication → Sign-in method
2. **Asegúrate de que Google esté habilitado** (toggle verde)
3. **Verifica que el Email de soporte del proyecto esté configurado**

### 3. Verificar People API habilitada

1. **Ve a Google Cloud Console**: https://console.cloud.google.com/
2. **Selecciona el proyecto**: equigasto (ID: 363848646486)
3. **Ve a**: APIs & Services → Library
4. **Busca "People API"** y verifica que esté habilitada
5. **Si no está habilitada**, haz clic en "Enable"

**URL directa**: https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=363848646486

### 4. Limpiar caché de Google Sign-In

Si el problema persiste, intenta:

1. **Desinstalar completamente la app** del dispositivo
2. **Limpiar datos de Google Play Services** (si es posible)
3. **Reinstalar la app** desde el nuevo AAB

### 5. Verificar configuración en el código

El código ya incluye:
- ✅ Verificación de tokens no nulos
- ✅ Manejo de errores específicos
- ✅ Mensajes claros para el usuario
- ✅ No mostrar error si el usuario cancela

## 🔄 Después de hacer cambios

1. **Regenera el AAB**:
   ```bash
   flutter clean
   flutter build appbundle --release
   ```

2. **Desinstala completamente la app** del dispositivo

3. **Reinstala** desde el nuevo AAB

## 📝 Notas

- El error puede ocurrir si el token de Google Sign-In ha expirado
- Asegúrate de que el SHA-256 esté agregado en Firebase Console
- El nuevo `google-services.json` debe incluir el OAuth client con SHA-256
- Espera 5-10 minutos después de agregar SHA en Firebase antes de probar








