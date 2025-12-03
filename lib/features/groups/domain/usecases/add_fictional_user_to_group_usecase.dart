import '../../../../core/utils/result.dart';
import '../../../auth/domain/entities/user.dart';
import '../repositories/groups_repository.dart';

class AddFictionalUserToGroupUseCase {
  final GroupsRepository repository;

  AddFictionalUserToGroupUseCase(this.repository);

  Future<Result<User>> call(String groupId, String name) {
    return repository.addFictionalUserToGroup(groupId, name);
  }
}

