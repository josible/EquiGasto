import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../../../core/di/providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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
    final notificationsAsync = FutureProvider((ref) async {
      final result = await notificationsRepository.getUserNotifications(user.id);
      return result.when(
        success: (notifications) => notifications,
        error: (_) => [],
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: ref.watch(notificationsAsync).when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                color: notification.isRead ? null : Colors.blue.shade50,
                child: ListTile(
                  leading: Icon(
                    _getIconForType(notification.type),
                    color: notification.isRead ? Colors.grey : Colors.blue,
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(notification.message),
                  trailing: Text(
                    '${notification.createdAt.day}/${notification.createdAt.month}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    if (!notification.isRead) {
                      await notificationsRepository.markAsRead(notification.id);
                      ref.invalidate(notificationsAsync);
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  IconData _getIconForType(notificationType) {
    switch (notificationType.toString()) {
      case 'NotificationType.expenseAdded':
        return Icons.receipt;
      case 'NotificationType.groupInvitation':
        return Icons.group_add;
      case 'NotificationType.debtSettled':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }
}

