import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/create_notification_usecase.dart';
import 'null_datasources.dart' as null_ds;
import '../services/local_auth_service.dart';
import '../services/credentials_storage.dart';
import '../services/push_notifications_service.dart';
import '../services/app_update_service.dart';
import '../services/play_integrity_service.dart';

// Firebase
final firebaseAuthProvider = Provider<firebase_auth.FirebaseAuth>((ref) {
  return firebase_auth.FirebaseAuth.instance;
});

final localAuthenticationProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

final localAuthServiceProvider = Provider<LocalAuthService>((ref) {
  final localAuth = ref.watch(localAuthenticationProvider);
  return LocalAuthService(localAuth);
});

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final credentialsStorageProvider = Provider<CredentialsStorage>((ref) {
  final secureStorage = ref.watch(flutterSecureStorageProvider);
  return CredentialsStorage(secureStorage);
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseRemoteConfigProvider =
    Provider<FirebaseRemoteConfig>((ref) => FirebaseRemoteConfig.instance);

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final flutterLocalNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
  return FlutterLocalNotificationsPlugin();
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn.instance;
});

// SharedPreferences
final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
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
  final googleSignIn = ref.watch(googleSignInProvider);
  return AuthRemoteDataSourceImpl(firebaseAuth, googleSignIn);
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

final expensesLocalDataSourceProvider =
    Provider<ExpensesLocalDataSource>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) => ExpensesLocalDataSourceImpl(prefs),
    loading: () => null_ds.NullExpensesLocalDataSource(),
    error: (error, stack) => null_ds.NullExpensesLocalDataSource(),
  );
});

final notificationsLocalDataSourceProvider =
    Provider<NotificationsLocalDataSource>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) => NotificationsLocalDataSourceImpl(prefs),
    loading: () => null_ds.NullNotificationsLocalDataSource(),
    error: (error, stack) => null_ds.NullNotificationsLocalDataSource(),
  );
});

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return NotificationsRemoteDataSourceImpl(firestore);
});

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final localDataSource = ref.watch(authLocalDataSourceProvider);
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final userRemoteDataSource = ref.watch(userRemoteDataSourceProvider);
  final credentialsStorage = ref.watch(credentialsStorageProvider);
  final groupsRepository = ref.watch(groupsRepositoryProvider);
  final expensesRepository = ref.watch(expensesRepositoryProvider);
  return AuthRepositoryImpl(
    localDataSource,
    remoteDataSource,
    userRemoteDataSource,
    credentialsStorage,
    groupsRepository,
    expensesRepository,
  );
});

final groupsRemoteDataSourceProvider = Provider<GroupsRemoteDataSource>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return GroupsRemoteDataSourceImpl(firestore);
});

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  final localDataSource = ref.watch(groupsLocalDataSourceProvider);
  final remoteDataSource = ref.watch(groupsRemoteDataSourceProvider);
  final userRemoteDataSource = ref.watch(userRemoteDataSourceProvider);
  return GroupsRepositoryImpl(localDataSource, remoteDataSource, userRemoteDataSource);
});

final expensesRemoteDataSourceProvider =
    Provider<ExpensesRemoteDataSource>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return ExpensesRemoteDataSourceImpl(firestore);
});

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  final localDataSource = ref.watch(expensesLocalDataSourceProvider);
  final remoteDataSource = ref.watch(expensesRemoteDataSourceProvider);
  return ExpensesRepositoryImpl(localDataSource, remoteDataSource);
});

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  final localDataSource = ref.watch(notificationsLocalDataSourceProvider);
  final remoteDataSource = ref.watch(notificationsRemoteDataSourceProvider);
  return NotificationsRepositoryImpl(localDataSource, remoteDataSource);
});

final createNotificationUseCaseProvider =
    Provider<CreateNotificationUseCase>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return CreateNotificationUseCase(repository);
});

final pushNotificationsServiceProvider =
    Provider<PushNotificationsService>((ref) {
  final messaging = ref.watch(firebaseMessagingProvider);
  final localNotifications = ref.watch(flutterLocalNotificationsPluginProvider);
  return PushNotificationsService(ref, messaging, localNotifications);
});

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  final remoteConfig = ref.watch(firebaseRemoteConfigProvider);
  return AppUpdateService(remoteConfig);
});

final playIntegrityServiceProvider = Provider<PlayIntegrityService>((ref) {
  return PlayIntegrityService();
});
