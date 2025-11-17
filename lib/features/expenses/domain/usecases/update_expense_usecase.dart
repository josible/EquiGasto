import '../../../../core/utils/result.dart';
import '../entities/expense.dart';
import '../repositories/expenses_repository.dart';

class UpdateExpenseUseCase {
  final ExpensesRepository repository;

  UpdateExpenseUseCase(this.repository);

  Future<Result<Expense>> call({
    required String expenseId,
    required String groupId,
    required String paidBy,
    required String description,
    required double amount,
    required DateTime date,
    required Map<String, double> splitAmounts,
    required DateTime createdAt,
  }) {
    return repository.updateExpense(
      expenseId: expenseId,
      groupId: groupId,
      paidBy: paidBy,
      description: description,
      amount: amount,
      date: date,
      splitAmounts: splitAmounts,
      createdAt: createdAt,
    );
  }
}
