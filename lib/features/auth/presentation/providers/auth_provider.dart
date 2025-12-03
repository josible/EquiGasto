import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import '../../domain/usecases/link_google_account_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../../../core/di/providers.dart';

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

final loginWithGoogleUseCaseProvider = Provider<LoginWithGoogleUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginWithGoogleUseCase(repository);
});

final linkGoogleAccountUseCaseProvider =
    Provider<LinkGoogleAccountUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LinkGoogleAccountUseCase(repository);
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RegisterUseCase(repository);
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repository);
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUserUseCase(repository);
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return UpdateProfileUseCase(repository);
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ResetPasswordUseCase(repository);
});

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ChangePasswordUseCase(repository);
});

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<User?> {
  bool _isSettingUser = false;

  GetCurrentUserUseCase get _getCurrentUserUseCase =>
      ref.read(getCurrentUserUseCaseProvider);
  LogoutUseCase get _logoutUseCase => ref.read(logoutUseCaseProvider);
  UpdateProfileUseCase get _updateProfileUseCase =>
      ref.read(updateProfileUseCaseProvider);

  @override
  Future<User?> build() async {
    return _loadCurrentUser();
  }

  Future<User?> _loadCurrentUser() async {
    try {
      await ref.watch(sharedPreferencesProvider.future);
    } catch (_) {
      // Si SharedPreferences falla, continuamos igualmente
    }

    final result = await _getCurrentUserUseCase();
    return result.when(
      success: (user) => user,
      error: (_) => null,
    );
  }

  Future<void> refreshAuth() async {
    if (_isSettingUser) return;
    state = const AsyncValue.loading();
    final user = await _loadCurrentUser();
    if (_isSettingUser) return;
    state = AsyncValue.data(user);
  }

  void setUser(User user) {
    _isSettingUser = true;
    state = AsyncValue.data(user);
    Future.microtask(() => _isSettingUser = false);
  }

  Future<void> logout() async {
    final result = await _logoutUseCase();
    result.when(
      success: (_) => state = const AsyncValue.data(null),
      error: (_) {},
    );
  }

  Future<void> updateProfile(
    String userId,
    String name,
    String? avatarUrl,
  ) async {
    final result = await _updateProfileUseCase(
      userId: userId,
      name: name,
      avatarUrl: avatarUrl,
    );
    result.when(
      success: (user) => setUser(user),
      error: (_) {},
    );
  }
}
