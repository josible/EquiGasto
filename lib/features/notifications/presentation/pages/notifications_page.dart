import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../../../../core/di/providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notificaciones')),
        body: const Center(child: Text('No hay usuario autenticado')),
      );
    }

    final notificationsRepository = ref.watch(notificationsRepositoryProvider);
    final notificationsAsync = ref.watch(userNotificationsProvider(user.id));
    final notificationsData =
        notificationsAsync.maybeWhen(data: (data) => data, orElse: () => null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if ((notificationsData?.isNotEmpty ?? false))
            TextButton(
              onPressed: () async {
                final result =
                    await notificationsRepository.markAllAsRead(user.id);
                result.when(
                  success: (_) {},
                  error: (failure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(failure.message)),
                    );
                  },
                );
              },
              child: const Text('Eliminar todo'),
            ),
        ],
      ),
      body: notificationsAsync.when(
            data: (notifications) {
              if (notifications.isEmpty) {
                return const _EmptyNotifications();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Card(
                    color: notification.isRead
                        ? null
                        : isDark
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.blue.shade50,
                    child: ListTile(
                      leading: Icon(
                        _getIconForType(notification.type),
                        color: notification.isRead
                            ? (isDark ? Colors.grey[400] : Colors.grey)
                            : (isDark ? Colors.blue[300] : Colors.blue),
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        '${notification.createdAt.day}/${notification.createdAt.month}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () async {
                        final result = await notificationsRepository
                            .markAsRead(notification.id);
                        result.when(
                          success: (_) {},
                          error: (failure) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(failure.message)),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const _EmptyNotifications(),
            error: (error, stack) => const _EmptyNotifications(),
          ),
    );
  }

  IconData _getIconForType(NotificationType notificationType) {
    switch (notificationType) {
      case NotificationType.expenseAdded:
        return Icons.receipt;
      case NotificationType.groupInvitation:
        return Icons.group_add;
      case NotificationType.debtSettled:
        return Icons.check_circle;
      case NotificationType.memberLeft:
        return Icons.person_remove;
    }
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Sin notificaciones',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
