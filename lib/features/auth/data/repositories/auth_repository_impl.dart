import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/user_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;
  final UserRemoteDataSource userRemoteDataSource;

  AuthRepositoryImpl(
    this.localDataSource,
    this.remoteDataSource,
    this.userRemoteDataSource,
  );

  @override
  Future<Result<User>> loginWithGoogle() async {
    try {
      // Autenticar con Google
      final userCredential = await remoteDataSource.signInWithGoogle();
      final firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        return const Error(AuthFailure('Error al iniciar sesión con Google'));
      }

      // Intentar obtener datos del usuario desde Firestore
      User? user;
      try {
        user = await userRemoteDataSource.getUserById(firebaseUser.uid);
      } catch (e) {
        // Si falla Firestore (permisos, etc.), continuamos con datos de Auth
        user = null;
      }
      
      // Si no existe en Firestore o falló, crear usuario desde Firebase Auth
      if (user == null) {
        user = User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'Usuario',
          avatarUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
        );
        
        // Intentar crear en Firestore (no crítico si falla)
        try {
          await userRemoteDataSource.createUser(user);
        } catch (e) {
          // Si falla, continuamos con el usuario de Auth
        }
      }
      
      // Guardar en cache local (no crítico si falla)
      try {
        await localDataSource.saveUser(user);
      } catch (e) {
        // Si falla el cache, no es crítico
      }
      
      return Success(user);
    } catch (e) {
      String errorMessage = 'Error al iniciar sesión con Google';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      return Error(AuthFailure(errorMessage));
    }
  }

  @override
  Future<Result<User>> login(String email, String password) async {
    try {
      if (email.isEmpty || !email.contains('@')) {
        return const Error(AuthFailure('Ingrese un email válido'));
      }
      if (password.isEmpty) {
        return const Error(AuthFailure('La contraseña es requerida'));
      }

      // Autenticar con Firebase
      final userCredential = await remoteDataSource.signInWithEmailAndPassword(email, password);
      final firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        return const Error(AuthFailure('Error al iniciar sesión'));
      }

      // Intentar obtener datos del usuario desde Firestore
      User? user;
      try {
        user = await userRemoteDataSource.getUserById(firebaseUser.uid);
      } catch (e) {
        // Si falla Firestore (permisos, etc.), continuamos con datos de Auth
        user = null;
      }
      
      // Si no existe en Firestore o falló, crear usuario desde Firebase Auth
      if (user == null) {
        user = User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? email,
          name: firebaseUser.displayName ?? email.split('@')[0],
          avatarUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
        );
        
        // Intentar crear en Firestore, pero no fallar si hay error de permisos
        try {
          await userRemoteDataSource.createUser(user);
        } catch (e) {
          // Si falla Firestore, continuamos igual - el usuario está autenticado
        }
      }

      // Guardar en cache local (opcional, no crítico si falla)
      try {
        await localDataSource.saveUser(user);
      } catch (e) {
        // Si falla el cache local, no es crítico
      }

      return Success(user);
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Result<User>> register(String email, String password, String name) async {
    try {
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        return const Error(ValidationFailure('Todos los campos son requeridos'));
      }

      // Crear usuario en Firebase Authentication
      final userCredential = await remoteDataSource.createUserWithEmailAndPassword(email, password);
      final firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        return const Error(AuthFailure('Error al registrar usuario: No se obtuvo información del usuario'));
      }

      // Actualizar el perfil con el nombre
      try {
        await firebaseUser.updateDisplayName(name);
        await firebaseUser.reload();
      } catch (e) {
        // Continuar aunque falle la actualización del displayName
        // El usuario ya está creado en Firebase Auth
      }

      // Crear registro en Firestore
      final user = User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? email,
        name: name,
        avatarUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
      );

      // Intentar crear en Firestore, pero no fallar si hay error de permisos
      try {
        await userRemoteDataSource.createUser(user);
      } catch (e) {
        // Si falla Firestore (probablemente por reglas), el usuario ya está en Auth
        // Continuamos con el registro exitoso
        // En producción, deberías revisar las reglas de Firestore
      }
      
      // Guardar en cache local (opcional, no crítico si falla)
      try {
        await localDataSource.saveUser(user);
      } catch (e) {
        // Si falla el cache local (SharedPreferences no disponible), no es crítico
        // El usuario ya está registrado en Firebase Auth y Firestore
      }

      return Success(user);
    } catch (e) {
      // Extraer el mensaje del error
      String errorMessage = 'Error al registrar usuario';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      return Error(AuthFailure(errorMessage));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await remoteDataSource.signOut();
      await localDataSource.clearUser();
      return const Success(null);
    } catch (e) {
      return Error(AuthFailure('Error al cerrar sesión: $e'));
    }
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    try {
      final firebaseUser = remoteDataSource.getCurrentFirebaseUser();
      
      if (firebaseUser == null) {
        // Limpiar cache local si no hay usuario en Firebase
        await localDataSource.clearUser();
        return const Success(null);
      }

      // Intentar obtener datos del usuario desde Firestore
      User? user;
      try {
        user = await userRemoteDataSource.getUserById(firebaseUser.uid);
      } catch (e) {
        // Si falla Firestore (permisos, etc.), continuamos con datos de Auth
        user = null;
      }
      
      if (user != null) {
        // Actualizar cache local (opcional, no crítico si falla)
        try {
          await localDataSource.saveUser(user);
        } catch (e) {
          // Si falla el cache local, no es crítico
        }
        return Success(user);
      }

      // Si no existe en Firestore o falló, crear registro básico desde Firebase Auth
      final newUser = User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'Usuario',
        avatarUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
      );
      
      // Intentar crear en Firestore, pero no fallar si hay error
      try {
        await userRemoteDataSource.createUser(newUser);
      } catch (e) {
        // Si falla Firestore, continuamos igual
      }
      
      // Intentar guardar en cache local
      try {
        await localDataSource.saveUser(newUser);
      } catch (e) {
        // Si falla el cache local, no es crítico
      }
      
      return Success(newUser);
    } catch (e) {
      return Error(AuthFailure('Error al obtener usuario: $e'));
    }
  }

  @override
  Future<Result<User>> updateProfile(String userId, String name, String? avatarUrl) async {
    try {
      final firebaseUser = remoteDataSource.getCurrentFirebaseUser();
      if (firebaseUser == null || firebaseUser.uid != userId) {
        return const Error(AuthFailure('Usuario no autenticado'));
      }

      // Actualizar en Firebase Auth
      if (name.isNotEmpty) {
        await firebaseUser.updateDisplayName(name);
      }
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        await firebaseUser.updatePhotoURL(avatarUrl);
      }
      await firebaseUser.reload();

      // Obtener usuario actualizado
      final currentUser = await userRemoteDataSource.getUserById(userId);
      if (currentUser == null) {
        return const Error(AuthFailure('Usuario no encontrado'));
      }

      // Actualizar en Firestore
      final updatedUser = User(
        id: currentUser.id,
        email: currentUser.email,
        name: name,
        avatarUrl: avatarUrl ?? firebaseUser.photoURL,
        createdAt: currentUser.createdAt,
      );

      await userRemoteDataSource.updateUser(updatedUser);
      
      // Actualizar cache local
      await localDataSource.saveUser(updatedUser);
      
      return Success(updatedUser);
    } catch (e) {
      return Error(AuthFailure('Error al actualizar perfil: $e'));
    }
  }
}



