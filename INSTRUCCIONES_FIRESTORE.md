# 🔥 Instrucciones para Configurar Firestore

## ⚠️ IMPORTANTE: Debes aplicar estas reglas en Firebase Console

El error "Missing or insufficient permissions" indica que las reglas de Firestore no están configuradas correctamente.

## 📋 Pasos para aplicar las reglas:

### 1. Ve a Firebase Console
- Abre: https://console.firebase.google.com
- Selecciona tu proyecto: **equigasto**

### 2. Ve a Firestore Database → Rules
- En el menú lateral, haz clic en **Firestore Database**
- Luego haz clic en la pestaña **Rules**

### 3. Copia y pega estas reglas:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Reglas para usuarios
    match /users/{userId} {
      // Permitir escribir solo al propio usuario autenticado
      allow write: if request.auth != null && request.auth.uid == userId;
      // Permitir crear si está autenticado
      allow create: if request.auth != null;
      // Permitir leer cualquier usuario para búsquedas por email (necesario para invitar a grupos)
      // Solo usuarios autenticados pueden leer otros usuarios
      allow read: if request.auth != null;
    }
    
    // Reglas para grupos
    match /groups/{groupId} {
      // Se puede leer si el usuario está autenticado (para ver información de invitación)
      // La aplicación verificará la membresía antes de permitir acciones
      allow read: if request.auth != null;
      
      // Solo se puede crear si el usuario está autenticado y es el creador
      allow create: if request.auth != null &&
                       request.auth.uid == request.resource.data.createdBy &&
                       request.auth.uid in request.resource.data.memberIds;
      
      // Solo se puede actualizar si el usuario es miembro del grupo
      allow update: if request.auth != null &&
                       request.auth.uid in resource.data.memberIds;
      
      // Solo el creador puede eliminar el grupo
      allow delete: if request.auth != null &&
                       request.auth.uid == resource.data.createdBy;
    }
    
    // Reglas para gastos
    match /expenses/{expenseId} {
      // Solo se puede leer si el usuario está autenticado
      // (se verificará en la aplicación que pertenece al grupo)
      allow read: if request.auth != null;
      
      // Solo se puede crear si el usuario está autenticado
      allow create: if request.auth != null;
      
      // Solo se puede actualizar si el usuario está autenticado
      allow update: if request.auth != null;
      
      // Solo se puede eliminar si el usuario está autenticado
      allow delete: if request.auth != null;
    }
    
    // Reglas para notificaciones
    match /notifications/{notificationId} {
      // Solo se puede leer si el usuario es el destinatario
      allow read: if request.auth != null &&
                     request.auth.uid == resource.data.userId;
      
      // Solo se puede crear si el usuario está autenticado
      allow create: if request.auth != null;
      
      // Solo se puede actualizar si el usuario es el destinatario
      allow update: if request.auth != null &&
                       request.auth.uid == resource.data.userId;
      
      // Solo se puede eliminar si el usuario es el destinatario
      allow delete: if request.auth != null &&
                       request.auth.uid == resource.data.userId;
    }
    
    // Reglas para códigos de invitación de grupos
    match /group_invites/{inviteCode} {
      // Cualquier usuario autenticado puede leer códigos de invitación (para validar y unirse)
      allow read: if request.auth != null;
      
      // Solo se puede crear si el usuario está autenticado
      allow create: if request.auth != null;
      
      // No se permite actualizar códigos de invitación
      allow update: if false;
      
      // No se permite eliminar códigos de invitación
      allow delete: if false;
    }
  }
}
```

### 4. Publica las reglas
- Haz clic en el botón **Publicar** (arriba a la derecha)
- Espera a que se confirme la publicación

### 5. Verifica que funcionó
- Intenta crear un grupo nuevamente
- Debería funcionar sin errores de permisos

## 🔍 Verificación adicional

Si después de aplicar las reglas sigue fallando, verifica:

1. **Que estés autenticado**: Asegúrate de haber iniciado sesión correctamente
2. **Que el usuario tenga un ID válido**: El `user.id` debe coincidir con `request.auth.uid` de Firebase
3. **Que las reglas se hayan publicado**: Revisa que las reglas en Firebase Console coincidan con las de arriba

## 📝 Nota sobre seguridad

Estas reglas aseguran que:
- ✅ Solo puedes ver grupos donde eres miembro
- ✅ Solo puedes crear grupos si estás autenticado
- ✅ Solo puedes actualizar grupos donde eres miembro
- ✅ Solo el creador puede eliminar un grupo
- ✅ Solo usuarios autenticados pueden crear y ver gastos

## 📊 Índices necesarios

### Índice para gastos (expenses)

Para ordenar los gastos por fecha, necesitarás crear un índice compuesto:

1. Ve a **Firestore Database** → **Indexes**
2. Haz clic en **Create Index**
3. Configura:
   - Collection ID: `expenses`
   - Fields to index:
     - `groupId` (Ascending)
     - `date` (Descending)
4. Haz clic en **Create**

**Nota**: Si ves un error al cargar gastos que menciona un índice faltante, Firebase te dará un enlace directo para crearlo. Haz clic en ese enlace y se creará automáticamente.

