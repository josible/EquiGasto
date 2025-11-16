import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/group.dart';

abstract class GroupsRemoteDataSource {
  Future<List<Group>> getUserGroups(String userId);
  Future<Group?> getGroupById(String groupId);
  Future<void> createGroup(Group group);
  Future<void> updateGroup(Group group);
  Future<void> deleteGroup(String groupId);
  Future<String?> findUserIdByEmail(String email);
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

