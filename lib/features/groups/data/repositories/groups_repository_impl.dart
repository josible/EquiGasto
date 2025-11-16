import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/group.dart';
import '../../domain/repositories/groups_repository.dart';
import '../datasources/groups_local_datasource.dart';
import '../datasources/groups_remote_datasource.dart';

class GroupsRepositoryImpl implements GroupsRepository {
  final GroupsLocalDataSource localDataSource;
  final GroupsRemoteDataSource remoteDataSource;

  GroupsRepositoryImpl(this.localDataSource, this.remoteDataSource);

  @override
  Future<Result<List<Group>>> getUserGroups(String userId) async {
    try {
      // Obtener grupos desde Firestore (solo los que el usuario es miembro)
      final groups = await remoteDataSource.getUserGroups(userId);
      
      // Guardar en cache local (opcional)
      try {
        for (final group in groups) {
          await localDataSource.saveGroup(group);
        }
      } catch (e) {
        // Si falla el cache, no es crítico
      }
      
      return Success(groups);
    } catch (e) {
      return Error(ServerFailure('Error al obtener grupos: $e'));
    }
  }

  @override
  Future<Result<Group>> getGroupById(String groupId) async {
    try {
      // Obtener desde Firestore
      final group = await remoteDataSource.getGroupById(groupId);
      if (group == null) {
        return Error(NotFoundFailure('Grupo no encontrado'));
      }
      
      // Guardar en cache local (opcional)
      try {
        await localDataSource.saveGroup(group);
      } catch (e) {
        // Si falla el cache, no es crítico
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
        memberIds: [createdBy], // El creador es automáticamente miembro
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Crear en Firestore
      await remoteDataSource.createGroup(group);
      
      // Guardar en cache local (opcional)
      try {
        await localDataSource.saveGroup(group);
      } catch (e) {
        // Si falla el cache, no es crítico
      }
      
      return Success(group);
    } catch (e) {
      return Error(ServerFailure('Error al crear grupo: $e'));
    }
  }

  @override
  Future<Result<Group>> updateGroup(String groupId, String name, String description) async {
    try {
      // Obtener grupo desde Firestore
      final existingGroup = await remoteDataSource.getGroupById(groupId);
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

      // Actualizar en Firestore
      await remoteDataSource.updateGroup(updatedGroup);
      
      // Actualizar cache local (opcional)
      try {
        await localDataSource.saveGroup(updatedGroup);
      } catch (e) {
        // Si falla el cache, no es crítico
      }
      
      return Success(updatedGroup);
    } catch (e) {
      return Error(ServerFailure('Error al actualizar grupo: $e'));
    }
  }

  @override
  Future<Result<void>> deleteGroup(String groupId) async {
    try {
      // Eliminar de Firestore
      await remoteDataSource.deleteGroup(groupId);
      
      // Eliminar de cache local (opcional)
      try {
        await localDataSource.deleteGroup(groupId);
      } catch (e) {
        // Si falla el cache, no es crítico
      }
      
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure('Error al eliminar grupo: $e'));
    }
  }

  @override
  Future<Result<void>> inviteUserToGroup(String groupId, String userEmail) async {
    try {
      // Obtener grupo desde Firestore
      final group = await remoteDataSource.getGroupById(groupId);
      if (group == null) {
        return Error(NotFoundFailure('Grupo no encontrado'));
      }

      // Buscar usuario por email en Firestore
      final invitedUserId = await remoteDataSource.findUserIdByEmail(userEmail);
      if (invitedUserId == null) {
        return const Error(ValidationFailure('Usuario no encontrado con ese email'));
      }

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

      // Actualizar en Firestore
      await remoteDataSource.updateGroup(updatedGroup);
      
      // Actualizar cache local (opcional)
      try {
        await localDataSource.saveGroup(updatedGroup);
      } catch (e) {
        // Si falla el cache, no es crítico
      }
      
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure('Error al invitar usuario: $e'));
    }
  }

  @override
  Future<Result<void>> removeUserFromGroup(String groupId, String userId) async {
    try {
      // Obtener grupo desde Firestore
      final group = await remoteDataSource.getGroupById(groupId);
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

      // Actualizar en Firestore
      await remoteDataSource.updateGroup(updatedGroup);
      
      // Actualizar cache local (opcional)
      try {
        await localDataSource.saveGroup(updatedGroup);
      } catch (e) {
        // Si falla el cache, no es crítico
      }
      
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure('Error al remover usuario: $e'));
    }
  }
}


