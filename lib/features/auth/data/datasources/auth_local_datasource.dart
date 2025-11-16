import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/user.dart';

abstract class AuthLocalDataSource {
  Future<void> saveUser(User user);
  Future<User?> getCurrentUser();
  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences prefs;

  AuthLocalDataSourceImpl(this.prefs);

  @override
  Future<void> saveUser(User user) async {
    final userJson = jsonEncode({
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'avatarUrl': user.avatarUrl,
      'createdAt': user.createdAt.toIso8601String(),
    });
    await prefs.setString('current_user', userJson);
  }

  @override
  Future<User?> getCurrentUser() async {
    final userJson = prefs.getString('current_user');
    if (userJson == null) return null;

    final userMap = jsonDecode(userJson) as Map<String, dynamic>;
    return User(
      id: userMap['id'] as String,
      email: userMap['email'] as String,
      name: userMap['name'] as String,
      avatarUrl: userMap['avatarUrl'] as String?,
      createdAt: DateTime.parse(userMap['createdAt'] as String),
    );
  }

  @override
  Future<void> clearUser() async {
    await prefs.remove('current_user');
  }
}


