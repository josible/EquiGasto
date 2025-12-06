import '../../../../core/utils/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class MigrateUserDataUseCase {
  final AuthRepository repository;

  MigrateUserDataUseCase(this.repository);

  Future<Result<User>> call(String oldUserId, String newUserId) {
    return repository.migrateUserData(oldUserId, newUserId);
  }
}

