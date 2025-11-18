# Guía de Configuración: Play Integrity API con Firebase App Check

## 📋 Pasos a Seguir

### 1. Firebase Console - Configurar App Check

#### Paso 1.1: Acceder a App Check
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto **EquiGasto**
3. En el menú lateral, busca **"App Check"** (puede estar en "Build" o "Seguridad")
4. Si no lo ves, haz clic en el ícono de configuración (⚙️) y busca "App Check"

#### Paso 1.2: Registrar la App Android
1. En la página de App Check, verás una lista de tus apps
2. Busca tu app Android (package name: `com.sire.equigasto`)
3. Si no aparece, haz clic en **"Registrar app"** o **"Add app"**
4. Selecciona **Android** como plataforma
5. Ingresa el package name: `com.sire.equigasto`

#### Paso 1.3: Configurar Play Integrity como Proveedor
1. Una vez registrada la app, verás una sección de **"Providers"**
2. Haz clic en **"Play Integrity"** o **"Agregar proveedor"**
3. Selecciona **"Play Integrity"** de la lista
4. Haz clic en **"Guardar"** o **"Save"**

#### Paso 1.4: Configurar Proveedor de Debug (Opcional pero Recomendado)
Para poder probar en modo debug sin problemas:
1. En la misma página de la app Android
2. Haz clic en **"Agregar proveedor"** o **"Add provider"**
3. Selecciona **"Debug"**
4. Necesitarás obtener un token de debug:
   - En Android, ejecuta: `adb shell setprop debug.firebase.app_check_token <TOKEN>`
   - O usa el token que Firebase te proporciona en la consola
5. Guarda el proveedor de debug

### 2. Google Play Console - Verificar Play Integrity API

#### Paso 2.1: Acceder a Play Console
1. Ve a [Google Play Console](https://play.google.com/console/)
2. Selecciona tu app **EquiGasto**

#### Paso 2.2: Verificar que Play Integrity esté habilitado
1. Ve a **"Configuración"** → **"Integridad de la app"** o **"App integrity"**
2. Verifica que **"Play Integrity API"** esté habilitado
3. Si no está habilitado, haz clic en **"Habilitar"** o **"Enable"**
4. Esto debería estar habilitado automáticamente para apps publicadas

### 3. Firebase Console - Activar Enforcement (Paso Final)

⚠️ **IMPORTANTE**: Solo activa enforcement cuando estés seguro de que todo funciona.

#### Paso 3.1: Probar sin Enforcement Primero
1. Deja **"Enforcement"** desactivado inicialmente
2. Publica la nueva versión de la app
3. Monitorea las métricas en App Check durante unos días
4. Verifica que los tokens se estén generando correctamente

#### Paso 3.2: Activar Enforcement Gradualmente
Una vez que confirmes que todo funciona:

**Para Firestore:**
1. Ve a **Firestore Database** en Firebase Console
2. Haz clic en **"Reglas"** o **"Rules"**
3. En la pestaña **"App Check"**, activa el enforcement
4. O en las reglas de seguridad, agrega:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null 
           && firebase.appCheck.verifyToken(request.appCheck.token).exists;
       }
     }
   }
   ```

**Para Firebase Auth:**
1. Ve a **Authentication** → **Settings** → **App Check**
2. Activa el enforcement para las operaciones que quieras proteger

**Para Cloud Functions (si las usas):**
1. En las funciones, verifica el token de App Check antes de procesar

### 4. Verificación y Monitoreo

#### Paso 4.1: Verificar que Funciona
1. En Firebase Console → **App Check**
2. Ve a la pestaña **"Métricas"** o **"Metrics"**
3. Deberías ver:
   - Tokens generados
   - Solicitudes verificadas
   - Errores (si los hay)

#### Paso 4.2: Probar en la App
1. Ejecuta la app en modo debug (usará el proveedor de debug)
2. Ejecuta la app en modo release (usará Play Integrity)
3. Verifica que las operaciones de Firebase funcionen correctamente

## 🔍 Verificación del Código

El código ya está integrado en:
- ✅ `lib/core/services/play_integrity_service.dart` - Servicio de integridad
- ✅ `lib/main.dart` - Inicialización en el startup
- ✅ `lib/core/di/providers.dart` - Provider para inyección de dependencias

## 📝 Checklist Final

- [ ] App Check configurado en Firebase Console
- [ ] Play Integrity agregado como proveedor
- [ ] Proveedor de debug configurado (opcional pero recomendado)
- [ ] Play Integrity API habilitado en Play Console
- [ ] Nueva versión de la app publicada
- [ ] Métricas monitoreadas durante unos días
- [ ] Enforcement activado gradualmente (solo cuando estés seguro)

## ⚠️ Notas Importantes

1. **No actives enforcement inmediatamente**: Espera a verificar que todo funciona
2. **El proveedor de debug es útil**: Te permite probar sin problemas en desarrollo
3. **Monitorea las métricas**: Revisa regularmente para detectar problemas
4. **Activa enforcement gradualmente**: Empieza con servicios menos críticos

## 🆘 Solución de Problemas

### Si las solicitudes fallan después de activar enforcement:
1. Verifica que Play Integrity esté habilitado en Play Console
2. Asegúrate de que la app esté publicada (no solo en internal testing)
3. Verifica que el package name coincida exactamente
4. Revisa los logs de la app para ver errores de App Check

### Si no ves métricas en Firebase:
1. Espera unos minutos (puede haber delay)
2. Verifica que la app esté usando la nueva versión
3. Asegúrate de que App Check esté inicializado correctamente

## 📚 Recursos Adicionales

- [Documentación oficial de Firebase App Check](https://firebase.google.com/docs/app-check)
- [Documentación de Play Integrity](https://developer.android.com/google/play/integrity)
- [Guía de App Check para Flutter](https://firebase.google.com/docs/app-check/flutter/get-started)

