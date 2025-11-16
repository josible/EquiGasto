import '../../../../core/utils/result.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Result<User>> login(String email, String password);
  Future<Result<User>> loginWithGoogle();
  Future<Result<User>> register(String email, String password, String name);
  Future<Result<void>> logout();
  Future<Result<User?>> getCurrentUser();
  Future<Result<User>> updateProfile(String userId, String name, String? avatarUrl);
}


