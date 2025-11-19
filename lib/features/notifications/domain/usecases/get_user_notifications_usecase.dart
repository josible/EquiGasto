import '../../../../core/utils/result.dart';
import '../entities/notification.dart';
import '../repositories/notifications_repository.dart';

class GetUserNotificationsUseCase {
  final NotificationsRepository repository;

  GetUserNotificationsUseCase(this.repository);

  Future<Result<List<AppNotification>>> call(String userId) {
    return repository.getUserNotifications(userId);
  }
}













