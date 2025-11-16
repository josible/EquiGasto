import '../../../../core/utils/result.dart';
import '../repositories/groups_repository.dart';

class InviteUserToGroupUseCase {
  final GroupsRepository repository;

  InviteUserToGroupUseCase(this.repository);

  Future<Result<void>> call(String groupId, String userEmail) {
    return repository.inviteUserToGroup(groupId, userEmail);
  }
}

