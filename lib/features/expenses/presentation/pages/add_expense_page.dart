import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/expense.dart';
import '../../../../core/di/providers.dart';
import '../providers/expenses_provider.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../groups/presentation/providers/group_members_provider.dart';
import '../../../groups/presentation/providers/group_balance_provider.dart';
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
  bool _isLoading = false;

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
          _selectedPaidBy = _isEditing
              ? widget.initialExpense!.paidBy
              : group.memberIds.first;
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
            )
          : await ref.read(addExpenseUseCaseProvider)(
              groupId: widget.groupId,
              paidBy: _selectedPaidBy!,
              description: description,
              amount: amount,
              date: _selectedDate,
              splitAmounts: splitAmounts,
            );

      setState(() => _isLoading = false);

      if (!mounted) return;

      result.when(
        success: (_) {
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
        error: (failure) {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
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
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Guardar cambios' : 'Agregar Gasto'),
            ),
          ],
        ),
      ),
    );
  }
}
