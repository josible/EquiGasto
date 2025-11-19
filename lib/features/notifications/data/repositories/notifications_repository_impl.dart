import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_local_datasource.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsLocalDataSource localDataSource;
  final NotificationsRemoteDataSource remoteDataSource;

  NotificationsRepositoryImpl(
    this.localDataSource,
    this.remoteDataSource,
  );

  @override
  Future<Result<List<AppNotification>>> getUserNotifications(
      String userId) async {
    try {
      final notifications = await remoteDataSource.getUserNotifications(userId);
      return Success(notifications);
    } catch (e) {
      return Error(ServerFailure('Error al obtener notificaciones: $e'));
    }
  }

  @override
  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      await remoteDataSource.markAsRead(notificationId);
      await localDataSource.markAsRead(notificationId);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure('Error al marcar notificación: $e'));
    }
  }

  @override
  Future<Result<void>> markAllAsRead(String userId) async {
    try {
      await remoteDataSource.markAllAsRead(userId);
      await localDataSource.markAllAsRead(userId);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure('Error al marcar todas como leídas: $e'));
    }
  }

  @override
  Future<Result<int>> getUnreadCount(String userId) async {
    try {
      try {
        final count = await remoteDataSource.getUnreadCount(userId);
        return Success(count);
      } catch (e) {
        final fallback = await localDataSource.getUnreadCount(userId);
        return Success(fallback);
      }
    } catch (e) {
      return Error(ServerFailure('Error al obtener conteo: $e'));
    }
  }

  @override
  Future<Result<void>> createNotification(AppNotification notification) async {
    try {
      await remoteDataSource.saveNotification(notification);
      await localDataSource.saveNotification(notification);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure('Error al guardar notificación: $e'));
    }
  }

  @override
  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    return remoteDataSource.watchUserNotifications(userId);
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return remoteDataSource.watchUnreadCount(userId);
  }
}
