import '../../../../core/utils/result.dart';
import '../entities/notification.dart';

abstract class NotificationsRepository {
  Future<Result<List<AppNotification>>> getUserNotifications(String userId);
  Future<Result<void>> markAsRead(String notificationId);
  Future<Result<void>> markAllAsRead(String userId);
  Future<Result<int>> getUnreadCount(String userId);
  Future<Result<void>> createNotification(AppNotification notification);
  Stream<List<AppNotification>> watchUserNotifications(String userId);
  Stream<int> watchUnreadCount(String userId);
}
