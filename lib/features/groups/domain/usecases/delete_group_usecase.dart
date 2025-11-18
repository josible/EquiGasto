import '../../../../core/utils/result.dart';
import '../repositories/groups_repository.dart';

class DeleteGroupUseCase {
  final GroupsRepository repository;

  DeleteGroupUseCase(this.repository);

  Future<Result<void>> call(String groupId) {
    return repository.deleteGroup(groupId);
  }
}










