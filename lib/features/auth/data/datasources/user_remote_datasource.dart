import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';

abstract class UserRemoteDataSource {
  Future<void> createUser(User user);
  Future<User?> getUserById(String userId);
  Future<List<User>> getUsersByIds(List<String> userIds);
  Future<void> updateUser(User user);
  Future<void> deleteUser(String userId);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore firestore;

  UserRemoteDataSourceImpl(this.firestore);

  @override
  Future<void> createUser(User user) async {
    try {
      await firestore.collection('users').doc(user.id).set({
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'avatarUrl': user.avatarUrl,
        'createdAt': Timestamp.fromDate(user.createdAt),
      });
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  @override
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return _mapDocumentToUser(doc);
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  @override
  Future<List<User>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];
      
      // Firestore permite hasta 10 documentos en una consulta 'in'
      // Si hay más, necesitamos hacer múltiples consultas
      final List<User> users = [];
      for (var i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        final futures = batch.map((id) => getUserById(id));
        final results = await Future.wait(futures);
        users.addAll(results.whereType<User>());
      }
      
      return users;
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  @override
  Future<void> updateUser(User user) async {
    try {
      await firestore.collection('users').doc(user.id).update({
        'name': user.name,
        'avatarUrl': user.avatarUrl,
        'email': user.email,
      });
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  User _mapDocumentToUser(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: data['id'] as String,
      email: data['email'] as String,
      name: data['name'] as String,
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

