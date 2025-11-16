import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/expense.dart';

abstract class ExpensesLocalDataSource {
  Future<List<Expense>> getGroupExpenses(String groupId);
  Future<List<Expense>> getAllExpenses();
  Future<void> saveExpense(Expense expense);
  Future<void> deleteExpense(String expenseId);
}

class ExpensesLocalDataSourceImpl implements ExpensesLocalDataSource {
  final SharedPreferences prefs;

  ExpensesLocalDataSourceImpl(this.prefs);

  @override
  Future<List<Expense>> getGroupExpenses(String groupId) async {
    final expensesJson = prefs.getString('expenses') ?? '[]';
    final List<dynamic> expensesList = jsonDecode(expensesJson);
    
    return expensesList
        .map((json) => _expenseFromJson(json as Map<String, dynamic>))
        .where((expense) => expense.groupId == groupId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    final expensesJson = prefs.getString('expenses') ?? '[]';
    final List<dynamic> expensesList = jsonDecode(expensesJson);
    
    return expensesList
        .map((json) => _expenseFromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveExpense(Expense expense) async {
    final expensesJson = prefs.getString('expenses') ?? '[]';
    final List<dynamic> expensesList = jsonDecode(expensesJson);
    
    final expenseMap = _expenseToJson(expense);
    final index = expensesList.indexWhere(
      (json) => (json as Map<String, dynamic>)['id'] == expense.id,
    );

    if (index >= 0) {
      expensesList[index] = expenseMap;
    } else {
      expensesList.add(expenseMap);
    }

    await prefs.setString('expenses', jsonEncode(expensesList));
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    final expensesJson = prefs.getString('expenses') ?? '[]';
    final List<dynamic> expensesList = jsonDecode(expensesJson);
    
    expensesList.removeWhere(
      (json) => (json as Map<String, dynamic>)['id'] == expenseId,
    );

    await prefs.setString('expenses', jsonEncode(expensesList));
  }

  Expense _expenseFromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      paidBy: json['paidBy'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      splitAmounts: Map<String, double>.from(
        (json['splitAmounts'] as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> _expenseToJson(Expense expense) {
    return {
      'id': expense.id,
      'groupId': expense.groupId,
      'paidBy': expense.paidBy,
      'description': expense.description,
      'amount': expense.amount,
      'date': expense.date.toIso8601String(),
      'splitAmounts': expense.splitAmounts,
      'createdAt': expense.createdAt.toIso8601String(),
    };
  }
}


