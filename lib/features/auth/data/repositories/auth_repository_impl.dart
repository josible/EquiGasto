import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl(this.localDataSource);

  @override
  Future<Result<User>> login(String email, String password) async {
    try {
      // Mock: Simular login
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Validación básica
      if (email.isEmpty || password.isEmpty) {
        return const Error(AuthFailure('Email y contraseña son requeridos'));
      }

      // Mock: Crear usuario si no existe
      final userId = const Uuid().v4();
      final user = User(
        id: userId,
        email: email,
        name: email.split('@')[0],
        createdAt: DateTime.now(),
      );

      await localDataSource.saveUser(user);
      return Success(user);
    } catch (e) {
      return Error(AuthFailure('Error al iniciar sesión: $e'));
    }
  }

  @override
  Future<Result<User>> register(String email, String password, String name) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        return const Error(ValidationFailure('Todos los campos son requeridos'));
      }

      final userId = const Uuid().v4();
      final user = User(
        id: userId,
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );

      await localDataSource.saveUser(user);
      return Success(user);
    } catch (e) {
      return Error(AuthFailure('Error al registrar usuario: $e'));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await localDataSource.clearUser();
      return const Success(null);
    } catch (e) {
      return Error(AuthFailure('Error al cerrar sesión: $e'));
    }
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    try {
      final user = await localDataSource.getCurrentUser();
      return Success(user);
    } catch (e) {
      return Error(AuthFailure('Error al obtener usuario: $e'));
    }
  }

  @override
  Future<Result<void>> updateProfile(String userId, String name, String? avatarUrl) async {
    try {
      final currentUser = await localDataSource.getCurrentUser();
      if (currentUser == null) {
        return const Error(AuthFailure('Usuario no autenticado'));
      }

      final updatedUser = User(
        id: currentUser.id,
        email: currentUser.email,
        name: name,
        avatarUrl: avatarUrl,
        createdAt: currentUser.createdAt,
      );

      await localDataSource.saveUser(updatedUser);
      return const Success(null);
    } catch (e) {
      return Error(AuthFailure('Error al actualizar perfil: $e'));
    }
  }
}

