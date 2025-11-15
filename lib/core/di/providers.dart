import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/groups/data/datasources/groups_local_datasource.dart';
import '../../features/groups/data/repositories/groups_repository_impl.dart';
import '../../features/groups/domain/repositories/groups_repository.dart';
import '../../features/expenses/data/datasources/expenses_local_datasource.dart';
import '../../features/expenses/data/repositories/expenses_repository_impl.dart';
import '../../features/expenses/domain/repositories/expenses_repository.dart';
import '../../features/notifications/data/datasources/notifications_local_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';

// SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

// Data Sources
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  if (prefsAsync.hasValue) {
    return AuthLocalDataSourceImpl(prefsAsync.value!);
  }
  throw Exception('SharedPreferences no está disponible');
});

final groupsLocalDataSourceProvider = Provider<GroupsLocalDataSource>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  if (prefsAsync.hasValue) {
    return GroupsLocalDataSourceImpl(prefsAsync.value!);
  }
  throw Exception('SharedPreferences no está disponible');
});

final expensesLocalDataSourceProvider = Provider<ExpensesLocalDataSource>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  if (prefsAsync.hasValue) {
    return ExpensesLocalDataSourceImpl(prefsAsync.value!);
  }
  throw Exception('SharedPreferences no está disponible');
});

final notificationsLocalDataSourceProvider = Provider<NotificationsLocalDataSource>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  if (prefsAsync.hasValue) {
    return NotificationsLocalDataSourceImpl(prefsAsync.value!);
  }
  throw Exception('SharedPreferences no está disponible');
});

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authLocalDataSourceProvider);
  return AuthRepositoryImpl(dataSource);
});

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  final dataSource = ref.watch(groupsLocalDataSourceProvider);
  return GroupsRepositoryImpl(dataSource);
});

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  final dataSource = ref.watch(expensesLocalDataSourceProvider);
  return ExpensesRepositoryImpl(dataSource);
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final dataSource = ref.watch(notificationsLocalDataSourceProvider);
  return NotificationsRepositoryImpl(dataSource);
});

