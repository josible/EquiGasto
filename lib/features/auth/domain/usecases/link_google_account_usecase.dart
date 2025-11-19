import '../../../../core/utils/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LinkGoogleAccountUseCase {
  final AuthRepository repository;

  LinkGoogleAccountUseCase(this.repository);

  Future<Result<User>> call() {
    return repository.linkGoogleAccount();
  }
}










