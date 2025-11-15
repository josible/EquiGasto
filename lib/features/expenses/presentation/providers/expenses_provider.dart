import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/add_expense_usecase.dart';
import '../../domain/usecases/get_group_debts_usecase.dart';
import '../../../../core/di/providers.dart';
import '../../domain/repositories/expenses_repository.dart';

final addExpenseUseCaseProvider = Provider<AddExpenseUseCase>((ref) {
  final repository = ref.watch(expensesRepositoryProvider);
  return AddExpenseUseCase(repository);
});

final getGroupDebtsUseCaseProvider = Provider<GetGroupDebtsUseCase>((ref) {
  final repository = ref.watch(expensesRepositoryProvider);
  return GetGroupDebtsUseCase(repository);
});

final groupExpensesProvider = FutureProvider.family<List<Expense>, String>((ref, groupId) async {
  final repository = ref.watch(expensesRepositoryProvider);
  final result = await repository.getGroupExpenses(groupId);

  return result.when(
    success: (expenses) => expenses,
    error: (_) => [],
  );
});

