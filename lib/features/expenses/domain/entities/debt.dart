import 'package:equatable/equatable.dart';

class Debt extends Equatable {
  final String fromUserId;
  final String toUserId;
  final String groupId;
  final double amount;

  const Debt({
    required this.fromUserId,
    required this.toUserId,
    required this.groupId,
    required this.amount,
  });

  @override
  List<Object?> get props => [fromUserId, toUserId, groupId, amount];
}

