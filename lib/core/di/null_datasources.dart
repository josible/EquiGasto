import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/groups/data/datasources/groups_local_datasource.dart';
import '../../features/groups/domain/entities/group.dart';
import '../../features/expenses/data/datasources/expenses_local_datasource.dart';
import '../../features/expenses/domain/entities/expense.dart';
import '../../features/notifications/data/datasources/notifications_local_datasource.dart';
import '../../features/notifications/domain/entities/notification.dart' as notification_entity;

// Null implementations that do nothing - used when SharedPreferences is not ready
// These classes are exported for use in providers.dart
class NullAuthLocalDataSource implements AuthLocalDataSource {
  @override
  Future<void> saveUser(User user) async {
    // Do nothing
  }

  @override
  Future<User?> getCurrentUser() async {
    return null;
  }

  @override
  Future<void> clearUser() async {
    // Do nothing
  }
}

class NullGroupsLocalDataSource implements GroupsLocalDataSource {
  @override
  Future<List<Group>> getUserGroups(String userId) async {
    return [];
  }

  @override
  Future<Group?> getGroupById(String groupId) async {
    return null;
  }

  @override
  Future<void> saveGroup(Group group) async {
    // Do nothing
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    // Do nothing
  }
}

class NullExpensesLocalDataSource implements ExpensesLocalDataSource {
  @override
  Future<List<Expense>> getGroupExpenses(String groupId) async {
    return [];
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    return [];
  }

  @override
  Future<void> saveExpense(Expense expense) async {
    // Do nothing
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    // Do nothing
  }
}

class NullNotificationsLocalDataSource implements NotificationsLocalDataSource {
  @override
  Future<List<notification_entity.AppNotification>> getUserNotifications(String userId) async {
    return [];
  }

  @override
  Future<void> saveNotification(notification_entity.AppNotification notification) async {
    // Do nothing
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    // Do nothing
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    // Do nothing
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    return 0;
  }
}

