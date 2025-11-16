import '../../../../core/utils/result.dart';
import '../repositories/groups_repository.dart';

class JoinGroupByCodeUseCase {
  final GroupsRepository repository;

  JoinGroupByCodeUseCase(this.repository);

  Future<Result<void>> call(String inviteCode, String userId) {
    return repository.joinGroupByCode(inviteCode, userId);
  }
}

