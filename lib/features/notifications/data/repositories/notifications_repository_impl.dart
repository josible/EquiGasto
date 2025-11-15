import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_local_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsLocalDataSource localDataSource;

  NotificationsRepositoryImpl(this.localDataSource);

  @override
  Future<Result<List<AppNotification>>> getUserNotifications(String userId) async {
    try {
      final notifications = await localDataSource.getUserNotifications(userId);
      return Success(notifications);
    } catch (e) {
      return Error(ServerFailure('Error al obtener notificaciones: $e'));
    }
  }

  @override
  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      await localDataSource.markAsRead(notificationId);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure('Error al marcar notificación: $e'));
    }
  }

  @override
  Future<Result<void>> markAllAsRead(String userId) async {
    try {
      await localDataSource.markAllAsRead(userId);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure('Error al marcar todas como leídas: $e'));
    }
  }

  @override
  Future<Result<int>> getUnreadCount(String userId) async {
    try {
      final count = await localDataSource.getUnreadCount(userId);
      return Success(count);
    } catch (e) {
      return Error(ServerFailure('Error al obtener conteo: $e'));
    }
  }
}

