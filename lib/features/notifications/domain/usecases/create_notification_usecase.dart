import '../../../../core/utils/result.dart';
import '../entities/notification.dart';
import '../repositories/notifications_repository.dart';

class CreateNotificationUseCase {
  final NotificationsRepository repository;

  CreateNotificationUseCase(this.repository);

  Future<Result<void>> call(AppNotification notification) {
    return repository.createNotification(notification);
  }
}
