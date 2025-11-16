import '../../../../core/utils/result.dart';
import '../repositories/expenses_repository.dart';

class SettleDebtUseCase {
  final ExpensesRepository repository;

  SettleDebtUseCase(this.repository);

  Future<Result<void>> call({
    required String fromUserId,
    required String toUserId,
    required String groupId,
    required double amount,
  }) {
    return repository.settleDebt(fromUserId, toUserId, groupId, amount);
  }
}

