import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/debt.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../datasources/expenses_local_datasource.dart';
import '../datasources/expenses_remote_datasource.dart';

class ExpensesRepositoryImpl implements ExpensesRepository {
  final ExpensesLocalDataSource localDataSource;
  final ExpensesRemoteDataSource remoteDataSource;

  ExpensesRepositoryImpl(this.localDataSource, this.remoteDataSource);

  @override
  Future<Result<List<Expense>>> getGroupExpenses(String groupId) async {
    try {
      // Obtener desde Firestore
      final expenses = await remoteDataSource.getGroupExpenses(groupId);

      // Guardar en cache local (opcional)
      try {
        for (final expense in expenses) {
          await localDataSource.saveExpense(expense);
        }
      } catch (e) {
        // Si falla el cache, no es crítico
      }

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
    ExpenseCategory category = ExpenseCategory.other,
  }) async {
    try {
      if (description.isEmpty) {
        return const Error(ValidationFailure('La descripción es requerida'));
      }
      if (amount <= 0) {
        return const Error(ValidationFailure('El monto debe ser mayor a 0'));
      }
      if (splitAmounts.isEmpty) {
        return const Error(
            ValidationFailure('Debe haber al menos un participante'));
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
        category: category,
      );

      // Guardar en Firestore
      await remoteDataSource.createExpense(expense);

      // Guardar en cache local (opcional)
      try {
        await localDataSource.saveExpense(expense);
      } catch (e) {
        // Si falla el cache, no es crítico
      }

      return Success(expense);
    } catch (e) {
      return Error(ServerFailure('Error al agregar gasto: $e'));
    }
  }

  @override
  Future<Result<void>> deleteExpense(String expenseId) async {
    try {
      // Eliminar de Firestore
      await remoteDataSource.deleteExpense(expenseId);

      // Eliminar de cache local (opcional)
      try {
        await localDataSource.deleteExpense(expenseId);
      } catch (e) {
        // Si falla el cache, no es crítico
      }

      return const Success(null);
    } catch (e) {
      return Error(ServerFailure('Error al eliminar gasto: $e'));
    }
  }

  @override
  Future<Result<Expense>> updateExpense({
    required String expenseId,
    required String groupId,
    required String paidBy,
    required String description,
    required double amount,
    required DateTime date,
    required Map<String, double> splitAmounts,
    required DateTime createdAt,
    ExpenseCategory category = ExpenseCategory.other,
  }) async {
    try {
      if (description.isEmpty) {
        return const Error(ValidationFailure('La descripción es requerida'));
      }
      if (amount <= 0) {
        return const Error(ValidationFailure('El monto debe ser mayor a 0'));
      }
      if (splitAmounts.isEmpty) {
        return const Error(
            ValidationFailure('Debe haber al menos un participante'));
      }

      final updatedExpense = Expense(
        id: expenseId,
        groupId: groupId,
        paidBy: paidBy,
        description: description,
        amount: amount,
        date: date,
        splitAmounts: splitAmounts,
        createdAt: createdAt,
        category: category,
      );

      await remoteDataSource.updateExpense(updatedExpense);

      try {
        await localDataSource.saveExpense(updatedExpense);
      } catch (e) {
        // Si falla el cache, no es crítico
      }

      return Success(updatedExpense);
    } catch (e) {
      return Error(ServerFailure('Error al actualizar gasto: $e'));
    }
  }

  @override
  Future<Result<List<Debt>>> getGroupDebts(String groupId) async {
    try {
      // Obtener gastos desde Firestore
      final expenses = await remoteDataSource.getGroupExpenses(groupId);
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
      final userDebts = debts
          .where((debt) => debt.fromUserId == userId || debt.toUserId == userId)
          .toList();
      return Success(userDebts);
    } catch (e) {
      return Error(ServerFailure('Error al obtener deudas: $e'));
    }
  }

  @override
  Future<Result<double>> getUserBalanceInGroup(
      String userId, String groupId) async {
    try {
      // Obtener gastos del grupo desde Firestore
      final expenses = await remoteDataSource.getGroupExpenses(groupId);

      // Calcular balance neto del usuario
      double balance = 0.0;

      for (final expense in expenses) {
        // Si el usuario pagó, recibe dinero (positivo)
        if (expense.paidBy == userId) {
          balance += expense.amount;
        }

        // Si el usuario participó, debe su parte (negativo)
        if (expense.splitAmounts.containsKey(userId)) {
          balance -= expense.splitAmounts[userId]!;
        }
      }

      return Success(balance);
    } catch (e) {
      return Error(ServerFailure('Error al calcular balance: $e'));
    }
  }

