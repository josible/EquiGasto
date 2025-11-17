import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Result<void>> call(String email) {
    return repository.resetPassword(email);
  }
}

