import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/notification.dart';

abstract class NotificationsLocalDataSource {
  Future<List<AppNotification>> getUserNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<int> getUnreadCount(String userId);
  Future<void> saveNotification(AppNotification notification);
}

class NotificationsLocalDataSourceImpl implements NotificationsLocalDataSource {
  final SharedPreferences prefs;

  NotificationsLocalDataSourceImpl(this.prefs);

  @override
  Future<List<AppNotification>> getUserNotifications(String userId) async {
    final notificationsJson = prefs.getString('notifications') ?? '[]';
    final List<dynamic> notificationsList = jsonDecode(notificationsJson);
    
    return notificationsList
        .map((json) => _notificationFromJson(json as Map<String, dynamic>))
        .where((notification) => notification.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final notificationsJson = prefs.getString('notifications') ?? '[]';
    final List<dynamic> notificationsList = jsonDecode(notificationsJson);
    
    final index = notificationsList.indexWhere(
      (json) => (json as Map<String, dynamic>)['id'] == notificationId,
    );

    if (index >= 0) {
      final notificationMap = notificationsList[index] as Map<String, dynamic>;
      notificationMap['isRead'] = true;
      notificationsList[index] = notificationMap;
      await prefs.setString('notifications', jsonEncode(notificationsList));
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final notificationsJson = prefs.getString('notifications') ?? '[]';
    final List<dynamic> notificationsList = jsonDecode(notificationsJson);
    
    for (var i = 0; i < notificationsList.length; i++) {
      final notificationMap = notificationsList[i] as Map<String, dynamic>;
      if (notificationMap['userId'] == userId && notificationMap['isRead'] == false) {
        notificationMap['isRead'] = true;
        notificationsList[i] = notificationMap;
      }
    }

    await prefs.setString('notifications', jsonEncode(notificationsList));
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    final notifications = await getUserNotifications(userId);
    return notifications.where((n) => !n.isRead).length;
  }

  @override
  Future<void> saveNotification(AppNotification notification) async {
    final notificationsJson = prefs.getString('notifications') ?? '[]';
    final List<dynamic> notificationsList = jsonDecode(notificationsJson);
    
    final notificationMap = _notificationToJson(notification);
    notificationsList.add(notificationMap);

    await prefs.setString('notifications', jsonEncode(notificationsList));
  }

  AppNotification _notificationFromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.expenseAdded,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> _notificationToJson(AppNotification notification) {
    return {
      'id': notification.id,
      'userId': notification.userId,
      'type': notification.type.name,
      'title': notification.title,
      'message': notification.message,
      'data': notification.data,
      'isRead': notification.isRead,
      'createdAt': notification.createdAt.toIso8601String(),
    };
  }
}


