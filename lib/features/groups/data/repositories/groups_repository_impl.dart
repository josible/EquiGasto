import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/group.dart';
import '../../domain/repositories/groups_repository.dart';
import '../datasources/groups_local_datasource.dart';

class GroupsRepositoryImpl implements GroupsRepository {
  final GroupsLocalDataSource localDataSource;

  GroupsRepositoryImpl(this.localDataSource);

  @override
  Future<Result<List<Group>>> getUserGroups(String userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final groups = await localDataSource.getUserGroups(userId);
      return Success(groups);
    } catch (e) {
      return Error(ServerFailure('Error al obtener grupos: $e'));
    }
  }

  @override
  Future<Result<Group>> getGroupById(String groupId) async {
    try {
      final group = await localDataSource.getGroupById(groupId);
      if (group == null) {
        return Error(NotFoundFailure('Grupo no encontrado'));
      }
      return Success(group);
    } catch (e) {
      return Error(ServerFailure('Error al obtener grupo: $e'));
    }
  }

  @override
  Future<Result<Group>> createGroup(String name, String description, String createdBy) async {
    try {
      if (name.isEmpty) {
        return const Error(ValidationFailure('El nombre del grupo es requerido'));
      }

      final group = Group(
        id: const Uuid().v4(),
        name: name,
        description: description,
        createdBy: createdBy,
        memberIds: [createdBy],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await localDataSource.saveGroup(group);
      return Success(group);
    } catch (e) {
      return Error(ServerFailure('Error al crear grupo: $e'));
    }
  }

  @override
  Future<Result<Group>> updateGroup(String groupId, String name, String description) async {
    try {
      final existingGroup = await localDataSource.getGroupById(groupId);
      if (existingGroup == null) {
        return Error(NotFoundFailure('Grupo no encontrado'));
      }

      final updatedGroup = Group(
        id: existingGroup.id,
        name: name,
        description: description,
        createdBy: existingGroup.createdBy,
        memberIds: existingGroup.memberIds,
        createdAt: existingGroup.createdAt,
        updatedAt: DateTime.now(),
      );

      await localDataSource.saveGroup(updatedGroup);
      return Success(updatedGroup);
    } catch (e) {
      return Error(ServerFailure('Error al actualizar grupo: $e'));
    }
  }

  @override
  Future<Result<void>> deleteGroup(String groupId) async {
    try {
      await localDataSource.deleteGroup(groupId);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure('Error al eliminar grupo: $e'));
    }
  }

  @override
  Future<Result<void>> inviteUserToGroup(String groupId, String userEmail) async {
    try {
      final group = await localDataSource.getGroupById(groupId);
      if (group == null) {
        return Error(NotFoundFailure('Grupo no encontrado'));
      }

      // Mock: Simular búsqueda de usuario por email
      final invitedUserId = const Uuid().v4(); // En producción, buscar por email

      if (group.memberIds.contains(invitedUserId)) {
        return const Error(ValidationFailure('El usuario ya es miembro del grupo'));
      }

      final updatedGroup = Group(
        id: group.id,
        name: group.name,
        description: group.description,
        createdBy: group.createdBy,
        memberIds: [...group.memberIds, invitedUserId],
        createdAt: group.createdAt,
        updatedAt: DateTime.now(),
      );

      await localDataSource.saveGroup(updatedGroup);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure('Error al invitar usuario: $e'));
    }
  }

  @override
  Future<Result<void>> removeUserFromGroup(String groupId, String userId) async {
    try {
      final group = await localDataSource.getGroupById(groupId);
      if (group == null) {
        return Error(NotFoundFailure('Grupo no encontrado'));
      }

      if (!group.memberIds.contains(userId)) {
        return const Error(ValidationFailure('El usuario no es miembro del grupo'));
      }

      final updatedMemberIds = group.memberIds.where((id) => id != userId).toList();
      final updatedGroup = Group(
        id: group.id,
        name: group.name,
        description: group.description,
        createdBy: group.createdBy,
        memberIds: updatedMemberIds,
        createdAt: group.createdAt,
        updatedAt: DateTime.now(),
      );

      await localDataSource.saveGroup(updatedGroup);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure('Error al remover usuario: $e'));
    }
  }
}

