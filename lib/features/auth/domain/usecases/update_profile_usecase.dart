import '../../../../core/utils/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Result<User>> call({
    required String userId,
    required String name,
    String? avatarUrl,
  }) {
    return repository.updateProfile(userId, name, avatarUrl);
  }
}

