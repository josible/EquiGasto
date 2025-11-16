import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/user_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/groups/data/datasources/groups_local_datasource.dart';
import '../../features/groups/data/datasources/groups_remote_datasource.dart';
import '../../features/groups/data/repositories/groups_repository_impl.dart';
import '../../features/groups/domain/repositories/groups_repository.dart';
import '../../features/expenses/data/datasources/expenses_local_datasource.dart';
import '../../features/expenses/data/datasources/expenses_remote_datasource.dart';
import '../../features/expenses/data/repositories/expenses_repository_impl.dart';
import '../../features/expenses/domain/repositories/expenses_repository.dart';
import '../../features/notifications/data/datasources/notifications_local_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import 'null_datasources.dart' as null_ds;

// Firebase
final firebaseAuthProvider = Provider<firebase_auth.FirebaseAuth>((ref) {
  return firebase_auth.FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

// Data Sources
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) => AuthLocalDataSourceImpl(prefs),
    loading: () => null_ds.NullAuthLocalDataSource(),
    error: (error, stack) => null_ds.NullAuthLocalDataSource(),
  );
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthRemoteDataSourceImpl(firebaseAuth);
});

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return UserRemoteDataSourceImpl(firestore);
});

final groupsLocalDataSourceProvider = Provider<GroupsLocalDataSource>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) => GroupsLocalDataSourceImpl(prefs),
    loading: () => null_ds.NullGroupsLocalDataSource(),
    error: (error, stack) => null_ds.NullGroupsLocalDataSource(),
  );
});

final expensesLocalDataSourceProvider = Provider<ExpensesLocalDataSource>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) => ExpensesLocalDataSourceImpl(prefs),
    loading: () => null_ds.NullExpensesLocalDataSource(),
    error: (error, stack) => null_ds.NullExpensesLocalDataSource(),
  );
});

final notificationsLocalDataSourceProvider = Provider<NotificationsLocalDataSource>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) => NotificationsLocalDataSourceImpl(prefs),
    loading: () => null_ds.NullNotificationsLocalDataSource(),
    error: (error, stack) => null_ds.NullNotificationsLocalDataSource(),
  );
});

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final localDataSource = ref.watch(authLocalDataSourceProvider);
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final userRemoteDataSource = ref.watch(userRemoteDataSourceProvider);
  return AuthRepositoryImpl(localDataSource, remoteDataSource, userRemoteDataSource);
});

final groupsRemoteDataSourceProvider = Provider<GroupsRemoteDataSource>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return GroupsRemoteDataSourceImpl(firestore);
});

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  final localDataSource = ref.watch(groupsLocalDataSourceProvider);
  final remoteDataSource = ref.watch(groupsRemoteDataSourceProvider);
  return GroupsRepositoryImpl(localDataSource, remoteDataSource);
});

final expensesRemoteDataSourceProvider = Provider<ExpensesRemoteDataSource>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return ExpensesRemoteDataSourceImpl(firestore);
});

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  final localDataSource = ref.watch(expensesLocalDataSourceProvider);
  final remoteDataSource = ref.watch(expensesRemoteDataSourceProvider);
  return ExpensesRepositoryImpl(localDataSource, remoteDataSource);
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final dataSource = ref.watch(notificationsLocalDataSourceProvider);
  return NotificationsRepositoryImpl(dataSource);
});

