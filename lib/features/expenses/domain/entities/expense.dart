import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final String id;
  final String groupId;
  final String paidBy;
  final String description;
  final double amount;
  final DateTime date;
  final Map<String, double> splitAmounts; // userId -> amount
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.groupId,
    required this.paidBy,
    required this.description,
    required this.amount,
    required this.date,
    required this.splitAmounts,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        groupId,
        paidBy,
        description,
        amount,
        date,
        splitAmounts,
        createdAt,
      ];
}


