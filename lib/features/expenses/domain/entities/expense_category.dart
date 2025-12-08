import 'package:flutter/material.dart';

enum ExpenseCategory {
  restaurant,
  shopping,
  transport,
  entertainment,
  accommodation,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.restaurant:
        return 'Restaurante';
      case ExpenseCategory.shopping:
        return 'Compras';
      case ExpenseCategory.transport:
        return 'Transporte';
      case ExpenseCategory.entertainment:
        return 'Ocio';
      case ExpenseCategory.accommodation:
        return 'Alojamiento';
      case ExpenseCategory.other:
        return 'Otros';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.restaurant:
        return Icons.restaurant;
      case ExpenseCategory.shopping:
        return Icons.shopping_cart;
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.accommodation:
        return Icons.hotel;
      case ExpenseCategory.other:
        return Icons.receipt;
    }
  }

  String get value {
    return name;
  }

  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}

