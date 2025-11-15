import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/group.dart';
import '../../domain/usecases/get_user_groups_usecase.dart';
import '../../domain/usecases/create_group_usecase.dart';
import '../../domain/usecases/delete_group_usecase.dart';
import '../../../../core/di/providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final getUserGroupsUseCaseProvider = Provider<GetUserGroupsUseCase>((ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return GetUserGroupsUseCase(repository);
});

final createGroupUseCaseProvider = Provider<CreateGroupUseCase>((ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return CreateGroupUseCase(repository);
});

final deleteGroupUseCaseProvider = Provider<DeleteGroupUseCase>((ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return DeleteGroupUseCase(repository);
});

final groupsListProvider = FutureProvider<List<Group>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return [];
  }

  final useCase = ref.watch(getUserGroupsUseCaseProvider);
  final result = await useCase(user.id);

  return result.when(
    success: (groups) => groups,
    error: (_) => [],
  );
});

