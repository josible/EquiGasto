import '../../../../core/utils/result.dart';
import '../entities/group.dart';
import '../repositories/groups_repository.dart';

class CreateGroupUseCase {
  final GroupsRepository repository;

  CreateGroupUseCase(this.repository);

  Future<Result<Group>> call(String name, String description, String createdBy) {
    return repository.createGroup(name, description, createdBy);
  }
}









