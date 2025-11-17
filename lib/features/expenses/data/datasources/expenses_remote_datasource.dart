import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/expense.dart';

abstract class ExpensesRemoteDataSource {
  Future<List<Expense>> getGroupExpenses(String groupId);
  Future<void> createExpense(Expense expense);
  Future<void> deleteExpense(String expenseId);
  Future<void> updateExpense(Expense expense);
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
      });
    } catch (e) {
      throw Exception('Error al actualizar gasto: $e');
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
    );
  }
}
