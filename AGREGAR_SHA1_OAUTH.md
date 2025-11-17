# ✅ Agregar SHA-1 al OAuth Client ID de Android

## 🔍 Situación

Ves el Android OAuth Client ID pero **NO tiene el SHA-1 de release configurado**.

## 📋 Pasos para agregar el SHA-1

### Paso 1: Estar en la página del OAuth Client ID
- Deberías estar viendo la página de edición del Android OAuth Client ID
- Debería mostrar algo como:
  - **Nombre**: Android client (auto created by Google Service) o similar
  - **Nombre del paquete**: `com.sire.equigasto`
  - **SHA certificate fingerprints**: (puede estar vacío o tener solo el SHA-1 de debug)

### Paso 2: Agregar el SHA-1 de release

1. **Busca la sección "SHA certificate fingerprints"**
   - Puede aparecer como "Huellas digitales de certificado SHA"
   - O "SHA certificate fingerprints"

2. **Si hay un botón "Agregar huella digital" o "Add fingerprint"**:
   - Haz clic en el botón
   - Pega el SHA-1: `B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69`
   - Haz clic en "Guardar" o "Save"

3. **Si hay un campo de texto para agregar SHA-1**:
   - Haz clic en "Agregar otra huella digital" o "Add another fingerprint"
   - Pega el SHA-1: `B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69`
   - Haz clic en "Guardar" o "Save"

### Paso 3: Verificar que se agregó

Después de guardar, deberías ver en la lista de SHA certificate fingerprints:
```
✅ B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69
```

### Paso 4: Esperar propagación

1. **Guarda los cambios**
2. **Espera 5-10 minutos** para que se propague
3. **Genera un nuevo AAB** con la versión actualizada
4. **Sube a Play Store** para probar

## 📝 SHA-1 de Release

```
B1:03:D8:3B:09:1D:8B:66:89:B1:94:F7:49:2E:E3:40:F9:9F:01:69
```

## ⚠️ Formato importante

- El SHA-1 debe estar en formato con dos puntos (:)
- Debe estar en **mayúsculas**
- No debe tener espacios antes o después

## ✅ Verificación final

Después de agregar el SHA-1, deberías ver:
- ✅ El SHA-1 de release en la lista de fingerprints
- ✅ El Client ID coincidiendo con el de `google-services.json`
- ✅ El package name correcto: `com.sire.equigasto`

## 🔗 Verificar en google-services.json

El Client ID del OAuth Client ID de Android debería ser uno de estos:
- `363848646486-jkqt1j6j2p4tqn1n0gq1gchje1t73s5n.apps.googleusercontent.com` (con SHA-1 de release)
- `363848646486-1hc2cpfpofs0qhshurfmiob0rk8gphf3.apps.googleusercontent.com` (con SHA-1 de debug)

Ambos deberían aparecer en tu `google-services.json`.





