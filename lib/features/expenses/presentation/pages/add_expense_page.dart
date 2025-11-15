import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../../../../core/di/providers.dart';
import '../providers/expenses_provider.dart';
import '../../../groups/domain/repositories/groups_repository.dart';

class AddExpensePage extends ConsumerStatefulWidget {
  final String groupId;

  const AddExpensePage({
    super.key,
    required this.groupId,
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

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
  }

  Future<void> _loadGroupMembers() async {
    final groupsRepository = ref.read(groupsRepositoryProvider);
    final result = await groupsRepository.getGroupById(widget.groupId);

    result.when(
      success: (group) {
        setState(() {
          _selectedPaidBy = group.memberIds.first;
          for (final memberId in group.memberIds) {
            _selectedMembers[memberId] = true;
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

    setState(() => _isLoading = true);

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final splitAmount = amount / selectedCount;

    final splitAmounts = <String, double>{};
    for (final entry in _selectedMembers.entries) {
      if (entry.value) {
        splitAmounts[entry.key] = splitAmount;
      }
    }

    final addExpenseUseCase = ref.read(addExpenseUseCaseProvider);
    final result = await addExpenseUseCase(
      groupId: widget.groupId,
      paidBy: _selectedPaidBy!,
      description: _descriptionController.text.trim(),
      amount: amount,
      date: _selectedDate,
      splitAmounts: splitAmounts,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(groupExpensesProvider(widget.groupId));
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto agregado exitosamente')),
        );
      },
      error: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupsRepository = ref.watch(groupsRepositoryProvider);
    final groupAsync = FutureProvider((ref) async {
      final result = await groupsRepository.getGroupById(widget.groupId);
      return result.when(
        success: (group) => group,
        error: (_) => throw Exception('Grupo no encontrado'),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Gasto'),
      ),
      body: ref.watch(groupAsync).when(
        data: (group) => SingleChildScrollView(
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
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El monto es requerido';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Ingrese un monto válido';
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
                  return RadioListTile<String>(
                    title: Text('Miembro ${memberId.substring(0, 8)}'),
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
                  return CheckboxListTile(
                    title: Text('Miembro ${memberId.substring(0, 8)}'),
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
                      : const Text('Agregar Gasto'),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

