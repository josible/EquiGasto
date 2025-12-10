import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/groups_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/currency.dart';

class CreateGroupDialog extends ConsumerStatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  ConsumerState<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Currency? _selectedCurrency;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCurrency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar una moneda')),
      );
      return;
    }

    final authState = ref.read(authStateProvider);
    final user = authState.value;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes estar autenticado para crear un grupo')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    debugPrint('💰 Creando grupo con moneda: ${_selectedCurrency!.code} (${_selectedCurrency!.symbol})');
    
    final createGroupUseCase = ref.read(createGroupUseCaseProvider);
    final result = await createGroupUseCase(
      _nameController.text.trim(),
      _descriptionController.text.trim(),
      user.id, // Este ID debe coincidir con request.auth.uid
      _selectedCurrency!,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    result.when(
      success: (group) {
        ref.invalidate(groupsListProvider);
        ref.invalidate(groupProvider(group.id));
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grupo creado exitosamente')),
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
    return AlertDialog(
      title: const Text('Crear Grupo'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del grupo',
                  hintText: 'Ej: Viaje a Cancún',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  // Construir la lista de items una vez
                  final dropdownItems = [
                    // Monedas principales primero
                    DropdownMenuItem<Currency>(
                      enabled: false,
                      value: null,
                      child: Text(
                        'Principales',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    ...Currency.mainCurrencies.map((currency) {
                      return DropdownMenuItem<Currency>(
                        value: currency,
                        child: Text(
                          '${currency.symbol} ${currency.displayName} (${currency.code})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                    // Separador
                    DropdownMenuItem<Currency>(
                      enabled: false,
                      value: null,
                      child: Divider(),
                    ),
                    // Otras monedas
                    DropdownMenuItem<Currency>(
                      enabled: false,
                      value: null,
                      child: Text(
                        'Otras monedas',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    ...Currency.values.where((c) => !Currency.mainCurrencies.contains(c)).map((currency) {
                      return DropdownMenuItem<Currency>(
                        value: currency,
                        child: Text(
                          '${currency.symbol} ${currency.displayName} (${currency.code})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ];

                  return DropdownButtonFormField<Currency>(
                    value: _selectedCurrency,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Moneda',
                      hintText: 'Selecciona una moneda',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Selecciona una moneda'),
                    items: dropdownItems,
                    selectedItemBuilder: (context) {
                      if (_selectedCurrency == null) {
                        return [const Text('Selecciona una moneda')];
                      }
                      // selectedItemBuilder debe devolver un widget para cada item en dropdownItems
                      // Incluyendo separadores y encabezados
                      return dropdownItems.map((item) {
                        if (item.value == null || item.value != _selectedCurrency) {
                          // Es un separador, encabezado, o una moneda no seleccionada
                          // Devolver un widget vacío o el mismo texto del item
                          return item.child ?? const SizedBox.shrink();
                        }
                        // Es la moneda seleccionada - usar texto con overflow controlado
                        return Text(
                          '${item.value!.symbol} ${item.value!.code}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        );
                      }).toList();
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'La moneda es obligatoria';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      debugPrint('💰 Moneda seleccionada en dropdown: ${value?.code} (${value?.symbol})');
                      setState(() {
                        _selectedCurrency = value;
                      });
                      debugPrint('💰 _selectedCurrency actualizado a: ${_selectedCurrency?.code} (${_selectedCurrency?.symbol})');
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleCreate,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }
}



