import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../../../../core/di/providers.dart';
import '../providers/expenses_provider.dart';
import '../../../groups/domain/entities/group.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../groups/presentation/providers/group_members_provider.dart';
import '../../../groups/presentation/providers/group_balance_provider.dart';
import '../../../notifications/domain/entities/notification.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AddExpensePage extends ConsumerStatefulWidget {
  final String groupId;
  final Expense? initialExpense;

  const AddExpensePage({
    super.key,
    required this.groupId,
    this.initialExpense,
  });

  @override
  ConsumerState<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends ConsumerState<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedPaidBy;
  final Map<String, bool> _selectedMembers = {};
  Group? _currentGroup;
  bool _isLoading = false;
  ExpenseCategory _selectedCategory = ExpenseCategory.other;

  bool get _isEditing => widget.initialExpense != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFieldsFromExpense(widget.initialExpense!);
    }
    _loadGroupMembers();
  }

  void _populateFieldsFromExpense(Expense expense) {
    _descriptionController.text = expense.description;
    _amountController.text =
        expense.amount.toStringAsFixed(2).replaceAll('.', ',');
    _selectedDate = expense.date;
    _selectedPaidBy = expense.paidBy;
    for (final entry in expense.splitAmounts.entries) {
      _selectedMembers[entry.key] = true;
    }
  }

  Future<void> _loadGroupMembers() async {
    final groupsRepository = ref.read(groupsRepositoryProvider);
    final result = await groupsRepository.getGroupById(widget.groupId);

    result.when(
      success: (group) {
        setState(() {
          _currentGroup = group;
          if (_isEditing) {
            _selectedPaidBy = widget.initialExpense!.paidBy;
          } else {
            // Seleccionar el usuario actual por defecto
            final currentUser = ref.read(authStateProvider).value;
            if (currentUser != null &&
                group.memberIds.contains(currentUser.id)) {
              _selectedPaidBy = currentUser.id;
            } else {
              // Fallback al primer miembro si el usuario actual no está en el grupo
              _selectedPaidBy = group.memberIds.first;
            }
          }
          _selectedMembers.clear();
          for (final memberId in group.memberIds) {
            if (_isEditing) {
              _selectedMembers[memberId] =
                  widget.initialExpense!.splitAmounts.containsKey(memberId);
            } else {
              _selectedMembers[memberId] = true;
            }
          }
        });
      },
      error: (_) {},
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPaidBy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione quien pagó')),
      );
      return;
    }

    final selectedCount = _selectedMembers.values.where((v) => v).length;
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos un participante')),
      );
      return;
    }

    if (_isEditing) {
      final currentUser = ref.read(authStateProvider).value;
      if (currentUser?.id != widget.initialExpense!.paidBy) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solo el creador del gasto puede editarlo'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Normalizar el valor: reemplazar coma por punto para parsear
      final normalizedAmount = _amountController.text.replaceAll(',', '.');
      final amount = double.tryParse(normalizedAmount) ?? 0.0;
      final splitAmount = amount / selectedCount;

      final splitAmounts = <String, double>{};
      for (final entry in _selectedMembers.entries) {
        if (entry.value) {
          splitAmounts[entry.key] = splitAmount;
        }
      }

      final description = _descriptionController.text.trim();

      final result = _isEditing
          ? await ref.read(updateExpenseUseCaseProvider)(
              expenseId: widget.initialExpense!.id,
              groupId: widget.groupId,
              paidBy: _selectedPaidBy!,
              description: description,
              amount: amount,
              date: _selectedDate,
              splitAmounts: splitAmounts,
              createdAt: widget.initialExpense!.createdAt,
              category: _selectedCategory,
            )
          : await ref.read(addExpenseUseCaseProvider)(
              groupId: widget.groupId,
              paidBy: _selectedPaidBy!,
              description: description,
              amount: amount,
              date: _selectedDate,
              splitAmounts: splitAmounts,
              category: _selectedCategory,
            );

      setState(() => _isLoading = false);

      if (!mounted) return;

      await result.when(
        success: (expense) async {
          if (!_isEditing) {
            await _notifyParticipants(expense);
          }
          // Invalidar providers para refrescar la lista de gastos, deudas y balances
          ref.invalidate(groupExpensesProvider(widget.groupId));
          ref.invalidate(groupDebtsProvider(widget.groupId));
          ref.invalidate(groupBalanceProvider(widget.groupId));
          // También invalidar la lista de grupos para actualizar los balances
          ref.invalidate(groupsListProvider);

          if (mounted) {
            context.pop();
            // Esperar un momento antes de mostrar el mensaje para dar tiempo a refrescar
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isEditing
                        ? 'Gasto actualizado correctamente'
                        : 'Gasto agregado exitosamente'),
                  ),
                );
              }
            });
          }
        },
        error: (failure) async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _notifyParticipants(Expense expense) async {
    final group = _currentGroup;
    final currentUser = ref.read(authStateProvider).value;
    if (group == null || currentUser == null) return;

    final affectedUserIds = expense.splitAmounts.keys.toSet()
      ..remove(currentUser.id);
    if (affectedUserIds.isEmpty) return;

    final notificationUseCase = ref.read(createNotificationUseCaseProvider);
    final createdAt = DateTime.now();
    final amountLabel = expense.amount.toStringAsFixed(2);

    for (final userId in affectedUserIds) {
      final notification = AppNotification(
        id: const Uuid().v4(),
        userId: userId,
        type: NotificationType.expenseAdded,
        title: 'Nuevo gasto en ${group.name}',
        message:
            '${currentUser.name} agregó ${expense.description} por €$amountLabel',
        data: {
          'groupId': expense.groupId,
          'expenseId': expense.id,
          'amount': expense.amount,
          'description': expense.description,
        },
        isRead: false,
        createdAt: createdAt,
      );

      final result = await notificationUseCase(notification);
      result.when(
        success: (_) {},
        error: (failure) {
          debugPrint('Error al crear notificación: ${failure.message}');
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Gasto' : 'Agregar Gasto'),
      ),
      body: groupAsync.when(
        data: (group) {
          final membersAsync = ref.watch(groupMembersProvider(group.memberIds));

          return membersAsync.when(
            data: (members) => _buildForm(context, group, members),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildForm(context, group, []),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildForm(BuildContext context, group, List members) {
    // Crear un mapa de userId -> User para búsqueda rápida
    final membersMap = <String, User>{};
    for (final member in members) {
      if (member is User) {
        membersMap[member.id] = member;
      }
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Ej: Cena en restaurante',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La descripción es requerida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+([.,]\d{0,2})?')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Importe',
                      prefixText: '€ ',
                      hintText: '0,00',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El importe es requerido';
                      }
                      // Reemplazar coma por punto para parsear
                      final normalizedValue = value.replaceAll(',', '.');
                      final amount = double.tryParse(normalizedValue);
                      if (amount == null || amount <= 0) {
                        return 'Ingrese un importe válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Fecha'),
                    subtitle: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Categoría',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ExpenseCategory.values.map((category) {
                      final isSelected = _selectedCategory == category;
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              category.icon,
                              size: 18,
                              color: isSelected ? Colors.white : null,
                            ),
                            const SizedBox(width: 4),
                            Text(category.displayName),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          }
                        },
                        selectedColor: Theme.of(context).primaryColor,
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quién pagó',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...group.memberIds.map((memberId) {
                    final member = membersMap[memberId];
                    final displayName = member != null
                        ? member.name
                        : 'Miembro ${memberId.substring(0, 8)}';
                    return RadioListTile<String>(
                      title: Text(displayName),
                      value: memberId,
                      groupValue: _selectedPaidBy,
                      onChanged: (value) {
                        setState(() => _selectedPaidBy = value);
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  const Text(
                    'Dividir entre',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...group.memberIds.map((memberId) {
                    final member = membersMap[memberId];
                    final displayName = member != null
                        ? member.name
                        : 'Miembro ${memberId.substring(0, 8)}';
                    return CheckboxListTile(
                      title: Text(displayName),
                      value: _selectedMembers[memberId] ?? false,
                      onChanged: (value) {
                        setState(() => _selectedMembers[memberId] = value ?? false);
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Botón fijo en la parte inferior
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isEditing ? 'Guardar cambios' : 'Agregar Gasto',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
