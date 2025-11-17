import '../../../../core/utils/result.dart';
import '../repositories/groups_repository.dart';

class RemoveUserFromGroupUseCase {
  final GroupsRepository repository;

  RemoveUserFromGroupUseCase(this.repository);

  Future<Result<void>> call(String groupId, String userId) {
    return repository.removeUserFromGroup(groupId, userId);
  }
}
