import '../../../../core/utils/result.dart';
import '../repositories/expenses_repository.dart';

class DeleteExpenseUseCase {
  final ExpensesRepository repository;

  DeleteExpenseUseCase(this.repository);

  Future<Result<void>> call(String expenseId) {
    return repository.deleteExpense(expenseId);
  }
}
