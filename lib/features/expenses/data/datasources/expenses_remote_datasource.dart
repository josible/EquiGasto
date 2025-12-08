import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';

abstract class ExpensesRemoteDataSource {
  Future<List<Expense>> getGroupExpenses(String groupId);
  Future<void> createExpense(Expense expense);
  Future<void> deleteExpense(String expenseId);
  Future<void> updateExpense(Expense expense);
  Future<List<Expense>> getExpensesByUserId(String userId);
  Future<void> replaceUserIdInExpenses(String oldUserId, String newUserId);
}

class ExpensesRemoteDataSourceImpl implements ExpensesRemoteDataSource {
  final FirebaseFirestore firestore;

  ExpensesRemoteDataSourceImpl(this.firestore);

  @override
  Future<List<Expense>> getGroupExpenses(String groupId) async {
    try {
      // Intentar consulta con ordenamiento
      try {
        final querySnapshot = await firestore
            .collection('expenses')
            .where('groupId', isEqualTo: groupId)
            .orderBy('date', descending: true)
            .get();

        final expenses = querySnapshot.docs
            .map((doc) => _mapDocumentToExpense(doc))
            .toList();

        // Ordenar por fecha descendente en memoria por si acaso
        expenses.sort((a, b) => b.date.compareTo(a.date));

        return expenses;
      } catch (e) {
        // Si falla por falta de índice, intentar sin orderBy
        if (e.toString().contains('index') || e.toString().contains('index')) {
          final querySnapshot = await firestore
              .collection('expenses')
              .where('groupId', isEqualTo: groupId)
              .get();

          final expenses = querySnapshot.docs
              .map((doc) => _mapDocumentToExpense(doc))
              .toList();

          // Ordenar por fecha descendente en memoria
          expenses.sort((a, b) => b.date.compareTo(a.date));

          return expenses;
        }
        rethrow;
      }
    } catch (e) {
      throw Exception('Error al obtener gastos: $e');
    }
  }

  @override
  Future<void> createExpense(Expense expense) async {
    try {
      await firestore.collection('expenses').doc(expense.id).set({
        'id': expense.id,
        'groupId': expense.groupId,
        'paidBy': expense.paidBy,
        'description': expense.description,
        'amount': expense.amount,
        'date': Timestamp.fromDate(expense.date),
        'splitAmounts': expense.splitAmounts,
        'createdAt': Timestamp.fromDate(expense.createdAt),
        'category': expense.category.value,
      });
    } catch (e) {
      throw Exception('Error al crear gasto: $e');
    }
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    try {
      await firestore.collection('expenses').doc(expenseId).delete();
    } catch (e) {
      throw Exception('Error al eliminar gasto: $e');
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    try {
      await firestore.collection('expenses').doc(expense.id).update({
        'groupId': expense.groupId,
        'paidBy': expense.paidBy,
        'description': expense.description,
        'amount': expense.amount,
        'date': Timestamp.fromDate(expense.date),
        'splitAmounts': expense.splitAmounts,
        'createdAt': Timestamp.fromDate(expense.createdAt),
        'category': expense.category.value,
      });
    } catch (e) {
      throw Exception('Error al actualizar gasto: $e');
    }
  }

  @override
  Future<List<Expense>> getExpensesByUserId(String userId) async {
    try {
      // Buscar gastos donde el usuario es el que pagó
      final paidByQuery = await firestore
          .collection('expenses')
          .where('paidBy', isEqualTo: userId)
          .get();

      // Buscar gastos donde el usuario está en splitAmounts
      // Nota: Firestore no permite consultas directas en mapas, así que
      // necesitamos obtener todos los gastos y filtrar en memoria
      // O mejor, usar una consulta compuesta si es posible
      final allExpenses = <Expense>[];
      
      for (final doc in paidByQuery.docs) {
        allExpenses.add(_mapDocumentToExpense(doc));
      }

      // Para splitAmounts, necesitamos buscar en todos los gastos
      // Esto no es eficiente, pero es necesario para reemplazar usuarios ficticios
      // En producción, podrías considerar agregar un campo arrayContains para splitAmounts
      final allExpensesQuery = await firestore
          .collection('expenses')
          .get();

      for (final doc in allExpensesQuery.docs) {
        final expense = _mapDocumentToExpense(doc);
        // Si el usuario está en splitAmounts y no lo hemos agregado ya
        if (expense.splitAmounts.containsKey(userId) &&
            !allExpenses.any((e) => e.id == expense.id)) {
          allExpenses.add(expense);
        }
      }

      return allExpenses;
    } catch (e) {
      throw Exception('Error al obtener gastos por usuario: $e');
    }
  }

  @override
  Future<void> replaceUserIdInExpenses(
    String oldUserId,
    String newUserId,
  ) async {
    try {
      final expenses = await getExpensesByUserId(oldUserId);

      for (final expense in expenses) {
        final updatedSplitAmounts = <String, double>{};
        bool needsUpdate = false;

        // Reemplazar en splitAmounts
        for (final entry in expense.splitAmounts.entries) {
          if (entry.key == oldUserId) {
            updatedSplitAmounts[newUserId] = entry.value;
            needsUpdate = true;
          } else {
            updatedSplitAmounts[entry.key] = entry.value;
          }
        }

        // Reemplazar en paidBy si es necesario
        final updatedPaidBy = expense.paidBy == oldUserId ? newUserId : expense.paidBy;
        if (expense.paidBy == oldUserId) {
          needsUpdate = true;
        }

        if (needsUpdate) {
          final updatedExpense = Expense(
            id: expense.id,
            groupId: expense.groupId,
            paidBy: updatedPaidBy,
            description: expense.description,
            amount: expense.amount,
            date: expense.date,
            splitAmounts: updatedSplitAmounts,
            createdAt: expense.createdAt,
            category: expense.category,
          );

          await updateExpense(updatedExpense);
        }
      }
    } catch (e) {
      throw Exception('Error al reemplazar usuario en gastos: $e');
    }
  }

  Expense _mapDocumentToExpense(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: data['id'] as String,
      groupId: data['groupId'] as String,
      paidBy: data['paidBy'] as String,
      description: data['description'] as String,
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      splitAmounts: Map<String, double>.from(
        (data['splitAmounts'] as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      category: data['category'] != null
          ? ExpenseCategory.fromString(data['category'] as String)
          : ExpenseCategory.other,
    );
  }
}
