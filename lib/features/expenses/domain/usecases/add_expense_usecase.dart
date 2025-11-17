import '../../../../core/utils/result.dart';
import '../entities/expense.dart';
import '../repositories/expenses_repository.dart';

class AddExpenseUseCase {
  final ExpensesRepository repository;

  AddExpenseUseCase(this.repository);

  Future<Result<Expense>> call({
    required String groupId,
    required String paidBy,
    required String description,
    required double amount,
    required DateTime date,
    required Map<String, double> splitAmounts,
  }) {
    return repository.addExpense(
      groupId: groupId,
      paidBy: paidBy,
      description: description,
      amount: amount,
      date: date,
      splitAmounts: splitAmounts,
    );
  }
}






