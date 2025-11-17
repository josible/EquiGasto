import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/group.dart';
import '../../domain/usecases/get_user_groups_usecase.dart';
import '../../domain/usecases/create_group_usecase.dart';
import '../../domain/usecases/delete_group_usecase.dart';
import '../../domain/usecases/invite_user_to_group_usecase.dart';
import '../../domain/usecases/generate_invite_code_usecase.dart';
import '../../domain/usecases/get_group_by_invite_code_usecase.dart';
import '../../domain/usecases/join_group_by_code_usecase.dart';
import '../../domain/usecases/remove_user_from_group_usecase.dart';
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

final inviteUserToGroupUseCaseProvider =
    Provider<InviteUserToGroupUseCase>((ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return InviteUserToGroupUseCase(repository);
});

final generateInviteCodeUseCaseProvider =
    Provider<GenerateInviteCodeUseCase>((ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return GenerateInviteCodeUseCase(repository);
});

final getGroupByInviteCodeUseCaseProvider =
    Provider<GetGroupByInviteCodeUseCase>((ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return GetGroupByInviteCodeUseCase(repository);
});

final joinGroupByCodeUseCaseProvider = Provider<JoinGroupByCodeUseCase>((ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return JoinGroupByCodeUseCase(repository);
});

final removeUserFromGroupUseCaseProvider =
    Provider<RemoveUserFromGroupUseCase>((ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return RemoveUserFromGroupUseCase(repository);
});

final groupByInviteCodeProvider =
    FutureProvider.family<Group, String>((ref, inviteCode) async {
  print('🔍 groupByInviteCodeProvider - Buscando grupo con código: $inviteCode (longitud: ${inviteCode.length})');
  debugPrint('🔍 groupByInviteCodeProvider - Buscando grupo con código: $inviteCode (longitud: ${inviteCode.length})');
  
  // Validar que el código tenga una longitud razonable (los códigos son de 8 caracteres)
  if (inviteCode.length > 20 || inviteCode.length < 4) {
    print('❌ groupByInviteCodeProvider - Código inválido (longitud: ${inviteCode.length})');
    debugPrint('❌ groupByInviteCodeProvider - Código inválido (longitud: ${inviteCode.length})');
    throw Exception('Código de invitación inválido. El código debe tener entre 4 y 20 caracteres.');
  }
  
  try {
    // Usar ref.read en lugar de ref.watch para evitar recargas infinitas
    final useCase = ref.read(getGroupByInviteCodeUseCaseProvider);
    
    // Agregar timeout de 5 segundos para evitar que se quede colgado
    final result = await Future(() => useCase(inviteCode)).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('❌ groupByInviteCodeProvider - Timeout después de 5 segundos');
        debugPrint('❌ groupByInviteCodeProvider - Timeout después de 5 segundos');
        throw Exception('Tiempo de espera agotado. El código podría no existir.');
      },
    );

    return result.when(
      success: (group) {
        print('✅ groupByInviteCodeProvider - Grupo encontrado: ${group.id} - ${group.name}');
        debugPrint('✅ groupByInviteCodeProvider - Grupo encontrado: ${group.id} - ${group.name}');
        return group;
      },
      error: (failure) {
        print('❌ groupByInviteCodeProvider - Error: ${failure.message}');
        debugPrint('❌ groupByInviteCodeProvider - Error: ${failure.message}');
        // Lanzar una excepción con el mensaje de error para que el provider entre en estado de error
        throw Exception(failure.message);
      },
    );
  } catch (e) {
    print('❌ groupByInviteCodeProvider - Excepción: $e');
    debugPrint('❌ groupByInviteCodeProvider - Excepción: $e');
    // Re-lanzar la excepción para que el provider entre en estado de error y no se recargue
    rethrow;
  }
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

final groupProvider =
    FutureProvider.family<Group, String>((ref, groupId) async {
  final repository = ref.watch(groupsRepositoryProvider);
  final result = await repository.getGroupById(groupId);

  return result.when(
    success: (group) => group,
    error: (failure) => throw Exception(failure.message),
  );
});
