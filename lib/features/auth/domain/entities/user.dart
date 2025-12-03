import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;
  final bool? isFictional; // true si es usuario ficticio, null o false si es real

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.createdAt,
    this.isFictional,
  });

  bool get isRealUser => isFictional != true;

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
    bool? isFictional,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      isFictional: isFictional ?? this.isFictional,
    );
  }

  @override
  List<Object?> get props => [id, email, name, avatarUrl, createdAt, isFictional];
}


