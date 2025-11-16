import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../expenses/domain/repositories/expenses_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final groupBalanceProvider = FutureProvider.family<double, String>((ref, groupId) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  
  if (user == null) return 0.0;
  
  final repository = ref.watch(expensesRepositoryProvider);
  final result = await repository.getUserBalanceInGroup(user.id, groupId);
  
  return result.when(
    success: (balance) => balance,
    error: (_) => 0.0,
  );
});

