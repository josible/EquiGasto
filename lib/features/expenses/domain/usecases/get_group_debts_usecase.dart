import '../../../../core/utils/result.dart';
import '../entities/debt.dart';
import '../repositories/expenses_repository.dart';

class GetGroupDebtsUseCase {
  final ExpensesRepository repository;

  GetGroupDebtsUseCase(this.repository);

  Future<Result<List<Debt>>> call(String groupId) {
    return repository.getGroupDebts(groupId);
  }
}








