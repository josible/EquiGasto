import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../../../core/di/providers.dart';

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
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

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);
  final logoutUseCase = ref.watch(logoutUseCaseProvider);
  final updateProfileUseCase = ref.watch(updateProfileUseCaseProvider);
  return AuthNotifier(getCurrentUserUseCase, logoutUseCase, updateProfileUseCase);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final LogoutUseCase logoutUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  bool _isSettingUser = false;

  AuthNotifier(this.getCurrentUserUseCase, this.logoutUseCase, this.updateProfileUseCase)
      : super(const AsyncValue.loading()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    // No sobrescribir si se está estableciendo un usuario manualmente
    if (_isSettingUser) return;
    
    state = const AsyncValue.loading();
    final result = await getCurrentUserUseCase();
    
    // Verificar nuevamente antes de actualizar
    if (_isSettingUser) return;
    
    result.when(
      success: (user) {
        state = AsyncValue.data(user);
      },
      error: (failure) {
        state = AsyncValue.data(null);
      },
    );
  }

  void setUser(User user) {
    _isSettingUser = true;
    state = AsyncValue.data(user);
    // Resetear la bandera después de un breve momento
    Future.microtask(() => _isSettingUser = false);
  }

  Future<void> logout() async {
    final result = await logoutUseCase();
    result.when(
      success: (_) {
        state = const AsyncValue.data(null);
      },
      error: (failure) {
        // Mantener estado actual
      },
    );
  }

  Future<void> updateProfile(String userId, String name, String? avatarUrl) async {
    final result = await updateProfileUseCase(
      userId: userId,
      name: name,
      avatarUrl: avatarUrl,
    );
    result.when(
      success: (user) {
        setUser(user);
      },
      error: (failure) {
        // Mantener estado actual, el error se manejará en la UI
      },
    );
  }
}

