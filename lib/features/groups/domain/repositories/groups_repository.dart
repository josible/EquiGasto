import '../../../../core/utils/result.dart';
import '../entities/group.dart';
import '../../../auth/domain/entities/user.dart';

abstract class GroupsRepository {
  Future<Result<List<Group>>> getUserGroups(String userId);
  Future<Result<Group>> getGroupById(String groupId);
  Future<Result<Group>> createGroup(String name, String description, String createdBy);
  Future<Result<Group>> updateGroup(String groupId, String name, String description);
  Future<Result<void>> deleteGroup(String groupId);
  Future<Result<void>> inviteUserToGroup(String groupId, String userEmail);
  Future<Result<void>> removeUserFromGroup(String groupId, String userId);
  Future<Result<String>> generateInviteCode(String groupId);
  Future<Result<Group>> getGroupByInviteCode(String inviteCode);
  Future<Result<void>> joinGroupByCode(String inviteCode, String userId);
  Future<Result<User>> addFictionalUserToGroup(String groupId, String name);
  Future<Result<void>> replaceFictionalUserWithRealUser(
    String fictionalUserId,
    String realUserId,
  );
  Future<Result<List<Group>>> getGroupsByMemberId(String memberId);
}


