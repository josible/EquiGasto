# Configuración de Firestore para EquiGasto

## Estructura de Datos

### Colección: `users`
Documentos de usuarios con la siguiente estructura:
```json
{
  "id": "userId",
  "email": "usuario@example.com",
  "name": "Nombre del usuario",
  "avatarUrl": "url_avatar (opcional)",
  "createdAt": "timestamp"
}
```

### Colección: `groups`
Documentos de grupos con la siguiente estructura:
```json
{
  "id": "groupId",
  "name": "Nombre del grupo",
  "description": "Descripción del grupo",
  "createdBy": "userId del creador",
  "memberIds": ["userId1", "userId2", ...],
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Importante**: Solo se pueden ver grupos donde el usuario esté en el array `memberIds`.

## Reglas de Seguridad

Copia y pega estas reglas en Firebase Console → Firestore Database → Rules:

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
      // Solo se puede leer si el usuario es miembro del grupo
      allow read: if request.auth != null && 
                     request.auth.uid in resource.data.memberIds;
      
      // Solo se puede crear si el usuario está autenticado y es el creador
      allow create: if request.auth != null &&
                       request.auth.uid == request.resource.data.createdBy &&
                       request.auth.uid in request.resource.data.memberIds &&
                       request.resource.data.id is string &&
                       request.resource.data.name is string &&
                       request.resource.data.createdBy is string &&
                       request.resource.data.memberIds is list;
      
      // Solo se puede actualizar si el usuario es miembro del grupo
      allow update: if request.auth != null &&
                       request.auth.uid in resource.data.memberIds;
      
      // Solo el creador puede eliminar el grupo
      allow delete: if request.auth != null &&
                       request.auth.uid == resource.data.createdBy;
    }
    
    // Reglas para gastos (expenses) - para futura implementación
    match /expenses/{expenseId} {
      allow read, write: if request.auth != null;
    }
    
    // Reglas para notificaciones - para futura implementación
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null &&
                     request.auth.uid == resource.data.userId;
    }
  }
}
```

## Cómo aplicar las reglas

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto `equigasto`
3. Ve a **Firestore Database** → **Rules**
4. Copia y pega las reglas de arriba
5. Haz clic en **Publicar**

## Índices necesarios

Si quieres ordenar los grupos por `updatedAt` en la consulta, necesitarás crear un índice compuesto:

1. Ve a **Firestore Database** → **Indexes**
2. Haz clic en **Create Index**
3. Configura:
   - Collection ID: `groups`
   - Fields to index:
     - `memberIds` (Array)
     - `updatedAt` (Descending)
4. Haz clic en **Create**

**Nota**: Por ahora, el código ordena en memoria, así que no es estrictamente necesario crear el índice, pero mejorará el rendimiento.

