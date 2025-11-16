import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/group.dart';

abstract class GroupsRemoteDataSource {
  Future<List<Group>> getUserGroups(String userId);
  Future<Group?> getGroupById(String groupId);
  Future<void> createGroup(Group group);
  Future<void> updateGroup(Group group);
  Future<void> deleteGroup(String groupId);
  Future<String?> findUserIdByEmail(String email);
  Future<String> generateInviteCode(String groupId);
  Future<String?> getGroupIdByInviteCode(String inviteCode);
  Future<void> joinGroupByCode(String groupId, String userId);
}

class GroupsRemoteDataSourceImpl implements GroupsRemoteDataSource {
  final FirebaseFirestore firestore;

  GroupsRemoteDataSourceImpl(this.firestore);

  @override
  Future<List<Group>> getUserGroups(String userId) async {
    try {
      // Obtener solo grupos donde el usuario es miembro
      // Nota: Si quieres ordenar por updatedAt, necesitarás crear un índice compuesto en Firestore
      // Por ahora, obtenemos todos y ordenamos en memoria
      final querySnapshot = await firestore
          .collection('groups')
          .where('memberIds', arrayContains: userId)
          .get();

      final groups = querySnapshot.docs
          .map((doc) => _mapDocumentToGroup(doc))
          .toList();
      
      // Ordenar por updatedAt descendente
      groups.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return groups;
    } catch (e) {
      throw Exception('Error al obtener grupos del usuario: $e');
    }
  }

  @override
  Future<Group?> getGroupById(String groupId) async {
    try {
      final doc = await firestore.collection('groups').doc(groupId).get();
      if (!doc.exists) return null;
      return _mapDocumentToGroup(doc);
    } catch (e) {
      throw Exception('Error al obtener grupo: $e');
    }
  }

  @override
  Future<void> createGroup(Group group) async {
    try {
      await firestore.collection('groups').doc(group.id).set({
        'id': group.id,
        'name': group.name,
        'description': group.description,
        'createdBy': group.createdBy,
        'memberIds': group.memberIds,
        'createdAt': Timestamp.fromDate(group.createdAt),
        'updatedAt': Timestamp.fromDate(group.updatedAt),
      });
    } catch (e) {
      throw Exception('Error al crear grupo: $e');
    }
  }

  @override
  Future<void> updateGroup(Group group) async {
    try {
      await firestore.collection('groups').doc(group.id).update({
        'name': group.name,
        'description': group.description,
        'memberIds': group.memberIds,
        'updatedAt': Timestamp.fromDate(group.updatedAt),
      });
    } catch (e) {
      throw Exception('Error al actualizar grupo: $e');
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    try {
      await firestore.collection('groups').doc(groupId).delete();
    } catch (e) {
      throw Exception('Error al eliminar grupo: $e');
    }
  }

  @override
  Future<String?> findUserIdByEmail(String email) async {
    try {
      // Buscar usuario por email en la colección de usuarios
      final querySnapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      return querySnapshot.docs.first.id;
    } catch (e) {
      throw Exception('Error al buscar usuario por email: $e');
    }
  }

  @override
  Future<String> generateInviteCode(String groupId) async {
    try {
      // Verificar si ya existe un código para este grupo
      final inviteQuery = await firestore
          .collection('group_invites')
          .where('groupId', isEqualTo: groupId)
          .limit(1)
          .get();

      if (inviteQuery.docs.isNotEmpty) {
        return inviteQuery.docs.first.id;
      }

      // Generar un código único de 8 caracteres
      // Usar los últimos caracteres del groupId (mínimo 8) o rellenar
      String code;
      if (groupId.length >= 8) {
        code = groupId.substring(groupId.length - 8).toUpperCase();
      } else {
        // Si el groupId es muy corto, usar el groupId completo y rellenar
        code = groupId.toUpperCase().padRight(8, '0');
      }
      
      // Asegurarse de que el código tenga exactamente 8 caracteres
      code = code.length > 8 ? code.substring(0, 8) : code.padRight(8, '0');
      
      // Verificar que el código no exista ya (por si acaso)
      final existingDoc = await firestore.collection('group_invites').doc(code).get();
      if (existingDoc.exists && existingDoc.data()?['groupId'] != groupId) {
        // Si existe pero es para otro grupo, agregar un sufijo
        code = '${code.substring(0, 6)}${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 2)}';
      }
      
      // Guardar en Firestore
      await firestore.collection('group_invites').doc(code).set({
        'groupId': groupId,
        'createdAt': Timestamp.now(),
      });

      return code;
    } catch (e) {
      throw Exception('Error al generar código de invitación: $e');
    }
  }

  @override
  Future<String?> getGroupIdByInviteCode(String inviteCode) async {
    try {
      final doc = await firestore.collection('group_invites').doc(inviteCode.toUpperCase()).get();
      if (!doc.exists) return null;
      final data = doc.data();
      return data?['groupId'] as String?;
    } catch (e) {
      throw Exception('Error al obtener grupo por código: $e');
    }
  }

  @override
  Future<void> joinGroupByCode(String groupId, String userId) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) {
        throw Exception('Grupo no encontrado');
      }

      if (group.memberIds.contains(userId)) {
        throw Exception('Ya eres miembro de este grupo');
      }

      final updatedGroup = Group(
        id: group.id,
        name: group.name,
        description: group.description,
        createdBy: group.createdBy,
        memberIds: [...group.memberIds, userId],
        createdAt: group.createdAt,
        updatedAt: DateTime.now(),
      );

      await updateGroup(updatedGroup);
    } catch (e) {
      throw Exception('Error al unirse al grupo: $e');
    }
  }

  Group _mapDocumentToGroup(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Group(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      createdBy: data['createdBy'] as String,
      memberIds: List<String>.from(data['memberIds'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}

