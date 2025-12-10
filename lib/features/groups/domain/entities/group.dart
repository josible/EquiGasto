import 'package:equatable/equatable.dart';
import 'currency.dart';

class Group extends Equatable {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final List<String> memberIds;
  final Currency currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.memberIds,
    this.currency = Currency.eur, // Default a EUR para compatibilidad
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
        currency,
        createdAt,
        updatedAt,
      ];
}


