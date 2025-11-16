import '../../../../core/utils/result.dart';
import '../entities/expense.dart';
import '../entities/debt.dart';

abstract class ExpensesRepository {
  Future<Result<List<Expense>>> getGroupExpenses(String groupId);
  Future<Result<Expense>> addExpense({
    required String groupId,
    required String paidBy,
    required String description,
    required double amount,
    required DateTime date,
    required Map<String, double> splitAmounts,
  });
  Future<Result<void>> deleteExpense(String expenseId);
  Future<Result<List<Debt>>> getGroupDebts(String groupId);
  Future<Result<List<Debt>>> getUserDebts(String userId);
  Future<Result<double>> getUserBalanceInGroup(String userId, String groupId);
  Future<Result<void>> settleDebt(String fromUserId, String toUserId, String groupId, double amount);
}


