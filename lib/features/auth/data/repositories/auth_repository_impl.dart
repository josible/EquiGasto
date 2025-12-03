import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/user_remote_datasource.dart';
import '../../../../core/services/credentials_storage.dart';
import '../../../groups/domain/repositories/groups_repository.dart';
import '../../../groups/domain/entities/group.dart';
import '../../../expenses/domain/repositories/expenses_repository.dart';
import '../../../expenses/domain/entities/expense.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;
  final UserRemoteDataSource userRemoteDataSource;
  final CredentialsStorage credentialsStorage;
  final GroupsRepository groupsRepository;
  final ExpensesRepository expensesRepository;

  AuthRepositoryImpl(
    this.localDataSource,
    this.remoteDataSource,
    this.userRemoteDataSource,
    this.credentialsStorage,
    this.groupsRepository,
    this.expensesRepository,
  );

  @override
  Future<Result<User>> loginWithGoogle() async {
    try {
      // Autenticar con Google
      final userCredential = await remoteDataSource.signInWithGoogle();
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return const Error(
          AuthFailure(
            'No se pudo obtener la información del usuario de Google',
          ),
        );
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
          name: firebaseUser.displayName ??
              firebaseUser.email?.split('@')[0] ??
              'Usuario',
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
  Future<Result<User>> linkGoogleAccount() async {
    try {
      // Vincular cuenta de Google a la cuenta actual
      final userCredential = await remoteDataSource.linkGoogleAccount();
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return const Error(
          AuthFailure('No se pudo vincular la cuenta de Google'),
        );
      }

      // Obtener o actualizar datos del usuario desde Firestore
      User? user;
      try {
        user = await userRemoteDataSource.getUserById(firebaseUser.uid);

        // Actualizar avatar si viene de Google y no existe
        if (user != null &&
            firebaseUser.photoURL != null &&
            user.avatarUrl == null) {
          final updatedUser = User(
            id: user.id,
            email: user.email,
            name: user.name,
            avatarUrl: firebaseUser.photoURL,
            createdAt: user.createdAt,
          );
          try {
            await userRemoteDataSource.updateUser(updatedUser);
            user = updatedUser;
          } catch (e) {
            // Si falla la actualización, continuamos con el usuario existente
          }
        }
      } catch (e) {
        // Si falla Firestore, crear usuario desde Firebase Auth
        user = null;
      }

      // Si no existe en Firestore, crear usuario desde Firebase Auth
      if (user == null) {
        user = User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ??
              firebaseUser.email?.split('@')[0] ??
              'Usuario',
          avatarUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
        );

        // Intentar crear en Firestore
        try {
          await userRemoteDataSource.createUser(user);
        } catch (e) {
          // Si falla, continuamos con el usuario de Auth
        }
      }

      // Guardar en cache local
      try {
        await localDataSource.saveUser(user);
      } catch (e) {
        // Si falla el cache, no es crítico
      }

      return Success(user);
    } catch (e) {
      String errorMessage = 'Error al vincular cuenta de Google';
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
      final userCredential =
          await remoteDataSource.signInWithEmailAndPassword(email, password);
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

      await _cacheCredentialsIfNeeded(
        email: email,
        password: password,
      );

      return Success(user);
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Result<User>> register(
      String email, String password, String name) async {
    try {
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        return const Error(
            ValidationFailure('Todos los campos son requeridos'));
      }

      // Crear usuario en Firebase Authentication
      final userCredential = await remoteDataSource
          .createUserWithEmailAndPassword(email, password);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return const Error(
          AuthFailure(
            'Error al registrar usuario: No se obtuvo información del usuario',
          ),
        );
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

      await _cacheCredentialsIfNeeded(
        email: email,
        password: password,
      );

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
      await credentialsStorage.clearCredentials();
      return const Success(null);
    } catch (e) {
      return Error(AuthFailure('Error al cerrar sesión: $e'));
    }
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    User? cachedUser;
    try {
      try {
        cachedUser = await localDataSource.getCurrentUser();
      } catch (_) {
        cachedUser = null;
      }

      final firebaseUser = remoteDataSource.getCurrentFirebaseUser();

      if (firebaseUser == null) {
        final autoLoginUser = await _tryAutoLoginWithStoredCredentials();
        if (autoLoginUser != null) {
          return Success(autoLoginUser);
        }
        if (cachedUser != null) {
          return Success(cachedUser);
        }
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

      // Si no existe en Firestore o falló, intentar con cache antes de crear uno nuevo
      if (cachedUser != null && cachedUser.id == firebaseUser.uid) {
        return Success(cachedUser);
      }

      final newUser = User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ??
            firebaseUser.email?.split('@')[0] ??
            'Usuario',
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
      if (cachedUser != null) {
        return Success(cachedUser);
      }
      return Error(AuthFailure('Error al obtener usuario: $e'));
    }
  }

  @override
  Future<Result<User>> updateProfile(
      String userId, String name, String? avatarUrl) async {
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

  @override
  Future<Result<void>> resetPassword(String email) async {
    try {
      if (email.isEmpty || !email.contains('@')) {
        return const Error(ValidationFailure('Ingrese un email válido'));
      }
      await remoteDataSource.sendPasswordResetEmail(email);
      return const Success(null);
    } catch (e) {
      return Error(AuthFailure('Error al enviar correo de recuperación: $e'));
    }
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (currentPassword.isEmpty || newPassword.isEmpty) {
        return const Error(
          ValidationFailure('Todos los campos son requeridos'),
        );
      }
      if (newPassword.length < 6) {
        return const Error(
          ValidationFailure('La nueva contraseña debe tener al menos 6 caracteres'),
        );
      }

      final firebaseUser = remoteDataSource.getCurrentFirebaseUser();
      if (firebaseUser == null || firebaseUser.email == null) {
        return const Error(AuthFailure('Usuario no autenticado'));
      }

      // Reautenticar al usuario con la contraseña actual
      try {
        await remoteDataSource.signInWithEmailAndPassword(
          firebaseUser.email!,
          currentPassword,
        );
      } catch (e) {
        return const Error(
          AuthFailure('La contraseña actual no es correcta'),
        );
      }

      await firebaseUser.updatePassword(newPassword);

      // Actualizar credenciales almacenadas si las hubiera
      await _cacheCredentialsIfNeeded(
        email: firebaseUser.email,
        password: newPassword,
      );

      return const Success(null);
    } catch (e) {
      String message = 'Error al cambiar la contraseña';
      final text = e.toString();
      if (text.contains('weak-password')) {
        message = 'La nueva contraseña es demasiado débil';
      } else if (text.contains('requires-recent-login')) {
        message =
            'Por seguridad, vuelve a iniciar sesión e inténtalo de nuevo.';
      }
      return Error(AuthFailure(message));
    }
  }

  Future<void> _cacheCredentialsIfNeeded({
    String? email,
    String? password,
  }) async {
    if (email == null || password == null) return;
    await credentialsStorage.saveCredentials(
      email: email,
      password: password,
    );
  }

  @override
  Future<Result<User>> claimFictionalUser(String fictionalUserId) async {
    try {
      // Verificar que el usuario esté autenticado
      final firebaseUser = remoteDataSource.getCurrentFirebaseUser();
      if (firebaseUser == null) {
        return const Error(
          AuthFailure('Debes estar autenticado para reclamar un usuario ficticio'),
        );
      }

      // Obtener el usuario ficticio de la colección users
      final fictionalUser = await userRemoteDataSource.getUserById(fictionalUserId);
      if (fictionalUser == null) {
        return const Error(NotFoundFailure('Usuario ficticio no encontrado'));
      }
      if (fictionalUser.isFictional != true) {
        return const Error(
          AuthFailure('Este usuario no es ficticio o ya ha sido reclamado'),
        );
      }

      // Validar que el usuario no sea creador de ningún grupo donde esté el ficticio
      final groupsResult = await groupsRepository.getGroupsByMemberId(fictionalUserId);
      final groupsWithFictional = groupsResult.when(
        success: (groups) => groups,
        error: (_) => <Group>[],
      );
      for (final group in groupsWithFictional) {
        if (group.createdBy == firebaseUser.uid) {
          return const Error(
            AuthFailure('El creador del grupo no puede reclamar usuarios ficticios'),
          );
        }
      }

      // Validar que el usuario no tenga gastos asociados en los grupos donde está el ficticio
      bool hasExpensesInFictionalGroups = false;
      for (final group in groupsWithFictional) {
        final groupExpensesResult = await expensesRepository.getGroupExpenses(group.id);
        final groupExpenses = groupExpensesResult.when(
          success: (expenses) => expenses,
          error: (_) => <Expense>[],
        );
        for (final expense in groupExpenses) {
          if (expense.paidBy == firebaseUser.uid ||
              expense.splitAmounts.containsKey(firebaseUser.uid)) {
            hasExpensesInFictionalGroups = true;
            break;
          }
        }
        if (hasExpensesInFictionalGroups) break;
      }
      
      if (hasExpensesInFictionalGroups) {
        return const Error(
          AuthFailure('No puedes reclamar un usuario ficticio si ya tienes gastos asociados en los grupos donde está'),
        );
      }

      // Reemplazar el usuario ficticio por el usuario real en todos los grupos
      final replaceGroupsResult = await groupsRepository.replaceFictionalUserWithRealUser(
        fictionalUserId,
        firebaseUser.uid,
      );
      replaceGroupsResult.when(
        success: (_) {},
        error: (failure) {
          throw Exception('Error al reemplazar en grupos: ${failure.message}');
        },
      );

      // Reemplazar el usuario ficticio por el usuario real en todos los gastos
      final replaceExpensesResult = await expensesRepository.replaceUserIdInExpenses(
        fictionalUserId,
        firebaseUser.uid,
      );
      replaceExpensesResult.when(
        success: (_) {},
        error: (failure) {
          throw Exception('Error al reemplazar en gastos: ${failure.message}');
        },
      );

      // Obtener el usuario real actual (si existe) para mantener su nombre
      User? realUser = await userRemoteDataSource.getUserById(firebaseUser.uid);
      
      // Si no existe el usuario real, crearlo con los datos de Firebase Auth
      if (realUser == null) {
        realUser = User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ??
              firebaseUser.email?.split('@')[0] ??
              'Usuario',
          avatarUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
          isFictional: false,
        );
        await userRemoteDataSource.createUser(realUser);
      }
      // Si ya existe, mantener su nombre original (no cambiarlo)

      // Eliminar el usuario ficticio después de reemplazarlo en grupos y gastos
      await userRemoteDataSource.deleteUser(fictionalUserId);

      // Guardar en cache local
      try {
        await localDataSource.saveUser(realUser);
      } catch (e) {
        // Si falla el cache local, no es crítico
      }

      return Success(realUser);
    } catch (e) {
      String errorMessage = 'Error al reclamar usuario ficticio';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      return Error(AuthFailure(errorMessage));
    }
  }

  Future<User?> _tryAutoLoginWithStoredCredentials() async {
    try {
      final credentials = await credentialsStorage.readCredentials();
      if (credentials == null) {
        return null;
      }

      final result = await login(credentials.email, credentials.password);
      if (result is Success<User>) {
        return result.data;
      }
      await credentialsStorage.clearCredentials();
      return null;
    } catch (_) {
      return null;
    }
  }
}
