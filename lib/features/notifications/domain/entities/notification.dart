import 'package:equatable/equatable.dart';

enum NotificationType {
  expenseAdded,
  groupInvitation,
  debtSettled,
  memberLeft,
}

class AppNotification extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        message,
        data,
        isRead,
        createdAt,
      ];
}
