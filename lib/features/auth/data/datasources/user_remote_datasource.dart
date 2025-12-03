import 'package:flutter/foundation.dart';
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
      final data = {
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'avatarUrl': user.avatarUrl,
        'createdAt': Timestamp.fromDate(user.createdAt),
      };
      // Solo agregar isFictional si es true (para no guardar null)
      if (user.isFictional == true) {
        data['isFictional'] = true;
      }
      await firestore.collection('users').doc(user.id).set(data);
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
      
      print('🔍 getUsersByIds - Obteniendo ${userIds.length} usuarios: $userIds');
      debugPrint('🔍 getUsersByIds - Obteniendo ${userIds.length} usuarios: $userIds');
      
      // Firestore permite hasta 10 documentos en una consulta 'in'
      // Si hay más, necesitamos hacer múltiples consultas
      final List<User> users = [];
      for (var i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        print('🔍 getUsersByIds - Procesando batch: $batch');
        debugPrint('🔍 getUsersByIds - Procesando batch: $batch');
        final futures = batch.map((id) => getUserById(id));
        final results = await Future.wait(futures);
        users.addAll(results.whereType<User>());
        print('🔍 getUsersByIds - Batch completado, usuarios encontrados: ${results.whereType<User>().length}');
        debugPrint('🔍 getUsersByIds - Batch completado, usuarios encontrados: ${results.whereType<User>().length}');
      }
      
      print('✅ getUsersByIds - Total usuarios obtenidos: ${users.length}');
      debugPrint('✅ getUsersByIds - Total usuarios obtenidos: ${users.length}');
      return users;
    } catch (e) {
      print('❌ getUsersByIds - Error: $e');
      debugPrint('❌ getUsersByIds - Error: $e');
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  @override
  Future<void> updateUser(User user) async {
    try {
      final data = <String, dynamic>{
        'name': user.name,
        'avatarUrl': user.avatarUrl,
        'email': user.email,
      };
      // Actualizar isFictional si está definido
      if (user.isFictional != null) {
        if (user.isFictional == true) {
          data['isFictional'] = true;
        } else {
          // Si es false, eliminar el campo (para usuarios que eran ficticios)
          data['isFictional'] = FieldValue.delete();
        }
      }
      await firestore.collection('users').doc(user.id).update(data);
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
      email: data['email'] as String? ?? '', // Email puede estar vacío para usuarios ficticios
      name: data['name'] as String,
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isFictional: data['isFictional'] as bool? ?? false,
    );
  }
}

