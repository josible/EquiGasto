import '../../../../core/utils/result.dart';
import '../entities/group.dart';
import '../entities/currency.dart';
import '../repositories/groups_repository.dart';

class CreateGroupUseCase {
  final GroupsRepository repository;

  CreateGroupUseCase(this.repository);

  Future<Result<Group>> call(String name, String description, String createdBy, Currency currency) {
    return repository.createGroup(name, description, createdBy, currency);
  }
}













