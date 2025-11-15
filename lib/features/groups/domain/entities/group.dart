import 'package:equatable/equatable.dart';

class Group extends Equatable {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        createdBy,
        memberIds,
        createdAt,
        updatedAt,
      ];
}