  @override
  Future<Result<void>> settleDebt(
      String fromUserId, String toUserId, String groupId, double amount) async {
    try {
      if (amount <= 0) {
        return const Error(ValidationFailure('El monto debe ser mayor a 0'));
      }

      // Crear un gasto compensatorio que representa el pago de la deuda
      // El deudor (fromUserId) paga al acreedor (toUserId)
      final settlementExpense = Expense(
        id: const Uuid().v4(),
        groupId: groupId,
        paidBy: fromUserId, // El deudor paga
        description: 'Liquidación de deuda',
        amount: amount,
        date: DateTime.now(),
        splitAmounts: {
          toUserId: amount, // Solo el acreedor recibe el dinero
        },
        createdAt: DateTime.now(),
        category: ExpenseCategory.other,
      );

      // Guardar el gasto compensatorio en Firestore
      await remoteDataSource.createExpense(settlementExpense);

      // Guardar en cache local (opcional)
      try {
        await localDataSource.saveExpense(settlementExpense);
      } catch (e) {
        // Si falla el cache, no es crítico
      }

      return const Success(null);
    } catch (e) {
      return Error(ServerFailure('Error al liquidar deuda: $e'));
    }
  }

  List<Debt> _calculateDebts(List<Expense> expenses) {
    if (expenses.isEmpty) return [];

    // Calcular el balance neto de cada usuario
    final Map<String, double> netBalances = {};

    for (final expense in expenses) {
      // El pagador recibe dinero (positivo)
      netBalances[expense.paidBy] =
          (netBalances[expense.paidBy] ?? 0) + expense.amount;

      // Los participantes deben dinero (negativo)
      for (final entry in expense.splitAmounts.entries) {
        final participantId = entry.key;
        final amount = entry.value;
        netBalances[participantId] = (netBalances[participantId] ?? 0) - amount;
      }
    }

    // Simplificar deudas: los que deben (negativo) deben a los que tienen crédito (positivo)
    final List<Debt> debts = [];
    final debtors = <String, double>{};
    final creditors = <String, double>{};

    // Separar deudores y acreedores
    for (final entry in netBalances.entries) {
      if (entry.value < -0.01) {
        // Deudor (debe dinero)
        debtors[entry.key] = -entry.value;
      } else if (entry.value > 0.01) {
        // Acreedor (le deben dinero)
        creditors[entry.key] = entry.value;
      }
    }

    // Asignar deudas de deudores a acreedores
    final debtorsList = debtors.entries.toList();
    final creditorsList = creditors.entries.toList();

    int debtorIndex = 0;
    int creditorIndex = 0;

    while (debtorIndex < debtorsList.length &&
        creditorIndex < creditorsList.length) {
      final debtor = debtorsList[debtorIndex];
      final creditor = creditorsList[creditorIndex];

      final amount =
          debtor.value < creditor.value ? debtor.value : creditor.value;

      // Encontrar el grupo más relevante
      final relevantExpense = expenses.firstWhere(
        (e) =>
            (e.paidBy == creditor.key &&
                e.splitAmounts.containsKey(debtor.key)) ||
            (e.paidBy == debtor.key &&
                e.splitAmounts.containsKey(creditor.key)),
        orElse: () => expenses.first,
      );

      debts.add(Debt(
        fromUserId: debtor.key,
        toUserId: creditor.key,
        groupId: relevantExpense.groupId,
        amount: amount,
      ));

      // Actualizar balances
      debtorsList[debtorIndex] = MapEntry(debtor.key, debtor.value - amount);
      creditorsList[creditorIndex] =
          MapEntry(creditor.key, creditor.value - amount);

      // Avanzar índices
      if (debtorsList[debtorIndex].value < 0.01) {
        debtorIndex++;
      }
      if (creditorsList[creditorIndex].value < 0.01) {
        creditorIndex++;
      }
    }

    return debts;
  }

  @override
  Future<Result<void>> replaceUserIdInExpenses(
    String oldUserId,
    String newUserId,
  ) async {
    try {
      await remoteDataSource.replaceUserIdInExpenses(oldUserId, newUserId);
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure('Error al reemplazar usuario en gastos: $e'));
    }
  }

  @override
  Future<Result<List<Expense>>> getExpensesByUserId(String userId) async {
    try {
      final expenses = await remoteDataSource.getExpensesByUserId(userId);
      return Success(expenses);
    } catch (e) {
      return Error(ServerFailure('Error al obtener gastos por usuario: $e'));
    }
  }
}
