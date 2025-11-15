import '../../../../core/utils/result.dart';
import '../entities/group.dart';
import '../repositories/groups_repository.dart';

class GetUserGroupsUseCase {
  final GroupsRepository repository;

  GetUserGroupsUseCase(this.repository);

  Future<Result<List<Group>>> call(String userId) {
    return repository.getUserGroups(userId);
  }
}

