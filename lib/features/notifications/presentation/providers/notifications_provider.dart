import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/notification.dart';
import '../../../../core/di/providers.dart';

final userNotificationsProvider =
    StreamProvider.autoDispose.family<List<AppNotification>, String>(
  (ref, userId) {
    final repository = ref.watch(notificationsRepositoryProvider);
    return repository.watchUserNotifications(userId);
  },
);

final unreadNotificationsCountProvider =
    StreamProvider.autoDispose.family<int, String>(
  (ref, userId) {
    final repository = ref.watch(notificationsRepositoryProvider);
    return repository.watchUnreadCount(userId);
  },
);
