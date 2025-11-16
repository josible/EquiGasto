import '../../../../core/utils/result.dart';
import '../entities/group.dart';
import '../repositories/groups_repository.dart';

class GetGroupByInviteCodeUseCase {
  final GroupsRepository repository;

  GetGroupByInviteCodeUseCase(this.repository);

  Future<Result<Group>> call(String inviteCode) {
    return repository.getGroupByInviteCode(inviteCode);
  }
}

