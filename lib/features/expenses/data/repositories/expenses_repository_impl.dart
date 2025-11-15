import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/debt.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../datasources/expenses_local_datasource.dart';

class ExpensesRepositoryImpl implements ExpensesRepository {
  final ExpensesLocalDataSource localDataSource;

  ExpensesRepositoryImpl(this.localDataSource);

  @override
  Future<Result<List<Expense>>> getGroupExpenses(String groupId) async {
    try {
      final expenses = await localDataSource.getGroupExpenses(groupId);
      return Success(expenses);
    } catch (e) {
      return Error(ServerFailure('Error al obtener gastos: $e'));
    }
  }

  @override
  Future<Result<Expense>> addExpense({
    required String groupId,
    required String paidBy,
    required String description,
    required double amount,
    required DateTime date,
    required Map<String, double> splitAmounts,
  }) async {
    try {
      if (description.isEmpty) {
        return const Error(ValidationFailure('La descripción es requerida'));
      }
      if (amount <= 0) {
        return const Error(ValidationFailure('El monto debe ser mayor a 0'));
      }
      if (splitAmounts.isEmpty) {
        return const Error(ValidationFailure('Debe haber al menos un participante'));
      }

      final expense = Expense(
        id: const Uuid().v4(),
        groupId: groupId,
        paidBy: paidBy,
        description: description,
        amount: amount,
        date: date,
        splitAmounts: splitAmounts,
        createdAt: DateTime.now(),
      );

      await localDataSource.saveExpense(expense);
      return Success(expense);
    } catch (e) {
      return Error(ServerFailure('Error al agregar gasto: $e'));
    }
  }

  @override
  Future<Result<void>> deleteExpense(String expenseId) async {
    try {
      await localDataSource.deleteExpense(expenseId);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure('Error al eliminar gasto: $e'));
    }
  }

  @override
  Future<Result<List<Debt>>> getGroupDebts(String groupId) async {
    try {
      final expenses = await localDataSource.getGroupExpenses(groupId);
      final debts = _calculateDebts(expenses);
      return Success(debts);
    } catch (e) {
      return Error(ServerFailure('Error al calcular deudas: $e'));
    }
  }

  @override
  Future<Result<List<Debt>>> getUserDebts(String userId) async {
    try {
      final allExpenses = await localDataSource.getAllExpenses();
      final debts = _calculateDebts(allExpenses);
      final userDebts = debts.where((debt) => 
        debt.fromUserId == userId || debt.toUserId == userId
      ).toList();
      return Success(userDebts);
    } catch (e) {
      return Error(ServerFailure('Error al obtener deudas: $e'));
    }
  }

  @override
  Future<Result<void>> settleDebt(String fromUserId, String toUserId, String groupId, double amount) async {
    try {
      // Mock: En producción esto actualizaría el estado de las deudas
      await Future.delayed(const Duration(milliseconds: 300));
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure('Error al liquidar deuda: $e'));
    }
  }

  List<Debt> _calculateDebts(List<Expense> expenses) {
    final Map<String, Map<String, double>> balances = {};

    for (final expense in expenses) {
      // Inicializar balance del pagador
      if (!balances.containsKey(expense.paidBy)) {
        balances[expense.paidBy] = {};
      }

      // Distribuir el gasto entre los participantes
      for (final entry in expense.splitAmounts.entries) {
        final participantId = entry.key;
        final amount = entry.value;

        // Inicializar balance del participante
        if (!balances.containsKey(participantId)) {
          balances[participantId] = {};
        }

        if (participantId != expense.paidBy) {
          // El participante debe al pagador
          balances[participantId]![expense.paidBy] = 
            (balances[participantId]![expense.paidBy] ?? 0) + amount;
          // El pagador le debe al participante (negativo)
          balances[expense.paidBy]![participantId] = 
            (balances[expense.paidBy]![participantId] ?? 0) - amount;
        }
      }
    }

    // Convertir balances a deudas simplificadas
    final List<Debt> debts = [];
    final processedPairs = <String>{};

    for (final fromUser in balances.keys) {
      for (final toUser in balances[fromUser]!.keys) {
        final amount = balances[fromUser]![toUser]!;
        
        if (amount > 0.01) { // Tolerancia para errores de punto flotante
          final pairKey = '${fromUser}_$toUser';
          final reversePairKey = '${toUser}_$fromUser';

          if (!processedPairs.contains(pairKey) && !processedPairs.contains(reversePairKey)) {
            // Encontrar el grupo más relevante (por simplicidad, usar el primero)
            final relevantExpense = expenses.firstWhere(
              (e) => (e.paidBy == fromUser && e.splitAmounts.containsKey(toUser)) ||
                     (e.paidBy == toUser && e.splitAmounts.containsKey(fromUser)),
              orElse: () => expenses.first,
            );

            debts.add(Debt(
              fromUserId: fromUser,
              toUserId: toUser,
              groupId: relevantExpense.groupId,
              amount: amount,
            ));
            processedPairs.add(pairKey);
          }
        }
      }
    }

    return debts;
  }
}

