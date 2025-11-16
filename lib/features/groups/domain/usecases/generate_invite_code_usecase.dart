import '../../../../core/utils/result.dart';
import '../repositories/groups_repository.dart';

class GenerateInviteCodeUseCase {
  final GroupsRepository repository;

  GenerateInviteCodeUseCase(this.repository);

  Future<Result<String>> call(String groupId) {
    return repository.generateInviteCode(groupId);
  }
}

